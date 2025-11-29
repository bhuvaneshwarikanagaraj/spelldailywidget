package com.company.spelldaily

import android.content.Context
import androidx.work.Data
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import java.util.Calendar
import java.util.concurrent.TimeUnit

object WidgetWorkScheduler {

    private fun tenMinuteWorkName(widgetId: Int) = "widget_${widgetId}_ten_minute"
    private fun nextDayWorkName(widgetId: Int) = "widget_${widgetId}_next_day"

    fun scheduleTenMinuteTransition(context: Context, widgetId: Int) {
        val request = OneTimeWorkRequestBuilder<WidgetStateWorker>()
            .setInitialDelay(10, TimeUnit.MINUTES)
            .setInputData(
                Data.Builder()
                    .putInt(WidgetStateWorker.KEY_WIDGET_ID, widgetId)
                    .putString(WidgetStateWorker.KEY_TARGET_STATE, "state3")
                    .putString(WidgetStateWorker.KEY_EXPECTED_STATE, "state2")
                    .build(),
            )
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            tenMinuteWorkName(widgetId),
            ExistingWorkPolicy.REPLACE,
            request,
        )
        WidgetInstanceStorage.update(context, widgetId) {
            it.copy(pendingTenMinuteWorkId = request.id.toString())
        }
    }

    fun scheduleNextDayTransition(context: Context, widgetId: Int) {
        val delayMinutes = minutesUntilNextDay().coerceAtLeast(10L)
        val request = OneTimeWorkRequestBuilder<WidgetStateWorker>()
            .setInitialDelay(delayMinutes, TimeUnit.MINUTES)
            .setInputData(
                Data.Builder()
                    .putInt(WidgetStateWorker.KEY_WIDGET_ID, widgetId)
                    .putString(WidgetStateWorker.KEY_TARGET_STATE, "state4")
                    .putString(WidgetStateWorker.KEY_EXPECTED_STATE, "state3")
                    .build(),
            )
            .build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            nextDayWorkName(widgetId),
            ExistingWorkPolicy.REPLACE,
            request,
        )
        WidgetInstanceStorage.update(context, widgetId) {
            it.copy(pendingNextDayWorkId = request.id.toString())
        }
    }

    private fun minutesUntilNextDay(): Long {
        val nowMillis = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMillis
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val diff = calendar.timeInMillis - nowMillis
        return TimeUnit.MILLISECONDS.toMinutes(diff)
    }
}

