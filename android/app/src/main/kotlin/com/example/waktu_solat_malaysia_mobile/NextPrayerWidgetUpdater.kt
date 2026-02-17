package com.example.waktu_solat_malaysia_mobile

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

object NextPrayerWidgetUpdater {
    private const val PREFS_NAME = "HomeWidgetPreferences"

    fun updateAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val mediumComponent = ComponentName(context, NextPrayerWidgetProvider::class.java)
        val smallComponent = ComponentName(context, NextPrayerSmallWidgetProvider::class.java)

        updateWidgets(
            context = context,
            manager = manager,
            widgetIds = manager.getAppWidgetIds(mediumComponent),
            layoutRes = R.layout.widget_next_prayer_medium
        )
        updateWidgets(
            context = context,
            manager = manager,
            widgetIds = manager.getAppWidgetIds(smallComponent),
            layoutRes = R.layout.widget_next_prayer_small
        )
    }

    private fun updateWidgets(
        context: Context,
        manager: AppWidgetManager,
        widgetIds: IntArray,
        layoutRes: Int
    ) {
        if (widgetIds.isEmpty()) {
            return
        }
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val languageCode = prefs.getString("languageCode", "en") ?: "en"
        val nextPrayerName = prefs.getString("nextPrayerName", fallback(languageCode, "Seterusnya", "Next")) ?: fallback(languageCode, "Seterusnya", "Next")
        val nextPrayerTime = prefs.getString("nextPrayerTime", "--:--") ?: "--:--"
        val countdown = prefs.getString("countdownRemaining", fallback(languageCode, "--j --m", "--h --m")) ?: fallback(languageCode, "--j --m", "--h --m")
        val subtitle = prefs.getString("subtitle", fallback(languageCode, "Sebelum waktu seterusnya", "Before next prayer")) ?: fallback(languageCode, "Sebelum waktu seterusnya", "Before next prayer")
        val location = prefs.getString("locationLabel", fallback(languageCode, "Lokasi", "Location")) ?: fallback(languageCode, "Lokasi", "Location")
        val updatedAtEpoch = prefs.getLong("updatedAtEpoch", 0L)

        val updatedLabel = updatedLabel(languageCode, updatedAtEpoch)
        val launchIntent = Intent(Intent.ACTION_VIEW, Uri.parse("myapp://times"), context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            72,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        for (widgetId in widgetIds) {
            val views = RemoteViews(context.packageName, layoutRes)
            views.setTextViewText(R.id.widgetTitleLabel, fallback(languageCode, "Seterusnya", "Next"))
            views.setTextViewText(R.id.widgetPrayerName, nextPrayerName)
            views.setTextViewText(R.id.widgetPrayerTime, nextPrayerTime)
            views.setTextViewText(R.id.widgetCountdown, countdown)
            views.setTextViewText(R.id.widgetSubtitle, subtitle)
            views.setTextViewText(R.id.widgetLocation, location)
            views.setTextViewText(R.id.widgetUpdated, updatedLabel)
            views.setOnClickPendingIntent(R.id.widgetRoot, pendingIntent)
            manager.updateAppWidget(widgetId, views)
        }
    }

    private fun updatedLabel(languageCode: String, updatedAtEpoch: Long): String {
        val liveLabel = fallback(languageCode, "Langsung", "Live")
        val nowLabel = fallback(languageCode, "kini", "now")
        if (updatedAtEpoch <= 0L) {
            return "$liveLabel • $nowLabel"
        }
        val ageMinutes = ((System.currentTimeMillis() - updatedAtEpoch) / 60000L).coerceAtLeast(0L)
        return if (ageMinutes <= 0L) {
            "$liveLabel • $nowLabel"
        } else {
            "$liveLabel • ${ageMinutes}m"
        }
    }

    private fun fallback(languageCode: String, bm: String, en: String): String {
        return if (languageCode == "en") en else bm
    }
}
