import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'hijri_offset_setting.dart';
import 'settings_components.dart';
import 'settings_styles.dart';

class PrayerTimesSettingsPage extends StatelessWidget {
  const PrayerTimesSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final locationLabel = controller.activeZone?.location ?? 'Kuala Lumpur';
    final zoneSummary =
        controller.autoLocation && !controller.locationPermissionDenied
            ? tr('Auto ($locationLabel)', 'Auto ($locationLabel)')
            : '${controller.manualZoneCode} $locationLabel';

    return SettingsSubpageScaffold(
      title: tr('Waktu Solat', 'Prayer Times'),
      child: SettingsSection(
        children: [
          if (controller.locationPermissionDenied)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InfoBanner(text: controller.t('permission_location_body')),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openZonePicker(context),
                    icon: const Icon(Icons.pin_drop_outlined),
                    label: Text(controller.t('permission_manual_zone_cta')),
                  ),
                ],
              ),
            ),
          SettingsToggleTile(
            icon: Icons.sync_alt_outlined,
            iconColor: const Color(0xFF5CA9FF),
            title: tr(
              'Auto-kemas kini ketika bermusafir',
              'Auto-update while traveling',
            ),
            subtitle: tr(
              'Kemas kini waktu solat dan qiblat secara automatik',
              'Automatically update prayer times and qibla',
            ),
            value: controller.travelModeEnabled,
            onChanged: controller.setTravelModeEnabled,
          ),
          SettingsToggleTile(
            icon: Icons.my_location_outlined,
            iconColor: const Color(0xFF5CA9FF),
            title: tr(
              'Kesan lokasi secara automatik',
              'Detect location automatically',
            ),
            subtitle: tr(
              'Matikan untuk pilih zon secara manual',
              'Turn off to pick zone manually',
            ),
            value: controller.autoLocation,
            onChanged: controller.setAutoLocation,
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.pin_drop_outlined,
              color: Color(0xFF5CA9FF),
            ),
            title: Text(tr('Zon', 'Zone')),
            subtitle: Text(
              controller.autoLocation && !controller.locationPermissionDenied
                  ? tr('Auto ($locationLabel)', 'Auto ($locationLabel)')
                  : zoneSummary,
            ),
          ),
          if (controller.requiresManualZonePicker)
            ListTile(
              leading: const LeadingIcon(
                icon: Icons.search,
                color: Color(0xFF5CA9FF),
              ),
              title: Text(tr('Tukar zon', 'Change zone')),
              subtitle: Text(
                tr('Cari dan pilih zon manual',
                    'Search and choose manual zone'),
              ),
              onTap: () => _openZonePicker(context),
            ),
          if (controller.requiresManualZonePicker)
            ZoneQuickChips(controller: controller),
          HijriOffsetSetting(controller: controller),
          SettingsNavTile(
            icon: Icons.calculate_outlined,
            iconColor: const Color(0xFF5CA9FF),
            title: tr('Kiraan Solat', 'Prayer calculation'),
            subtitle:
                '${controller.prayerCalculationMethod} | ${controller.asarMethod}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PrayerCalculationSettingsPage(
                  controller: controller,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openZonePicker(BuildContext context) async {
    final tr = controller.tr;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: settingsSurface,
      showDragHandle: true,
      builder: (context) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final zones = controller.zones
                .where(
                  (z) =>
                      z.label.toLowerCase().contains(query.toLowerCase()) ||
                      z.code.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            final recentCodes = controller.recentZones.take(8).toList();
            final recents = recentCodes
                .map((c) => controller.zones.where((z) => z.code == c).toList())
                .expand((x) => x)
                .toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: tr('Cari zon', 'Search zone'),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => query = value),
                    ),
                    const SizedBox(height: 8),
                    if (controller.zones.isEmpty)
                      SizedBox(
                        height: 120,
                        child: Center(
                          child:
                              Text(tr('Memuatkan zon...', 'Loading zones...')),
                        ),
                      )
                    else if (zones.isEmpty)
                      SizedBox(
                        height: 120,
                        child: Center(
                          child:
                              Text(tr('Tiada zon ditemui', 'No zones found')),
                        ),
                      )
                    else ...[
                      if (query.isEmpty && recents.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            tr('Terkini', 'Recent'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: settingsTextMuted),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: recents.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final zone = recents[index];
                              return ActionChip(
                                label: Text(zone.code),
                                onPressed: () =>
                                    Navigator.pop(context, zone.code),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        height: 360,
                        child: ListView.separated(
                          itemCount: zones.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final zone = zones[index];
                            final isActive =
                                zone.code == controller.manualZoneCode;
                            final isFav = controller.isZoneFavorite(zone.code);
                            return ListTile(
                              tileColor: settingsSurfaceAlt,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(zone.label),
                              subtitle: Text(zone.code),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFav ? Icons.star : Icons.star_outline,
                                      color: const Color(0xFFF4C542),
                                    ),
                                    onPressed: () {
                                      controller.toggleFavoriteZone(zone.code);
                                      setState(() {});
                                    },
                                  ),
                                  if (isActive)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4BD6C7),
                                    ),
                                ],
                              ),
                              onTap: () => Navigator.pop(context, zone.code),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected != null) {
      await controller.setManualZone(selected);
    }
  }
}

class PrayerCalculationSettingsPage extends StatelessWidget {
  const PrayerCalculationSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    const calcMethods = <String>[
      'JAKIM',
      'MWL',
      'ISNA',
      'Umm al-Qura',
      'Egyptian',
      'Karachi',
    ];
    const asarMethods = <String>["Shafi'i", 'Hanafi'];
    const highLatRules = <String>[
      'Middle of the Night',
      'One Seventh',
      'Twilight Angle',
    ];

    return SettingsSubpageScaffold(
      title: tr('Kiraan Solat', 'Prayer calculation'),
      child: Column(
        children: [
          SettingsSection(
            children: [
              DropdownTile(
                icon: Icons.functions_outlined,
                iconColor: const Color(0xFF5CA9FF),
                title: tr('Kaedah kiraan', 'Calculation method'),
                value: controller.prayerCalculationMethod,
                options: calcMethods,
                onChanged: controller.setPrayerCalculationMethod,
              ),
              DropdownTile(
                icon: Icons.schedule_outlined,
                iconColor: const Color(0xFF5CA9FF),
                title: tr('Kaedah Asar', 'Asar method'),
                value: controller.asarMethod,
                options: asarMethods,
                onChanged: controller.setAsarMethod,
              ),
              DropdownTile(
                icon: Icons.nightlight_outlined,
                iconColor: const Color(0xFF5CA9FF),
                title: tr('Peraturan latitud tinggi', 'High latitude rule'),
                value: controller.highLatitudeRule,
                options: highLatRules,
                onChanged: controller.setHighLatitudeRule,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SettingsSection(
            title: tr('Pelarasan Minit Manual', 'Manual minute adjustments'),
            children: controller.prayerNamesOrdered
                .map(
                  (name) => PrayerAdjustTile(
                    prayerName: controller.displayPrayerName(name),
                    value: controller.manualPrayerAdjustments[name] ?? 0,
                    onChanged: (value) =>
                        controller.setManualPrayerAdjustment(name, value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              tr(
                'Pelarasan minit mempengaruhi paparan waktu dan notifikasi. Jika method bukan JAKIM dipilih, waktu akan ikut kiraan tempatan.',
                'Minute adjustments affect displayed times and notifications. When method is not JAKIM, local calculation is used.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: settingsTextMuted,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SettingsSection(
            children: [
              ListTile(
                leading: const LeadingIcon(
                  icon: Icons.restart_alt_rounded,
                  color: Color(0xFFE08EA6),
                ),
                title: Text(controller.t('prayer_calc_reset_all')),
                subtitle: Text(tr(
                  'Pulihkan semua waktu ke 0 minit',
                  'Restore all prayers to 0 minutes',
                )),
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title:
                          Text(controller.t('prayer_calc_reset_confirm_title')),
                      content:
                          Text(controller.t('prayer_calc_reset_confirm_body')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(tr('Batal', 'Cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(tr('Reset', 'Reset')),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await controller.resetAllManualPrayerAdjustments();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
