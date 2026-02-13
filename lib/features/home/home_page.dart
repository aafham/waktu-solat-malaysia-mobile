import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_controller.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final prayers = controller.dailyPrayerTimes?.entries ?? [];
    final nextPrayer = controller.nextPrayer;
    final countdown = controller.timeToNextPrayer;

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
            const SizedBox(height: 20),
            if (controller.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (controller.errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(controller.errorMessage!),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
