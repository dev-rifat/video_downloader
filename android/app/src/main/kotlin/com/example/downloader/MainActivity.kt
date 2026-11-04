package com.example.downloader

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Receives links shared from Facebook, YouTube, Instagram, browsers, etc.
 * (ACTION_SEND text/plain and ACTION_VIEW) and forwards them to Flutter.
 * Native implementation = no extra plugin, smaller APK.
 */
class MainActivity : FlutterActivity() {
    private var initialText: String? = null
    private var events: EventChannel.EventSink? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Ignore the launch intent when the activity is recreated (rotation)
        // or relaunched from recents, so the same link isn't re-processed.
        if (savedInstanceState == null &&
            (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY) == 0
        ) {
            initialText = extractText(intent)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(messenger, "downloader/share").setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialText" -> {
                    result.success(initialText)
                    initialText = null // consume once
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "downloader/share/events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    events = sink
                }

                override fun onCancel(arguments: Any?) {
                    events = null
                }
            }
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = extractText(intent) ?: return
        val sink = events
        if (sink != null) sink.success(text) else initialText = text
    }

    private fun extractText(intent: Intent?): String? = when (intent?.action) {
        Intent.ACTION_SEND ->
            intent.getStringExtra(Intent.EXTRA_TEXT)
                ?: intent.getStringExtra(Intent.EXTRA_SUBJECT)
        Intent.ACTION_VIEW -> intent.dataString
        else -> null
    }?.takeIf { it.isNotBlank() }
}
