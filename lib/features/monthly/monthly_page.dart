import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../state/app_controller.dart';

class MonthlyPage extends StatelessWidget {
  const MonthlyPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final monthly = controller.monthlyPrayerTimes;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshMonthlyData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Jadual Bulanan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final csv = controller.exportMonthlyAsCsv();
                    if (csv.isEmpty) return;
                    await SharePlus.instance.share(
                      ShareParams(
                        text: csv,
                        subject: 'Jadual Waktu Solat Bulanan',
                      ),
                    );
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Share CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final csv = controller.exportMonthlyAsCsv();
                    if (csv.isEmpty) return;
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV disalin ke clipboard')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy CSV'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              controller.activeZone?.label ?? 'Zon belum ditentukan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (controller.isMonthlyLoading)
              const Center(child: CircularProgressIndicator())
            else if (monthly == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Jadual bulanan belum tersedia. Tarik untuk refresh.'),
                ),
              )
            else ...[
              Text(
                DateFormat('MMMM yyyy').format(monthly.month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ...monthly.days.map((day) {
                final subuh = day.entries.firstWhere((e) => e.name == 'Subuh');
                final maghrib = day.entries.firstWhere((e) => e.name == 'Maghrib');
                return Card(
                  child: ListTile(
                    title: Text(DateFormat('EEE, dd MMM').format(day.date)),
                    subtitle: Text('Subuh ${DateFormat('HH:mm').format(subuh.time)}'),
                    trailing: Text('Maghrib ${DateFormat('HH:mm').format(maghrib.time)}'),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
