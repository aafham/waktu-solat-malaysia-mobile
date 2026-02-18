import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../../theme/page_header_style.dart';
import 'about_page.dart';
import 'appearance_settings_page.dart';
import 'fasting_settings_page.dart';
import 'notifications_settings_page.dart';
import 'prayer_times_settings_page.dart';
import 'settings_components.dart';
import 'settings_styles.dart';
import 'tasbih_settings_page.dart';

export 'about_page.dart';
export 'appearance_settings_page.dart';
export 'fasting_settings_page.dart';
export 'notifications_settings_page.dart';
export 'prayer_times_settings_page.dart';
export 'tasbih_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _versionBuild = 'v1.0.0+1';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final query = _query.trim().toLowerCase();

    bool match(List<String> keywords) {
      if (query.isEmpty) {
        return true;
      }
      return keywords.any((k) => k.toLowerCase().contains(query));
    }

    final languageSummary = controller.isEnglish ? 'English' : 'Bahasa Melayu';
    final appearanceSummary = tr(
      'Teks: ${_textScaleLabel(controller.textScale)} | Kontras: ${controller.highContrast ? 'Aktif' : 'Mati'}',
      'Text: ${_textScaleLabel(controller.textScale)} | Contrast: ${controller.highContrast ? 'On' : 'Off'}',
    );
    final prayerSummary = controller.autoLocation
        ? tr(
            'Auto | ${controller.activeZone?.location ?? 'Kuala Lumpur'}',
            'Auto | ${controller.activeZone?.location ?? 'Kuala Lumpur'}',
          )
        : tr(
            'Manual | ${controller.manualZoneCode}',
            'Manual | ${controller.manualZoneCode}',
          );
    final notificationSummary = controller.notifyEnabled
        ? tr(
            'Aktif | Awal ${_leadLabel(controller, controller.notificationLeadMinutes)}',
            'Enabled | Lead ${_leadLabel(controller, controller.notificationLeadMinutes)}',
          )
        : tr('Tidak aktif', 'Disabled');
    final fastingCount = <bool>[
      controller.isRamadanModeActive,
      controller.fastingMondayThursdayEnabled,
      controller.fastingAyyamulBidhEnabled,
    ].where((v) => v).length;
    final fastingSummary = fastingCount == 0
        ? tr('Tiada aktif', 'None active')
        : tr('$fastingCount aktif', '$fastingCount active');
    final tasbihSummary = tr(
      'Sasaran ${controller.tasbihCycleTarget} | Auto reset: ${controller.tasbihAutoResetDaily ? 'Aktif' : 'Mati'}',
      'Target ${controller.tasbihCycleTarget} | Auto reset: ${controller.tasbihAutoResetDaily ? 'On' : 'Off'}',
    );
    final aboutSummary = tr(
      '$_versionBuild | JAKIM + Waktu Solat API | ${controller.prayerDataFreshnessLabel}',
      '$_versionBuild | JAKIM + Waktu Solat API | ${controller.prayerDataFreshnessLabel}',
    );

    final showLanguage =
        match(<String>[tr('Bahasa', 'Language'), languageSummary]);
    final showAppearance =
        match(<String>[tr('Paparan', 'Appearance'), appearanceSummary]);
    final showPrayerTimes = match(<String>[
      tr('Waktu Solat', 'Prayer Times'),
      prayerSummary,
      tr('Zon', 'Zone'),
    ]);
    final showNotifications = match(<String>[
      tr('Notifikasi', 'Notifications'),
      notificationSummary,
      tr('Bunyi', 'Sound'),
    ]);
    final showFasting = match(<String>[
      tr('Peringatan Puasa', 'Fasting reminders'),
      fastingSummary,
      'Ramadan',
      'Ayyamul Bidh',
    ]);
    final showTasbih = match(
        <String>[tr('Tasbih', 'Tasbih'), tasbihSummary, tr('Zikir', 'Dhikr')]);
    final showAbout = match(<String>[
      tr('Tentang', 'About'),
      'JagaSolat',
      aboutSummary,
    ]);

    final hasResult = showLanguage ||
        showAppearance ||
        showPrayerTimes ||
        showNotifications ||
        showFasting ||
        showTasbih ||
        showAbout;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [settingsBgTop, settingsBgBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            Text(
              controller.t('page_title_settings'),
              style: pageTitleStyle(context).copyWith(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              controller.t('page_subtitle_settings'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: settingsTextMuted,
                  ),
            ),
            const SizedBox(height: 12),
            SearchField(
              controller: _searchController,
              hint: tr('Cari tetapan', 'Search settings'),
              onChanged: (value) => setState(() => _query = value),
              onClear: _query.isEmpty
                  ? null
                  : () => setState(() {
                        _query = '';
                        _searchController.clear();
                      }),
            ),
            if (!hasResult) ...[
              const SizedBox(height: 12),
              EmptyState(text: tr('Tiada hasil ditemui.', 'No results found.')),
            ],
            if (showLanguage || showAppearance) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Umum', 'General'),
                children: [
                  if (showLanguage) ...[
                    ListTile(
                      leading: const LeadingIcon(
                        icon: Icons.language,
                        color: Color(0xFF50D7C9),
                      ),
                      title: Text(tr('Bahasa', 'Language')),
                      subtitle: Text(languageSummary),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                  value: 'ms', label: Text('BM')),
                              ButtonSegment<String>(
                                  value: 'en', label: Text('EN')),
                            ],
                            selected: <String>{controller.languageCode},
                            onSelectionChanged: (selection) =>
                                controller.setLanguageCode(selection.first),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showAppearance)
                    SettingsNavTile(
                      icon: Icons.palette_outlined,
                      iconColor: const Color(0xFFE76EA4),
                      title: tr('Paparan', 'Appearance'),
                      subtitle: appearanceSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AppearanceSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (showPrayerTimes || showNotifications || showFasting) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Solat', 'Prayer'),
                children: [
                  if (showPrayerTimes)
                    SettingsNavTile(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF5CA9FF),
                      title: tr('Waktu Solat', 'Prayer Times'),
                      subtitle: prayerSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PrayerTimesSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                  if (showNotifications)
                    SettingsNavTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFFFA450),
                      title: tr('Notifikasi', 'Notifications'),
                      subtitle: notificationSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              NotificationsSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                  if (showFasting)
                    SettingsNavTile(
                      icon: Icons.nights_stay_outlined,
                      iconColor: const Color(0xFFF2CB54),
                      title: tr('Peringatan Puasa', 'Fasting reminders'),
                      subtitle: fastingSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FastingSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (showTasbih) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Tasbih', 'Tasbih'),
                children: [
                  SettingsNavTile(
                    icon: Icons.touch_app_outlined,
                    iconColor: const Color(0xFFA98EFF),
                    title: tr('Tetapan Tasbih', 'Tasbih settings'),
                    subtitle: tasbihSummary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TasbihSettingsPage(controller: controller),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (showAbout) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Tentang', 'About'),
                children: [
                  SettingsNavTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF4EC7F7),
                    title: tr('Tentang aplikasi', 'About app'),
                    subtitle: aboutSummary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AboutPage(controller: controller),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _textScaleLabel(double value) {
    if (value <= 0.95) {
      return 'S';
    }
    if (value <= 1.05) {
      return 'M';
    }
    if (value <= 1.25) {
      return 'L';
    }
    return 'XL';
  }

  String _leadLabel(AppController controller, int value) {
    if (value <= 0) {
      return controller.tr('Tepat waktu', 'On time');
    }
    return '$value min';
  }
}
