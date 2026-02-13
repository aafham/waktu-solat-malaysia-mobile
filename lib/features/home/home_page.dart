import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final prayers = controller.dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[];
    final nextPrayer = controller.nextPrayer;
    final countdown = controller.timeToNextPrayer;
    final now = DateTime.now();
    final currentPrayer = _currentPrayer(prayers, now);
    final heroTheme = _themeForPrayer(nextPrayer?.name ?? currentPrayer?.name);

    PrayerTimeEntry? findPrayer(String name) {
      for (final p in prayers) {
        if (p.name == name) {
          return p;
        }
      }
      return null;
    }

    final maghrib = findPrayer('Maghrib');
    final imsak = findPrayer('Imsak');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshPrayerData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Waktu Solat Malaysia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              controller.activeZone?.label ?? 'Zon belum ditentukan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'API berjaya: ${controller.apiSuccessCount} | Gagal: ${controller.apiFailureCount} | Cache: ${controller.cacheHitCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            if (controller.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (controller.errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.errorMessage!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: controller.refreshPrayerData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba semula'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Text(
                'Seterusnya',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroTheme,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextPrayer == null
                            ? 'Tiada waktu seterusnya hari ini'
                            : nextPrayer.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextPrayer == null
                            ? '-'
                            : '${DateFormat('HH:mm').format(nextPrayer.time)} • ${_formatCountdown(countdown)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 10),
                      if (currentPrayer != null)
                        Text(
                          'Sedang berjalan: ${currentPrayer.name}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(5),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            child: const Text('Snooze 5 min'),
                          ),
                          OutlinedButton(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(10),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            child: const Text('Snooze 10 min'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Hari Ini',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (maghrib != null)
                    Chip(
                      avatar: const Icon(Icons.restaurant, size: 16),
                      label: Text(
                        'Berbuka ${DateFormat('HH:mm').format(maghrib.time)}',
                      ),
                    ),
                  if (imsak != null)
                    Chip(
                      avatar: const Icon(Icons.nights_stay, size: 16),
                      label: Text(
                        'Imsak ${DateFormat('HH:mm').format(imsak.time)}',
                      ),
                    ),
                  if (!controller.exactAlarmAllowed)
                    const Chip(
                      avatar: Icon(Icons.warning_amber, size: 16),
                      label: Text('Exact alarm mungkin diblok'),
                    ),
                ],
              ),
              if (controller.ramadhanMode) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Mod Ramadhan aktif: fokus pada Imsak dan Maghrib untuk jadual puasa harian.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: controller.refreshPrayerData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = controller.nearbyMosqueMapUrl();
                      if (url == null) return;
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Masjid berdekatan'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Jadual',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...prayers.map(
                (item) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(item.name),
                    trailing: Text(DateFormat('HH:mm').format(item.time)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  PrayerTimeEntry? _currentPrayer(List<PrayerTimeEntry> entries, DateTime now) {
    if (entries.isEmpty) {
      return null;
    }
    PrayerTimeEntry? current;
    for (final entry in entries) {
      if (entry.time.isBefore(now) || entry.time.isAtSameMomentAs(now)) {
        current = entry;
      }
    }
    return current;
  }

  List<Color> _themeForPrayer(String? prayerName) {
    switch (prayerName) {
      case 'Subuh':
        return const [Color(0xFF3A6EA5), Color(0xFF274B74)];
      case 'Zohor':
        return const [Color(0xFF5E6C84), Color(0xFF36445A)];
      case 'Asar':
        return const [Color(0xFF4A7A6A), Color(0xFF2E5A4D)];
      case 'Maghrib':
        return const [Color(0xFFB15E3E), Color(0xFF7D3D24)];
      case 'Isyak':
        return const [Color(0xFF24566B), Color(0xFF123848)];
      default:
        return const [Color(0xFF0D8C7B), Color(0xFF0A6A60)];
    }
  }

  String _formatCountdown(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return '00:00';
    }

    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
