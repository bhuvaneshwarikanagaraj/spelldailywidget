package com.company.spelldaily

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.company.spelldaily/navigation"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for widget navigation
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialRoute" -> {
                        val route = intent?.getStringExtra("route") ?: "/"
                        result.success(route)
                    }
                    "getInitialArguments" -> {
                        val loginCode = intent?.getStringExtra("loginCode")
                        val payload = mapOf(
                            "route" to (intent?.getStringExtra("route") ?: "/"),
                            "loginCode" to loginCode
                        )
                        result.success(payload)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}


