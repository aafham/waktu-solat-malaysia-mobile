package com.example.waktu_solat_malaysia_mobile

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object WidgetWorkScheduler {
    private const val WORK_NAME = "next_prayer_widget_refresh"

    fun schedule(context: Context) {
        val work = PeriodicWorkRequestBuilder<WidgetRefreshWorker>(
            15,
            TimeUnit.MINUTES
        ).build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            work
        )
    }
}
