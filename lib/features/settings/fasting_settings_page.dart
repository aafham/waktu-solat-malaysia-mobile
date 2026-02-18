import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';
import 'settings_styles.dart';

class FastingSettingsPage extends StatelessWidget {
  const FastingSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final tr = controller.tr;
        final autoRamadanActive = controller.isHijriRamadanToday;
        return SettingsSubpageScaffold(
          title: tr('Peringatan Puasa', 'Fasting reminders'),
          child: Column(
            children: [
              if (!controller.notifyEnabled)
                InfoBanner(
                  text: tr(
                    'Aktifkan notifikasi untuk menggunakan peringatan puasa.',
                    'Enable notifications to use fasting reminders.',
                  ),
                ),
              if (!controller.notifyEnabled) const SizedBox(height: 10),
              SettingsSection(
                children: [
                  SettingsToggleTile(
                    icon: Icons.nights_stay_outlined,
                    iconColor: const Color(0xFFF2CB54),
                    title: tr('Mod Ramadan', 'Ramadan mode'),
                    subtitle: tr(
                      autoRamadanActive
                          ? 'Aktif automatik sepanjang Ramadan (berdasarkan tarikh Hijri).'
                          : 'Peringatan harian sepanjang Ramadan',
                      autoRamadanActive
                          ? 'Auto active throughout Ramadan (based on Hijri date).'
                          : 'Daily reminders throughout Ramadan',
                    ),
                    value: controller.isRamadanModeActive,
                    onChanged: controller.notifyEnabled && !autoRamadanActive
                        ? controller.setRamadhanMode
                        : null,
                  ),
                  SettingsToggleTile(
                    icon: Icons.calendar_view_week_outlined,
                    iconColor: const Color(0xFFF2CB54),
                    title: tr('Isnin & Khamis', 'Monday & Thursday'),
                    subtitle: tr(
                      'Peringatan puasa sunat mingguan',
                      'Weekly sunnah fasting reminders',
                    ),
                    value: controller.fastingMondayThursdayEnabled,
                    onChanged: controller.notifyEnabled
                        ? controller.setFastingMondayThursdayEnabled
                        : null,
                  ),
                  SettingsToggleTile(
                    icon: Icons.brightness_2_outlined,
                    iconColor: const Color(0xFFF2CB54),
                    title: tr('Ayyamul Bidh', 'Ayyamul Bidh'),
                    subtitle: tr(
                      '13, 14, 15 setiap bulan hijrah',
                      '13, 14, 15 every hijri month',
                    ),
                    value: controller.fastingAyyamulBidhEnabled,
                    onChanged: controller.notifyEnabled
                        ? controller.setFastingAyyamulBidhEnabled
                        : null,
                  ),
                  SettingsNavTile(
                    icon: Icons.event_note_outlined,
                    iconColor: const Color(0xFFF2CB54),
                    title: tr('Pratonton tarikh akan datang',
                        'Preview upcoming dates'),
                    subtitle: tr(
                      'Lihat 5 peringatan seterusnya',
                      'See next 5 upcoming reminders',
                    ),
                    onTap: () => _showUpcomingPreview(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  tr(
                    'Jadual peringatan dijana automatik berdasarkan data bulanan semasa.',
                    'Reminder schedule is generated automatically from current monthly data.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: settingsTextMuted,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showUpcomingPreview(BuildContext context) async {
    final tr = controller.tr;
    final days = controller.upcomingFastingReminderDates(limit: 5);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: settingsSurface,
      showDragHandle: true,
      builder: (context) {
        if (days.isEmpty) {
          return SizedBox(
            height: 160,
            child: Center(
              child: Text(
                tr('Tiada peringatan dijumpai', 'No upcoming reminders found'),
              ),
            ),
          );
        }
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: days.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final day = days[index];
              final date =
                  '${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}/${day.date.year}';
              return ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(date),
                subtitle: Text(controller.formatHijriWithOffset(day.hijriDate)),
              );
            },
          ),
        );
      },
    );
  }
}
