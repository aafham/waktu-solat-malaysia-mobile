import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

enum MonthlyFilter { all, subuh, maghrib }
const _msLocale = 'ms_MY';

class MonthlyPage extends StatefulWidget {
  const MonthlyPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<MonthlyPage> createState() => _MonthlyPageState();
}

class _MonthlyPageState extends State<MonthlyPage> {
  MonthlyFilter filter = MonthlyFilter.all;

  @override
  Widget build(BuildContext context) {
    final monthly = widget.controller.monthlyPrayerTimes;
    final days = monthly?.days ?? <DailyPrayerTimes>[];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: widget.controller.refreshMonthlyData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              'Jadual Bulanan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final csv = widget.controller.exportMonthlyAsCsv();
                    if (csv.isEmpty) return;
                    await Share.share(
                      csv,
                      subject: 'Jadual Waktu Solat Bulanan',
                    );
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Kongsi CSV'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final csv = widget.controller.exportMonthlyAsCsv();
                    if (csv.isEmpty) return;
                    await Clipboard.setData(ClipboardData(text: csv));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV disalin ke papan klip')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Salin CSV'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.activeZone?.label ?? 'Zon belum ditentukan',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (widget.controller.isMonthlyLoading)
              const Center(child: CircularProgressIndicator())
            else if (monthly == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Jadual bulanan belum tersedia. Tarik untuk muat semula.'),
                ),
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('MMMM yyyy', _msLocale).format(monthly.month),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: SegmentedButton<MonthlyFilter>(
                        segments: const [
                          ButtonSegment(
                            value: MonthlyFilter.all,
                            label: Text('Semua'),
                          ),
                          ButtonSegment(
                            value: MonthlyFilter.subuh,
                            label: Text('Subuh'),
                          ),
                          ButtonSegment(
                            value: MonthlyFilter.maghrib,
                            label: Text('Maghrib'),
                          ),
                        ],
                        selected: <MonthlyFilter>{filter},
                        onSelectionChanged: (selection) {
                          setState(() {
                            filter = selection.first;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('Peta Haba Waktu', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _HeatMap(days: days, filter: filter),
              const SizedBox(height: 12),
              ...days.map((day) => _buildDayTile(context, day)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, DailyPrayerTimes day) {
    String pickSummary() {
      if (filter == MonthlyFilter.subuh) {
        final subuh = day.entries.firstWhere((e) => e.name == 'Subuh');
        return 'Subuh ${DateFormat('HH:mm', _msLocale).format(subuh.time)}';
      }
      if (filter == MonthlyFilter.maghrib) {
        final maghrib = day.entries.firstWhere((e) => e.name == 'Maghrib');
        return 'Maghrib ${DateFormat('HH:mm', _msLocale).format(maghrib.time)}';
      }
      final subuh = day.entries.firstWhere((e) => e.name == 'Subuh');
      final maghrib = day.entries.firstWhere((e) => e.name == 'Maghrib');
      return 'Subuh ${DateFormat('HH:mm', _msLocale).format(subuh.time)} | Maghrib ${DateFormat('HH:mm', _msLocale).format(maghrib.time)}';
    }

    return Card(
      child: ListTile(
        title: Text(DateFormat('EEE, dd MMM', _msLocale).format(day.date)),
        subtitle: Text(pickSummary()),
      ),
    );
  }
}

class _HeatMap extends StatelessWidget {
  const _HeatMap({required this.days, required this.filter});

  final List<DailyPrayerTimes> days;
  final MonthlyFilter filter;

  @override
  Widget build(BuildContext context) {
    final values = days.map((day) => _valueMinutes(day)).toList();
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final span = (max - min).abs();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(values.length, (idx) {
        final v = values[idx];
        final t = span == 0 ? 0.5 : (v - min) / span;
        final color = Color.lerp(
          const Color(0xFFDBEFEA),
          const Color(0xFF0D8C7B),
          t.clamp(0, 1),
        )!;

        return Tooltip(
          message:
              '${DateFormat('dd MMM', _msLocale).format(days[idx].date)} | ${_formatMinutes(v)}',
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  int _valueMinutes(DailyPrayerTimes day) {
    PrayerTimeEntry entry;
    if (filter == MonthlyFilter.subuh) {
      entry = day.entries.firstWhere((e) => e.name == 'Subuh');
    } else if (filter == MonthlyFilter.maghrib) {
      entry = day.entries.firstWhere((e) => e.name == 'Maghrib');
    } else {
      entry = day.entries.firstWhere((e) => e.name == 'Subuh');
    }
    return entry.time.hour * 60 + entry.time.minute;
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
