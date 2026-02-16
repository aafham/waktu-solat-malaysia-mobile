import 'package:flutter/material.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final zones = controller.zones;
    final filteredZones = zones
        .where((z) => z.label.toLowerCase().contains(_searchTerm.toLowerCase()))
        .toList();
    final locationLabel = controller.activeZone?.location ?? 'Kuala Lumpur';

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1A38), Color(0xFF07142E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(
              'settings',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'set your intentions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB8C4D9),
                  ),
            ),
            const SizedBox(height: 14),
            _SettingCard(
              icon: Icons.place,
              iconColor: const Color(0xFF4EA4FF),
              title: 'prayer times',
              subtitle: locationLabel,
              trailing: controller.autoLocation
                  ? const Text('auto')
                  : Text(controller.manualZoneCode),
              child: Column(
                children: [
                  _SwitchRow(
                    title: 'auto-update when traveling',
                    subtitle: 'automatically update prayer times and qibla',
                    value: controller.travelModeEnabled,
                    onChanged: controller.setTravelModeEnabled,
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    title: 'detect location automatically',
                    subtitle: 'turn off to pick zone manually',
                    value: controller.autoLocation,
                    onChanged: controller.setAutoLocation,
                  ),
                  if (!controller.autoLocation) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'search zone',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchTerm = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue:
                          zones.any((z) => z.code == controller.manualZoneCode)
                              ? controller.manualZoneCode
                              : null,
                      items: filteredZones
                          .map(
                            (zone) => DropdownMenuItem<String>(
                              value: zone.code,
                              child: Text(zone.label),
                            ),
                          )
                          .toList(),
                      decoration: const InputDecoration(labelText: 'manual zone'),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setManualZone(value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _FavoriteZoneChips(
                      controller: controller,
                      zones: zones,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.notifications_active,
              iconColor: const Color(0xFFFF9A3E),
              title: 'notifications',
              subtitle: controller.notifyEnabled ? 'enabled' : 'disabled',
              child: Column(
                children: [
                  _SwitchRow(
                    title: 'enable notifications',
                    subtitle: 'azan and reminder alerts',
                    value: controller.notifyEnabled,
                    onChanged: controller.setNotifyEnabled,
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    title: 'vibrate',
                    subtitle: 'vibrate when notification arrives',
                    value: controller.vibrateEnabled,
                    onChanged: controller.notifyEnabled
                        ? controller.setVibrateEnabled
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: controller.notifyEnabled
                          ? () {
                              final prayer =
                                  controller.nextPrayer?.name ?? 'Subuh';
                              controller.previewPrayerSound(prayer);
                            }
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('test sound'),
                    ),
                  ),
                  const Divider(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'enable for prayers',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: controller.prayerNotificationToggles.entries
                        .map(
                          (entry) => FilterChip(
                            label: Text(entry.key),
                            selected: entry.value,
                            onSelected: controller.notifyEnabled
                                ? (value) => controller.setPrayerNotifyEnabled(
                                      entry.key,
                                      value,
                                    )
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.palette,
              iconColor: const Color(0xFFE75A93),
              title: 'appearance',
              subtitle: controller.highContrast ? 'high contrast' : 'standard',
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'text size',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment<double>(value: 0.9, label: Text('S')),
                      ButtonSegment<double>(value: 1.0, label: Text('M')),
                      ButtonSegment<double>(value: 1.2, label: Text('L')),
                      ButtonSegment<double>(value: 1.4, label: Text('XL')),
                    ],
                    selected: <double>{_closestTextScale(controller.textScale)},
                    onSelectionChanged: (selection) {
                      controller.setTextScale(selection.first);
                    },
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    title: 'high contrast',
                    subtitle: 'improve readability',
                    value: controller.highContrast,
                    onChanged: controller.setHighContrast,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.nights_stay,
              iconColor: const Color(0xFFF4C542),
              title: 'fasting reminders',
              subtitle: 'ramadhan and sunnah',
              child: Column(
                children: [
                  _SwitchRow(
                    title: 'ramadhan mode',
                    subtitle: 'supportive reminders for fasting days',
                    value: controller.ramadhanMode,
                    onChanged: controller.setRamadhanMode,
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    title: 'monday & thursday',
                    subtitle: 'schedule fasting reminders',
                    value: controller.fastingMondayThursdayEnabled,
                    onChanged: controller.setFastingMondayThursdayEnabled,
                  ),
                  const Divider(height: 20),
                  _SwitchRow(
                    title: 'ayyamul bidh',
                    subtitle: '13, 14, 15 every hijri month',
                    value: controller.fastingAyyamulBidhEnabled,
                    onChanged: controller.setFastingAyyamulBidhEnabled,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.touch_app,
              iconColor: const Color(0xFF9B77FF),
              title: 'zikir',
              subtitle: 'today ${controller.tasbihTodayCount} | total ${controller.tasbihCount}',
              child: Column(
                children: [
                  Row(
                    children: [
                      _DataPill(label: '7 hari', value: '${controller.tasbihWeekCount}'),
                      const SizedBox(width: 8),
                      _DataPill(label: 'streak', value: '${controller.tasbihStreakDays}'),
                      const SizedBox(width: 8),
                      _DataPill(label: 'terbaik', value: '${controller.tasbihBestDay}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: controller.tasbihCount == 0
                          ? null
                          : () => _confirmResetTasbih(controller),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('reset count'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _SettingCard(
              icon: Icons.info_outline,
              iconColor: const Color(0xFF49C5F6),
              title: 'about',
              subtitle: 'JagaSolat',
              child: Text(
                'data source: JAKIM e-Solat + Malaysia Waktu Solat API\n${controller.prayerDataFreshnessLabel}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFC8D3E8),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _closestTextScale(double value) {
    const options = <double>[0.9, 1.0, 1.2, 1.4];
    var best = options.first;
    var bestDiff = (value - best).abs();
    for (final option in options.skip(1)) {
      final diff = (value - option).abs();
      if (diff < bestDiff) {
        best = option;
        bestDiff = diff;
      }
    }
    return best;
  }

  Future<void> _confirmResetTasbih(AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset zikir count?'),
          content: const Text('Kiraan akan kembali ke 0.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await controller.resetTasbih();
    }
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2F3750),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFAEBBD3),
                            ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFAEBBD3),
                    ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DataPill extends StatelessWidget {
  const _DataPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF3B445D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4D5772)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFAEBBD3),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteZoneChips extends StatelessWidget {
  const _FavoriteZoneChips({
    required this.controller,
    required this.zones,
  });

  final AppController controller;
  final List<PrayerZone> zones;

  @override
  Widget build(BuildContext context) {
    PrayerZone? byCode(String code) {
      for (final zone in zones) {
        if (zone.code == code) {
          return zone;
        }
      }
      return null;
    }

    final shortcuts = <PrayerZone>[
      ...controller.favoriteZones.map(byCode).whereType<PrayerZone>(),
      ...controller.recentZones
          .map(byCode)
          .whereType<PrayerZone>()
          .where((zone) => !controller.favoriteZones.contains(zone.code)),
    ];

    if (shortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shortcuts
          .map(
            (zone) => ActionChip(
              label: Text(zone.code),
              avatar: Icon(
                controller.isZoneFavorite(zone.code)
                    ? Icons.star
                    : Icons.history,
                size: 16,
              ),
              onPressed: () => controller.setManualZone(zone.code),
            ),
          )
          .toList(),
    );
  }
}
