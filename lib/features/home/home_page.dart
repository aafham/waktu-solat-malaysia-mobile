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
    final prayers = controller.dailyPrayerTimes?.entries ?? [];
    final nextPrayer = controller.nextPrayer;
    final countdown = controller.timeToNextPrayer;
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
              'API berjaya: ${controller.apiSuccessCount}  •  Gagal: ${controller.apiFailureCount}  •  Cache: ${controller.cacheHitCount}',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nextPrayer == null ? 'Tiada waktu seterusnya hari ini' : 'Seterusnya: ${nextPrayer.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nextPrayer == null
                            ? '-'
                            : '${DateFormat('HH:mm').format(nextPrayer.time)} (${_formatCountdown(countdown)})',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(5),
                            child: const Text('Snooze 5 min'),
                          ),
                          OutlinedButton(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(10),
                            child: const Text('Snooze 10 min'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (maghrib != null || imsak != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (maghrib != null)
                              Chip(
                                label: Text(
                                  'Berbuka ${DateFormat('HH:mm').format(maghrib.time)}',
                                ),
                              ),
                            if (imsak != null)
                              Chip(
                                label: Text(
                                  'Imsak ${DateFormat('HH:mm').format(imsak.time)}',
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (controller.ramadhanMode)
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = controller.nearbyMosqueMapUrl();
                      if (url == null) return;
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Masjid berdekatan'),
                  ),
                  if (!controller.exactAlarmAllowed)
                    Chip(
                      avatar: const Icon(Icons.warning_amber, size: 16),
                      label: const Text('Exact alarm mungkin diblok'),
                    ),
                ],
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

  String _formatCountdown(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return '00:00';
    }

    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
