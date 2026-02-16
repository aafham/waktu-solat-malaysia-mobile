import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';
import '../../theme/app_tokens.dart';

const _msLocale = 'ms_MY';
const _mainPrayerOrder = <String>['Subuh', 'Zohor', 'Asar', 'Maghrib', 'Isyak'];

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
  });

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final tokens = context.prayerHomeTokens;
    final locale = controller.isEnglish ? 'en_US' : _msLocale;
    final allPrayers =
        controller.dailyPrayerTimes?.entries ?? <PrayerTimeEntry>[];
    final prayers = _orderedMainPrayers(allPrayers);
    final now = DateTime.now();
    final currentPrayer = _currentPrayer(prayers, now);
    final nextPrayer = controller.nextPrayer;

    if (controller.errorMessage != null) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.cardPadding),
          child: _HomeErrorCard(controller: controller),
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshHomeData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 52,
              collapsedHeight: 52,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              titleSpacing: tokens.cardPadding,
              title: PinnedMiniHeader(
                controller: controller,
                currentPrayer: currentPrayer,
                nextPrayer: nextPrayer,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.cardPadding,
                  tokens.cardPadding,
                  tokens.cardPadding,
                  100,
                ),
                child: controller.isLoading && allPrayers.isEmpty
                    ? const _HomeSkeleton()
                    : prayers.isEmpty
                        ? _HomeEmptyState(controller: controller)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('Waktu Solat', 'Waktu Solat'),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: tokens.grid),
                              Text(
                                DateFormat('EEEE, d MMMM yyyy', locale)
                                    .format(now),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: tokens.textMuted,
                                    ),
                              ),
                              SizedBox(height: tokens.sectionGap),
                              TimesHeroCard(
                                controller: controller,
                                prayers: prayers,
                                currentPrayer: currentPrayer,
                                nextPrayer: nextPrayer,
                                onCheckIn: _checkInCurrentPrayer,
                                onSnooze: () async {
                                  await controller.snoozeNextPrayer(5);
                                  await HapticFeedback.lightImpact();
                                },
                              ),
                              const SizedBox(height: 8),
                              NextPrayerStrip(
                                controller: controller,
                                nextPrayer: nextPrayer,
                              ),
                              SizedBox(height: tokens.sectionGap),
                              TodayScheduleList(
                                controller: controller,
                                prayers: prayers,
                                currentPrayer: currentPrayer,
                                nextPrayer: nextPrayer,
                                onTapRow: _onPrayerRowTap,
                                onLongPressRow: _onPrayerRowLongPress,
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PrayerTimeEntry> _orderedMainPrayers(List<PrayerTimeEntry> entries) {
    final result = <PrayerTimeEntry>[];
    for (final name in _mainPrayerOrder) {
      for (final entry in entries) {
        if (entry.name == name) {
          result.add(entry);
          break;
        }
      }
    }
    return result;
  }

  PrayerTimeEntry? _currentPrayer(List<PrayerTimeEntry> entries, DateTime now) {
    PrayerTimeEntry? current;
    for (final entry in entries) {
      if (!entry.time.isAfter(now)) {
        current = entry;
      }
    }
    return current;
  }

  Future<void> _checkInCurrentPrayer() async {
    final before = widget.controller.todayPrayerCompletedCount;
    await widget.controller.markCurrentPrayerAsDone();
    await HapticFeedback.selectionClick();
    if (!mounted) {
      return;
    }
    final after = widget.controller.todayPrayerCompletedCount;
    if (after > before) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.tr(
            'Check-in berjaya.',
            'Check-in berjaya.',
          )),
        ),
      );
    }
  }

  Future<void> _onPrayerRowTap(PrayerTimeEntry entry, bool completed) async {
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.controller.tr(
            'Tekan lama untuk undo.',
            'Tekan lama untuk undo.',
          )),
        ),
      );
      return;
    }
    await widget.controller.togglePrayerCompletedToday(entry.name);
    await HapticFeedback.selectionClick();
  }

  Future<void> _onPrayerRowLongPress(
    PrayerTimeEntry entry,
    bool completed,
  ) async {
    if (!completed) {
      return;
    }
    final tr = widget.controller.tr;
    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('Batal check-in?', 'Batal check-in?')),
          content: Text(
            tr(
              'Rekod ${entry.name} akan ditanda belum selesai.',
              'Rekod ${entry.name} akan ditanda belum selesai.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Batal', 'Batal')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(tr('Undo', 'Undo')),
            ),
          ],
        );
      },
    );
    if (shouldUndo == true) {
      await widget.controller.togglePrayerCompletedToday(entry.name);
      await HapticFeedback.lightImpact();
    }
  }

  Future<void> _refreshHomeData() async {
    await widget.controller.refreshPrayerData();
  }
}

class TimesHeroCard extends StatefulWidget {
  const TimesHeroCard({
    super.key,
    required this.controller,
    required this.prayers,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.onCheckIn,
    required this.onSnooze,
  });

  final AppController controller;
  final List<PrayerTimeEntry> prayers;
  final PrayerTimeEntry? currentPrayer;
  final PrayerTimeEntry? nextPrayer;
  final Future<void> Function() onCheckIn;
  final Future<void> Function() onSnooze;

  @override
  State<TimesHeroCard> createState() => _TimesHeroCardState();
}

class _TimesHeroCardState extends State<TimesHeroCard> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _syncCountdown();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_syncCountdown);
    });
  }

  @override
  void didUpdateWidget(covariant TimesHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nextPrayer?.time != widget.nextPrayer?.time) {
      _syncCountdown();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncCountdown() {
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
    final tokens = context.prayerHomeTokens;
    final tr = widget.controller.tr;
    final current =
        widget.currentPrayer?.name ?? tr('Belum bermula', 'Belum bermula');
    final next = widget.nextPrayer;
    final currentTime = widget.currentPrayer == null
        ? '--:--'
        : DateFormat('HH:mm', _msLocale).format(widget.currentPrayer!.time);
    final nextText = next == null
        ? tr('Tiada waktu seterusnya', 'Tiada waktu seterusnya')
        : tr(
            'Seterusnya ${next.name} (${_formatShort(_remaining)})',
            'Seterusnya ${next.name} (${_formatShort(_remaining)})',
          );
    final checkedCurrent = widget.currentPrayer != null &&
        widget.controller.isPrayerCompletedToday(widget.currentPrayer!.name);

    final progress = _progressToNextPrayer(
      now: DateTime.now(),
      current: widget.currentPrayer,
      next: widget.nextPrayer,
    );

    final location = widget.controller.activeZone?.location ??
        tr('Lokasi belum ditentukan', 'Lokasi belum ditentukan');
    final freshness = widget.controller.prayerDataFreshnessLabel;

    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('Waktu Semasa', 'Waktu Semasa'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentTime,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFFF2D57D),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      nextText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFDDE7F7),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              _HeroCountdownRing(progress: progress, remaining: _remaining),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MetaChip(icon: Icons.place_outlined, label: location),
              _MetaChip(icon: Icons.bolt_outlined, label: freshness),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              AnimatedSwitcher(
                duration: tokens.fastAnim,
                child: checkedCurrent
                    ? Container(
                        key: const ValueKey<String>('checked-chip'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x263B516D),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Color(0xFFBFD0E8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tr('Sudah ditanda', 'Sudah ditanda'),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFFBFD0E8),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton.icon(
                        key: const ValueKey<String>('checkin'),
                        onPressed: widget.onCheckIn,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(tr('Tanda selesai', 'Tanda selesai')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
              ),
              const Spacer(),
              TextButton(
                onPressed: widget.onSnooze,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(tr('Tunda 5 min', 'Tunda 5 min')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progressToNextPrayer({
    required DateTime now,
    required PrayerTimeEntry? current,
    required PrayerTimeEntry? next,
  }) {
    if (next == null) {
      return 0;
    }
    final start = current?.time ?? DateTime(now.year, now.month, now.day);
    final total = next.time.difference(start).inSeconds;
    if (total <= 0) {
      return 0;
    }
    final elapsed = now.difference(start).inSeconds.clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}h ${m}m';
    }
    return '${m}m';
  }
}

class NextPrayerStrip extends StatelessWidget {
  const NextPrayerStrip({
    super.key,
    required this.controller,
    required this.nextPrayer,
  });

  final AppController controller;
  final PrayerTimeEntry? nextPrayer;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    final tr = controller.tr;
    final next = nextPrayer;
    if (next == null) {
      return const SizedBox.shrink();
    }
    final remaining = next.time.difference(DateTime.now());
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final text =
        '${tr('Seterusnya', 'Seterusnya')}: ${next.name} ${DateFormat('HH:mm', _msLocale).format(next.time)} • ${_formatShort(safe)}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF152745),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33567798)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 16, color: tokens.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFE7F0FF),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) {
      return '${h}j ${m}m';
    }
    return '${m}m';
  }
}

class TodayScheduleList extends StatefulWidget {
  const TodayScheduleList({
    super.key,
    required this.controller,
    required this.prayers,
    required this.currentPrayer,
    required this.nextPrayer,
    required this.onTapRow,
    required this.onLongPressRow,
  });

  final AppController controller;
  final List<PrayerTimeEntry> prayers;
  final PrayerTimeEntry? currentPrayer;
  final PrayerTimeEntry? nextPrayer;
  final Future<void> Function(PrayerTimeEntry, bool) onTapRow;
  final Future<void> Function(PrayerTimeEntry, bool) onLongPressRow;

  @override
  State<TodayScheduleList> createState() => _TodayScheduleListState();
}

class _TodayScheduleListState extends State<TodayScheduleList> {
  bool _showCompleted = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final tokens = context.prayerHomeTokens;
    final completedRows = widget.prayers.where((entry) {
      final done = controller.isPrayerCompletedToday(entry.name);
      final isCurrent = widget.currentPrayer?.name == entry.name;
      return done && !isCurrent;
    }).toList();
    final activeRows = widget.prayers.where((entry) {
      final done = controller.isPrayerCompletedToday(entry.name);
      final isCurrent = widget.currentPrayer?.name == entry.name;
      return isCurrent || !done;
    }).toList();
    final remaining =
        (controller.todayPrayerTargetCount - controller.todayPrayerCompletedCount)
            .clamp(0, controller.todayPrayerTargetCount);
    final streak = _prayerStreakDays(controller);
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr('Jadual Hari Ini', 'Jadual Hari Ini'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: tokens.baseAnim,
                child: Text(
                  '${controller.todayPrayerCompletedCount}/${controller.todayPrayerTargetCount}',
                  key: ValueKey<int>(controller.todayPrayerCompletedCount),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tokens.accent,
                        fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InsightChip(
                label: tr('Selesai', 'Selesai'),
                value:
                    '${controller.todayPrayerCompletedCount}/${controller.todayPrayerTargetCount}',
              ),
              _InsightChip(
                label: tr('Baki', 'Baki'),
                value: '$remaining',
              ),
              _InsightChip(
                label: tr('Streak', 'Streak'),
                value: '${streak}h',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: tokens.slowAnim,
            tween: Tween<double>(
              begin: 0,
              end: controller.todayPrayerProgress,
            ),
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: value.clamp(0.0, 1.0),
                  color: tokens.accent,
                  backgroundColor: const Color(0xFF2A3651),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Tekan untuk tandakan, tekan lama untuk undo.',
              'Tekan untuk tandakan, tekan lama untuk undo.',
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFBECDE2),
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (completedRows.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => setState(() => _showCompleted = !_showCompleted),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showCompleted
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      size: 18,
                      color: const Color(0xFFB9CAE2),
                    ),
                    Text(
                      _showCompleted
                          ? tr('Sembunyi selesai', 'Sembunyi selesai')
                          : tr(
                              'Tunjuk selesai (${completedRows.length})',
                              'Tunjuk selesai (${completedRows.length})',
                            ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: const Color(0xFFB9CAE2),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...activeRows.map((entry) => _buildRow(entry, controller, tr)),
          if (_showCompleted)
            ...completedRows.map((entry) => _buildRow(entry, controller, tr)),
        ],
      ),
    );
  }

  Widget _buildRow(
    PrayerTimeEntry entry,
    AppController controller,
    String Function(String, String) tr,
  ) {
    final done = controller.isPrayerCompletedToday(entry.name);
    final isCurrent = widget.currentPrayer?.name == entry.name;
    final isNext = widget.nextPrayer != null &&
        widget.nextPrayer!.name == entry.name &&
        _isSameDay(widget.nextPrayer!.time, entry.time);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _ScheduleRow(
        title: entry.name,
        subtitle: DateFormat('HH:mm', _msLocale).format(entry.time),
        isDone: done,
        isCurrent: isCurrent,
        isNext: isNext,
        statusLabel: isCurrent
            ? tr('SEMASA', 'SEMASA')
            : isNext
                ? tr('Seterusnya', 'Seterusnya')
                : done
                    ? tr('Selesai', 'Selesai')
                    : null,
        onTap: () => widget.onTapRow(entry, done),
        onLongPress: () => widget.onLongPressRow(entry, done),
      ),
    );
  }

  int _prayerStreakDays(AppController controller) {
    final target = controller.todayPrayerTargetCount;
    var streak = 0;
    var cursor = DateTime.now();
    while (true) {
      final key =
          '${cursor.year.toString().padLeft(4, '0')}-${cursor.month.toString().padLeft(2, '0')}-${cursor.day.toString().padLeft(2, '0')}';
      final doneCount = controller.prayerCheckinsByDate[key]?.length ?? 0;
      if (doneCount < target) {
        break;
      }
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class PinnedMiniHeader extends StatefulWidget {
  const PinnedMiniHeader({
    super.key,
    required this.controller,
    required this.currentPrayer,
    required this.nextPrayer,
  });

  final AppController controller;
  final PrayerTimeEntry? currentPrayer;
  final PrayerTimeEntry? nextPrayer;

  @override
  State<PinnedMiniHeader> createState() => _PinnedMiniHeaderState();
}

class _PinnedMiniHeaderState extends State<PinnedMiniHeader> {
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
  void didUpdateWidget(covariant PinnedMiniHeader oldWidget) {
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
    final tr = widget.controller.tr;
    final current =
        widget.currentPrayer?.name ?? tr('Belum bermula', 'Belum bermula');
    final next = widget.nextPrayer;
    final nextText = next == null
        ? tr('Tiada seterusnya', 'Tiada seterusnya')
        : '${next.name} ${DateFormat('HH:mm', _msLocale).format(next.time)} (${_formatCompact(_remaining)})';
    return Text(
      '$current • $nextText',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  String _formatCompact(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}j ${m}m';
    return '${m}m';
  }
}

class _HeroCountdownRing extends StatelessWidget {
  const _HeroCountdownRing({
    required this.progress,
    required this.remaining,
  });

  final double progress;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: tokens.baseAnim,
            tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
            builder: (context, value, _) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: const Color(0xFF2A3651),
                valueColor: AlwaysStoppedAnimation<Color>(tokens.accent),
              );
            },
          ),
          Text(
            '${remaining.inHours.toString().padLeft(2, '0')}\n${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textMuted,
                  height: 0.95,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x1F3E5575),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x2D5E7A9F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFC6D6EC)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFC6D6EC),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x193D5473),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x295A769C)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.labelMedium,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFFB8CAE3),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFFEAF3FF),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    required this.isNext,
    required this.statusLabel,
    required this.onTap,
    required this.onLongPress,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isNext;
  final String? statusLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    final visualDone = isDone && !isCurrent;
    final textColor =
        visualDone ? const Color(0xFFA8B8D3) : const Color(0xFFF0F6FF);
    final bg = isCurrent
        ? const Color(0xFF28446D)
        : isNext
            ? const Color(0xFF1A2D49)
            : visualDone
                ? const Color(0xFF16253E)
                : const Color(0xFF14233A);
    final stroke = isCurrent
        ? const Color(0x4DF4C542)
        : isNext
            ? const Color(0x335F7AA1)
            : visualDone
                ? const Color(0x223D5475)
            : const Color(0xFF14233A);
    final statusColor = isCurrent
        ? tokens.accent
        : visualDone
            ? const Color(0xFF8FA3C4)
            : const Color(0xFFAFC2DE);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: AnimatedContainer(
            duration: tokens.fastAnim,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: stroke, width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isNext ? tokens.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: visualDone ? 0.66 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                            ),
                            if (statusLabel != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x1AF4C542),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFB7C7DE),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: tokens.fastAnim,
                  child: Icon(
                    isCurrent
                        ? Icons.access_time_filled_rounded
                        : visualDone
                            ? Icons.check_circle_rounded
                            : isNext
                                ? Icons.schedule_rounded
                                : Icons.circle_outlined,
                    key: ValueKey<String>(
                      '${isCurrent}_${visualDone}_$isNext',
                    ),
                    size: visualDone ? 22 : 20,
                    color: isCurrent
                        ? const Color(0xFFF4C542)
                        : visualDone
                            ? tokens.accent
                            : const Color(0xFF7D93B7),
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

class _HomeCard extends StatelessWidget {
  const _HomeCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radius),
        border: Border.all(color: const Color(0x3A4F6486), width: 1),
        boxShadow: [tokens.shadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.cardPadding),
        child: child,
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SkeletonCard(height: 180),
        SizedBox(height: 16),
        _SkeletonCard(height: 320),
        SizedBox(height: 16),
        _SkeletonCard(height: 48),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(tokens.radius),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.topLeft,
          child: LinearProgressIndicator(minHeight: 4),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Data waktu belum tersedia.', 'Data waktu belum tersedia.'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Tarik ke bawah untuk cuba semula.',
              'Tarik ke bawah untuk cuba semula.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: controller.refreshPrayerData,
            child: Text(tr('Muat semula', 'Muat semula')),
          ),
        ],
      ),
    );
  }
}

class _HomeErrorCard extends StatelessWidget {
  const _HomeErrorCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.errorMessage ??
                tr('Ralat tidak diketahui.', 'Ralat tidak diketahui.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFD7D7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: controller.refreshPrayerData,
                icon: const Icon(Icons.refresh),
                label: Text(tr('Cuba semula', 'Cuba semula')),
              ),
              if (controller.errorActionLabel != null)
                OutlinedButton(
                  onPressed: controller.runErrorAction,
                  child: Text(controller.errorActionLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
