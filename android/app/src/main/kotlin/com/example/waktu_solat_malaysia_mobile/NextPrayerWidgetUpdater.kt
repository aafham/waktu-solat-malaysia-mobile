package com.example.waktu_solat_malaysia_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import java.util.Locale

object NextPrayerWidgetUpdater {
    private const val PREFS_NAME = "HomeWidgetPreferences"
    private const val BULLET = " \u00B7 "

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val compactIds = manager.getAppWidgetIds(ComponentName(context, NextPrayerSmallWidgetProvider::class.java))
        val contextIds = manager.getAppWidgetIds(ComponentName(context, TasbihWidgetProvider::class.java))
        val progressIds = manager.getAppWidgetIds(ComponentName(context, NextPrayerWidgetProvider::class.java))

        val locale = context.resources.configuration.locales.get(0) ?: Locale.getDefault()
        val isEnglish = locale.language.equals("en", ignoreCase = true)

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val model = WidgetModel.fromPrefs(prefs, isEnglish)
        val pendingIntent = buildLaunchPendingIntent(context)

        compactIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_2x1_compact)
            views.setTextViewText(R.id.widgetNextName, model.nextName)
            views.setTextViewText(R.id.widgetNextTime, model.nextTime)
            views.setTextViewText(R.id.widgetNextCountdown, model.nextCountdown)
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            manager.updateAppWidget(id, views)
        }

        contextIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_2x2_next_context)
            views.setTextViewText(R.id.widgetBadge, if (isEnglish) "NEXT" else "SETERUSNYA")
            views.setTextViewText(R.id.widgetNextName, model.nextName)
            views.setTextViewText(R.id.widgetNextTime, model.nextTime)
            views.setTextViewText(R.id.widgetNextCountdown, model.nextCountdown)
            views.setTextViewText(R.id.widgetNextSubtitle, model.nextSubtitle)
            views.setTextViewText(R.id.widgetFooter, "${model.locationLabel}$BULLET${model.liveLabel}")
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            manager.updateAppWidget(id, views)
        }

        progressIds.forEach { id ->
            val views = RemoteViews(context.packageName, R.layout.widget_3x2_today_progress)
            views.setTextViewText(R.id.widgetHeaderToday, if (isEnglish) "Today" else "Hari ini")
            views.setTextViewText(R.id.widgetTodayDone, model.todayDone)
            views.setTextViewText(
                R.id.widgetStreak,
                if (isEnglish) "Streak ${model.streakText}" else "Streak ${model.streakText}"
            )
            views.setTextViewText(
                R.id.widgetNextSummary,
                if (isEnglish) "Next ${model.nextName}$BULLET${model.nextTime}"
                else "Seterusnya ${model.nextName}$BULLET${model.nextTime}"
            )
            views.setTextViewText(
                R.id.widgetRemainingCount,
                if (isEnglish) "Remaining ${model.nextCountdown}" else "Baki ${model.nextCountdown}"
            )
            views.setTextViewText(
                R.id.widgetCurrentSummary,
                if (isEnglish) "Current: ${model.currentName} ${model.currentTime}"
                else "Semasa: ${model.currentName} ${model.currentTime}"
            )
            views.setTextViewText(R.id.widgetFooter, "${model.locationLabel}$BULLET${model.liveLabel}")
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            manager.updateAppWidget(id, views)
        }
    }

    private fun buildLaunchPendingIntent(context: Context): PendingIntent {
        val launchIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("myapp://times"),
            context,
            MainActivity::class.java
        ).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        return PendingIntent.getActivity(
            context,
            72,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private data class WidgetModel(
        val nextName: String,
        val nextTime: String,
        val nextCountdown: String,
        val nextSubtitle: String,
        val locationLabel: String,
        val liveLabel: String,
        val todayDone: String,
        val streakText: String,
        val currentName: String,
        val currentTime: String
    ) {
        companion object {
            fun fromPrefs(prefs: android.content.SharedPreferences, isEnglish: Boolean): WidgetModel {
                val doneCount = prefs.getInt("todayDoneCount", 0)
                val targetCount = prefs.getInt("todayTargetCount", 5).coerceAtLeast(1)
                val streakDays = prefs.getInt("streakDays", 0).coerceAtLeast(0)
                val nextEpoch = prefs.getLong("nextPrayerEpoch", 0L)

                val rawNext = prefs.getString("nextName", null)
                    ?: prefs.getString("nextPrayerName", "Imsak")
                    ?: "Imsak"
                val rawCurrent = prefs.getString("currentName", "Zohor") ?: "Zohor"

                val localizedNext = localizePrayerName(rawNext, isEnglish)
                val localizedCurrent = localizePrayerName(rawCurrent, isEnglish)
                val countdown = buildCountdown(
                    nextEpoch = nextEpoch,
                    fallback = prefs.getString("nextCountdown", null)
                        ?: prefs.getString("countdownRemainingText", null)
                        ?: prefs.getString("countdownRemaining", null)
                        ?: "--",
                    isEnglish = isEnglish
                )

                return WidgetModel(
                    nextName = localizedNext,
                    nextTime = prefs.getString("nextTime", null)
                        ?: prefs.getString("nextPrayerTime", "--:--")
                        ?: "--:--",
                    nextCountdown = countdown,
                    nextSubtitle = if (isEnglish) "Before $localizedNext begins" else "Sebelum $localizedNext bermula",
                    locationLabel = prefs.getString("locationLabel", "Putrajaya") ?: "Putrajaya",
                    liveLabel = if (isEnglish) "Live" else "Langsung",
                    todayDone = prefs.getString("todayDone", "$doneCount/$targetCount") ?: "$doneCount/$targetCount",
                    streakText = prefs.getString("streakText", "${streakDays}h") ?: "${streakDays}h",
                    currentName = localizedCurrent,
                    currentTime = prefs.getString("currentTime", "--:--") ?: "--:--"
                )
            }

            private fun buildCountdown(nextEpoch: Long, fallback: String, isEnglish: Boolean): String {
                if (nextEpoch > 0L) {
                    val diffMillis = (nextEpoch - System.currentTimeMillis()).coerceAtLeast(0L)
                    return formatDuration(diffMillis / 60000L, isEnglish)
                }
                val numbers = Regex("""\d+""").findAll(fallback).map { it.value.toLong() }.toList()
                return if (numbers.isNotEmpty()) {
                    val h = numbers.firstOrNull() ?: 0L
                    val m = numbers.getOrNull(1) ?: 0L
                    formatDuration((h * 60L) + m, isEnglish)
                } else {
                    if (isEnglish) "0 minutes" else "0 minit"
                }
            }

            private fun formatDuration(totalMinutes: Long, isEnglish: Boolean): String {
                val safe = totalMinutes.coerceAtLeast(0L)
                val hours = safe / 60L
                val minutes = safe % 60L
                return if (isEnglish) {
                    when {
                        hours > 0L && minutes > 0L -> "$hours ${if (hours == 1L) "hour" else "hours"} $minutes ${if (minutes == 1L) "minute" else "minutes"}"
                        hours > 0L -> "$hours ${if (hours == 1L) "hour" else "hours"}"
                        else -> "$minutes ${if (minutes == 1L) "minute" else "minutes"}"
                    }
                } else {
                    when {
                        hours > 0L && minutes > 0L -> "$hours jam $minutes minit"
                        hours > 0L -> "$hours jam"
                        else -> "$minutes minit"
                    }
                }
            }

            private fun localizePrayerName(value: String, isEnglish: Boolean): String {
                val v = value.trim().lowercase(Locale.ROOT)
                if (!isEnglish) {
                    return when (v) {
                        "fajr" -> "Subuh"
                        "sunrise" -> "Syuruk"
                        "dhuhr" -> "Zohor"
                        "asr" -> "Asar"
                        "maghrib" -> "Maghrib"
                        "isha", "isyak" -> "Isyak"
                        else -> value
                    }
                }
                return when (v) {
                    "imsak" -> "Imsak"
                    "subuh", "fajr" -> "Fajr"
                    "syuruk", "sunrise" -> "Sunrise"
                    "zohor", "dhuhr" -> "Dhuhr"
                    "asar", "asr" -> "Asr"
                    "maghrib" -> "Maghrib"
                    "isyak", "isha" -> "Isha"
                    else -> value
                }
            }
        }
    }
}
