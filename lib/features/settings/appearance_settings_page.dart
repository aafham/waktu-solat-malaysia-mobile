import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return SettingsSubpageScaffold(
      title: tr('Paparan', 'Appearance'),
      child: SettingsSection(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              tr('Saiz teks', 'Text size'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<double>(
                segments: const [
                  ButtonSegment<double>(value: 0.9, label: Text('S')),
                  ButtonSegment<double>(value: 1.0, label: Text('M')),
                  ButtonSegment<double>(value: 1.2, label: Text('L')),
                  ButtonSegment<double>(value: 1.4, label: Text('XL')),
                ],
                selected: <double>{_closestTextScale(controller.textScale)},
                onSelectionChanged: (selection) =>
                    controller.setTextScale(selection.first),
              ),
            ),
          ),
          SettingsToggleTile(
            icon: Icons.contrast_outlined,
            iconColor: const Color(0xFFE76EA4),
            title: tr('Kontras tinggi', 'High contrast'),
            subtitle: tr('Tingkatkan keterbacaan', 'Improve readability'),
            value: controller.highContrast,
            onChanged: controller.setHighContrast,
          ),
        ],
      ),
    );
  }

  double _closestTextScale(double value) {
    const options = <double>[0.9, 1.0, 1.2, 1.4];
    var best = options.first;
    var diff = (value - best).abs();
    for (final option in options.skip(1)) {
      final d = (value - option).abs();
      if (d < diff) {
        diff = d;
        best = option;
      }
    }
    return best;
  }
}
