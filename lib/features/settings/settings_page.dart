import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final zones = controller.zones;

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
            onChanged: controller.notifyEnabled ? controller.setVibrateEnabled : null,
          ),
          SwitchListTile(
            title: const Text('Auto detect lokasi'),
            value: controller.autoLocation,
            onChanged: controller.setAutoLocation,
          ),
          const SizedBox(height: 8),
          if (!controller.autoLocation)
            DropdownButtonFormField<String>(
              value: zones.any((z) => z.code == controller.manualZoneCode)
                  ? controller.manualZoneCode
                  : null,
              items: zones
                  .map(
                    (zone) => DropdownMenuItem<String>(
                      value: zone.code,
                      child: Text(zone.label),
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
}
