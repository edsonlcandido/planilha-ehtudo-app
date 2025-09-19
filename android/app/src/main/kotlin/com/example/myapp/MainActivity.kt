package com.example.myapp

import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.myapp/control"
    private val TAG = "MainActivity"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Add our notification plugin
        flutterEngine.plugins.add(NotificationPlugin())
        Log.d(TAG, "NotificationPlugin added to Flutter engine")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationListenerEnabled" -> {
                    val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
                    val isEnabled = enabledListeners.contains(packageName)
                    Log.d(TAG, "Notification listener enabled: $isEnabled")
                    result.success(isEnabled)
                }
                "openNotificationListenerSettings" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    Log.d(TAG, "Opening notification listener settings")
                    result.success(null)
                }
                "startForegroundService" -> {
                    val intent = Intent(this, NotificationListener::class.java)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    Log.d(TAG, "Starting notification listener service")
                    result.success(null)
                }
                "stopForegroundService" -> {
                    val intent = Intent(this, NotificationListener::class.java)
                    stopService(intent)
                    Log.d(TAG, "Stopping notification listener service")
                    result.success(null)
                }
                "setSelectedApps" -> {
                    val packages = call.argument<List<String>>("packages")
                    NotificationListener.setSelectedApps(packages ?: listOf())
                    Log.d(TAG, "Selected apps updated: ${packages?.size ?: 0} apps")
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
