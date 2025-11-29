package com.company.spelldaily

import android.appwidget.AppWidgetManager
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class WidgetStateWorker(
    appContext: Context,
    params: WorkerParameters,
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val widgetId =
            inputData.getInt(KEY_WIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            return Result.failure()
        }
        val targetState = inputData.getString(KEY_TARGET_STATE) ?: return Result.failure()
        val expectedState = inputData.getString(KEY_EXPECTED_STATE)

        var applied = false
        WidgetInstanceStorage.update(applicationContext, widgetId) { instance ->
            if (!expectedState.isNullOrEmpty() && instance.state != expectedState) {
                return@update instance
            }
            applied = true
            instance.copy(
                state = targetState,
                lastStateChange = System.currentTimeMillis(),
                pendingTenMinuteWorkId = if (targetState == "state3") null else instance.pendingTenMinuteWorkId,
                pendingNextDayWorkId = if (targetState == "state4") null else instance.pendingNextDayWorkId,
            )
        }

        if (applied) {
            val manager = AppWidgetManager.getInstance(applicationContext)
            StreakWidgetProvider.updateAppWidget(
                applicationContext,
                manager,
                widgetId,
            )
        }

        return Result.success()
    }

    companion object {
        const val KEY_WIDGET_ID = "widget_id"
        const val KEY_TARGET_STATE = "target_state"
        const val KEY_EXPECTED_STATE = "expected_state"
    }
}


