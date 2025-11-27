package com.company.spelldaily

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONObject
import com.company.spelldaily.R

/**
 * App Widget Provider for Streak Widget
 * Updates the home screen widget with streak data from SharedPreferences
 */
class StreakWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widget instances
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, StreakWidgetProvider::class.java)
            )
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        val homeWidgetPrefs = context.getSharedPreferences(
            "HomeWidgetPreferences",
            Context.MODE_PRIVATE
        )
        val flutterPrefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )

        val assignmentsJson = flutterPrefs.getString("flutter.widget_assignments", null)
        val assignmentsObj = if (assignmentsJson.isNullOrBlank()) {
            JSONObject()
        } else {
            try {
                JSONObject(assignmentsJson)
            } catch (_: Exception) {
                JSONObject()
            }
        }

        appWidgetIds.forEach { widgetId ->
            val prefix = "widget_${widgetId}_"
            homeWidgetPrefs.edit().apply {
                remove("${prefix}state")
                remove("${prefix}streak_count")
                remove("${prefix}has_completed_first_game")
                remove("${prefix}week_progress")
                remove("${prefix}last_played_date")
                remove("${prefix}streak_data")
                remove("${prefix}user_id")
            }.apply()
            assignmentsObj.remove(widgetId.toString())
        }

        flutterPrefs.edit()
            .putString("flutter.widget_assignments", assignmentsObj.toString())
            .apply()
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val flutterPrefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )

            val homeWidgetPrefs = context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE
            )

            val keyPrefix = "widget_${appWidgetId}_"

            var userId = homeWidgetPrefs.getString("${keyPrefix}user_id", null)
            if (userId.isNullOrBlank()) {
                val assignmentsJson = flutterPrefs.getString("flutter.widget_assignments", null)
                if (!assignmentsJson.isNullOrBlank()) {
                    try {
                        val assignments = JSONObject(assignmentsJson)
                        val value = assignments.optString(appWidgetId.toString(), null)
                        if (!value.isNullOrBlank()) {
                            userId = value
                        }
                    } catch (_: Exception) {
                    }
                }
            }

            var streakCount = homeWidgetPrefs.getInt("${keyPrefix}streak_count", -1)
            if (streakCount < 0) streakCount = 0

            var hasCompletedFirstGame =
                homeWidgetPrefs.getBoolean("${keyPrefix}has_completed_first_game", false)
            var weekProgressString =
                homeWidgetPrefs.getString("${keyPrefix}week_progress", null)
            var widgetState = homeWidgetPrefs.getString("${keyPrefix}state", null)
            var lastPlayedIso =
                homeWidgetPrefs.getString("${keyPrefix}last_played_date", null)

            val weekProgress = mutableListOf<Boolean>()
            if (!weekProgressString.isNullOrBlank()) {
                weekProgress.addAll(
                    weekProgressString.split(",").map {
                        it == "1" || it.equals("true", ignoreCase = true)
                    }
                )
            }

            if (weekProgress.isEmpty()) {
                weekProgress.addAll(List(7) { false })
            }
            while (weekProgress.size < 7) {
                weekProgress.add(false)
            }
            if (weekProgress.size > 7) {
                while (weekProgress.size > 7) weekProgress.removeLast()
            }

            val userMapJson = flutterPrefs.getString("flutter.user_streak_map", null)
            if (!userMapJson.isNullOrBlank() && !userId.isNullOrBlank()) {
                try {
                    val users = JSONObject(userMapJson)
                    val userJson = users.optJSONObject(userId)
                    if (userJson != null) {
                        streakCount = userJson.optInt("streakCount", streakCount)
                        hasCompletedFirstGame =
                            userJson.optBoolean("hasCompletedFirstGame", hasCompletedFirstGame)

                        val weekArray = userJson.optJSONArray("weekProgress")
                        if (weekArray != null) {
                            weekProgress.clear()
                            for (i in 0 until minOf(7, weekArray.length())) {
                                weekProgress.add(weekArray.optBoolean(i, false))
                            }
                            while (weekProgress.size < 7) {
                                weekProgress.add(false)
                            }
                        }

                        val last = userJson.optString("lastPlayedDate", null)
                        if (!last.isNullOrBlank()) {
                            lastPlayedIso = last
                        }
                    }
                } catch (_: Exception) {
                }
            } else if (streakCount == 0 && !hasCompletedFirstGame) {
                // Legacy fallback
                val legacyJson = flutterPrefs.getString("flutter.streak_data", null)
                if (!legacyJson.isNullOrBlank()) {
                    try {
                        val legacy = JSONObject(legacyJson)
                        streakCount = legacy.optInt("streakCount", streakCount)
                        hasCompletedFirstGame =
                            legacy.optBoolean("hasCompletedFirstGame", hasCompletedFirstGame)
                        val weekArray = legacy.optJSONArray("weekProgress")
                        if (weekArray != null) {
                            weekProgress.clear()
                            for (i in 0 until minOf(7, weekArray.length())) {
                                weekProgress.add(weekArray.optBoolean(i, false))
                            }
                            while (weekProgress.size < 7) {
                                weekProgress.add(false)
                            }
                        }
                        val last = legacy.optString("lastPlayedDate", null)
                        if (!last.isNullOrBlank()) {
                            lastPlayedIso = last
                        }
                    } catch (_: Exception) {
                    }
                }
            }

            // Determine widget state: use stored state if valid, otherwise recalculate
            // This ensures widgets update correctly even when app is closed
            val resolvedState = run {
                // If stored state exists and is valid, use it (for immediate updates like state2)
                // Otherwise, recalculate based on current time
                val storedState = if (!widgetState.isNullOrBlank()) widgetState else null
                
                // Recalculate state based on current time
                val calculatedState = run {
                    if (!hasCompletedFirstGame) {
                        "state1"
                    } else if (!lastPlayedIso.isNullOrBlank()) {
                        try {
                            val lastInstant = java.time.Instant.parse(lastPlayedIso)
                            val nowInstant = java.time.Instant.now()
                            val zone = java.time.ZoneId.systemDefault()
                            val sameDay =
                                java.time.ZonedDateTime.ofInstant(lastInstant, zone).toLocalDate() ==
                                        java.time.ZonedDateTime.ofInstant(nowInstant, zone)
                                            .toLocalDate()
                            if (sameDay) {
                                val minutesSince =
                                    java.time.Duration.between(lastInstant, nowInstant).toMinutes()
                                if (minutesSince >= 10) "state3" else "state2"
                            } else {
                                // State 4: Check if there's activity in past 7 days
                                val lastDate = java.time.ZonedDateTime.ofInstant(lastInstant, zone).toLocalDate()
                                val nowDate = java.time.ZonedDateTime.ofInstant(nowInstant, zone).toLocalDate()
                                val daysSince = java.time.temporal.ChronoUnit.DAYS.between(lastDate, nowDate)
                                if (daysSince <= 6 && streakCount > 0) {
                                    "state4"
                                } else {
                                    "state1"
                                }
                            }
                        } catch (_: Exception) {
                            // Fallback: if we can't parse date, check streak count
                            // But prefer checking activity in past 7 days if possible
                            if (streakCount > 0 && !lastPlayedIso.isNullOrBlank()) {
                                // Try to check if date is recent (within 7 days)
                                try {
                                    val lastInstant = java.time.Instant.parse(lastPlayedIso)
                                    val nowInstant = java.time.Instant.now()
                                    val zone = java.time.ZoneId.systemDefault()
                                    val lastDate = java.time.ZonedDateTime.ofInstant(lastInstant, zone).toLocalDate()
                                    val nowDate = java.time.ZonedDateTime.ofInstant(nowInstant, zone).toLocalDate()
                                    val daysSince = java.time.temporal.ChronoUnit.DAYS.between(lastDate, nowDate)
                                    if (daysSince <= 6) "state4" else "state1"
                                } catch (_: Exception) {
                                    "state1"
                                }
                            } else {
                                "state1"
                            }
                        }
                    } else {
                        // No last played date - can't verify activity in past 7 days
                        "state1"
                    }
                }
                
                // Use stored state if it's valid and matches calculated state logic
                // Otherwise use calculated state (for automatic updates when app is closed)
                if (storedState != null) {
                    // Validate stored state: if it's state2 and we're past 10 minutes, use calculated
                    // Otherwise, trust the stored state for immediate updates
                    if (storedState == "state2" && !lastPlayedIso.isNullOrBlank()) {
                        try {
                            val lastInstant = java.time.Instant.parse(lastPlayedIso)
                            val nowInstant = java.time.Instant.now()
                            val minutesSince = java.time.Duration.between(lastInstant, nowInstant).toMinutes()
                            if (minutesSince >= 10) {
                                // Past 10 minutes, use calculated state (state3)
                                calculatedState
                            } else {
                                // Still within 10 minutes, use stored state2
                                storedState
                            }
                        } catch (_: Exception) {
                            storedState
                        }
                    } else {
                        // For other states, use stored state if it makes sense, otherwise calculated
                        storedState
                    }
                } else {
                    calculatedState
                }
            }
            
            // Update stored state if it changed (for consistency)
            // This ensures the stored state matches what's displayed
            if (resolvedState != widgetState) {
                homeWidgetPrefs.edit()
                    .putString("${keyPrefix}state", resolvedState)
                    .apply()
            }

            val defaultRoute = if (userId.isNullOrBlank()) "/login" else "/start"
            val forceLogin = userId.isNullOrBlank()
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("widget_id", appWidgetId)
                putExtra("route", defaultRoute)
                putExtra("force_login", forceLogin)
                if (!userId.isNullOrBlank()) {
                    putExtra("user_id", userId)
                }
                flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val launchPendingIntent = android.app.PendingIntent.getActivity(
                context,
                appWidgetId,
                launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )

            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            when (resolvedState) {
                "state1" -> {
                    // State 1: Logo + START CHALLENGE + BEGIN button
                    // Try to set logo (will work if logo.png is in drawable folder)
                    // Note: Copy assets/images/logo.png to android/app/src/main/res/drawable/logo.png
                    val logoResId = context.resources.getIdentifier("logo", "drawable", context.packageName)
                    if (logoResId != 0) {
                        views.setImageViewResource(R.id.widget_logo_state1, logoResId)
                        views.setViewVisibility(R.id.widget_logo_state1, android.view.View.VISIBLE)
                    } else {
                        // Logo not found, hide it
                        views.setViewVisibility(R.id.widget_logo_state1, android.view.View.GONE)
                    }
                    views.setTextViewText(R.id.widget_title, "START CHALLENGE")
                    views.setViewVisibility(R.id.widget_title, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_begin_button, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_streak_info, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_week_progress, android.view.View.GONE)
                    
                    // Set up click intent for BEGIN button
                    views.setOnClickPendingIntent(R.id.widget_begin_button, launchPendingIntent)
                }
                "state4", "state2" -> {
                    // State 2/4: Streak + week progress + logo
                    views.setViewVisibility(R.id.widget_logo_state1, android.view.View.GONE)
                    val dayLabel = if (streakCount == 1) "DAY" else "DAYS"
                    views.setTextViewText(R.id.widget_streak_count, "$streakCount $dayLabel")
                    views.setViewVisibility(R.id.widget_title, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_begin_button, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_streak_info, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_week_progress, android.view.View.VISIBLE)
                    
                    // Set logo on the left (uses drawable/logo.png if present)
                    val logoResId = context.resources.getIdentifier("logo", "drawable", context.packageName)
                    if (logoResId != 0) views.setImageViewResource(R.id.widget_logo, logoResId)
                    
                    // Set arrow on the right (vector fallback: arrow_icon)
                    val arrowResIdPng = context.resources.getIdentifier("arrow", "drawable", context.packageName)
                    if (arrowResIdPng != 0) {
                        views.setImageViewResource(R.id.widget_arrow, arrowResIdPng)
                    } else {
                        views.setImageViewResource(R.id.widget_arrow, R.drawable.arrow_icon)
                    }
                    
                    // Update week progress indicators
                    val dayViews = listOf(
                        R.id.day_mon, R.id.day_tue, R.id.day_wed,
                        R.id.day_thu, R.id.day_fri, R.id.day_sat, R.id.day_sun
                    )
                    val dayBgViews = listOf(
                        R.id.day_mon_bg, R.id.day_tue_bg, R.id.day_wed_bg,
                        R.id.day_thu_bg, R.id.day_fri_bg, R.id.day_sat_bg, R.id.day_sun_bg
                    )
                    
                    weekProgress.forEachIndexed { index, isCompleted ->
                        if (index < dayViews.size && index < dayBgViews.size) {
                            if (isCompleted) {
                                // Show tick and set streak background
                                views.setViewVisibility(dayViews[index], android.view.View.VISIBLE)
                                views.setImageViewResource(dayBgViews[index], R.drawable.day_box_completed)
                            } else {
                                // Hide tick and set default background
                                views.setViewVisibility(dayViews[index], android.view.View.GONE)
                                views.setImageViewResource(dayBgViews[index], R.drawable.day_box_background)
                            }
                        }
                    }
                    
                    // Set up click intent to open app
                    views.setOnClickPendingIntent(R.id.widget_container, launchPendingIntent)
                }
                "state3" -> {
                    // Use the same layout as state4 for now
                    views.setViewVisibility(R.id.widget_logo_state1, android.view.View.GONE)
                    val dayLabel = if (streakCount == 1) "DAY" else "DAYS"
                    views.setTextViewText(R.id.widget_streak_count, "$streakCount $dayLabel")
                    views.setViewVisibility(R.id.widget_title, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_begin_button, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_streak_info, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_week_progress, android.view.View.VISIBLE)

                    val logoResId = context.resources.getIdentifier("logo", "drawable", context.packageName)
                    if (logoResId != 0) views.setImageViewResource(R.id.widget_logo, logoResId)

                    val arrowResIdPng = context.resources.getIdentifier("arrow", "drawable", context.packageName)
                    if (arrowResIdPng != 0) {
                        views.setImageViewResource(R.id.widget_arrow, arrowResIdPng)
                    } else {
                        views.setImageViewResource(R.id.widget_arrow, R.drawable.arrow_icon)
                    }

                    val dayViews = listOf(
                        R.id.day_mon, R.id.day_tue, R.id.day_wed,
                        R.id.day_thu, R.id.day_fri, R.id.day_sat, R.id.day_sun
                    )
                    val dayBgViews = listOf(
                        R.id.day_mon_bg, R.id.day_tue_bg, R.id.day_wed_bg,
                        R.id.day_thu_bg, R.id.day_fri_bg, R.id.day_sat_bg, R.id.day_sun_bg
                    )

                    weekProgress.forEachIndexed { index, isCompleted ->
                        if (index < dayViews.size && index < dayBgViews.size) {
                            if (isCompleted) {
                                views.setViewVisibility(dayViews[index], android.view.View.VISIBLE)
                                views.setImageViewResource(dayBgViews[index], R.drawable.day_box_completed)
                            } else {
                                views.setViewVisibility(dayViews[index], android.view.View.GONE)
                                views.setImageViewResource(dayBgViews[index], R.drawable.day_box_background)
                            }
                        }
                    }

                    views.setOnClickPendingIntent(R.id.widget_container, launchPendingIntent)
                }
            }

            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}

