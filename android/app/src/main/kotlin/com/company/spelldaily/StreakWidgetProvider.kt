package com.company.spelldaily

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import kotlin.math.max

class StreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId ->
            updateAppWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val manager = AppWidgetManager.getInstance(context)
            val ids =
                manager.getAppWidgetIds(ComponentName(context, StreakWidgetProvider::class.java))
            onUpdate(context, manager, ids)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        appWidgetIds.forEach { WidgetInstanceStorage.delete(context, it) }
    }

    companion object {
        private val containers = intArrayOf(
            R.id.state_unlinked_container,
            R.id.state_start_container,
            R.id.state_celebration_container,
            R.id.state_progress_container,
        )

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val instance = WidgetInstanceStorage.load(context, appWidgetId)
            val loginCode = instance.loginCode?.trim()?.uppercase().orEmpty()
            val resolvedState = if (loginCode.isEmpty()) {
                "unlinked"
            } else {
                instance.state.ifEmpty { "state1" }
            }

            val beginPendingIntent = PendingIntent.getBroadcast(
                context,
                20000 + appWidgetId,
                Intent(context, WidgetActionReceiver::class.java).apply {
                    action = WidgetActionReceiver.ACTION_BEGIN
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val linkPendingIntent = PendingIntent.getActivity(
                context,
                10000 + appWidgetId,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget_begin", true)
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            when (resolvedState) {
                "unlinked" -> renderUnlinkedState(views, linkPendingIntent)
                "state1" -> renderStartState(
                    views = views,
                    loginCode = loginCode,
                    beginIntent = beginPendingIntent,
                )
                "state2" -> renderCelebrationState(
                    views = views,
                    streakCount = max(1, instance.streakCount),
                    loginCode = loginCode,
                )
                "state3" -> renderProgressState(
                    views = views,
                    loginCode = loginCode,
                    streakCount = max(1, instance.streakCount),
                    weekProgress = instance.weekProgress,
                    showStartButton = false,
                    pendingIntent = beginPendingIntent,
                )
                "state4" -> renderProgressState(
                    views = views,
                    loginCode = loginCode,
                    streakCount = max(1, instance.streakCount),
                    weekProgress = instance.weekProgress,
                    showStartButton = true,
                    pendingIntent = beginPendingIntent,
                )
                else -> renderStartState(
                    views = views,
                    loginCode = loginCode,
                    beginIntent = beginPendingIntent,
                )
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun renderUnlinkedState(
            views: RemoteViews,
            pendingIntent: PendingIntent,
        ) {
            showContainer(views, R.id.state_unlinked_container)
            // Hide login code for unlinked state
            views.setViewVisibility(R.id.widget_login_code_top, View.GONE)
            views.setOnClickPendingIntent(R.id.link_button, pendingIntent)
            views.setOnClickPendingIntent(R.id.state_unlinked_container, pendingIntent)
        }

        private fun renderStartState(
            views: RemoteViews,
            loginCode: String,
            beginIntent: PendingIntent,
        ) {
            showContainer(views, R.id.state_start_container)
            // Show login code at top
            views.setViewVisibility(R.id.widget_login_code_top, View.VISIBLE)
            views.setTextViewText(R.id.widget_login_code_top, "CODE: ${loginCode.ifEmpty { "--" }}")
            views.setOnClickPendingIntent(R.id.start_begin_button, beginIntent)
            views.setOnClickPendingIntent(R.id.state_start_container, beginIntent)
        }

        private fun renderCelebrationState(
            views: RemoteViews,
            streakCount: Int,
            loginCode: String,
        ) {
            showContainer(views, R.id.state_celebration_container)
            // Show login code at top
            views.setViewVisibility(R.id.widget_login_code_top, View.VISIBLE)
            views.setTextViewText(R.id.widget_login_code_top, "CODE: ${loginCode.ifEmpty { "--" }}")
            val label = if (streakCount == 1) "1 DAY" else "$streakCount DAYS"
            views.setTextViewText(R.id.celebration_day_text, label)
        }

        private fun renderProgressState(
            views: RemoteViews,
            loginCode: String,
            streakCount: Int,
            weekProgress: BooleanArray,
            showStartButton: Boolean,
            pendingIntent: PendingIntent,
        ) {
            showContainer(views, R.id.state_progress_container)
            // Show login code at top
            views.setViewVisibility(R.id.widget_login_code_top, View.VISIBLE)
            views.setTextViewText(R.id.widget_login_code_top, "CODE: ${loginCode.ifEmpty { "--" }}")
            val label = if (streakCount == 1) "1 DAY" else "$streakCount DAYS"
            views.setTextViewText(R.id.progress_streak_text, label)
            views.setTextViewText(R.id.progress_login_code, "CODE: ${loginCode.ifEmpty { "--" }}")
            val statusText = if (showStartButton) {
                "Keep the streak alive. Tap start when you're ready!"
            } else {
                "Amazing! You've completed today's challenge."
            }
            views.setTextViewText(R.id.progress_status_text, statusText)
            views.setViewVisibility(
                R.id.progress_button,
                if (showStartButton) View.VISIBLE else View.GONE,
            )
            if (showStartButton) {
                views.setOnClickPendingIntent(R.id.progress_button, pendingIntent)
            }
            setWeekProgress(views, weekProgress)
        }

        private fun showContainer(views: RemoteViews, visibleId: Int) {
            containers.forEach { id ->
                views.setViewVisibility(id, if (id == visibleId) View.VISIBLE else View.GONE)
            }
        }

        private fun setWeekProgress(
            views: RemoteViews,
            progress: BooleanArray,
        ) {
            val dayTicks = intArrayOf(
                R.id.day_mon, R.id.day_tue, R.id.day_wed, R.id.day_thu,
                R.id.day_fri, R.id.day_sat, R.id.day_sun,
            )
            val dayBgs = intArrayOf(
                R.id.day_mon_bg, R.id.day_tue_bg, R.id.day_wed_bg, R.id.day_thu_bg,
                R.id.day_fri_bg, R.id.day_sat_bg, R.id.day_sun_bg,
            )
            progress.forEachIndexed { index, completed ->
                if (index < dayTicks.size) {
                    views.setViewVisibility(
                        dayTicks[index],
                        if (completed) View.VISIBLE else View.GONE,
                    )
                    views.setImageViewResource(
                        dayBgs[index],
                        if (completed) R.drawable.day_box_completed else R.drawable.day_box_background,
                    )
                }
            }
        }
    }
}
