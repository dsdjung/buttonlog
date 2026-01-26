package com.buttonlog.app.ui.viewmodels

import app.cash.turbine.test
import com.buttonlog.app.data.model.AuthUserData
import com.buttonlog.app.data.model.User
import com.buttonlog.app.data.repository.AuthRepository
import com.google.common.truth.Truth.assertThat
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private lateinit var authRepository: AuthRepository
    private lateinit var viewModel: AuthViewModel

    private val testDispatcher = StandardTestDispatcher()

    private val testUser = User(
        id = "test-user-id",
        email = "test@example.com",
        username = "testuser",
        displayName = "Test User",
        firstName = null,
        lastName = null,
        profileVisibility = "public",
        activityVisibility = "friends",
        subscriptionTier = "free",
        isActive = true,
        emailVerified = true,
        onboardingCompleted = false,
        createdAt = "2024-01-01T00:00:00Z",
        updatedAt = "2024-01-01T00:00:00Z"
    )

    private val testAuthUserData = AuthUserData(
        user = testUser,
        token = "test-token",
        refreshToken = "test-refresh-token"
    )

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        authRepository = mockk(relaxed = true)

        every { authRepository.isLoggedIn } returns MutableStateFlow(false)
        every { authRepository.onboardingCompleted } returns MutableStateFlow(false)

        viewModel = AuthViewModel(authRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun `initial state is not logged in`() = runTest {
        assertThat(viewModel.isLoggedIn.value).isFalse()
    }

    @Test
    fun `initial state has no error`() = runTest {
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isNull()
        }
    }

    @Test
    fun `initial state is not loading`() = runTest {
        viewModel.isLoading.test {
            assertThat(awaitItem()).isFalse()
        }
    }

    @Test
    fun `login calls repository with correct credentials`() = runTest {
        // Given
        coEvery { authRepository.login("test@example.com", "password123") } returns Result.success(testAuthUserData)

        // When
        viewModel.login("test@example.com", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { authRepository.login("test@example.com", "password123") }
    }

    @Test
    fun `login sets loading state during operation`() = runTest {
        // Given
        coEvery { authRepository.login(any(), any()) } returns Result.success(testAuthUserData)

        // When
        viewModel.login("test@example.com", "password123")

        // Then - check loading started
        assertThat(viewModel.isLoading.value).isTrue()

        testDispatcher.scheduler.advanceUntilIdle()

        // Loading should be false after operation completes
        assertThat(viewModel.isLoading.value).isFalse()
    }

    @Test
    fun `login failure sets error message`() = runTest {
        // Given
        coEvery { authRepository.login(any(), any()) } returns Result.failure(
            Exception("Invalid credentials")
        )

        // When
        viewModel.login("test@example.com", "wrongpassword")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isEqualTo("Invalid credentials")
        }
    }

    @Test
    fun `register with mismatched passwords sets error without calling repository`() = runTest {
        // When
        viewModel.register("test@example.com", "password123", "differentpassword")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isEqualTo("Passwords do not match")
        }

        // Repository should not be called
        coVerify(exactly = 0) { authRepository.register(any(), any(), any()) }
    }

    @Test
    fun `register with matching passwords calls repository`() = runTest {
        // Given
        coEvery { authRepository.register(any(), any(), any()) } returns Result.success(testAuthUserData)

        // When
        viewModel.register("test@example.com", "password123", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { authRepository.register("test@example.com", "password123", "password123") }
    }

    @Test
    fun `register sets loading state during operation`() = runTest {
        // Given
        coEvery { authRepository.register(any(), any(), any()) } returns Result.success(testAuthUserData)

        // When
        viewModel.register("test@example.com", "password123", "password123")

        // Then - check loading started
        assertThat(viewModel.isLoading.value).isTrue()

        testDispatcher.scheduler.advanceUntilIdle()

        // Loading should be false after operation completes
        assertThat(viewModel.isLoading.value).isFalse()
    }

    @Test
    fun `register failure sets error message`() = runTest {
        // Given
        coEvery { authRepository.register(any(), any(), any()) } returns Result.failure(
            Exception("Email already exists")
        )

        // When
        viewModel.register("existing@example.com", "password123", "password123")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isEqualTo("Email already exists")
        }
    }

    @Test
    fun `logout calls repository`() = runTest {
        // When
        viewModel.logout()

        // Then
        verify { authRepository.logout() }
    }

    @Test
    fun `completeOnboarding calls repository`() = runTest {
        // When
        viewModel.completeOnboarding()
        testDispatcher.scheduler.advanceUntilIdle()

        // Then
        coVerify { authRepository.completeOnboarding() }
    }

    @Test
    fun `clearError resets error message`() = runTest {
        // Given - set an error first
        coEvery { authRepository.login(any(), any()) } returns Result.failure(
            Exception("Some error")
        )
        viewModel.login("test@example.com", "password")
        testDispatcher.scheduler.advanceUntilIdle()

        // When
        viewModel.clearError()

        // Then
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isNull()
        }
    }

    @Test
    fun `login clears previous error message`() = runTest {
        // Given - set an error first
        coEvery { authRepository.login(any(), any()) } returns Result.failure(
            Exception("First error")
        )
        viewModel.login("test@example.com", "wrong")
        testDispatcher.scheduler.advanceUntilIdle()

        // Setup for success
        coEvery { authRepository.login(any(), any()) } returns Result.success(testAuthUserData)

        // When
        viewModel.login("test@example.com", "correct")
        testDispatcher.scheduler.advanceUntilIdle()

        // Then - error should be cleared (was set to null before operation)
        viewModel.errorMessage.test {
            assertThat(awaitItem()).isNull()
        }
    }

    @Test
    fun `onboardingCompleted reflects repository state`() = runTest {
        // Given
        val onboardingFlow = MutableStateFlow(false)
        every { authRepository.onboardingCompleted } returns onboardingFlow

        // Create new viewModel with updated mock
        viewModel = AuthViewModel(authRepository)

        // Initial state
        assertThat(viewModel.onboardingCompleted.value).isFalse()

        // When repository updates
        onboardingFlow.value = true

        // Then viewModel reflects the change
        viewModel.onboardingCompleted.test {
            assertThat(awaitItem()).isTrue()
        }
    }

    @Test
    fun `isLoggedIn reflects repository state`() = runTest {
        // Given
        val isLoggedInFlow = MutableStateFlow(false)
        every { authRepository.isLoggedIn } returns isLoggedInFlow

        // Create new viewModel with updated mock
        viewModel = AuthViewModel(authRepository)

        // Initial state
        assertThat(viewModel.isLoggedIn.value).isFalse()

        // When repository updates
        isLoggedInFlow.value = true

        // Then viewModel reflects the change
        viewModel.isLoggedIn.test {
            assertThat(awaitItem()).isTrue()
        }
    }
}
