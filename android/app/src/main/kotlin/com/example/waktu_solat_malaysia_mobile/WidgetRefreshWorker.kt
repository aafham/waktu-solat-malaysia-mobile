package com.example.waktu_solat_malaysia_mobile

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

class WidgetRefreshWorker(
    appContext: Context,
    params: WorkerParameters
) : Worker(appContext, params) {

    override fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val languageCode = prefs.getString("languageCode", "en") ?: "en"
        val nextPrayerEpoch = prefs.getLong("nextPrayerEpoch", 0L)
        if (nextPrayerEpoch > 0L) {
            val diffMillis = (nextPrayerEpoch - System.currentTimeMillis()).coerceAtLeast(0L)
            val totalMinutes = diffMillis / 60000L
            val hours = totalMinutes / 60L
            val minutes = totalMinutes % 60L
            val hourSuffix = if (languageCode == "en") "h" else "j"
            val countdown = "$hours$hourSuffix ${minutes.toString().padStart(2, '0')}m"
            prefs.edit().putString("countdownRemaining", countdown).apply()
        }
        NextPrayerWidgetUpdater.updateAll(applicationContext)
        return Result.success()
    }
}
