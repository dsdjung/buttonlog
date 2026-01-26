package com.buttonlog.app.integration

import android.util.Log
import com.buttonlog.app.data.api.APIService
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import org.junit.After
import org.junit.Before
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Base class for integration tests that need to make real API calls.
 *
 * This class sets up a real Retrofit instance (not mocked) that connects
 * to the configured API server. Use this for testing actual API behavior.
 *
 * Usage:
 *   class MyIntegrationTest : BaseIntegrationTest() {
 *       @Test
 *       fun testSomething() = runIntegrationTest {
 *           val response = apiService.someEndpoint()
 *           // assertions
 *       }
 *   }
 */
abstract class BaseIntegrationTest {

    protected lateinit var apiService: APIService
    protected lateinit var httpClient: OkHttpClient
    protected lateinit var gson: Gson

    // Store auth token for authenticated requests
    protected var authToken: String? = null

    companion object {
        private const val TAG = "IntegrationTest"
    }

    @Before
    open fun setUp() {
        Log.i(TAG, "Setting up integration test")
        Log.i(TAG, "API Base URL: ${IntegrationTestConfig.apiBaseUrl}")

        gson = GsonBuilder()
            .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
            .create()

        // Create logging interceptor
        val loggingInterceptor = HttpLoggingInterceptor { message ->
            Log.d(TAG, message)
        }.apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        // Create OkHttp client with auth and logging
        httpClient = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val original = chain.request()
                val builder = original.newBuilder()

                // Add auth token if available
                authToken?.let { token ->
                    builder.addHeader("Authorization", "Bearer $token")
                }

                builder.addHeader("Content-Type", "application/json")
                builder.addHeader("Accept", "application/json")

                chain.proceed(builder.build())
            }
            .addInterceptor(loggingInterceptor)
            .connectTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .readTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .writeTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .build()

        // Create Retrofit instance
        val retrofit = Retrofit.Builder()
            .baseUrl(IntegrationTestConfig.apiBaseUrl)
            .client(httpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        apiService = retrofit.create(APIService::class.java)

        Log.i(TAG, "Integration test setup complete")
    }

    @After
    open fun tearDown() {
        Log.i(TAG, "Tearing down integration test")
        authToken = null
    }

    /**
     * Run an integration test with proper timeout handling.
     */
    protected fun runIntegrationTest(
        timeout: Long = IntegrationTestConfig.Timeouts.TEST_OVERALL,
        block: suspend () -> Unit
    ) = runBlocking {
        withTimeout(timeout) {
            block()
        }
    }

    /**
     * Login with test credentials and store the auth token.
     * Call this at the start of tests that need authentication.
     */
    protected suspend fun loginTestUser(
        email: String = IntegrationTestConfig.TestCredentials.TEST_EMAIL,
        password: String = IntegrationTestConfig.TestCredentials.TEST_PASSWORD
    ): Boolean {
        return try {
            Log.i(TAG, "Logging in test user: $email")
            val response = apiService.login(
                com.buttonlog.app.data.api.LoginCredentials(email, password)
            )
            if (response.success) {
                val data = response.data
                authToken = data?.token
                Log.i(TAG, "Login successful, token obtained")

                // Recreate API service with new token
                recreateApiServiceWithToken()
                true
            } else {
                Log.e(TAG, "Login failed: ${response.error?.message}")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Login exception: ${e.message}", e)
            false
        }
    }

    /**
     * Recreate the API service with the auth token in the header.
     * This is needed because OkHttp interceptors use the token at request time.
     */
    private fun recreateApiServiceWithToken() {
        val loggingInterceptor = HttpLoggingInterceptor { message ->
            Log.d(TAG, message)
        }.apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        httpClient = OkHttpClient.Builder()
            .addInterceptor { chain ->
                val original = chain.request()
                val builder = original.newBuilder()

                authToken?.let { token ->
                    builder.addHeader("Authorization", "Bearer $token")
                }

                builder.addHeader("Content-Type", "application/json")
                builder.addHeader("Accept", "application/json")

                chain.proceed(builder.build())
            }
            .addInterceptor(loggingInterceptor)
            .connectTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .readTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .writeTimeout(IntegrationTestConfig.Timeouts.API_CALL, TimeUnit.MILLISECONDS)
            .build()

        val retrofit = Retrofit.Builder()
            .baseUrl(IntegrationTestConfig.apiBaseUrl)
            .client(httpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        apiService = retrofit.create(APIService::class.java)
    }

    /**
     * Skip test if running against production (for destructive tests).
     */
    protected fun skipIfProduction(reason: String = "Test skipped in production environment") {
        if (IntegrationTestConfig.isProduction) {
            Log.w(TAG, reason)
            org.junit.Assume.assumeFalse(
                "Skipping test in production: $reason",
                IntegrationTestConfig.isProduction
            )
        }
    }

    /**
     * Generate a unique test identifier for test data.
     */
    protected fun uniqueTestId(): String {
        return "test_${System.currentTimeMillis()}_${(1000..9999).random()}"
    }
}
