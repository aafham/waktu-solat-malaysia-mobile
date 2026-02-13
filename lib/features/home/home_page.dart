import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

const _msLocale = 'ms_MY';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final prayers = controller.dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[];
    final nextPrayer = controller.nextPrayer;
    final countdown = controller.timeToNextPrayer;
    final now = DateTime.now();
    final currentPrayer = _currentPrayer(prayers, now);
    final heroTheme = _themeForPrayer(nextPrayer?.name ?? currentPrayer?.name);

    PrayerTimeEntry? findPrayer(String name) {
      for (final p in prayers) {
        if (p.name == name) {
          return p;
        }
      }
      return null;
    }

    final maghrib = findPrayer('Maghrib');
    final imsak = findPrayer('Imsak');

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshPrayerData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            _SectionTitle(
              title: 'Waktu Solat Malaysia',
              subtitle: controller.activeZone?.label ?? 'Zon belum ditentukan',
            ),
            const SizedBox(height: 10),
            _DateClockCard(
              hijriDate: controller.dailyPrayerTimes?.hijriDate,
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: Colors.white.withValues(alpha: 0.82),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'API berjaya: ${controller.apiSuccessCount} | Gagal: ${controller.apiFailureCount} | Simpanan: ${controller.cacheHitCount}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: controller.isUsingCachedPrayerData
                            ? Colors.amber.shade50
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.isUsingCachedPrayerData
                                ? Icons.cloud_off
                                : Icons.cloud_done,
                            size: 16,
                            color: controller.isUsingCachedPrayerData
                                ? Colors.orange.shade700
                                : Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.prayerDataFreshnessLabel,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (controller.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (controller.errorMessage != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.errorMessage!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: controller.refreshPrayerData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cuba semula'),
                      ),
                      if (controller.errorActionLabel != null) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: controller.runErrorAction,
                          icon: const Icon(Icons.settings),
                          label: Text(controller.errorActionLabel!),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else ...[
              _SectionLabel(
                icon: Icons.schedule,
                text: 'Seterusnya',
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: heroTheme,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _NextPrayerCountdownCard(
                        nextPrayer: nextPrayer,
                        currentPrayer: currentPrayer,
                      ),
                      const SizedBox(height: 12),
                      OverflowBar(
                        spacing: 8,
                        overflowSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(5),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            icon: const Icon(Icons.alarm, size: 16),
                            label: const Text('Tunda 5 min'),
                          ),
                          OutlinedButton.icon(
                            onPressed: nextPrayer == null
                                ? null
                                : () => controller.snoozeNextPrayer(10),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                            ),
                            icon: const Icon(Icons.alarm, size: 16),
                            label: const Text('Tunda 10 min'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionLabel(
                icon: Icons.today,
                text: 'Hari Ini',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (maghrib != null)
                    Chip(
                      avatar: const Icon(Icons.restaurant, size: 16),
                      label: Text(
                        'Berbuka ${DateFormat('HH:mm', _msLocale).format(maghrib.time)}',
                      ),
                    ),
                  if (imsak != null)
                    Chip(
                      avatar: const Icon(Icons.nights_stay, size: 16),
                      label: Text(
                        'Imsak ${DateFormat('HH:mm', _msLocale).format(imsak.time)}',
                      ),
                    ),
                  if (!controller.exactAlarmAllowed)
                    const Chip(
                      avatar: Icon(Icons.warning_amber, size: 16),
                      label: Text('Penggera tepat mungkin disekat'),
                    ),
                ],
              ),
              if (controller.ramadhanMode) ...[
                const SizedBox(height: 8),
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      'Mod Ramadan aktif: fokus pada Imsak dan Maghrib untuk jadual puasa harian.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _SectionLabel(
                icon: Icons.flash_on,
                text: 'Tindakan Pantas',
              ),
              const SizedBox(height: 8),
              OverflowBar(
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: controller.refreshPrayerData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat semula'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      final text = _buildTodayShareText(
                        zoneLabel: controller.activeZone?.label ?? '-',
                        nextPrayer: nextPrayer,
                        countdown: countdown,
                        prayers: prayers,
                      );
                      await Share.share(
                        text,
                        subject: 'Waktu Solat Hari Ini',
                      );
                    },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Kongsi hari ini'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final url = controller.nearbyMosqueMapUrl();
                      if (url == null) return;
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Masjid terdekat'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionLabel(
                icon: Icons.view_module,
                text: 'Jadual',
              ),
              const SizedBox(height: 8),
              _PrayerGrid(
                prayers: prayers,
                nextPrayerName: nextPrayer?.name,
              ),
            ],
          ],
        ),
      ),
    );
  }

  PrayerTimeEntry? _currentPrayer(List<PrayerTimeEntry> entries, DateTime now) {
    if (entries.isEmpty) {
      return null;
    }
    PrayerTimeEntry? current;
    for (final entry in entries) {
      if (entry.time.isBefore(now) || entry.time.isAtSameMomentAs(now)) {
        current = entry;
      }
    }
    return current;
  }

  List<Color> _themeForPrayer(String? prayerName) {
    switch (prayerName) {
      case 'Subuh':
        return const [Color(0xFF3A6EA5), Color(0xFF274B74)];
      case 'Zohor':
        return const [Color(0xFF5E6C84), Color(0xFF36445A)];
      case 'Asar':
        return const [Color(0xFF4A7A6A), Color(0xFF2E5A4D)];
      case 'Maghrib':
        return const [Color(0xFFB15E3E), Color(0xFF7D3D24)];
      case 'Isyak':
        return const [Color(0xFF24566B), Color(0xFF123848)];
      default:
        return const [Color(0xFF0D8C7B), Color(0xFF0A6A60)];
    }
  }

  String _formatCountdown(Duration? duration) {
    if (duration == null || duration.isNegative) {
      return '00:00';
    }

    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  String _buildTodayShareText({
    required String zoneLabel,
    required PrayerTimeEntry? nextPrayer,
    required Duration? countdown,
    required List<PrayerTimeEntry> prayers,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Waktu Solat Malaysia');
    buffer.writeln(zoneLabel);
    buffer.writeln('');
    if (nextPrayer != null) {
      buffer.writeln(
        'Seterusnya: ${nextPrayer.name} ${DateFormat('HH:mm', _msLocale).format(nextPrayer.time)} (${_formatCountdown(countdown)})',
      );
      buffer.writeln('');
    }
    for (final p in prayers) {
      buffer.writeln('${p.name}: ${DateFormat('HH:mm', _msLocale).format(p.time)}');
    }
    return buffer.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DateClockCard extends StatefulWidget {
  const _DateClockCard({
    required this.hijriDate,
  });

  final String? hijriDate;

  @override
  State<_DateClockCard> createState() => _DateClockCardState();
}

class _DateClockCardState extends State<_DateClockCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gDate = DateFormat('EEEE, d MMMM yyyy', _msLocale).format(_now);
    final clock = DateFormat('HH:mm:ss', _msLocale).format(_now);
    final hijri = widget.hijriDate ?? '--';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2524), Color(0xFF142D2A)],
        ),
        border: Border.all(color: const Color(0xFF2F4A46)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TARIKH MASIHI',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF9EC2BC),
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TARIKH HIJRAH',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF9EC2BC),
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hijri,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clock,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF6BE0B7),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _AnalogClock(now: _now),
          ],
        ),
      ),
    );
  }
}

class _AnalogClock extends StatelessWidget {
  const _AnalogClock({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final minuteAngle = (2 * 3.141592653589793) * (now.minute / 60);
    final hourAngle =
        (2 * 3.141592653589793) * ((now.hour % 12) / 12 + now.minute / 720);

    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: const Color(0xFF2E4945)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _tick(Alignment.topCenter),
          _tick(Alignment.centerLeft),
          _tick(Alignment.centerRight),
          _tick(Alignment.bottomCenter),
          Transform.rotate(
            angle: hourAngle,
            child: Container(
              width: 3.2,
              height: 32,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Transform.rotate(
            angle: minuteAngle,
            child: Container(
              width: 2.4,
              height: 42,
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: const Color(0xFF6BE0B7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6BE0B7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tick(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? 3
            : 10,
        height: alignment == Alignment.topCenter || alignment == Alignment.bottomCenter
            ? 10
            : 3,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFC5DEDA),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _PrayerGrid extends StatelessWidget {
  const _PrayerGrid({
    required this.prayers,
    required this.nextPrayerName,
  });

  final List<PrayerTimeEntry> prayers;
  final String? nextPrayerName;

  @override
  Widget build(BuildContext context) {
    final order = <String>[
      'Subuh',
      'Syuruk',
      'Zohor',
      'Asar',
      'Maghrib',
      'Isyak',
    ];
    final labels = <String, String>{
      'Subuh': 'Subuh',
      'Syuruk': 'Syuruk',
      'Zohor': 'Zohor',
      'Asar': 'Asar',
      'Maghrib': 'Maghrib',
      'Isyak': 'Isyak',
    };

    final visible = <PrayerTimeEntry>[];
    for (final key in order) {
      for (final p in prayers) {
        if (p.name == key) {
          visible.add(p);
          break;
        }
      }
    }

    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = visible[index];
        final active = item.name == nextPrayerName;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1616), Color(0xFF101D1C)],
            ),
            border: Border.all(
              color: active ? const Color(0xFF38C28E) : const Color(0xFF273837),
              width: active ? 1.6 : 1.0,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x3347D49A),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  labels[item.name] ?? item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                DateFormat('HH:mm', _msLocale).format(item.time),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NextPrayerCountdownCard extends StatefulWidget {
  const _NextPrayerCountdownCard({
    required this.nextPrayer,
    required this.currentPrayer,
  });

  final PrayerTimeEntry? nextPrayer;
  final PrayerTimeEntry? currentPrayer;

  @override
  State<_NextPrayerCountdownCard> createState() =>
      _NextPrayerCountdownCardState();
}

class _NextPrayerCountdownCardState extends State<_NextPrayerCountdownCard> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_updateRemaining);
    });
  }

  @override
  void didUpdateWidget(covariant _NextPrayerCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayer?.time != widget.nextPrayer?.time) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final next = widget.nextPrayer;
    if (next == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = next.time.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  Widget build(BuildContext context) {
    final next = widget.nextPrayer;
    final timeLabel =
        next == null ? '-' : DateFormat('HH:mm', _msLocale).format(next.time);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WAKTU SETERUSNYA',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                next?.name ?? 'Tiada lagi',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
              ),
              if (widget.currentPrayer != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Sedang: ${widget.currentPrayer!.name}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'KIRAAN MUNDUR',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatHms(_remaining),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
