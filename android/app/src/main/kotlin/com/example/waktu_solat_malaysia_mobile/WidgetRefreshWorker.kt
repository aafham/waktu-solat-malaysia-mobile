package com.example.waktu_solat_malaysia_mobile

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.Locale

class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val nextPrayerEpoch = prefs.getLong("nextPrayerEpoch", 0L)
        val locale = applicationContext.resources.configuration.locales.get(0) ?: Locale.getDefault()
        val isEnglish = locale.language.equals("en", ignoreCase = true)
        if (nextPrayerEpoch > 0L) {
            val diffMillis = (nextPrayerEpoch - System.currentTimeMillis()).coerceAtLeast(0L)
            val totalMinutes = diffMillis / 60000L
            val countdown = formatDuration(totalMinutes, isEnglish)
            prefs.edit()
                .putString("nextCountdown", countdown)
                .putString("countdownRemainingText", countdown)
                .putString("countdownRemaining", countdown)
                .apply()
        }
        NextPrayerWidgetUpdater.updateAll(applicationContext)
        return Result.success()
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
}
