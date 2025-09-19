package com.example.myapp

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
            if (call.method == "isNotificationListenerEnabled") {
                val enabledListeners = NotificationManagerCompat.getEnabledListenerPackages(this)
                val isEnabled = enabledListeners.contains(packageName)
                result.success(isEnabled)
            } else if (call.method == "setSelectedApps") {
                val packages = call.argument<List<String>>("packages")
                val notificationListener = flutterEngine.plugins.get(NotificationListener::class.java) as? NotificationListener
                notificationListener?.setSelectedApps(packages ?: listOf())
                result.success(null)
            }
            else {
                result.notImplemented()
            }
        }
    }
}
