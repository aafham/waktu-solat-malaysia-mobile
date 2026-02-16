import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';

const _msLocale = 'ms_MY';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.onNavigateToTab,
  });

  final AppController controller;
  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ScrollController _scrollController;
  bool _showMiniBar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final visible = _scrollController.offset > 210;
    if (visible != _showMiniBar) {
      setState(() {
        _showMiniBar = visible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final prayers = controller.dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[];
    final nextPrayer = controller.nextPrayer;
    final now = DateTime.now();
    final currentPrayer = _currentPrayer(prayers, now);
    final zoneLabel = controller.activeZone?.label ??
        tr('Zon belum ditentukan', 'Zone not selected');
    final heroTheme = _themeForPrayer(nextPrayer?.name ?? currentPrayer?.name);
    final pageMood =
        _pageMoodForPrayer(nextPrayer?.name ?? currentPrayer?.name);

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: pageMood,
                ),
              ),
            ),
          ),
          RefreshIndicator(
            onRefresh: controller.refreshPrayerData,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                Text(
                  tr('Waktu Solat', 'Prayer Times'),
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
                const SizedBox(height: 8),
                _DataFreshnessPill(
                  label: controller.prayerDataFreshnessLabel,
                  isCache: controller.isUsingCachedPrayerData,
                ),
                const SizedBox(height: 10),
                if (controller.errorMessage != null)
                  _ErrorCard(controller: controller)
                else ...[
                  _DateClockCard(
                    controller: controller,
                    hijriDate: controller.dailyPrayerTimes?.hijriDate,
                  ),
                  const SizedBox(height: 10),
                  _HeroPrayerCard(
                    controller: controller,
                    nextPrayer: nextPrayer,
                    currentPrayer: currentPrayer,
                    gradientColors: heroTheme,
                  ),
                  const SizedBox(height: 10),
                  _SectionLabel(
                    icon: Icons.timeline,
                    text: tr('Ritma Solat', 'Prayer Rhythm'),
                  ),
                  const SizedBox(height: 8),
                  _PrayerRhythmStrip(
                    controller: controller,
                    prayers: prayers,
                    nextPrayerName: nextPrayer?.name,
                    currentPrayerName: currentPrayer?.name,
                  ),
                  const SizedBox(height: 10),
                  _DailyProgressCard(
                    controller: controller,
                    completed: controller.todayPrayerCompletedCount,
                    total: controller.todayPrayerTargetCount,
                    progress: controller.todayPrayerProgress,
                  ),
                  const SizedBox(height: 10),
                  _QuickActionsRow(
                    controller: controller,
                    onOpenTools: () => _showQuickTools(context),
                    onOpenQiblat: () => widget.onNavigateToTab(1),
                    onOpenZikir: () => widget.onNavigateToTab(2),
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel(
                    icon: Icons.checklist,
                    text:
                        tr('Check-in Solat Hari Ini', 'Today Prayer Check-in'),
                  ),
                  const SizedBox(height: 8),
                  _PrayerCheckinList(
                    prayers: prayers,
                    controller: controller,
                    onToggle: (name) =>
                        controller.togglePrayerCompletedToday(name),
                  ),
                  const SizedBox(height: 12),
                  _SectionLabel(
                    icon: Icons.schedule,
                    text: tr('Jadual Ringkas', 'Quick Schedule'),
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
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: IgnorePointer(
              ignoring: !_showMiniBar,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                offset: _showMiniBar ? Offset.zero : const Offset(0, -1.15),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _showMiniBar ? 1 : 0,
                  child: _MiniCountdownBar(
                    controller: controller,
                    nextPrayer: nextPrayer,
                  ),
                ),
              ),
            ),
          ),
        ],
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

  List<Color> _pageMoodForPrayer(String? prayerName) {
    switch (prayerName) {
      case 'Subuh':
        return const [Color(0xFF08264A), Color(0xFF051B36)];
      case 'Zohor':
        return const [Color(0xFF16365A), Color(0xFF071E3D)];
      case 'Asar':
        return const [Color(0xFF1B3D46), Color(0xFF082532)];
      case 'Maghrib':
        return const [Color(0xFF3D2F2A), Color(0xFF0A243D)];
      case 'Isyak':
        return const [Color(0xFF0C2445), Color(0xFF061A32)];
      default:
        return const [Color(0xFF0A1A38), Color(0xFF07142E)];
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
                      label: widget.controller.tr('Waktu', 'Times'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToTab(0);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.explore,
                      label: widget.controller.tr('Qiblat', 'Qibla'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToTab(1);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.touch_app,
                      label: widget.controller.tr('Zikir', 'Tasbih'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToTab(2);
                      },
                    ),
                    _QuickToolTile(
                      icon: Icons.settings,
                      label: widget.controller.tr('Tetapan', 'Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onNavigateToTab(3);
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

class _MiniCountdownBar extends StatefulWidget {
  const _MiniCountdownBar({
    required this.controller,
    required this.nextPrayer,
  });

  final AppController controller;
  final PrayerTimeEntry? nextPrayer;

  @override
  State<_MiniCountdownBar> createState() => _MiniCountdownBarState();
}

class _MiniCountdownBarState extends State<_MiniCountdownBar> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_refresh);
    });
  }

  @override
  void didUpdateWidget(covariant _MiniCountdownBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayer?.time != widget.nextPrayer?.time) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _refresh() {
    final next = widget.controller.nextPrayer;
    if (next == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = next.time.difference(DateTime.now());
    _remaining = diff.isNegative ? Duration.zero : diff;
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.controller.tr;
    final next = widget.controller.nextPrayer;
    final text = next == null
        ? tr('Tiada waktu seterusnya', 'No next prayer')
        : tr(
            '${next.name} dalam ${_formatHms(_remaining)}',
            '${next.name} in ${_formatHms(_remaining)}',
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xF018335B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF40628E)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, size: 16, color: Color(0xFFF3C623)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFEAF2FF),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
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
  Timer? _pulseTimer;
  Duration _remaining = Duration.zero;
  bool _refreshingNext = false;
  bool _pulse = false;

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
      _pulseTimer?.cancel();
      setState(() {
        _pulse = true;
      });
      _pulseTimer = Timer(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() {
          _pulse = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseTimer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final next = widget.controller.nextPrayer;
    if (next == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = next.time.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds == 0) {
      _remaining = Duration.zero;
      if (!_refreshingNext) {
        _refreshingNext = true;
        widget.controller.refreshPrayerData().whenComplete(() {
          _refreshingNext = false;
        });
      }
      return;
    }
    _remaining = diff;
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.controller.tr;
    final currentName =
        _currentPrayerName() ?? tr('Belum bermula', 'Not started');
    final next = widget.controller.nextPrayer;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _pulse ? const Color(0x66F3C623) : const Color(0x44000000),
            blurRadius: _pulse ? 24 : 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('WAKTU SEMASA', 'CURRENT PRAYER'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    letterSpacing: 1.1,
                  ),
            ),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: Text(
                currentName,
                key: ValueKey<String>(currentName),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (next != null) ...[
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  tr(
                    'Seterusnya ${next.name} pada ${DateFormat('HH:mm', _msLocale).format(next.time)}',
                    'Next ${next.name} at ${DateFormat('HH:mm', _msLocale).format(next.time)}',
                  ),
                  key: ValueKey<String>('next-${next.name}-${next.time}'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
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
                tr(
                  'sebelum masuk waktu ${next.name.toLowerCase()}',
                  'until ${next.name.toLowerCase()} starts',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ] else
              Text(
                tr(
                  'Tiada waktu seterusnya buat masa ini.',
                  'No next prayer time for now.',
                ),
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
                  SnackBar(
                    content: Text(
                      tr('Rekod solat dikemas kini.', 'Prayer record updated.'),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                tr('Tanda Solat Selesai', 'Mark As Completed'),
                style: const TextStyle(fontWeight: FontWeight.w700),
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

  String? _currentPrayerName() {
    final entries = widget.controller.dailyPrayerTimes?.entries;
    if (entries == null || entries.isEmpty) {
      return widget.currentPrayer?.name;
    }
    final now = DateTime.now();
    PrayerTimeEntry? current;
    for (final entry in entries) {
      if (entry.time.isBefore(now) || entry.time.isAtSameMomentAs(now)) {
        current = entry;
      }
    }
    return current?.name ?? widget.currentPrayer?.name;
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({
    required this.controller,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final AppController controller;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('Progress Hari Ini', 'Today Progress'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('$completed/$total selesai',
                        '$completed/$total completed'),
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
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF3C623)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRhythmStrip extends StatelessWidget {
  const _PrayerRhythmStrip({
    required this.controller,
    required this.prayers,
    required this.nextPrayerName,
    required this.currentPrayerName,
  });

  final AppController controller;
  final List<PrayerTimeEntry> prayers;
  final String? nextPrayerName;
  final String? currentPrayerName;

  @override
  Widget build(BuildContext context) {
    if (prayers.isEmpty) {
      return const SizedBox.shrink();
    }
    final now = DateTime.now();
    final visible = prayers
        .where(
          (p) =>
              p.name == 'Subuh' ||
              p.name == 'Syuruk' ||
              p.name == 'Zohor' ||
              p.name == 'Asar' ||
              p.name == 'Maghrib' ||
              p.name == 'Isyak',
        )
        .toList();
    if (visible.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 122,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = visible[i];
          final isNext = item.name == nextPrayerName;
          final isCurrent = item.name == currentPrayerName;
          final isDone = item.time.isBefore(now) && !isCurrent;
          final status = isCurrent
              ? controller.tr('Semasa', 'Current')
              : isNext
                  ? controller.tr('Seterusnya', 'Next')
                  : isDone
                      ? controller.tr('Selesai', 'Done')
                      : controller.tr('Akan datang', 'Upcoming');
          final accent = isCurrent
              ? const Color(0xFF3CCAB5)
              : isNext
                  ? const Color(0xFFF3C623)
                  : const Color(0xFF7D93B8);

          return Container(
            width: 132,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isNext
                    ? const [Color(0xFF1F3F6A), Color(0xFF17375E)]
                    : const [Color(0xFF162D4D), Color(0xFF132540)],
              ),
              border: Border.all(
                color:
                    isNext ? const Color(0xFFF3C623) : const Color(0xFF31527A),
                width: isNext ? 1.4 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFC9D8EF),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFFEAF2FF),
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Text(
                  DateFormat('HH:mm', _msLocale).format(item.time),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFEAF2FF),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.controller,
    required this.onOpenTools,
    required this.onOpenQiblat,
    required this.onOpenZikir,
  });

  final AppController controller;
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
          label: Text(controller.tr('Alat Pantas', 'Quick Tools')),
        ),
        OutlinedButton.icon(
          onPressed: onOpenQiblat,
          icon: const Icon(Icons.explore),
          label: Text(controller.tr('Qiblat', 'Qibla')),
        ),
        OutlinedButton.icon(
          onPressed: onOpenZikir,
          icon: const Icon(Icons.touch_app),
          label: Text(controller.tr('Zikir', 'Tasbih')),
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
      final tr = controller.tr;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr(
                  'Tiada rekod untuk dipaparkan.', 'No records to display.')),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: controller.refreshPrayerData,
                child: Text(tr('Muat semula data waktu', 'Reload prayer data')),
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
              color:
                  completed ? const Color(0xFFF3C623) : const Color(0xFF9BB1CE),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFEAF2FF),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (active)
                      Text(
                        'NEXT',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFFF3C623),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                  ],
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
    required this.controller,
    required this.hijriDate,
  });

  final AppController controller;
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
    final locale = widget.controller.isEnglish ? 'en_US' : _msLocale;
    final tr = widget.controller.tr;
    final gDate = DateFormat('EEEE, d MMMM yyyy', locale).format(_now);
    final clock = DateFormat('HH:mm:ss', locale).format(_now);
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
                    tr('TARIKH MASIHI', 'GREGORIAN DATE'),
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
                    tr('TARIKH HIJRAH', 'HIJRI DATE'),
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
        width: alignment == Alignment.topCenter ||
                alignment == Alignment.bottomCenter
            ? 3
            : 10,
        height: alignment == Alignment.topCenter ||
                alignment == Alignment.bottomCenter
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
    final tr = controller.tr;
    return Card(
      color: const Color(0xFF3B1E29),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.errorMessage ??
                  tr('Ralat tidak diketahui.', 'Unknown error.'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: controller.refreshPrayerData,
              icon: const Icon(Icons.refresh),
              label: Text(tr('Cuba semula', 'Try again')),
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

class _DataFreshnessPill extends StatelessWidget {
  const _DataFreshnessPill({
    required this.label,
    required this.isCache,
  });

  final String label;
  final bool isCache;

  @override
  Widget build(BuildContext context) {
    final color = isCache ? const Color(0xFFF4C542) : const Color(0xFF3CCAB5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF132B4D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF31527A)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done, size: 15, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFD8E5F8),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
