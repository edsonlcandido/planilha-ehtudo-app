package com.example.myapp

import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.myapp/control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(NotificationListener())

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
                    val isEnabled = enabledListeners.contains(packageName)
                    result.success(isEnabled)
                }
                "openNotificationListenerSettings" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(null)
                }
                "startForegroundService" -> {
                    val intent = Intent(this, NotificationListener::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "stopForegroundService" -> {
                    val intent = Intent(this, NotificationListener::class.java)
                    stopService(intent)
                    result.success(null)
                }
                "setSelectedApps" -> {
                    val packages = call.argument<List<String>>("packages")
                    val notificationListener = flutterEngine.plugins.get(NotificationListener::class.java) as? NotificationListener
                    notificationListener?.setSelectedApps(packages ?: listOf())
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
