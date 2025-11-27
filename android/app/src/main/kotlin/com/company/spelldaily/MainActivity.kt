package com.company.spelldaily

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle intent on initial launch
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        // Also check on resume in case intent was set before Flutter was ready
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null && intent.getBooleanExtra("from_widget_begin", false)) {
            // Store flag in SharedPreferences for Flutter to read
            val prefs: SharedPreferences = getSharedPreferences(
                "FlutterSharedPreferences",
                MODE_PRIVATE
            )
            prefs.edit().putBoolean("flutter.from_widget_begin", true).apply()
            // Clear the flag from intent to avoid reprocessing
            intent.removeExtra("from_widget_begin")
        }
    }
}

