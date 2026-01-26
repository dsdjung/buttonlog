package com.buttonlog.app.integration

import android.util.Log
import com.buttonlog.app.BuildConfig

/**
 * Configuration for integration tests.
 *
 * The base URL is determined by:
 * 1. System property "test.api.baseUrl" (set via -Dtest.api.baseUrl=...)
 * 2. BuildConfig.API_BASE_URL from the current product flavor
 *
 * This allows running tests against:
 * - Local dev server: ./gradlew connectedDevelopmentDebugAndroidTest -Dtest.api.baseUrl=http://10.0.2.2:4000/api/
 * - Staging server: ./gradlew connectedStagingDebugAndroidTest
 * - Production (sanity only): ./gradlew connectedProductionDebugAndroidTest
 */
object IntegrationTestConfig {

    private const val TAG = "IntegrationTestConfig"

    /**
     * The API base URL for integration tests.
     * Reads from system property first, falls back to BuildConfig.
     */
    val apiBaseUrl: String by lazy {
        val systemUrl = System.getProperty("test.api.baseUrl")
        val url = if (!systemUrl.isNullOrBlank()) {
            Log.d(TAG, "Using API URL from system property: $systemUrl")
            systemUrl
        } else {
            Log.d(TAG, "Using API URL from BuildConfig: ${BuildConfig.API_BASE_URL}")
            BuildConfig.API_BASE_URL
        }

        // Ensure URL ends with /
        if (url.endsWith("/")) url else "$url/"
    }

    /**
     * Test user credentials for integration tests.
     * These accounts exist in both local dev and staging environments.
     *
     * Android uses: dsdjungtest1@gmail.com
     * iOS uses: dsdjungtest@gmail.com
     */
    object TestCredentials {
        // Primary Android test user
        const val TEST_EMAIL = "dsdjungtest1@gmail.com"
        const val TEST_PASSWORD = "Test123!"  // Update this to the actual password
        const val TEST_USERNAME = "dsdjungtest1"

        // Secondary test user (iOS test account) for friend operations
        const val TEST_EMAIL_2 = "dsdjungtest@gmail.com"
        const val TEST_PASSWORD_2 = "Test123!"  // Update this to the actual password
        const val TEST_USERNAME_2 = "dsdjungtest"
    }

    /**
     * Timeouts for integration tests (in milliseconds)
     */
    object Timeouts {
        const val API_CALL = 30_000L  // 30 seconds for API calls
        const val TEST_OVERALL = 60_000L  // 60 seconds per test
    }

    /**
     * Check if we're running against a local development server.
     */
    val isLocalDev: Boolean
        get() = apiBaseUrl.contains("10.0.2.2") || apiBaseUrl.contains("localhost")

    /**
     * Check if we're running against staging.
     */
    val isStaging: Boolean
        get() = apiBaseUrl.contains("staging")

    /**
     * Check if we're running against production.
     */
    val isProduction: Boolean
        get() = apiBaseUrl.contains("buttonlog.com") && !isStaging
}
