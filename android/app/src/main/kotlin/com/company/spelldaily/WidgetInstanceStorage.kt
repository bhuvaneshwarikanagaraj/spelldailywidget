package com.company.spelldaily

import android.content.Context
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject

data class WidgetInstanceData(
    val widgetId: Int,
    val loginCode: String? = null,
    val state: String = "unlinked",
    val streakCount: Int = 0,
    val weekProgress: BooleanArray = BooleanArray(7) { false },
    val lastStateChange: Long = 0L,
    val pendingTenMinuteWorkId: String? = null,
    val pendingNextDayWorkId: String? = null,
) {
    fun toJson(): String {
        val array = JSONArray()
        weekProgress.forEach { array.put(it) }
        return JSONObject().apply {
            put("widgetId", widgetId)
            if (!loginCode.isNullOrEmpty()) {
                put("loginCode", loginCode)
            }
            put("state", state)
            put("streakCount", streakCount)
            put("weekProgress", array)
            put("lastStateChange", lastStateChange)
            pendingTenMinuteWorkId?.let { put("pendingTenMinuteWorkId", it) }
            pendingNextDayWorkId?.let { put("pendingNextDayWorkId", it) }
        }.toString()
    }

    companion object {
        fun fromJson(widgetId: Int, json: String): WidgetInstanceData {
            val obj = JSONObject(json)
            val weekArray = obj.optJSONArray("weekProgress") ?: JSONArray()
            val progresses = BooleanArray(7) { index ->
                weekArray.optBoolean(index, false)
            }
            val login = if (obj.has("loginCode") && !obj.isNull("loginCode")) {
                obj.optString("loginCode")
            } else {
                null
            }
            val tenId =
                if (obj.has("pendingTenMinuteWorkId") && !obj.isNull("pendingTenMinuteWorkId")) {
                    obj.optString("pendingTenMinuteWorkId")
                } else {
                    null
                }
            val nextId =
                if (obj.has("pendingNextDayWorkId") && !obj.isNull("pendingNextDayWorkId")) {
                    obj.optString("pendingNextDayWorkId")
                } else {
                    null
                }
            return WidgetInstanceData(
                widgetId = widgetId,
                loginCode = login,
                state = obj.optString("state", "unlinked"),
                streakCount = obj.optInt("streakCount", 0),
                weekProgress = progresses,
                lastStateChange = obj.optLong("lastStateChange", 0L),
                pendingTenMinuteWorkId = tenId,
                pendingNextDayWorkId = nextId,
            )
        }
    }
}

object WidgetInstanceStorage {
    private fun key(widgetId: Int) = "widget_instance_$widgetId"

    private fun preferences(context: Context) = HomeWidgetPlugin.getData(context)

    fun load(context: Context, widgetId: Int): WidgetInstanceData {
        val prefs = preferences(context)
        val raw = prefs.getString(key(widgetId), null)
        return if (raw.isNullOrEmpty()) {
            WidgetInstanceData(widgetId = widgetId)
        } else {
            runCatching { WidgetInstanceData.fromJson(widgetId, raw) }
                .getOrElse { WidgetInstanceData(widgetId = widgetId) }
        }
    }

    fun save(context: Context, data: WidgetInstanceData) {
        preferences(context).edit().putString(key(data.widgetId), data.toJson()).apply()
    }

    fun update(
        context: Context,
        widgetId: Int,
        transform: (WidgetInstanceData) -> WidgetInstanceData,
    ): WidgetInstanceData {
        val updated = transform(load(context, widgetId))
        save(context, updated)
        return updated
    }

    fun delete(context: Context, widgetId: Int) {
        preferences(context).edit().remove(key(widgetId)).apply()
    }
}


