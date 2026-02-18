import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';

class HijriOffsetSetting extends StatelessWidget {
  const HijriOffsetSetting({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Column(
          children: [
            ListTile(
              leading: const LeadingIcon(
                icon: Icons.calendar_month_outlined,
                color: Color(0xFFF2CB54),
              ),
              title: Text(controller.t('hijri_offset')),
              subtitle: Text(controller.t('hijri_offset_helper')),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: -2, label: Text('-2')),
                    ButtonSegment<int>(value: -1, label: Text('-1')),
                    ButtonSegment<int>(value: 0, label: Text('0')),
                    ButtonSegment<int>(value: 1, label: Text('+1')),
                    ButtonSegment<int>(value: 2, label: Text('+2')),
                  ],
                  selected: <int>{controller.hijriOffsetDays},
                  onSelectionChanged: (value) =>
                      controller.setHijriOffsetDays(value.first),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  controller.todayHijriPreviewLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFB9CAE2),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
