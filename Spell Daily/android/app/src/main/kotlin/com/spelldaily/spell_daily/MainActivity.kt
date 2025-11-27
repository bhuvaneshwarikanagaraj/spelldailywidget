package com.company.spelldaily

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import java.util.Calendar

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.company.spelldaily/navigation"
    private val SCHEDULER_CHANNEL = "com.company.spelldaily/widget_scheduler"
    private var navigationChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Handle widget navigation
        val intent = intent
        if (intent != null && intent.hasExtra("route")) {
            val route = intent.getStringExtra("route")
            // Route will be handled by Flutter navigation in main.dart
        }
        
        // Set up method channel for widget communication
        navigationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialRoute" -> {
                        val route = intent?.getStringExtra("route") ?: "/"
                        result.success(route)
                    }
                    "getInitialLaunchDetails" -> {
                        val route = intent?.getStringExtra("route")
                        val widgetId = intent?.getIntExtra("widget_id", -1)?.takeIf { it != -1 }
                        val userId = intent?.getStringExtra("user_id")
                        val forceLogin = intent?.getBooleanExtra("force_login", false) ?: false
                        val payload = mapOf(
                            "route" to route,
                            "widgetId" to widgetId,
                            "userId" to userId,
                            "forceLogin" to forceLogin
                        )
                        result.success(payload)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }

        // Scheduler channel to manage widget refresh work and fallbacks
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCHEDULER_CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "scheduleWidgetRefreshForUser" -> {
                        val userId = call.argument<String>("userId")
                        val delayMs = (call.argument<Number>("delayMs")?.toLong()) ?: 0L
                        if (!userId.isNullOrBlank()) {
                            WidgetRefreshScheduler.scheduleUserRefresh(this, userId, delayMs)
                        }
                        result.success(true)
                    }
                    "cancelWidgetRefreshForUser" -> {
                        val userId = call.argument<String>("userId")
                        if (!userId.isNullOrBlank()) {
                            WidgetRefreshScheduler.cancelUserRefresh(this, userId)
                        }
                        result.success(true)
                    }
                    "scheduleWidgetRefreshInMs" -> {
                        val delayMs = (call.argument<Number>("delayMs")?.toLong()) ?: 0L
                        scheduleOneOffRefresh(delayMs)
                        result.success(true)
                    }
                    "scheduleDailyWidgetRefresh" -> {
                        val hour = call.argument<Int>("hour") ?: 5
                        val minute = call.argument<Int>("minute") ?: 5
                        WidgetRefreshScheduler.scheduleDailyRefresh(this, hour, minute, replace = true)
                        scheduleDailyRefresh(hour, minute)
                        result.success(true)
                    }
                    "schedulePeriodicWidgetRefresh" -> {
                        val intervalMinutes = call.argument<Int>("intervalMinutes") ?: 60
                        WidgetRefreshScheduler.ensurePeriodicRefresh(this, intervalMinutes)
                        schedulePeriodicRefresh(intervalMinutes)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("SCHED_ERROR", e.message, null)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Handle deep links and widget taps
        handleIntent(intent, false)
    }

    private fun scheduleOneOffRefresh(delayMs: Long) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WidgetUpdateReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            1001,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val triggerAt = System.currentTimeMillis() + delayMs
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
    }

    private fun scheduleDailyRefresh(hour: Int, minute: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WidgetUpdateReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            1002,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val cal = Calendar.getInstance().apply {
            timeInMillis = System.currentTimeMillis()
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) {
                add(Calendar.DAY_OF_YEAR, 1)
            }
        }
        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            cal.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pendingIntent
        )
    }

    private fun schedulePeriodicRefresh(intervalMinutes: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, WidgetUpdateReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            1003,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val intervalMs = intervalMinutes * 60 * 1000L
        val triggerAt = System.currentTimeMillis() + intervalMs
        // Use setRepeating for periodic updates
        alarmManager.setRepeating(
            AlarmManager.RTC_WAKEUP,
            triggerAt,
            intervalMs,
            pendingIntent
        )
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, true)
    }

    private fun handleIntent(intent: Intent?, fromNewIntent: Boolean) {
        if (intent != null) {
            val route = intent.getStringExtra("route")
            if (route != null) {
                // Navigate to route in Flutter
                // This is handled by Flutter's navigation system
            }

            if (fromNewIntent) {
                val widgetId = intent.getIntExtra("widget_id", -1).takeIf { it != -1 }
                val userId = intent.getStringExtra("user_id")
                val forceLogin = intent.getBooleanExtra("force_login", false)
                val payload = mapOf(
                    "route" to route,
                    "widgetId" to widgetId,
                    "userId" to userId,
                    "forceLogin" to forceLogin
                )
                navigationChannel?.invokeMethod("onWidgetLaunch", payload)
            }
        }
    }
}
