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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            'Tetapan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tetapan ringkas untuk Waktu Solat, Qiblat dan Zikir.',
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Notifikasi Waktu Solat',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Hidupkan notifikasi'),
                  subtitle: const Text('Peringatan bila masuk waktu solat'),
                  value: controller.notifyEnabled,
                  onChanged: controller.setNotifyEnabled,
                ),
                SwitchListTile(
                  title: const Text('Getaran'),
                  subtitle: const Text('Telefon bergetar semasa notifikasi'),
                  value: controller.vibrateEnabled,
                  onChanged: controller.notifyEnabled
                      ? controller.setVibrateEnabled
                      : null,
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: controller.notifyEnabled
                        ? () {
                            final prayer = controller.nextPrayer?.name ?? 'Subuh';
                            controller.previewPrayerSound(prayer);
                          }
                        : null,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Uji bunyi notifikasi'),
                  ),
                ),
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Pilihan ikut waktu (lanjutan)'),
                  subtitle: const Text('Boleh dibiar default jika tidak pasti'),
                  children: [
                    ...controller.prayerNotificationToggles.entries.map(
                      (entry) => SwitchListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: controller.notifyEnabled
                            ? (value) =>
                                controller.setPrayerNotifyEnabled(entry.key, value)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Lokasi & Zon',
            icon: Icons.place_outlined,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Kesan lokasi automatik'),
                  subtitle: const Text('Disyorkan untuk kebanyakan pengguna'),
                  value: controller.autoLocation,
                  onChanged: controller.setAutoLocation,
                ),
                if (!controller.autoLocation) ...[
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Cari zon',
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
                    decoration: const InputDecoration(
                      labelText: 'Pilih zon manual',
                    ),
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
                if (zones.isEmpty)
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Data zon belum siap dimuatkan. Sila cuba semula.'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Paparan Mesra Mata',
            icon: Icons.text_fields,
            child: Column(
              children: [
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment<double>(value: 0.9, label: Text('Kecil')),
                    ButtonSegment<double>(value: 1.0, label: Text('Biasa')),
                    ButtonSegment<double>(value: 1.2, label: Text('Besar')),
                    ButtonSegment<double>(value: 1.4, label: Text('Sangat Besar')),
                  ],
                  selected: <double>{_closestTextScale(controller.textScale)},
                  onSelectionChanged: (selection) {
                    controller.setTextScale(selection.first);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Kontras tinggi'),
                  subtitle: const Text('Mudah dibaca untuk semua peringkat umur'),
                  value: controller.highContrast,
                  onChanged: controller.setHighContrast,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: 'Zikir',
            icon: Icons.touch_app,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.countertops),
                  title: const Text('Kiraan semasa'),
                  subtitle: Text('${controller.tasbihCount}'),
                ),
                OutlinedButton.icon(
                  onPressed: controller.tasbihCount == 0
                      ? null
                      : () => _confirmResetTasbih(controller),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Tetapkan semula kiraan zikir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Tip mesra pengguna: jika anda kurang pasti, kekalkan tetapan default. Hanya ubah Lokasi dan Saiz Teks bila perlu.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
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
          title: const Text('Tetapkan semula kiraan zikir?'),
          content: const Text('Kiraan akan kembali ke 0.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, semula'),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
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
