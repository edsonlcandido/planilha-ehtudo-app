
package com.example.myapp

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NotificationListener : NotificationListenerService(), EventChannel.StreamHandler, FlutterPlugin {
    private var eventSink: EventChannel.EventSink? = null
    private val NOTIFICATION_CHANNEL_ID = "com.example.myapp.service"
    private val NOTIFICATION_ID = 1

    companion object {
        private const val EVENT_CHANNEL_NAME = "com.example.myapp/notifications"
        private const val METHOD_CHANNEL_NAME = "com.example.myapp/control"
        
        var staticEventSink: EventChannel.EventSink? = null
        private var selectedApps = emptySet<String>()

        fun sendNotificationData(data: Map<String, Any?>) {
            staticEventSink?.success(data)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, createNotification())
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Serviço de Notificação",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): Notification {
        val notificationBuilder = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Planilha Eh Tudo")
            .setContentText("Monitorando notificações para capturar transações.")
            .setSmallIcon(R.mipmap.ic_launcher) // Make sure you have this icon
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
        return notificationBuilder.build()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Setup EventChannel for streaming notifications to Flutter
        val eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)

        // Setup MethodChannel for receiving commands from Flutter
        val methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "setSelectedApps") {
                val packages = call.argument<Map<String, List<String>>>("packages")
                selectedApps = packages?.get("packages")?.toSet() ?: emptySet()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        staticEventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        staticEventSink = null
    }

    fun setSelectedApps(packages: List<String>) {
        selectedApps = packages.toSet()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName

        // Filter notifications: if the list is empty, allow all. Otherwise, only allow from selected apps.
        if (selectedApps.isNotEmpty() && packageName !in selectedApps) {
            return
        }

        val extras = sbn.notification.extras
        val title = extras.getString(Notification.EXTRA_TITLE)
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()

        if (title != null && text != null) {
            val notificationData = mapOf(
                "package" to packageName,
                "title" to title,
                "message" to text,
                "timestamp" to (System.currentTimeMillis() / 1000)
            )
            sendNotificationData(notificationData)
        }
    }
}
