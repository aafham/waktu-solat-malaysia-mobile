import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';
import 'settings_styles.dart';

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final prayerNames = controller.prayerNamesOrdered;
    final toggles = controller.prayerNotificationToggles;
    final lead = _closestLead(controller.notificationLeadMinutes);

    return SettingsSubpageScaffold(
      title: tr('Notifikasi', 'Notifications'),
      child: SettingsSection(
        children: [
          SettingsToggleTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFFFFA450),
            title: tr('Aktifkan notifikasi', 'Enable notifications'),
            subtitle:
                tr('Amaran azan dan peringatan', 'Azan and reminder alerts'),
            value: controller.notifyEnabled,
            onChanged: controller.setNotifyEnabled,
          ),
          SettingsToggleTile(
            icon: Icons.vibration_outlined,
            iconColor: const Color(0xFF80D7C8),
            title: tr('Getaran', 'Vibrate'),
            subtitle: tr(
              'Getar semasa notifikasi masuk',
              'Vibrate when notification arrives',
            ),
            value: controller.vibrateEnabled,
            onChanged:
                controller.notifyEnabled ? controller.setVibrateEnabled : null,
          ),
          SettingsToggleTile(
            icon: Icons.volume_mute_outlined,
            iconColor: const Color(0xFF80D7C8),
            title: tr('Hormat mod senyap', 'Respect silent mode'),
            subtitle: tr(
              'Guna tingkah laku notifikasi standard',
              'Use standard notification audio behavior',
            ),
            value: controller.respectSilentMode,
            onChanged: controller.notifyEnabled
                ? controller.setRespectSilentMode
                : null,
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.music_note_outlined,
              color: Color(0xFFF4C542),
            ),
            title: Text(tr('Bunyi Azan', 'Azan sound')),
            subtitle: Text(
              _soundProfileLabel(controller, controller.globalAzanSoundProfile),
            ),
            enabled: controller.notifyEnabled,
            onTap: controller.notifyEnabled
                ? () => _openSoundPicker(context)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Text(
              tr('Bunyi mengikut waktu', 'Per-prayer sound'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...prayerNames.map(
            (name) => ListTile(
              leading: const LeadingIcon(
                icon: Icons.audiotrack_outlined,
                color: Color(0xFFF4C542),
              ),
              title: Text(controller.displayPrayerName(name)),
              subtitle: Text(
                _soundProfileLabel(
                  controller,
                  controller.prayerSoundProfiles[name] ?? 'default',
                ),
              ),
              enabled: controller.notifyEnabled,
              onTap: controller.notifyEnabled
                  ? () => _openPerPrayerSoundPicker(context, name)
                  : null,
            ),
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.play_arrow_rounded,
              color: Color(0xFFF4C542),
            ),
            title: Text(tr('Uji bunyi', 'Test sound')),
            subtitle:
                Text(tr('Mainkan bunyi yang dipilih', 'Play selected sound')),
            enabled: controller.notifyEnabled,
            onTap: controller.notifyEnabled
                ? () {
                    final prayer = controller.nextPrayer?.name ?? 'Subuh';
                    controller.previewPrayerSound(prayer);
                  }
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              tr('Jeda awal notifikasi', 'Notification lead time'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text(tr('Tepat waktu', 'On time')),
                  ),
                  const ButtonSegment<int>(value: 5, label: Text('5 min')),
                  const ButtonSegment<int>(value: 10, label: Text('10 min')),
                  const ButtonSegment<int>(value: 15, label: Text('15 min')),
                ],
                selected: <int>{lead},
                onSelectionChanged: controller.notifyEnabled
                    ? (selection) =>
                        controller.setNotificationLeadMinutes(selection.first)
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Aktif untuk waktu', 'Enable for prayers'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: controller.notifyEnabled
                          ? () => controller.setAllPrayerNotifications(true)
                          : null,
                      child: Text(tr('Pilih semua', 'Select all')),
                    ),
                    TextButton(
                      onPressed: controller.notifyEnabled
                          ? () => controller.setAllPrayerNotifications(false)
                          : null,
                      child: Text(tr('Kosongkan', 'Clear')),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prayerNames
                  .where((name) => toggles.containsKey(name))
                  .map(
                    (name) => FilterChip(
                      label: Text(controller.displayPrayerName(name)),
                      selected: toggles[name] ?? false,
                      onSelected: controller.notifyEnabled
                          ? (v) => controller.setPrayerNotifyEnabled(name, v)
                          : null,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  int _closestLead(int value) {
    const options = <int>[0, 5, 10, 15];
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

  String _soundProfileLabel(AppController controller, String value) {
    switch (value) {
      case 'silent':
        return controller.tr('Senyap', 'Silent');
      default:
        return controller.tr('Asal aplikasi', 'App default');
    }
  }

  Future<void> _openSoundPicker(BuildContext context) async {
    final tr = controller.tr;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: settingsSurface,
      showDragHandle: true,
      builder: (context) {
        final future = Future<List<String>>.delayed(
          const Duration(milliseconds: 180),
          () => controller.availableSoundProfiles,
        );
        return FutureBuilder<List<String>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sounds = snapshot.data ?? const <String>[];
            if (sounds.isEmpty) {
              return SizedBox(
                height: 120,
                child: Center(
                  child:
                      Text(tr('Tiada bunyi tersedia', 'No sounds available')),
                ),
              );
            }
            return SafeArea(
              child: ListView(
                shrinkWrap: true,
                children: sounds
                    .map(
                      (profile) => ListTile(
                        title: Text(_soundProfileLabel(controller, profile)),
                        subtitle: Text(
                          profile == 'silent'
                              ? tr(
                                  'Notifikasi tanpa bunyi',
                                  'Notification without sound',
                                )
                              : tr(
                                  'Bunyi azan lalai aplikasi',
                                  'Default app azan sound',
                                ),
                        ),
                        trailing: controller.globalAzanSoundProfile == profile
                            ? const Icon(Icons.check_circle)
                            : null,
                        onTap: () => Navigator.pop(context, profile),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
    if (selected != null) {
      await controller.setAllPrayerSoundProfiles(selected);
    }
  }

  Future<void> _openPerPrayerSoundPicker(
    BuildContext context,
    String prayerName,
  ) async {
    final tr = controller.tr;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: settingsSurface,
      showDragHandle: true,
      builder: (context) {
        final sounds = controller.availableSoundProfiles;
        if (sounds.isEmpty) {
          return SizedBox(
            height: 120,
            child: Center(
              child: Text(tr('Tiada bunyi tersedia', 'No sounds available')),
            ),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: sounds
                .map(
                  (profile) => ListTile(
                    title: Text(_soundProfileLabel(controller, profile)),
                    subtitle: Text(prayerName),
                    trailing: (controller.prayerSoundProfiles[prayerName] ??
                                'default') ==
                            profile
                        ? const Icon(Icons.check_circle)
                        : null,
                    onTap: () => Navigator.pop(context, profile),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
    if (selected != null) {
      await controller.setPrayerSoundProfile(prayerName, selected);
    }
  }
}
