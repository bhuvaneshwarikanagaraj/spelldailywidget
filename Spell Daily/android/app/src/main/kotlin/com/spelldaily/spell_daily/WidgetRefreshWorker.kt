package com.company.spelldaily

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class WidgetRefreshWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : Worker(appContext, workerParams) {

    override fun doWork(): Result {
        return try {
            val context = applicationContext
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, StreakWidgetProvider::class.java)
            val widgetIds = manager.getAppWidgetIds(component)
            widgetIds.forEach { id ->
                StreakWidgetProvider.updateAppWidget(context, manager, id)
            }

            val mode = inputData.getString("mode")
            if (mode == "daily") {
                val hour = inputData.getInt("hour", 5)
                val minute = inputData.getInt("minute", 5)
                WidgetRefreshScheduler.scheduleDailyRefresh(
                    context,
                    hour,
                    minute,
                    replace = true,
                )
            }

            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}

