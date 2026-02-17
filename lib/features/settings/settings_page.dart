import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

const _bgTop = Color(0xFF071B38);
const _bgBottom = Color(0xFF06152D);
const _surface = Color(0xFF2E3854);
const _surfaceAlt = Color(0xFF394462);
const _textMuted = Color(0xFFB9C7DE);
const _radius = 16.0;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final q = _query.trim().toLowerCase();

    bool matches(List<String> keywords) {
      if (q.isEmpty) {
        return true;
      }
      return keywords.any((k) => k.toLowerCase().contains(q));
    }

    final languageSummary = controller.isEnglish ? 'English' : 'Bahasa Melayu';
    final appearanceSummary = tr(
      'Teks: ${_textScaleLabel(controller.textScale)} • Kontras: ${controller.highContrast ? 'Aktif' : 'Mati'}',
      'Text: ${_textScaleLabel(controller.textScale)} • Contrast: ${controller.highContrast ? 'On' : 'Off'}',
    );
    final prayerSummary = controller.autoLocation
        ? tr(
            'Auto • ${controller.activeZone?.location ?? 'Kuala Lumpur'}',
            'Auto • ${controller.activeZone?.location ?? 'Kuala Lumpur'}',
          )
        : tr(
            'Manual • ${controller.manualZoneCode}',
            'Manual • ${controller.manualZoneCode}',
          );
    final notificationSummary = controller.notifyEnabled
        ? tr(
            'Aktif • Awal ${_leadLabel(controller, controller.notificationLeadMinutes)}',
            'Enabled • Lead ${_leadLabel(controller, controller.notificationLeadMinutes)}',
          )
        : tr('Tidak aktif', 'Disabled');
    final fastingCount = <bool>[
      controller.ramadhanMode,
      controller.fastingMondayThursdayEnabled,
      controller.fastingAyyamulBidhEnabled,
    ].where((v) => v).length;
    final fastingSummary = fastingCount == 0
        ? tr('Tiada aktif', 'None active')
        : tr('$fastingCount aktif', '$fastingCount active');
    final tasbihSummary = tr(
      'Sasaran ${controller.tasbihCycleTarget} • Auto reset: ${controller.tasbihAutoResetDaily ? 'Aktif' : 'Mati'}',
      'Target ${controller.tasbihCycleTarget} • Auto reset: ${controller.tasbihAutoResetDaily ? 'On' : 'Off'}',
    );

    final showLanguage = matches(<String>[
      tr('Bahasa', 'Language'),
      languageSummary,
    ]);
    final showAppearance = matches(<String>[
      tr('Paparan', 'Appearance'),
      appearanceSummary,
    ]);
    final showPrayerTimes = matches(<String>[
      tr('Waktu Solat', 'Prayer Times'),
      prayerSummary,
      tr('Lokasi', 'Location'),
    ]);
    final showNotifications = matches(<String>[
      tr('Notifikasi', 'Notifications'),
      notificationSummary,
      tr('Getaran', 'Vibrate'),
    ]);
    final showFasting = matches(<String>[
      tr('Peringatan Puasa', 'Fasting reminders'),
      fastingSummary,
      'Ramadan',
      'Ayyamul Bidh',
    ]);
    final showTasbih = matches(<String>[
      tr('Tasbih', 'Tasbih'),
      tasbihSummary,
      tr('Zikir', 'Dhikr'),
    ]);
    final showAbout = matches(<String>[
      tr('Tentang', 'About'),
      'JagaSolat',
      controller.prayerDataFreshnessLabel,
    ]);

    final hasResult = showLanguage ||
        showAppearance ||
        showPrayerTimes ||
        showNotifications ||
        showFasting ||
        showTasbih ||
        showAbout;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
          children: [
            Text(
              tr('Tetapan', 'Settings'),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Sesuaikan aplikasi anda', 'Personalize your app'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _textMuted,
                  ),
            ),
            const SizedBox(height: 12),
            _SearchField(
              controller: _searchController,
              hint: tr('Cari tetapan', 'Search settings'),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
              onClear: _query.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _searchController.clear();
                        _query = '';
                      });
                    },
            ),
            if (!hasResult) ...[
              const SizedBox(height: 12),
              _EmptyState(
                text: tr(
                  'Tiada hasil. Cuba kata kunci lain.',
                  'No results. Try another keyword.',
                ),
              ),
            ],
            if (showLanguage || showAppearance) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Umum', 'General'),
                children: [
                  if (showLanguage) ...[
                    ListTile(
                      leading: const _LeadingIcon(
                        icon: Icons.language,
                        color: Color(0xFF50D7C9),
                      ),
                      title: Text(tr('Bahasa', 'Language')),
                      subtitle: Text(languageSummary),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'ms',
                                label: Text('BM'),
                              ),
                              ButtonSegment<String>(
                                value: 'en',
                                label: Text('EN'),
                              ),
                            ],
                            selected: <String>{controller.languageCode},
                            onSelectionChanged: (selection) {
                              controller.setLanguageCode(selection.first);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showAppearance)
                    SettingsNavTile(
                      icon: Icons.palette_outlined,
                      iconColor: const Color(0xFFE76EA4),
                      title: tr('Paparan', 'Appearance'),
                      subtitle: appearanceSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              AppearanceSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (showPrayerTimes || showNotifications || showFasting) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Solat', 'Prayer'),
                children: [
                  if (showPrayerTimes)
                    SettingsNavTile(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF5CA9FF),
                      title: tr('Waktu Solat', 'Prayer Times'),
                      subtitle: prayerSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              PrayerTimesSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                  if (showNotifications)
                    SettingsNavTile(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFFFA450),
                      title: tr('Notifikasi', 'Notifications'),
                      subtitle: notificationSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NotificationsSettingsPage(
                            controller: controller,
                          ),
                        ),
                      ),
                    ),
                  if (showFasting)
                    SettingsNavTile(
                      icon: Icons.nights_stay_outlined,
                      iconColor: const Color(0xFFF2CB54),
                      title: tr('Peringatan Puasa', 'Fasting reminders'),
                      subtitle: fastingSummary,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FastingSettingsPage(controller: controller),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (showTasbih) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Tasbih', 'Tasbih'),
                children: [
                  SettingsNavTile(
                    icon: Icons.touch_app_outlined,
                    iconColor: const Color(0xFFA98EFF),
                    title: tr('Tetapan Tasbih', 'Tasbih settings'),
                    subtitle: tasbihSummary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TasbihSettingsPage(controller: controller),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (showAbout) ...[
              const SizedBox(height: 12),
              SettingsSection(
                title: tr('Tentang', 'About'),
                children: [
                  SettingsNavTile(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF4EC7F7),
                    title: tr('Tentang aplikasi', 'About app'),
                    subtitle: 'JagaSolat',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AboutSettingsPage(controller: controller),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _textScaleLabel(double value) {
    if (value <= 0.95) {
      return 'S';
    }
    if (value <= 1.05) {
      return 'M';
    }
    if (value <= 1.25) {
      return 'L';
    }
    return 'XL';
  }

  String _leadLabel(AppController controller, int value) {
    if (value <= 0) {
      return controller.tr('Tepat waktu', 'On time');
    }
    return '$value min';
  }
}

class NotificationsSettingsPage extends StatelessWidget {
  const NotificationsSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final order = <String>[
      'Imsak',
      'Subuh',
      'Syuruk',
      'Zohor',
      'Asar',
      'Maghrib',
      'Isyak',
    ];
    final toggles = controller.prayerNotificationToggles;
    final lead = _closestLead(controller.notificationLeadMinutes);

    return _SettingsSubpageScaffold(
      title: tr('Notifikasi', 'Notifications'),
      child: SettingsSection(
        children: [
          SettingsToggleTile(
            icon: Icons.notifications_active_outlined,
            iconColor: const Color(0xFFFFA450),
            title: tr('Aktifkan notifikasi', 'Enable notifications'),
            subtitle: tr(
              'Amaran azan dan peringatan',
              'Azan and reminder alerts',
            ),
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
          ListTile(
            leading: const _LeadingIcon(
              icon: Icons.play_arrow_rounded,
              color: Color(0xFFF4C542),
            ),
            title: Text(tr('Uji bunyi', 'Test sound')),
            subtitle: Text(
              tr('Mainkan bunyi notifikasi ringkas', 'Play a short preview'),
            ),
            enabled: controller.notifyEnabled,
            onTap: controller.notifyEnabled
                ? () {
                    final prayer = controller.nextPrayer?.name ?? 'Subuh';
                    controller.previewPrayerSound(prayer);
                  }
                : null,
          ),
          const SizedBox(height: 4),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              tr('Aktif untuk waktu', 'Enable for prayers'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: order
                  .where((name) => toggles.containsKey(name))
                  .map(
                    (name) => FilterChip(
                      label: Text(name),
                      selected: toggles[name] ?? false,
                      onSelected: controller.notifyEnabled
                          ? (value) =>
                              controller.setPrayerNotifyEnabled(name, value)
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
    for (final o in options.skip(1)) {
      final d = (value - o).abs();
      if (d < diff) {
        diff = d;
        best = o;
      }
    }
    return best;
  }
}

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return _SettingsSubpageScaffold(
      title: tr('Paparan', 'Appearance'),
      child: SettingsSection(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              tr('Saiz teks', 'Text size'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                onSelectionChanged: (selection) {
                  controller.setTextScale(selection.first);
                },
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
    for (final o in options.skip(1)) {
      final d = (value - o).abs();
      if (d < diff) {
        diff = d;
        best = o;
      }
    }
    return best;
  }
}

class PrayerTimesSettingsPage extends StatelessWidget {
  const PrayerTimesSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final locationLabel = controller.activeZone?.location ?? 'Kuala Lumpur';

    return _SettingsSubpageScaffold(
      title: tr('Waktu Solat', 'Prayer Times'),
      child: Column(
        children: [
          SettingsSection(
            children: [
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
              if (!controller.autoLocation) ...[
                SettingsNavTile(
                  icon: Icons.place_outlined,
                  iconColor: const Color(0xFF5CA9FF),
                  title: tr('Pilih zon manual', 'Pick manual zone'),
                  subtitle: '${controller.manualZoneCode} • $locationLabel',
                  onTap: () => _openZonePicker(context, controller),
                ),
                _ZoneQuickChips(controller: controller),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openZonePicker(
    BuildContext context,
    AppController controller,
  ) async {
    final tr = controller.tr;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
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
                      onChanged: (value) {
                        setState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 360,
                      child: ListView.separated(
                        itemCount: zones.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final zone = zones[index];
                          final isActive =
                              zone.code == controller.manualZoneCode;
                          final isFav = controller.isZoneFavorite(zone.code);
                          return ListTile(
                            tileColor: _surfaceAlt,
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

class FastingSettingsPage extends StatelessWidget {
  const FastingSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return _SettingsSubpageScaffold(
      title: tr('Peringatan Puasa', 'Fasting reminders'),
      child: Column(
        children: [
          if (!controller.notifyEnabled)
            _InfoBanner(
              text: tr(
                'Aktifkan notifikasi untuk menggunakan peringatan puasa.',
                'Enable notifications to use fasting reminders.',
              ),
            ),
          if (!controller.notifyEnabled) const SizedBox(height: 10),
          SettingsSection(
            children: [
              SettingsToggleTile(
                icon: Icons.nights_stay_outlined,
                iconColor: const Color(0xFFF2CB54),
                title: tr('Mod Ramadan', 'Ramadan mode'),
                subtitle: tr(
                  'Peringatan harian sepanjang Ramadan',
                  'Daily reminders throughout Ramadan',
                ),
                value: controller.ramadhanMode,
                onChanged: controller.notifyEnabled
                    ? controller.setRamadhanMode
                    : null,
              ),
              SettingsToggleTile(
                icon: Icons.calendar_view_week_outlined,
                iconColor: const Color(0xFFF2CB54),
                title: tr('Isnin & Khamis', 'Monday & Thursday'),
                subtitle: tr(
                  'Peringatan puasa sunat mingguan',
                  'Weekly sunnah fasting reminders',
                ),
                value: controller.fastingMondayThursdayEnabled,
                onChanged: controller.notifyEnabled
                    ? controller.setFastingMondayThursdayEnabled
                    : null,
              ),
              SettingsToggleTile(
                icon: Icons.brightness_2_outlined,
                iconColor: const Color(0xFFF2CB54),
                title: tr('Ayyamul Bidh', 'Ayyamul Bidh'),
                subtitle: tr(
                  '13, 14, 15 setiap bulan hijrah',
                  '13, 14, 15 every hijri month',
                ),
                value: controller.fastingAyyamulBidhEnabled,
                onChanged: controller.notifyEnabled
                    ? controller.setFastingAyyamulBidhEnabled
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              tr(
                'Jadual peringatan dijana automatik berdasarkan data bulanan semasa.',
                'Reminder schedule is generated automatically from current monthly data.',
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class TasbihSettingsPage extends StatelessWidget {
  const TasbihSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final selectedTarget = _selectedTarget(controller.tasbihCycleTarget);

    return _SettingsSubpageScaffold(
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
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
                    final custom = await _pickCustomTarget(context, controller);
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
          ListTile(
            leading: const _LeadingIcon(
              icon: Icons.analytics_outlined,
              color: Color(0xFFA98EFF),
            ),
            title: Text(tr('Statistik ringkas', 'Quick stats')),
            subtitle: Text(
              tr(
                'Hari ini ${controller.tasbihTodayCount} • 7 hari ${controller.tasbihWeekCount} • streak ${controller.tasbihStreakDays} • terbaik ${controller.tasbihBestDay}',
                'Today ${controller.tasbihTodayCount} • 7 days ${controller.tasbihWeekCount} • streak ${controller.tasbihStreakDays} • best ${controller.tasbihBestDay}',
              ),
            ),
          ),
          ListTile(
            leading: const _LeadingIcon(
              icon: Icons.restart_alt,
              color: Color(0xFFE08EA6),
            ),
            title: Text(tr('Reset kiraan', 'Reset count')),
            subtitle: Text(tr('Kiraan semasa akan dikosongkan',
                'Current count will be cleared')),
            enabled: controller.tasbihCount > 0,
            onTap: controller.tasbihCount == 0
                ? null
                : () => _confirmReset(context, controller),
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

  Future<int?> _pickCustomTarget(
    BuildContext context,
    AppController controller,
  ) async {
    final c = TextEditingController(text: '${controller.tasbihCycleTarget}');
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );
    c.dispose();
    return result;
  }

  Future<void> _confirmReset(
      BuildContext context, AppController controller) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(controller.tr('Reset kiraan zikir?', 'Reset tasbih count?')),
          content: Text(
            controller.tr(
                'Kiraan akan kembali ke 0.', 'Count will return to 0.'),
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
        );
      },
    );
    if (ok == true) {
      await controller.resetTasbih();
    }
  }
}

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return _SettingsSubpageScaffold(
      title: tr('Tentang', 'About'),
      child: SettingsSection(
        children: [
          ListTile(
            leading: const _LeadingIcon(
              icon: Icons.info_outline,
              color: Color(0xFF4EC7F7),
            ),
            title: const Text('JagaSolat'),
            subtitle: Text(
              '${tr('Sumber data', 'Data source')}: JAKIM e-Solat + Malaysia Waktu Solat API',
            ),
          ),
          ListTile(
            leading: const _LeadingIcon(
              icon: Icons.update_outlined,
              color: Color(0xFF4EC7F7),
            ),
            title: Text(tr('Status data', 'Data status')),
            subtitle: Text(controller.prayerDataFreshnessLabel),
          ),
        ],
      ),
    );
  }
}

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    this.title,
    required this.children,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _textMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: _LeadingIcon(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
      secondary: _LeadingIcon(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsSubpageScaffold extends StatelessWidget {
  const _SettingsSubpageScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            child,
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
      onChanged: onChanged,
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2F2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFFFD7C8),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _ZoneQuickChips extends StatelessWidget {
  const _ZoneQuickChips({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final codes = <String>[
      ...controller.favoriteZones,
      ...controller.recentZones,
    ].where((c) => seen.add(c)).take(10).toList();

    if (codes.isEmpty) {
      return const SizedBox.shrink();
    }

    final zonesByCode = {
      for (final zone in controller.zones) zone.code: zone,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: codes
            .where((code) => zonesByCode.containsKey(code))
            .map(
              (code) => ActionChip(
                label: Text(code),
                avatar: Icon(
                  controller.favoriteZones.contains(code)
                      ? Icons.star
                      : Icons.history,
                  size: 15,
                ),
                onPressed: () => controller.setManualZone(code),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _textMuted,
            ),
      ),
    );
  }
}
