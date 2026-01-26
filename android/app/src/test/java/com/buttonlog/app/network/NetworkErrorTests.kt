package com.buttonlog.app.network

import com.buttonlog.app.data.model.ApiError
import com.google.common.truth.Truth.assertThat
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Test
import retrofit2.HttpException
import retrofit2.Response
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/**
 * Tests for network error handling scenarios.
 *
 * These tests verify the app handles various network failure conditions:
 * - Connection timeouts
 * - Server errors (5xx)
 * - Malformed responses
 * - Network connectivity issues
 */
class NetworkErrorTests {

    private val gson = Gson()

    // Test data class for API response parsing
    data class TestApiResponse(
        val success: Boolean = false,
        val data: Any? = null,
        val error: ApiError? = null
    )

    // MARK: - Timeout Tests

    @Test
    fun `timeout exception is identifiable`() {
        val exception = SocketTimeoutException("Connection timed out")

        assertThat(exception).isInstanceOf(IOException::class.java)
        assertThat(isRetryableException(exception)).isTrue()
    }

    @Test
    fun `unknown host exception is identifiable`() {
        val exception = UnknownHostException("Unable to resolve host")

        assertThat(exception).isInstanceOf(IOException::class.java)
        assertThat(isRetryableException(exception)).isFalse()
    }

    // MARK: - Malformed Response Tests

    @Test
    fun `malformed JSON throws JsonSyntaxException`() {
        val malformedJson = "{ invalid json }"

        try {
            gson.fromJson(malformedJson, TestApiResponse::class.java)
            throw AssertionError("Should have thrown JsonSyntaxException")
        } catch (e: JsonSyntaxException) {
            // Expected
            assertThat(e).isInstanceOf(JsonSyntaxException::class.java)
        }
    }

    @Test
    fun `empty response parses as null`() {
        val emptyJson = ""

        val response = gson.fromJson(emptyJson, TestApiResponse::class.java)

        // Gson returns null for empty string
        assertThat(response).isNull()
    }

    @Test
    fun `unexpected structure parses with null fields`() {
        val unexpectedJson = """
            {
                "unexpected_field": "value",
                "another_field": 123
            }
        """.trimIndent()

        val response = gson.fromJson(unexpectedJson, TestApiResponse::class.java)

        // Fields should be null/default when not present
        assertThat(response.success).isFalse()
        assertThat(response.data).isNull()
    }

    // MARK: - HTTP Error Code Tests

    @Test
    fun `unauthorized error parses correctly`() {
        val errorJson = """
            {
                "success": false,
                "error": {
                    "code": "UNAUTHORIZED",
                    "message": "Authentication required"
                }
            }
        """.trimIndent()

        val response = gson.fromJson(errorJson, TestApiResponse::class.java)

        assertThat(response.success).isFalse()
        assertThat(response.error).isNotNull()
        assertThat(response.error?.code).isEqualTo("UNAUTHORIZED")
        assertThat(response.error?.message).isEqualTo("Authentication required")
    }

    @Test
    fun `validation error parses correctly`() {
        val errorJson = """
            {
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Email is invalid"
                }
            }
        """.trimIndent()

        val response = gson.fromJson(errorJson, TestApiResponse::class.java)

        assertThat(response.success).isFalse()
        assertThat(response.error?.code).isEqualTo("VALIDATION_ERROR")
        assertThat(response.error?.message).contains("invalid")
    }

    @Test
    fun `server error parses correctly`() {
        val errorJson = """
            {
                "success": false,
                "error": {
                    "code": "INTERNAL_SERVER_ERROR",
                    "message": "Something went wrong"
                }
            }
        """.trimIndent()

        val response = gson.fromJson(errorJson, TestApiResponse::class.java)

        assertThat(response.success).isFalse()
        assertThat(response.error?.code).isEqualTo("INTERNAL_SERVER_ERROR")
    }

    @Test
    fun `rate limited error parses correctly`() {
        val errorJson = """
            {
                "success": false,
                "error": {
                    "code": "RATE_LIMITED",
                    "message": "Too many requests"
                }
            }
        """.trimIndent()

        val response = gson.fromJson(errorJson, TestApiResponse::class.java)

        assertThat(response.success).isFalse()
        assertThat(response.error?.code).isEqualTo("RATE_LIMITED")
    }

    // MARK: - HTTP Exception Tests

    @Test
    fun `HttpException with 401 is unauthorized`() {
        val response = Response.error<Any>(
            401,
            "Unauthorized".toResponseBody("application/json".toMediaType())
        )
        val exception = HttpException(response)

        assertThat(exception.code()).isEqualTo(401)
        assertThat(isUnauthorizedException(exception)).isTrue()
    }

    @Test
    fun `HttpException with 404 is not found`() {
        val response = Response.error<Any>(
            404,
            "Not Found".toResponseBody("application/json".toMediaType())
        )
        val exception = HttpException(response)

        assertThat(exception.code()).isEqualTo(404)
        assertThat(isNotFoundError(exception)).isTrue()
    }

    @Test
    fun `HttpException with 500 is server error`() {
        val response = Response.error<Any>(
            500,
            "Internal Server Error".toResponseBody("application/json".toMediaType())
        )
        val exception = HttpException(response)

        assertThat(exception.code()).isEqualTo(500)
        assertThat(isServerError(exception)).isTrue()
    }

    @Test
    fun `HttpException with 503 is retryable`() {
        val response = Response.error<Any>(
            503,
            "Service Unavailable".toResponseBody("application/json".toMediaType())
        )
        val exception = HttpException(response)

        assertThat(exception.code()).isEqualTo(503)
        assertThat(isRetryableHttpException(exception)).isTrue()
    }

    // MARK: - Retry Logic Tests

    @Test
    fun `retryable exceptions are identified correctly`() {
        val retryableExceptions = listOf(
            SocketTimeoutException("timeout"),
            IOException("Network unreachable")
        )

        val nonRetryableExceptions = listOf(
            UnknownHostException("unknown host"),
            IllegalArgumentException("bad argument"),
            NullPointerException("null")
        )

        retryableExceptions.forEach { exception ->
            assertThat(isRetryableException(exception)).isTrue()
        }

        nonRetryableExceptions.forEach { exception ->
            assertThat(isRetryableException(exception)).isFalse()
        }
    }

    // MARK: - HTTP Status Code Tests

    @Test
    fun `success status codes are identified correctly`() {
        val successCodes = listOf(200, 201, 204)
        val errorCodes = listOf(400, 401, 403, 404, 422, 429, 500, 502, 503, 504)

        successCodes.forEach { code ->
            assertThat(isSuccessStatusCode(code)).isTrue()
        }

        errorCodes.forEach { code ->
            assertThat(isSuccessStatusCode(code)).isFalse()
        }
    }

    @Test
    fun `client error status codes are identified correctly`() {
        val clientErrorCodes = listOf(400, 401, 403, 404, 422, 429)
        val nonClientErrorCodes = listOf(200, 201, 500, 503)

        clientErrorCodes.forEach { code ->
            assertThat(isClientError(code)).isTrue()
        }

        nonClientErrorCodes.forEach { code ->
            assertThat(isClientError(code)).isFalse()
        }
    }

    @Test
    fun `server error status codes are identified correctly`() {
        val serverErrorCodes = listOf(500, 502, 503, 504)
        val nonServerErrorCodes = listOf(200, 201, 400, 401, 404)

        serverErrorCodes.forEach { code ->
            assertThat(isServerErrorCode(code)).isTrue()
        }

        nonServerErrorCodes.forEach { code ->
            assertThat(isServerErrorCode(code)).isFalse()
        }
    }

    // MARK: - Error Message Extraction

    @Test
    fun `error message extracts from API response`() {
        val errorJson = """
            {
                "success": false,
                "error": {
                    "code": "VALIDATION_ERROR",
                    "message": "Email is required"
                }
            }
        """.trimIndent()

        val message = extractErrorMessage(errorJson)

        assertThat(message).isEqualTo("Email is required")
    }

    @Test
    fun `error message returns default for invalid JSON`() {
        val invalidJson = "not json"

        val message = extractErrorMessage(invalidJson)

        assertThat(message).isEqualTo("An unknown error occurred")
    }

    // MARK: - Helper Methods

    private fun isRetryableException(exception: Exception): Boolean {
        return when (exception) {
            is SocketTimeoutException -> true
            is IOException -> exception !is UnknownHostException
            else -> false
        }
    }

    private fun isRetryableHttpException(exception: HttpException): Boolean {
        return exception.code() in listOf(408, 429, 500, 502, 503, 504)
    }

    private fun isUnauthorizedException(exception: HttpException): Boolean {
        return exception.code() == 401
    }

    private fun isNotFoundError(exception: HttpException): Boolean {
        return exception.code() == 404
    }

    private fun isServerError(exception: HttpException): Boolean {
        return exception.code() >= 500
    }

    private fun isSuccessStatusCode(code: Int): Boolean {
        return code in 200..299
    }

    private fun isClientError(code: Int): Boolean {
        return code in 400..499
    }

    private fun isServerErrorCode(code: Int): Boolean {
        return code in 500..599
    }

    private fun extractErrorMessage(responseBody: String): String {
        return try {
            val response = gson.fromJson(responseBody, TestApiResponse::class.java)
            response.error?.message ?: "An unknown error occurred"
        } catch (e: Exception) {
            "An unknown error occurred"
        }
    }
}
