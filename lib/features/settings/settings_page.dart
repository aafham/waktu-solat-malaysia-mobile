import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
          Text('Tetapan', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Urus notifikasi, lokasi, paparan dan sandaran data.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Aktifkan notifikasi waktu solat'),
                  value: controller.notifyEnabled,
                  onChanged: controller.setNotifyEnabled,
                ),
                SwitchListTile(
                  title: const Text('Aktifkan getaran notifikasi'),
                  value: controller.vibrateEnabled,
                  onChanged: controller.notifyEnabled
                      ? controller.setVibrateEnabled
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Mod Ramadan'),
                  subtitle: const Text('Fokus paparan Imsak & Maghrib'),
                  value: controller.ramadhanMode,
                  onChanged: controller.setRamadhanMode,
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notifikasi ikut waktu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 6),
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
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bunyi notifikasi ikut waktu',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                const SizedBox(height: 6),
                ...controller.prayerNotificationToggles.keys.map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                controller.prayerSoundProfiles[name] ?? 'default',
                            decoration: InputDecoration(
                              labelText: 'Bunyi $name',
                              border: const OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'default',
                                child: Text('Biasa'),
                              ),
                              DropdownMenuItem(
                                value: 'silent',
                                child: Text('Senyap'),
                              ),
                            ],
                            onChanged: controller.notifyEnabled
                                ? (value) {
                                    if (value != null) {
                                      controller.setPrayerSoundProfile(name, value);
                                    }
                                  }
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Pratonton bunyi',
                          onPressed: controller.notifyEnabled
                              ? () => controller.previewPrayerSound(name)
                              : null,
                          icon: const Icon(Icons.play_arrow),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!controller.exactAlarmAllowed)
                  Card(
                    color: Colors.orange.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Penggera tepat mungkin disekat. Semak Tetapan telefon > Penggera & peringatan.',
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Peringatan puasa sunat',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Isnin & Khamis'),
                  subtitle: const Text('Peringatan malam dan hampir Imsak'),
                  value: controller.fastingMondayThursdayEnabled,
                  onChanged: controller.notifyEnabled
                      ? controller.setFastingMondayThursdayEnabled
                      : null,
                ),
                SwitchListTile(
                  title: const Text('Ayyamul Bidh (13-15 Hijrah)'),
                  subtitle: const Text('Peringatan puasa bulanan hijrah'),
                  value: controller.fastingAyyamulBidhEnabled,
                  onChanged: controller.notifyEnabled
                      ? controller.setFastingAyyamulBidhEnabled
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.place_outlined,
            title: 'Lokasi',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Kesan lokasi automatik'),
                  value: controller.autoLocation,
                  onChanged: controller.setAutoLocation,
                ),
                SwitchListTile(
                  title: const Text('Travel mode (auto tukar zon)'),
                  subtitle: const Text('Semak lokasi berkala bila anda bergerak'),
                  value: controller.travelModeEnabled,
                  onChanged: controller.autoLocation
                      ? controller.setTravelModeEnabled
                      : null,
                ),
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
                            tooltip: 'Kegemaran',
                            onPressed: () =>
                                controller.toggleFavoriteZone(zone.code),
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.palette_outlined,
            title: 'Paparan',
            child: Column(
              children: [
                ListTile(
                  title: const Text('Saiz teks'),
                  subtitle: Slider(
                    value: controller.textScale,
                    min: 0.9,
                    max: 1.4,
                    divisions: 5,
                    label: controller.textScale.toStringAsFixed(2),
                    onChanged: (value) => controller.setTextScale(value),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Mod kontras tinggi'),
                  value: controller.highContrast,
                  onChanged: controller.setHighContrast,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            icon: Icons.storage_outlined,
            title: 'Data & Sandaran',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: controller.refreshPrayerData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat semula data sekarang'),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final jsonText = controller.exportSettingsJson();
                        await Clipboard.setData(ClipboardData(text: jsonText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sandaran JSON disalin ke papan klip'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Sandaran'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showImportDialog(context, controller),
                      icon: const Icon(Icons.upload),
                      label: const Text('Pulih'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ExpansionTile(
                  title: const Text('Log kesihatan (setempat)'),
                  subtitle: const Text('Ringkas untuk semak kestabilan aplikasi'),
                  children: controller.healthLogs
                      .take(20)
                      .map(
                        (line) => ListTile(
                          dense: true,
                          title: Text(
                            line,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Nota: Untuk azan kustom, letak fail audio di android/app/src/main/res/raw dan konfigurasi saluran bunyi Android.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(
    BuildContext context,
    AppController controller,
  ) async {
    final input = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pulihkan Tetapan JSON'),
          content: TextField(
            controller: input,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Tampal JSON sandaran di sini',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await controller.importSettingsJson(input.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tetapan berjaya dipulihkan')),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Format JSON tidak sah')),
                    );
                  }
                }
              },
              child: const Text('Pulihkan'),
            ),
          ],
        );
      },
    );
    input.dispose();
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
  }
}
