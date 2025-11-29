package com.company.spelldaily

import android.appwidget.AppWidgetManager
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
        if (intent == null) return
        if (intent.getBooleanExtra("from_widget_begin", false)) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
            val prefs: SharedPreferences = getSharedPreferences(
                "FlutterSharedPreferences",
                MODE_PRIVATE,
            )
            val editor = prefs.edit()
            editor.putBoolean("flutter.from_widget_begin", true)
            if (widgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                editor.putInt("flutter.pending_widget_id", widgetId)
            }
            editor.apply()

            intent.removeExtra("from_widget_begin")
            intent.removeExtra(AppWidgetManager.EXTRA_APPWIDGET_ID)
        }
    }
}

