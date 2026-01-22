package com.buttonlog.app.services

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.buttonlog.app.MainActivity
import com.buttonlog.app.R
import com.buttonlog.app.data.api.APIService
import com.buttonlog.app.data.api.DeviceRegistrationRequest
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class ButtonLogFirebaseMessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var apiService: APIService

    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    companion object {
        private const val TAG = "ButtonLogFCM"
        const val CHANNEL_ID = "buttonlog_notifications"
        const val CHANNEL_NAME = "ButtonLog Notifications"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New FCM token: $token")

        // Register the new token with the backend
        serviceScope.launch {
            registerTokenWithBackend(token)
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)
        Log.d(TAG, "Message received from: ${message.from}")

        // Handle notification payload
        message.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "ButtonLog",
                body = notification.body ?: "",
                data = message.data
            )
        }

        // Handle data payload (for silent notifications)
        if (message.data.isNotEmpty()) {
            handleDataMessage(message.data)
        }
    }

    private fun showNotification(title: String, body: String, data: Map<String, String>) {
        createNotificationChannel()

        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            // Pass notification data to the activity
            data.forEach { (key, value) ->
                putExtra(key, value)
            }
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun handleDataMessage(data: Map<String, String>) {
        val type = data["type"] ?: return

        when (type) {
            "button_click" -> {
                val buttonId = data["button_id"]
                Log.d(TAG, "Button click notification for button: $buttonId")
                // Could broadcast an intent or update local state
            }
            "friend_request" -> {
                Log.d(TAG, "Friend request notification")
            }
            "friend_accepted" -> {
                Log.d(TAG, "Friend accepted notification")
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications from ButtonLog"
                enableLights(true)
                enableVibration(true)
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private suspend fun registerTokenWithBackend(token: String) {
        try {
            val request = DeviceRegistrationRequest(
                deviceToken = token,
                platform = "android",
                appVersion = getAppVersion(),
                osVersion = Build.VERSION.RELEASE
            )
            val response = apiService.registerDevice(request)
            if (response.success) {
                Log.d(TAG, "FCM token registered with backend: ${response.data?.id}")
            } else {
                Log.e(TAG, "Failed to register token: ${response.error?.message}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error registering token with backend", e)
        }
    }

    private fun getAppVersion(): String {
        return try {
            packageManager.getPackageInfo(packageName, 0).versionName ?: "1.0"
        } catch (e: Exception) {
            "1.0"
        }
    }
}
