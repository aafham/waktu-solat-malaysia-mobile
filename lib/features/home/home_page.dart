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
    required this.onNavigateToTab,
  });

  final AppController controller;
  final ValueChanged<int> onNavigateToTab;

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
                              tr('Waktu Solat', 'Prayer Times'),
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(height: tokens.grid / 2),
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
                            SizedBox(height: tokens.sectionGap),
                            TodayScheduleList(
                              controller: controller,
                              prayers: prayers,
                              currentPrayer: currentPrayer,
                              nextPrayer: nextPrayer,
                              onTapRow: _onPrayerRowTap,
                              onLongPressRow: _onPrayerRowLongPress,
                            ),
                            SizedBox(height: tokens.sectionGap),
                            QuickActionChipsRow(
                              controller: controller,
                              onOpenQibla: () => widget.onNavigateToTab(1),
                              onOpenTasbih: () => widget.onNavigateToTab(2),
                              onOpenCalendar: () =>
                                  _showCalendarSheet(allPrayers),
                              onOpenMore: () => widget.onNavigateToTab(3),
                            ),
                          ],
                        ),
            ),
          ),
        ],
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
            'Prayer check-in completed.',
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
            'Long press to undo.',
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
          title: Text(tr('Undo check-in?', 'Undo check-in?')),
          content: Text(
            tr(
              'Rekod ${entry.name} akan ditanda belum selesai.',
              '${entry.name} will be marked as not completed.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(tr('Batal', 'Cancel')),
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

  Future<void> _showCalendarSheet(List<PrayerTimeEntry> entries) async {
    final tr = widget.controller.tr;
    final locale = widget.controller.isEnglish ? 'en_US' : _msLocale;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A243D),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('Jadual Hari Ini', 'Today Schedule'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', locale)
                      .format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.prayerHomeTokens.textMuted,
                      ),
                ),
                const SizedBox(height: 12),
                if (entries.isEmpty)
                  Text(tr('Tiada data tersedia.', 'No data available.'))
                else
                  ...entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(entry.name)),
                          Text(DateFormat('HH:mm', _msLocale)
                              .format(entry.time)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
        widget.currentPrayer?.name ?? tr('Belum bermula', 'Not started');
    final next = widget.nextPrayer;
    final nextText = next == null
        ? tr('Tiada waktu seterusnya', 'No next prayer')
        : tr(
            'Seterusnya ${next.name} (${_formatShort(_remaining)})',
            'Next ${next.name} (${_formatShort(_remaining)})',
          );
    final checkedCurrent = widget.currentPrayer != null &&
        widget.controller.isPrayerCompletedToday(widget.currentPrayer!.name);

    final progress = _progressToNextPrayer(
      now: DateTime.now(),
      current: widget.currentPrayer,
      next: widget.nextPrayer,
    );

    final location = widget.controller.activeZone?.location ??
        tr('Lokasi belum ditentukan', 'Location unavailable');
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
                      tr('Waktu Semasa', 'Current Prayer'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFFDDE7F7),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              _HeroCountdownRing(progress: progress, remaining: _remaining),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$location  •  $freshness',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tokens.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AnimatedSwitcher(
                duration: tokens.fastAnim,
                child: checkedCurrent
                    ? FilledButton.tonalIcon(
                        key: const ValueKey<String>('checked'),
                        onPressed: null,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(tr('Selesai', 'Done')),
                      )
                    : FilledButton.icon(
                        key: const ValueKey<String>('checkin'),
                        onPressed: widget.onCheckIn,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(tr('Check-in', 'Check-in')),
                      ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: widget.onSnooze,
                child: Text(tr('Tunda 5 min', 'Snooze 5 min')),
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

class TodayScheduleList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final tokens = context.prayerHomeTokens;
    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tr('Jadual Hari Ini', 'Today Schedule'),
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
                  minHeight: 5,
                  value: value.clamp(0.0, 1.0),
                  color: tokens.accent,
                  backgroundColor: const Color(0xFF2A3651),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          ...prayers.map((entry) {
            final done = controller.isPrayerCompletedToday(entry.name);
            final isCurrent = currentPrayer?.name == entry.name;
            final isNext = nextPrayer != null &&
                nextPrayer!.name == entry.name &&
                _isSameDay(nextPrayer!.time, entry.time);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ScheduleRow(
                title: entry.name,
                subtitle: DateFormat('HH:mm', _msLocale).format(entry.time),
                isDone: done,
                isCurrent: isCurrent,
                isNext: isNext,
                onTap: () => onTapRow(entry, done),
                onLongPress: () => onLongPressRow(entry, done),
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class QuickActionChipsRow extends StatelessWidget {
  const QuickActionChipsRow({
    super.key,
    required this.controller,
    required this.onOpenQibla,
    required this.onOpenTasbih,
    required this.onOpenCalendar,
    required this.onOpenMore,
  });

  final AppController controller;
  final VoidCallback onOpenQibla;
  final VoidCallback onOpenTasbih;
  final VoidCallback onOpenCalendar;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final tokens = context.prayerHomeTokens;

    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
    }) {
      return ActionChip(
        onPressed: onTap,
        avatar: Icon(icon, size: 18, color: const Color(0xFFC7D5EE)),
        label: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFFEAF1FF),
              ),
        ),
        side: BorderSide.none,
        backgroundColor: tokens.surfaceMuted,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(
          icon: Icons.explore_outlined,
          label: tr('Qibla', 'Qibla'),
          onTap: onOpenQibla,
        ),
        chip(
          icon: Icons.touch_app_outlined,
          label: tr('Tasbih', 'Tasbih'),
          onTap: onOpenTasbih,
        ),
        chip(
          icon: Icons.calendar_month_outlined,
          label: tr('Kalendar', 'Calendar'),
          onTap: onOpenCalendar,
        ),
        chip(
          icon: Icons.more_horiz,
          label: tr('Lagi', 'More'),
          onTap: onOpenMore,
        ),
      ],
    );
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
        widget.currentPrayer?.name ?? tr('Belum bermula', 'Not started');
    final next = widget.nextPrayer;
    final nextText = next == null
        ? tr('Tiada waktu seterusnya', 'No next prayer')
        : tr(
            'Next ${next.name} ${DateFormat('HH:mm', _msLocale).format(next.time)} (${_formatShort(_remaining)})',
            'Next ${next.name} ${DateFormat('HH:mm', _msLocale).format(next.time)} (${_formatShort(_remaining)})',
          );
    return Text(
      '$current - $nextText',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }

  String _formatShort(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
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

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isCurrent,
    required this.isNext,
    required this.onTap,
    required this.onLongPress,
  });

  final String title;
  final String subtitle;
  final bool isDone;
  final bool isCurrent;
  final bool isNext;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prayerHomeTokens;
    final textColor =
        isDone ? const Color(0xFF9FAFCC) : const Color(0xFFEAF2FF);
    final bg = isCurrent
        ? const Color(0xFF243454)
        : isDone
            ? const Color(0xFF18243D)
            : tokens.surfaceMuted;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isNext ? tokens.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Opacity(
                    opacity: isDone ? 0.76 : 1,
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
                            if (isCurrent) ...[
                              const SizedBox(width: 8),
                              Text(
                                'NOW',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: tokens.accent,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textMuted,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: tokens.fastAnim,
                  child: Icon(
                    isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                    key: ValueKey<bool>(isDone),
                    size: isDone ? 22 : 18,
                    color: isDone ? tokens.accent : const Color(0xFF7187AB),
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
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.cardPadding - 2),
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
            tr('Data waktu belum tersedia.', 'Prayer times are unavailable.'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            tr(
              'Tarik ke bawah untuk cuba semula.',
              'Pull down to refresh and try again.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: controller.refreshPrayerData,
            child: Text(tr('Muat semula', 'Reload')),
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
                tr('Ralat tidak diketahui.', 'Unknown error.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFFFD7D7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: controller.refreshPrayerData,
                icon: const Icon(Icons.refresh),
                label: Text(tr('Cuba semula', 'Try again')),
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
