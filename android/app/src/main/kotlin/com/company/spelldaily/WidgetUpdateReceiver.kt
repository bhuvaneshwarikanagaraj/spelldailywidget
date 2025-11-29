package com.company.spelldaily

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class WidgetUpdateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, StreakWidgetProvider::class.java))
        ids.forEach { id ->
            StreakWidgetProvider.updateAppWidget(context, manager, id)
        }
    }
}



