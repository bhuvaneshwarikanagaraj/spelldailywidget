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
import es.antonborri.home_widget.HomeWidgetPlugin
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
        private const val PAYLOAD_KEY = "widget_payload"
        private const val PAYLOAD_PREFIX = "widget_payload_"
        private const val ASSIGNMENT_PREF_PREFIX = "flutter.widget.assignment."
        private const val ASSIGNMENT_WIDGET_PREFIX = "widget_assignment_"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
        ) {
            val flutterPrefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE,
            )
            val widgetPrefs = HomeWidgetPlugin.getData(context)

            val assignmentKey = "$ASSIGNMENT_PREF_PREFIX$appWidgetId"
            val assignedLoginCode =
                widgetPrefs.getString("$ASSIGNMENT_WIDGET_PREFIX$appWidgetId", null)
                    ?.trim()
                    ?.uppercase()
                    ?: flutterPrefs.getString(assignmentKey, "")?.trim()?.uppercase()
                    ?: ""
            val payloadKey = if (assignedLoginCode.isNotEmpty()) {
                "$PAYLOAD_PREFIX$assignedLoginCode"
            } else {
                PAYLOAD_KEY
            }

            val payload = widgetPrefs.getString(payloadKey, null)
            val json = payload?.let {
                try {
                    JSONObject(it)
                } catch (_: Exception) {
                    null
                }
            }

            val hasAssignment = assignedLoginCode.isNotEmpty()
            val state = if (hasAssignment) {
                json?.optString("state").orEmpty().ifEmpty { "state1" }
            } else {
                "unlinked"
            }
            val streakCount = if (hasAssignment) json?.optInt("streakCount", 0) ?: 0 else 0
            val weekProgress = if (hasAssignment) {
                parseWeekProgress(json?.optJSONArray("weekProgress"))
            } else {
                BooleanArray(7) { false }
            }
            val loginCode = if (hasAssignment) assignedLoginCode else ""

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            views.setViewVisibility(R.id.widget_login_code, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_login_code,
                if (loginCode.isNotEmpty()) {
                    "CODE: $loginCode"
                } else {
                    "TAP TO LINK"
                },
            )

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
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
            }
            
            val pendingIntent = PendingIntent.getActivity(
                context,
                appWidgetId,
                browserIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )

            when (state) {
                "state1" -> renderStartState(views, pendingIntent, linkMode = false)
                "state2" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                "state3" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                "state4" -> renderStreakState(views, streakCount, weekProgress, pendingIntent)
                "unlinked" -> renderStartState(views, pendingIntent, linkMode = true)
                else -> renderStartState(views, pendingIntent, linkMode = false)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun renderStartState(
            views: RemoteViews,
            pendingIntent: PendingIntent,
            linkMode: Boolean,
        ) {
            views.setViewVisibility(R.id.widget_logo_state1, View.VISIBLE)
            views.setViewVisibility(R.id.widget_title, View.VISIBLE)
            views.setViewVisibility(R.id.widget_begin_button, View.VISIBLE)
            views.setViewVisibility(R.id.widget_streak_info, View.GONE)
            views.setViewVisibility(R.id.widget_week_progress, View.GONE)
            views.setTextViewText(
                R.id.widget_title,
                if (linkMode) "LINK YOUR WIDGET" else "START CHALLENGE",
            )
            views.setTextViewText(
                R.id.widget_begin_button,
                if (linkMode) "LINK" else "BEGIN",
            )
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

