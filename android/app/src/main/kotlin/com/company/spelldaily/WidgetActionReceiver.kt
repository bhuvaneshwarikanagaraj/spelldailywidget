package com.company.spelldaily

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri

class WidgetActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null) return
        val widgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        )
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

        when (intent.action) {
            ACTION_BEGIN -> handleBegin(context, widgetId)
        }
    }

    private fun handleBegin(context: Context, widgetId: Int) {
        val instance = WidgetInstanceStorage.load(context, widgetId)
        val loginCode = instance.loginCode

        if (loginCode.isNullOrEmpty()) {
            val activityIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("from_widget_begin", true)
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            context.startActivity(activityIntent)
            return
        }

        val url = "https://app.spelldaily.com/?code=${loginCode.uppercase()}"
        val browserIntent = Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(browserIntent)

        WidgetInstanceStorage.update(context, widgetId) {
            it.copy(
                state = "state2",
                lastStateChange = System.currentTimeMillis(),
            )
        }
        WidgetWorkScheduler.scheduleTenMinuteTransition(context, widgetId)
        WidgetWorkScheduler.scheduleNextDayTransition(context, widgetId)

        val manager = AppWidgetManager.getInstance(context)
        StreakWidgetProvider.updateAppWidget(context, manager, widgetId)
    }

    companion object {
        const val ACTION_BEGIN = "com.company.spelldaily.widget.ACTION_BEGIN"
    }
}

