package com.example.myapp

import io.flutter.plugin.common.EventChannel

interface NotificationEventSink {
    fun sendNotification(data: Map<String, Any?>)
}

class NotificationEventSinkImpl(private val eventSink: EventChannel.EventSink?) : NotificationEventSink {
    override fun sendNotification(data: Map<String, Any?>) {
        eventSink?.success(data)
    }
}