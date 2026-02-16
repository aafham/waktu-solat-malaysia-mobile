import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

const _msLocale = 'ms_MY';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onNavigateToTab,
  });

  final AppController controller;
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final prayers = controller.dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[];
    final nextPrayer = controller.nextPrayer;
    final now = DateTime.now();
    final currentPrayer = _currentPrayer(prayers, now);
    final zoneLabel = controller.activeZone?.label ?? 'Zon belum ditentukan';
    final heroTheme = _themeForPrayer(nextPrayer?.name ?? currentPrayer?.name);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: controller.refreshPrayerData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Text(
              'Waktu Solat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              zoneLabel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB9C8E2),
                  ),
            ),
            const SizedBox(height: 10),
            if (controller.errorMessage != null)
              _ErrorCard(controller: controller)
            else ...[
              _DateClockCard(hijriDate: controller.dailyPrayerTimes?.hijriDate),
              const SizedBox(height: 10),
              _HeroPrayerCard(
                controller: controller,
                nextPrayer: nextPrayer,
                currentPrayer: currentPrayer,
                gradientColors: heroTheme,
              ),
              const SizedBox(height: 10),
              _DailyProgressCard(
                completed: controller.todayPrayerCompletedCount,
                total: controller.todayPrayerTargetCount,
                progress: controller.todayPrayerProgress,
              ),
              const SizedBox(height: 10),
              _QuickActionsRow(
                onOpenTools: () => _showQuickTools(context),
                onOpenQiblat: () => onNavigateToTab(1),
                onOpenZikir: () => onNavigateToTab(2),
              ),
              const SizedBox(height: 12),
              const _SectionLabel(icon: Icons.checklist, text: 'Check-in Solat Hari Ini'),
              const SizedBox(height: 8),
              _PrayerCheckinList(
                prayers: prayers,
                controller: controller,
                onToggle: (name) => controller.togglePrayerCompletedToday(name),
              ),
              const SizedBox(height: 12),
              const _SectionLabel(icon: Icons.schedule, text: 'Jadual Ringkas'),
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
        return const [Color(0xFF376FA1), Color(0xFF1E3E65)];
      case 'Zohor':
        return const [Color(0xFF6F7FA3), Color(0xFF3D4967)];
      case 'Asar':
        return const [Color(0xFF4D7A70), Color(0xFF2A544C)];
      case 'Maghrib':
        return const [Color(0xFFB57038), Color(0xFF7A4B26)];
      case 'Isyak':
        return const [Color(0xFF315E8A), Color(0xFF1C3552)];
      default:
        return const [Color(0xFF1D5B8C), Color(0xFF173D64)];
    }
  }

  Future<void> _showQuickTools(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF112544),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B658A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickToolTile(
                      icon: Icons.home_outlined,
                      label: 'Waktu',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateToTab(0);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.explore,
                      label: 'Kiblat',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateToTab(1);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.touch_app,
                      label: 'Zikir',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateToTab(2);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.settings,
                      label: 'Tetapan',
                      onTap: () {
                        Navigator.pop(context);
                        onNavigateToTab(3);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroPrayerCard extends StatefulWidget {
  const _HeroPrayerCard({
    required this.controller,
    required this.nextPrayer,
    required this.currentPrayer,
    required this.gradientColors,
  });

  final AppController controller;
  final PrayerTimeEntry? nextPrayer;
  final PrayerTimeEntry? currentPrayer;
  final List<Color> gradientColors;

  @override
  State<_HeroPrayerCard> createState() => _HeroPrayerCardState();
}

class _HeroPrayerCardState extends State<_HeroPrayerCard> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(_updateRemaining);
    });
  }

  @override
  void didUpdateWidget(covariant _HeroPrayerCard oldWidget) {
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
    final currentName = widget.currentPrayer?.name ?? 'Belum bermula';
    final next = widget.nextPrayer;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WAKTU SEMASA',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              currentName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            if (next != null) ...[
              Text(
                'Seterusnya ${next.name} pada ${DateFormat('HH:mm', _msLocale).format(next.time)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatHms(_remaining),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: const Color(0xFFFFF3D1),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                'sebelum masuk waktu ${next.name.toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ] else
              Text(
                'Tiada waktu seterusnya buat masa ini.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.94),
                    ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await widget.controller.markCurrentPrayerAsDone();
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rekod solat dikemas kini.')),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text(
                'Tanda Solat Selesai',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHms(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Hari Ini',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$completed/$total selesai',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFF3C623),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: const Color(0xFF233D61),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF3C623)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onOpenTools,
    required this.onOpenQiblat,
    required this.onOpenZikir,
  });

  final VoidCallback onOpenTools;
  final VoidCallback onOpenQiblat;
  final VoidCallback onOpenZikir;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          onPressed: onOpenTools,
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('Quick Tools'),
        ),
        OutlinedButton.icon(
          onPressed: onOpenQiblat,
          icon: const Icon(Icons.explore),
          label: const Text('Qiblat'),
        ),
        OutlinedButton.icon(
          onPressed: onOpenZikir,
          icon: const Icon(Icons.touch_app),
          label: const Text('Zikir'),
        ),
      ],
    );
  }
}

class _PrayerCheckinList extends StatelessWidget {
  const _PrayerCheckinList({
    required this.prayers,
    required this.controller,
    required this.onToggle,
  });

  final List<PrayerTimeEntry> prayers;
  final AppController controller;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    const order = <String>['Subuh', 'Zohor', 'Asar', 'Maghrib', 'Isyak'];
    final selected = prayers.where((p) => order.contains(p.name)).toList();
    if (selected.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tiada rekod untuk dipaparkan.'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: controller.refreshPrayerData,
                child: const Text('Muat semula data waktu'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: selected.map((entry) {
          final completed = controller.isPrayerCompletedToday(entry.name);
          return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: completed,
            onChanged: (_) => onToggle(entry.name),
            title: Text(entry.name),
            subtitle: Text(DateFormat('HH:mm', _msLocale).format(entry.time)),
            secondary: Icon(
              completed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: completed ? const Color(0xFFF3C623) : const Color(0xFF9BB1CE),
            ),
          );
        }).toList(),
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
    const order = <String>[
      'Subuh',
      'Syuruk',
      'Zohor',
      'Asar',
      'Maghrib',
      'Isyak',
    ];
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
            color: const Color(0xFF0F2746),
            border: Border.all(
              color: active ? const Color(0xFFF3C623) : const Color(0xFF28476D),
              width: active ? 1.8 : 1.0,
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x33F3C623),
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
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFEAF2FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                DateFormat('HH:mm', _msLocale).format(item.time),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFEAF2FF),
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
      if (!mounted) {
        return;
      }
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
        color: const Color(0xFF0F2746),
        border: Border.all(color: const Color(0xFF28476D)),
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
                          color: const Color(0xFF90A9CC),
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gDate,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFEAF2FF),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TARIKH HIJRAH',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF90A9CC),
                          letterSpacing: 1.1,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hijri,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFEAF2FF),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clock,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFFF3C623),
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
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: const Color(0xFF35577F)),
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
              height: 30,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Transform.rotate(
            angle: minuteAngle,
            child: Container(
              width: 2.4,
              height: 40,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFF3C623),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFF3C623),
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
          color: const Color(0xFF9CB3D2),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF3B1E29),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.errorMessage ?? 'Ralat tidak diketahui.',
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
        Icon(icon, size: 18, color: const Color(0xFFF3C623)),
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

class _QuickToolTile extends StatelessWidget {
  const _QuickToolTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFF18345A),
              border: Border.all(color: const Color(0xFF365B86)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFF3C623)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFEAF2FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
