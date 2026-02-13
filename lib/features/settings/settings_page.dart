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

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Aktifkan notifikasi waktu solat'),
            value: controller.notifyEnabled,
            onChanged: controller.setNotifyEnabled,
          ),
          SwitchListTile(
            title: const Text('Aktifkan vibrate notifikasi'),
            value: controller.vibrateEnabled,
            onChanged:
                controller.notifyEnabled ? controller.setVibrateEnabled : null,
          ),
          SwitchListTile(
            title: const Text('Auto detect lokasi'),
            value: controller.autoLocation,
            onChanged: controller.setAutoLocation,
          ),
          const SizedBox(height: 8),
          _buildZoneShortcutChips(controller, zones),
          const SizedBox(height: 8),
          if (!controller.autoLocation) ...[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari zon',
                border: OutlineInputBorder(),
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
                      child: Row(
                        children: [
                          Expanded(child: Text(zone.label)),
                          Icon(
                            controller.isZoneFavorite(zone.code)
                                ? Icons.star
                                : Icons.star_border,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Pilih zon manual',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value != null) {
                  controller.setManualZone(value);
                }
              },
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: filteredZones.take(12).map((zone) {
                  return ListTile(
                    dense: true,
                    title: Text(zone.label),
                    trailing: IconButton(
                      tooltip: 'Favorite',
                      onPressed: () => controller.toggleFavoriteZone(zone.code),
                      icon: Icon(
                        controller.isZoneFavorite(zone.code)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                    onTap: () => controller.setManualZone(zone.code),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Notifikasi ikut waktu',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...controller.prayerNotificationToggles.entries.map(
            (entry) => SwitchListTile(
              title: Text(entry.key),
              value: entry.value,
              onChanged: controller.notifyEnabled
                  ? (value) => controller.setPrayerNotifyEnabled(entry.key, value)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saiz teks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: controller.textScale,
            min: 0.9,
            max: 1.4,
            divisions: 5,
            label: controller.textScale.toStringAsFixed(2),
            onChanged: (value) => controller.setTextScale(value),
          ),
          SwitchListTile(
            title: const Text('High contrast mode'),
            value: controller.highContrast,
            onChanged: controller.setHighContrast,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: controller.refreshPrayerData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh data sekarang'),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Nota: Untuk azan custom, letak fail audio di android/app/src/main/res/raw dan konfigurasi channel sound Android.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneShortcutChips(
    AppController controller,
    List<PrayerZone> zones,
  ) {
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
