import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class WidgetUpdateService {
  const WidgetUpdateService();

  static const String _compactProvider = 'NextPrayerSmallWidgetProvider';
  static const String _contextProvider = 'TasbihWidgetProvider';
  static const String _progressProvider = 'NextPrayerWidgetProvider';

  Future<void> updateWidgets({
    required String nextName,
    required String nextTime,
    required String nextCountdown,
    required String nextSubtitle,
    required String locationLabel,
    required String liveLabel,
    required String todayDone,
    required String streakText,
    required String currentName,
    required String currentTime,
    String? remainingCount,
    required int nextPrayerEpoch,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await HomeWidget.saveWidgetData<String>('nextName', nextName);
      await HomeWidget.saveWidgetData<String>('nextTime', nextTime);
      await HomeWidget.saveWidgetData<String>('nextCountdown', nextCountdown);
      await HomeWidget.saveWidgetData<String>('nextSubtitle', nextSubtitle);
      await HomeWidget.saveWidgetData<String>('locationLabel', locationLabel);
      await HomeWidget.saveWidgetData<String>('liveLabel', liveLabel);
      await HomeWidget.saveWidgetData<String>('todayDone', todayDone);
      await HomeWidget.saveWidgetData<String>('streakText', streakText);
      await HomeWidget.saveWidgetData<String>('currentName', currentName);
      await HomeWidget.saveWidgetData<String>('currentTime', currentTime);
      if (remainingCount != null && remainingCount.trim().isNotEmpty) {
        await HomeWidget.saveWidgetData<String>('remainingCount', remainingCount);
      }

      // Backward-compatible keys still read by Android fallbacks.
      await HomeWidget.saveWidgetData<String>('nextPrayerName', nextName);
      await HomeWidget.saveWidgetData<String>('nextPrayerTime', nextTime);
      await HomeWidget.saveWidgetData<String>('countdownRemainingText', nextCountdown);
      await HomeWidget.saveWidgetData<String>('countdownRemaining', nextCountdown);
      await HomeWidget.saveWidgetData<String>('subtitle', nextSubtitle);
      await HomeWidget.saveWidgetData<int>('nextPrayerEpoch', nextPrayerEpoch);

      await HomeWidget.updateWidget(name: _compactProvider);
      await HomeWidget.updateWidget(name: _contextProvider);
      await HomeWidget.updateWidget(name: _progressProvider);
    } on MissingPluginException catch (e) {
      debugPrint('Widget channel unavailable: $e');
    } on PlatformException catch (e) {
      debugPrint('Widget update platform error: ${e.message}');
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
