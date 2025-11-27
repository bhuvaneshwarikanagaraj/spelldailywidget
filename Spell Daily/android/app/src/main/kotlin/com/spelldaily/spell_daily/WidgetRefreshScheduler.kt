package com.company.spelldaily

import android.content.Context
import androidx.work.Data
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.Calendar
import java.util.concurrent.TimeUnit

object WidgetRefreshScheduler {
    private const val USER_WORK_PREFIX = "widget_refresh_user_"
    private const val PERIODIC_WORK_NAME = "widget_periodic_refresh"
    private const val DAILY_WORK_NAME = "widget_daily_refresh"

    fun scheduleUserRefresh(
        context: Context,
        userId: String,
        delayMs: Long,
    ) {
        val data = Data.Builder()
            .putString("mode", "user")
            .putString("userId", userId)
            .build()

        val requestBuilder = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
            .setInputData(data)

        if (delayMs > 0L) {
            requestBuilder.setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
        }

        val request = requestBuilder.build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            USER_WORK_PREFIX + userId,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    fun cancelUserRefresh(context: Context, userId: String) {
        WorkManager.getInstance(context).cancelUniqueWork(USER_WORK_PREFIX + userId)
    }

    fun ensurePeriodicRefresh(context: Context, intervalMinutes: Int) {
        val data = Data.Builder()
            .putString("mode", "periodic")
            .build()

        val request = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
            intervalMinutes.toLong(),
            TimeUnit.MINUTES,
        )
            .setInputData(data)
            .build()

        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            PERIODIC_WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun scheduleDailyRefresh(
        context: Context,
        hour: Int,
        minute: Int,
        replace: Boolean = false,
    ) {
        val nowMs = System.currentTimeMillis()
        val calendar = Calendar.getInstance().apply {
            timeInMillis = nowMs
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= nowMs) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        val delayMs = calendar.timeInMillis - nowMs

        val data = Data.Builder()
            .putString("mode", "daily")
            .putInt("hour", hour)
            .putInt("minute", minute)
            .build()

        val request = OneTimeWorkRequestBuilder<WidgetRefreshWorker>()
            .setInputData(data)
            .setInitialDelay(delayMs, TimeUnit.MILLISECONDS)
            .build()

        WorkManager.getInstance(context).enqueueUniqueWork(
            DAILY_WORK_NAME,
            if (replace) ExistingWorkPolicy.REPLACE else ExistingWorkPolicy.KEEP,
            request,
        )
    }
}

