import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';
import 'settings_styles.dart';

class TasbihSettingsPage extends StatelessWidget {
  const TasbihSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final selectedTarget = _selectedTarget(controller.tasbihCycleTarget);

    return SettingsSubpageScaffold(
      title: tr('Tetapan Tasbih', 'Tasbih settings'),
      child: SettingsSection(
        children: [
          SettingsToggleTile(
            icon: Icons.refresh_outlined,
            iconColor: const Color(0xFFA98EFF),
            title: tr('Auto reset harian', 'Auto reset daily'),
            subtitle: tr(
              'Reset kiraan ke 0 setiap hari baharu',
              'Reset count to 0 every new day',
            ),
            value: controller.tasbihAutoResetDaily,
            onChanged: controller.setTasbihAutoResetDaily,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Text(
              tr('Sasaran pusingan', 'Cycle target'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: [
                  const ButtonSegment<int>(value: 33, label: Text('33')),
                  const ButtonSegment<int>(value: 99, label: Text('99')),
                  const ButtonSegment<int>(value: 100, label: Text('100')),
                  ButtonSegment<int>(
                    value: -1,
                    label: Text(tr('Custom', 'Custom')),
                  ),
                ],
                selected: <int>{selectedTarget},
                onSelectionChanged: (selection) async {
                  final value = selection.first;
                  if (value == -1) {
                    final custom = await _pickCustomTarget(context);
                    if (custom != null) {
                      await controller.setTasbihCycleTarget(custom);
                    }
                    return;
                  }
                  controller.setTasbihCycleTarget(value);
                },
              ),
            ),
          ),
          if (selectedTarget == -1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  tr(
                    'Custom semasa: ${controller.tasbihCycleTarget}',
                    'Current custom: ${controller.tasbihCycleTarget}',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: settingsTextMuted,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.analytics_outlined,
              color: Color(0xFFA98EFF),
            ),
            title: Text(tr('Statistik ringkas', 'Quick stats')),
            subtitle: Text(
              tr(
                'Hari ini ${controller.tasbihTodayCount} | 7 hari ${controller.tasbihWeekCount} | streak ${controller.tasbihStreakDays} | terbaik ${controller.tasbihBestDay}',
                'Today ${controller.tasbihTodayCount} | 7 days ${controller.tasbihWeekCount} | streak ${controller.tasbihStreakDays} | best ${controller.tasbihBestDay}',
              ),
            ),
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.restart_alt,
              color: Color(0xFFE08EA6),
            ),
            title: Text(tr('Reset kiraan', 'Reset count')),
            subtitle: Text(
              tr(
                'Kiraan semasa akan dikosongkan',
                'Current count will be cleared',
              ),
            ),
            enabled: controller.tasbihCount > 0,
            onTap: controller.tasbihCount == 0
                ? null
                : () => _confirmReset(context),
          ),
        ],
      ),
    );
  }

  int _selectedTarget(int value) {
    if (value == 33 || value == 99 || value == 100) {
      return value;
    }
    return -1;
  }

  Future<int?> _pickCustomTarget(BuildContext context) async {
    final c = TextEditingController(text: '${controller.tasbihCycleTarget}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(controller.tr('Sasaran custom', 'Custom target')),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: controller.tr('Masukkan nombor', 'Enter number'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(controller.tr('Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(c.text.trim());
              if (value == null || value <= 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, value);
            },
            child: Text(controller.tr('Simpan', 'Save')),
          ),
        ],
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _confirmReset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(controller.tr('Reset kiraan zikir?', 'Reset tasbih count?')),
        content: Text(
          controller.tr('Kiraan akan kembali ke 0.', 'Count will return to 0.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(controller.tr('Batal', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(controller.tr('Reset', 'Reset')),
          ),
        ],
      ),
    );
    if (ok == true) {
      await controller.resetTasbih();
    }
  }
}
