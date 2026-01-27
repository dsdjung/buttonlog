package com.buttonlog.app.di

import android.annotation.SuppressLint
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.provider.Settings
import com.buttonlog.app.BuildConfig
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.ApiConfig
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Named
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    private const val PREFS_NAME = "buttonlog_prefs"
    private const val KEY_AUTH_TOKEN = "auth_token"

    @Provides
    @Singleton
    fun provideSharedPreferences(@ApplicationContext context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    @Provides
    @Singleton
    fun provideGson(): Gson {
        return GsonBuilder()
            .registerTypeAdapter(java.util.Date::class.java, ISO8601DateAdapter())
            .create()
    }

    /**
     * Custom TypeAdapter that properly handles ISO8601 dates with UTC timezone.
     * The backend sends dates like "2026-01-26T15:30:00Z" or "2026-01-26T15:30:00.123456Z"
     * The 'Z' suffix indicates UTC time, which needs to be converted to local timezone for display.
     *
     * Note: SimpleDateFormat only supports milliseconds (SSS, 3 digits), not microseconds.
     * We truncate microseconds to milliseconds before parsing.
     */
    private class ISO8601DateAdapter : com.google.gson.TypeAdapter<java.util.Date>() {
        // UTC timezone for parsing - dates from backend are always in UTC
        private val utcTimezone = java.util.TimeZone.getTimeZone("UTC")

        // Format patterns to try (in order of preference)
        private val formatPatterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",      // Most common: 2026-01-27T04:13:58Z
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",  // With millis: 2026-01-27T04:13:58.123Z
            "yyyy-MM-dd'T'HH:mm:ssXXX",      // With offset: 2026-01-27T04:13:58+00:00
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX",  // Millis + offset
            "yyyy-MM-dd'T'HH:mm:ss"          // No timezone (assume UTC)
        )

        override fun write(out: com.google.gson.stream.JsonWriter, value: java.util.Date?) {
            if (value == null) {
                out.nullValue()
            } else {
                val format = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", java.util.Locale.US).apply {
                    timeZone = utcTimezone
                }
                out.value(format.format(value))
            }
        }

        override fun read(reader: com.google.gson.stream.JsonReader): java.util.Date? {
            if (reader.peek() == com.google.gson.stream.JsonToken.NULL) {
                reader.nextNull()
                return null
            }
            var dateString = reader.nextString()

            // Normalize the date string:
            // Truncate microseconds to milliseconds (SimpleDateFormat only supports SSS)
            // e.g., "2026-01-26T15:30:00.123456Z" -> "2026-01-26T15:30:00.123Z"
            val microsecondPattern = Regex("""(\.\d{3})\d+(Z|[+-])""")
            dateString = dateString.replace(microsecondPattern, "$1$2")

            // Try each format pattern - create new SimpleDateFormat each time for thread safety
            for (pattern in formatPatterns) {
                try {
                    val format = java.text.SimpleDateFormat(pattern, java.util.Locale.US).apply {
                        timeZone = utcTimezone
                    }
                    val date = format.parse(dateString)
                    if (date != null) {
                        android.util.Log.d("ISO8601DateAdapter", "Parsed '$dateString' with pattern '$pattern' -> epoch=${date.time}, localTime=${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z", java.util.Locale.US).apply { timeZone = java.util.TimeZone.getDefault() }.format(date)}")
                        return date
                    }
                } catch (_: java.text.ParseException) {
                    // Try next format
                }
            }
            // If all formats fail, return null
            android.util.Log.w("ISO8601DateAdapter", "Failed to parse date: $dateString")
            return null
        }
    }

    @SuppressLint("HardwareIds")
    @Provides
    @Singleton
    @Named("deviceId")
    fun provideDeviceId(@ApplicationContext context: Context): String {
        return Settings.Secure.getString(context.contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(
        sharedPreferences: SharedPreferences,
        @Named("deviceId") deviceId: String
    ): Interceptor {
        return Interceptor { chain ->
            val original = chain.request()
            val token = sharedPreferences.getString(KEY_AUTH_TOKEN, null)

            val requestBuilder = original.newBuilder()
                .header(ApiConfig.HEADER_CONTENT_TYPE, ApiConfig.CONTENT_TYPE_JSON)
                .header(ApiConfig.HEADER_ACCEPT, ApiConfig.CONTENT_TYPE_JSON)
                // Client version tracking headers
                .header(ApiConfig.HEADER_APP_VERSION, BuildConfig.VERSION_NAME)
                .header(ApiConfig.HEADER_PLATFORM, "android")
                .header(ApiConfig.HEADER_DEVICE_ID, deviceId)

            if (!token.isNullOrEmpty()) {
                requestBuilder.header(ApiConfig.HEADER_AUTHORIZATION, "Bearer $token")
            }

            chain.proceed(requestBuilder.build())
        }
    }

    @Provides
    @Singleton
    @Named("authResponseInterceptor")
    fun provideAuthResponseInterceptor(sharedPreferences: SharedPreferences): Interceptor {
        return Interceptor { chain ->
            val response = chain.proceed(chain.request())

            // Auto-logout on 401 Unauthorized responses
            if (response.code == 401) {
                // Clear auth token - app will detect logged out state
                sharedPreferences.edit()
                    .remove(KEY_AUTH_TOKEN)
                    .apply()
            }

            response
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        authInterceptor: Interceptor,
        @Named("authResponseInterceptor") authResponseInterceptor: Interceptor
    ): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authResponseInterceptor)  // Check responses for 401
            .connectTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(ApiConfig.TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .build()
    }

    @Provides
    @Singleton
    fun provideRetrofit(okHttpClient: OkHttpClient, gson: Gson): Retrofit {
        return Retrofit.Builder()
            .baseUrl(ApiConfig.BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()
    }

    @Provides
    @Singleton
    fun provideAPIService(retrofit: Retrofit): APIService {
        return retrofit.create(APIService::class.java)
    }
}
