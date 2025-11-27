package com.company.spelldaily

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject

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
            val ids = manager.getAppWidgetIds(ComponentName(context, StreakWidgetProvider::class.java))
            onUpdate(context, manager, ids)
        }
    }

    companion object {
        private const val PAYLOAD_KEY = "flutter.widget_payload"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
            val payload = prefs.getString(PAYLOAD_KEY, null)
            val json = payload?.let {
                try {
                    JSONObject(it)
                } catch (_: Exception) {
                    null
                }
            }

            val state = json?.optString("state").orEmpty().ifEmpty { "state1" }
            val streakCount = json?.optInt("streakCount", 0) ?: 0
            val weekProgress = parseWeekProgress(json?.optJSONArray("weekProgress"))
            val loginCode = json?.optString("loginCode").orEmpty().ifEmpty {
                prefs.getString("flutter.loginCode", "") ?: ""
            }

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            if (loginCode.isNotEmpty()) {
                views.setViewVisibility(R.id.widget_login_code, View.VISIBLE)
                views.setTextViewText(
                    R.id.widget_login_code,
                    "CODE: ${loginCode.uppercase()}",
                )
            } else {
                views.setViewVisibility(R.id.widget_login_code, View.GONE)
            }

            // Create intent to open browser with game URL
            val browserIntent = if (loginCode.isNotEmpty()) {
                val url = "https://app.spelldaily.com/?code=${loginCode.uppercase()}"
                Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
            } else {
                // Fallback: open app if no login code
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("from_widget_begin", true)
                }
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                browserIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            when (state) {
                "state1" -> renderStartState(views, pendingIntent)
                "state2" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                "state3" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                "state4" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                else -> renderStartState(views, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun renderStartState(
            views: RemoteViews,
            pendingIntent: PendingIntent,
        ) {
            views.setViewVisibility(R.id.widget_logo_state1, View.VISIBLE)
            views.setViewVisibility(R.id.widget_title, View.VISIBLE)
            views.setViewVisibility(R.id.widget_begin_button, View.VISIBLE)
            views.setViewVisibility(R.id.widget_streak_info, View.GONE)
            views.setViewVisibility(R.id.widget_week_progress, View.GONE)
            views.setOnClickPendingIntent(R.id.widget_begin_button, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        }

        private fun renderStreakState(
            views: RemoteViews,
            streakCount: Int,
            weekProgress: BooleanArray,
            pendingIntent: PendingIntent,
        ) {
            val label = if (streakCount == 1) "DAY" else "DAYS"
            views.setTextViewText(R.id.widget_streak_count, "$streakCount $label")

            views.setViewVisibility(R.id.widget_logo_state1, View.GONE)
            views.setViewVisibility(R.id.widget_title, View.GONE)
            views.setViewVisibility(R.id.widget_begin_button, View.GONE)
            views.setViewVisibility(R.id.widget_streak_info, View.VISIBLE)
            views.setViewVisibility(R.id.widget_week_progress, View.VISIBLE)

            val dayTicks = intArrayOf(
                R.id.day_mon, R.id.day_tue, R.id.day_wed, R.id.day_thu,
                R.id.day_fri, R.id.day_sat, R.id.day_sun,
            )
            val dayBgs = intArrayOf(
                R.id.day_mon_bg, R.id.day_tue_bg, R.id.day_wed_bg, R.id.day_thu_bg,
                R.id.day_fri_bg, R.id.day_sat_bg, R.id.day_sun_bg,
            )

            weekProgress.forEachIndexed { index, completed ->
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

            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        }

        private fun parseWeekProgress(array: JSONArray?): BooleanArray {
            val progress = BooleanArray(7) { false }
            if (array == null) return progress
            for (i in 0 until minOf(array.length(), 7)) {
                progress[i] = array.optBoolean(i, false)
            }
            return progress
        }
    }
}

