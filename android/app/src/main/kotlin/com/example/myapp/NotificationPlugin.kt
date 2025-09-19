package com.example.myapp

import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NotificationPlugin : FlutterPlugin, EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val TAG = "NotificationPlugin"
    
    companion object {
        private const val EVENT_CHANNEL_NAME = "com.example.myapp/notifications"
        private const val METHOD_CHANNEL_NAME = "com.example.myapp/control"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "NotificationPlugin attached to engine")
        
        // Setup EventChannel for streaming notifications to Flutter
        val eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)

        // Setup MethodChannel for receiving commands from Flutter
        val methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setSelectedApps" -> {
                    val packages = call.argument<List<String>>("packages")
                    NotificationListener.setSelectedApps(packages ?: listOf())
                    Log.d(TAG, "Selected apps set: ${packages?.size ?: 0} apps")
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "NotificationPlugin detached from engine")
        NotificationListener.staticEventSink = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Log.d(TAG, "Event channel listener attached")
        eventSink = events
        NotificationListener.staticEventSink = NotificationEventSinkImpl(events)
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Event channel listener cancelled")
        eventSink = null
        NotificationListener.staticEventSink = null
    }
}