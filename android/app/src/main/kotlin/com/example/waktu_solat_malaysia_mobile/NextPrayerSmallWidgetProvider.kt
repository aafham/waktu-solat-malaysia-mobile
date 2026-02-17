package com.example.waktu_solat_malaysia_mobile

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent

class NextPrayerSmallWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        NextPrayerWidgetUpdater.updateAll(context)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetWorkScheduler.schedule(context)
        NextPrayerWidgetUpdater.updateAll(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        NextPrayerWidgetUpdater.updateAll(context)
    }
}
