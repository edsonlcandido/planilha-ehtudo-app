
package com.example.myapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat

class NotificationListener : NotificationListenerService() {
    private val NOTIFICATION_CHANNEL_ID = "com.example.myapp.service"
    private val NOTIFICATION_ID = 1

    companion object {
        private const val TAG = "NotificationListener"
        var staticEventSink: NotificationEventSink? = null
        private var selectedApps = emptySet<String>()

        fun sendNotificationData(data: Map<String, Any?>) {
            Log.d(TAG, "Attempting to send notification data: $data")
            staticEventSink?.sendNotification(data)
        }

        fun setSelectedApps(packages: List<String>) {
            selectedApps = packages.toSet()
            Log.d(TAG, "Selected apps updated: $selectedApps")
        }
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "NotificationListener service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "NotificationListener service started")
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "NotificationListener connected")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "NotificationListener disconnected")
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Serviço de Notificação",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Serviço em segundo plano para capturar notificações"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val notificationBuilder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Planilha Eh Tudo")
            .setContentText("Monitorando notificações para capturar transações.")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setShowWhen(false)
        return notificationBuilder.build()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName
        Log.d(TAG, "Notification received from: $packageName")

        // Filter notifications: if the list is empty, allow all. Otherwise, only allow from selected apps.
        if (selectedApps.isNotEmpty() && packageName !in selectedApps) {
            Log.d(TAG, "Notification filtered out - not in selected apps")
            return
        }

        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE)
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        Log.d(TAG, "Processing notification - Title: $title, Text: $text")

        if (title != null && text != null) {
            val notificationData = mapOf(
                "package" to packageName,
                "title" to title,
                "message" to text,
                "timestamp" to (System.currentTimeMillis() / 1000)
            )
            Log.d(TAG, "Sending notification data: $notificationData")
            sendNotificationData(notificationData)
        } else {
            Log.d(TAG, "Notification ignored - missing title or text")
        }
    }
}
