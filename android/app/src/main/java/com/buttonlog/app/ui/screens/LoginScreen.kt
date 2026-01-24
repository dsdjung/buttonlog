package com.buttonlog.app.ui.screens

import android.app.Activity
import android.util.Log
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import androidx.hilt.navigation.compose.hiltViewModel
import com.buttonlog.app.R
import com.buttonlog.app.ui.viewmodels.AuthViewModel
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import kotlinx.coroutines.launch
import org.json.JSONObject
import android.util.Base64

// Google OAuth Web Client ID from Google Cloud Console
private const val GOOGLE_WEB_CLIENT_ID = "789726851913-bmttjvlpaatgv2dde08vs05ihndkskfd.apps.googleusercontent.com"

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LoginScreen(
    viewModel: AuthViewModel = hiltViewModel()
) {
    val isLoading by viewModel.isLoading.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    val context = LocalContext.current
    val coroutineScope = rememberCoroutineScope()

    var isGoogleLoading by remember { mutableStateOf(false) }

    val scrollState = rememberScrollState()

    // Google Sign-In handler
    fun signInWithGoogle() {
        coroutineScope.launch {
            isGoogleLoading = true
            viewModel.clearError()

            try {
                val credentialManager = CredentialManager.create(context)

                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(GOOGLE_WEB_CLIENT_ID)
                    .setAutoSelectEnabled(false)
                    .build()

                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()

                val result = credentialManager.getCredential(
                    request = request,
                    context = context as Activity
                )

                val credential = result.credential
                val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)

                // Extract user info from the Google credential
                val userEmail = googleIdTokenCredential.id
                val displayName = googleIdTokenCredential.displayName
                val givenName = googleIdTokenCredential.givenName
                val familyName = googleIdTokenCredential.familyName
                val profilePictureUri = googleIdTokenCredential.profilePictureUri?.toString()
                val idToken = googleIdTokenCredential.idToken

                // Extract the 'sub' claim from the ID token for a stable unique user ID
                // The ID token is a JWT with format: header.payload.signature
                val userId = try {
                    val parts = idToken.split(".")
                    if (parts.size >= 2) {
                        val payload = String(Base64.decode(parts[1], Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP))
                        val json = JSONObject(payload)
                        json.optString("sub", userEmail) // Use 'sub' claim, fallback to email
                    } else {
                        userEmail
                    }
                } catch (e: Exception) {
                    Log.w("LoginScreen", "Failed to extract sub from ID token, using email as UID", e)
                    userEmail
                }

                // Send to backend
                viewModel.loginWithOAuth(
                    provider = "google",
                    email = userEmail,
                    uid = userId,
                    name = displayName,
                    firstName = givenName,
                    lastName = familyName,
                    image = profilePictureUri,
                    accessToken = idToken
                )
            } catch (e: NoCredentialException) {
                Log.w("LoginScreen", "No Google credential found - user may need to add account")
                viewModel.setError("No Google account found. Please add a Google account to your device.")
            } catch (e: GetCredentialException) {
                Log.e("LoginScreen", "Google Sign-In failed: ${e.type} - ${e.message}", e)
                viewModel.setError("Google Sign-In failed: ${e.message ?: e.type}")
            } catch (e: Exception) {
                Log.e("LoginScreen", "Google Sign-In error: ${e.message}", e)
                viewModel.setError("Google Sign-In error: ${e.message ?: "Unknown error"}")
            } finally {
                isGoogleLoading = false
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(24.dp)
            .verticalScroll(scrollState),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Logo
        Image(
            painter = painterResource(id = R.drawable.logo),
            contentDescription = "ButtonLog Logo",
            modifier = Modifier.size(100.dp)
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Title
        Text(
            text = "ButtonLog",
            style = MaterialTheme.typography.displayMedium,
            color = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Track your activities with the tap of a button",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(48.dp))

        // Error Message
        errorMessage?.let { error ->
            Text(
                text = error,
                color = MaterialTheme.colorScheme.error,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(bottom = 16.dp)
            )
        }

        // Google Sign-In Button
        OutlinedButton(
            onClick = { signInWithGoogle() },
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            enabled = !isLoading && !isGoogleLoading,
            border = BorderStroke(1.dp, MaterialTheme.colorScheme.outline),
            colors = ButtonDefaults.outlinedButtonColors(
                containerColor = Color.White
            )
        ) {
            if (isGoogleLoading) {
                CircularProgressIndicator(
                    modifier = Modifier.size(24.dp),
                    color = MaterialTheme.colorScheme.primary
                )
            } else {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.ic_google),
                        contentDescription = "Google logo",
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(modifier = Modifier.width(12.dp))
                    Text(
                        text = "Continue with Google",
                        color = Color.Black
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        // Terms and Privacy
        Text(
            text = "By continuing, you agree to our Terms of Service and Privacy Policy",
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center
        )
    }
}
