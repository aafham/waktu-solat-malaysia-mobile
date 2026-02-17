import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_controller.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final rows = controller.prayerHistory7Days;
    final locale = controller.isEnglish ? 'en_US' : 'ms_MY';
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.t('history_title')),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rows.isEmpty ? 1 : rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (rows.isEmpty) {
            return ListTile(
              title: Text(controller.t('history_empty')),
            );
          }
          final row = rows[index];
          final date = row['date'] as DateTime;
          final done = row['done'] as int;
          final target = row['target'] as int;
          final progress = target == 0 ? 0.0 : (done / target).clamp(0.0, 1.0);
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              title: Text(DateFormat('EEE, d MMM', locale).format(date)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  controller.t(
                    'history_day_done',
                    params: <String, String>{
                      'done': '$done',
                      'target': '$target',
                    },
                  ),
                ),
              ),
              trailing: SizedBox(
                width: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
