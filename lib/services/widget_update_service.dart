import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

class WidgetUpdateService {
  const WidgetUpdateService();

  static const String _smallProvider = 'NextPrayerSmallWidgetProvider';
  static const String _mediumProvider = 'NextPrayerWidgetProvider';

  Future<void> updateNextPrayerWidget({
    required String nextPrayerName,
    required String nextPrayerTime,
    required String countdownRemaining,
    required String locationLabel,
    required String subtitle,
    required int updatedAtEpoch,
    required int nextPrayerEpoch,
    required String languageCode,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await HomeWidget.saveWidgetData<String>('nextPrayerName', nextPrayerName);
      await HomeWidget.saveWidgetData<String>('nextPrayerTime', nextPrayerTime);
      await HomeWidget.saveWidgetData<String>(
        'countdownRemaining',
        countdownRemaining,
      );
      await HomeWidget.saveWidgetData<String>('locationLabel', locationLabel);
      await HomeWidget.saveWidgetData<String>('subtitle', subtitle);
      await HomeWidget.saveWidgetData<int>('updatedAtEpoch', updatedAtEpoch);
      await HomeWidget.saveWidgetData<int>('nextPrayerEpoch', nextPrayerEpoch);
      await HomeWidget.saveWidgetData<String>('languageCode', languageCode);

      await HomeWidget.updateWidget(name: _smallProvider);
      await HomeWidget.updateWidget(name: _mediumProvider);
    } on MissingPluginException catch (e) {
      debugPrint('Widget channel unavailable: $e');
    } on PlatformException catch (e) {
      debugPrint('Widget update platform error: ${e.message}');
    } catch (e) {
      debugPrint('Widget update failed: $e');
    }
  }
}
