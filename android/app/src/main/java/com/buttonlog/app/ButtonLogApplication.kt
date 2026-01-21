package com.buttonlog.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class ButtonLogApplication : Application() {
    
    companion object {
        const val CHANNEL_ID_BUTTONS = "button_notifications"
        const val CHANNEL_ID_FRIENDS = "friend_notifications"
        const val CHANNEL_ID_GENERAL = "general_notifications"
    }
    
    override fun onCreate() {
        super.onCreate()
        
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            // Button notifications channel
            val buttonChannel = NotificationChannel(
                CHANNEL_ID_BUTTONS,
                "Button Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for button clicks and activities"
                enableVibration(true)
                enableLights(true)
            }
            
            // Friend notifications channel
            val friendChannel = NotificationChannel(
                CHANNEL_ID_FRIENDS,
                "Friend Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for friend requests and social activities"
                enableVibration(true)
            }
            
            // General notifications channel
            val generalChannel = NotificationChannel(
                CHANNEL_ID_GENERAL,
                "General Notifications",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "General app notifications and updates"
            }
            
            notificationManager.createNotificationChannels(
                listOf(buttonChannel, friendChannel, generalChannel)
            )
        }
    }
}

