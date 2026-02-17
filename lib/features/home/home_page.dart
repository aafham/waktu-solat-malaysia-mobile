import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/prayer_models.dart';
import '../../state/app_controller.dart';
import '../../theme/app_tokens.dart';
import 'history_page.dart';

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
                              if (controller.todayHijriHeaderLabel != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  controller.todayHijriHeaderLabel!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: tokens.textMuted.withValues(
                                          alpha: 0.86,
                                        ),
                                      ),
                                ),
                              ],
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
          content: Text(widget.controller.t('times_checkin_success')),
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
          title: Text(tr('Batal check-in?', 'Undo check-in?')),
          content: Text(
            tr(
              'Rekod ${entry.name} akan ditanda belum selesai.',
              '${widget.controller.displayPrayerName(entry.name)} will be marked as not completed.',
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
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
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
    final displayPrayer = widget.currentPrayer ?? widget.nextPrayer;
    final now = DateTime.now();
    final current = displayPrayer == null
        ? tr('Belum bermula', 'Not started')
        : widget.controller.displayPrayerName(displayPrayer.name);
    final currentTime = displayPrayer == null
        ? '--:--'
        : DateFormat(
            'HH:mm',
            widget.controller.isEnglish ? 'en_US' : _msLocale,
          ).format(displayPrayer.time);
    final checkedCurrent = widget.currentPrayer != null &&
        widget.controller.isPrayerCompletedToday(widget.currentPrayer!.name);
    final canCheckIn = widget.currentPrayer != null;
    final remainingText = _formatRemaining(_remaining);
    final countdownCaption = _countdownCaption();

    final location = widget.controller.activeZone?.location ??
        tr('Lokasi belum ditentukan', 'Location unavailable');
    final statusMeta = _compactMeta(location);
    final checkInHelper = _checkInHelper(now);

    return _HomeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('Waktu Seterusnya', 'NEXT PRAYER'),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  current,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                ),
                const SizedBox(width: 10),
                Text(
                  currentTime,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: const Color(0xFFF2D57D),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NextPrayerCountdownText(
            remainingText: remainingText,
            caption: countdownCaption,
          ),
          const SizedBox(height: 12),
          _MetaChip(icon: Icons.place_outlined, label: statusMeta),
          const SizedBox(height: 16),
          Row(
            children: [
              AnimatedSwitcher(
                duration: tokens.fastAnim,
                child: !canCheckIn
                    ? _HeroStatusPill(
                        key: const ValueKey<String>('checkin-disabled'),
                        icon: Icons.schedule_rounded,
                        label: _checkInNextPrayerLabel(),
                      )
                    : checkedCurrent
                        ? _HeroStatusPill(
                            key: const ValueKey<String>('checked-chip'),
                            icon: Icons.check_circle_rounded,
                            label: tr('Sudah ditanda', 'Marked'),
                          )
                        : FilledButton.icon(
                            key: const ValueKey<String>('checkin'),
                            onPressed: widget.onCheckIn,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: Text(tr('Tanda selesai', 'Mark done')),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onSnooze,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                icon: const Icon(Icons.snooze_outlined, size: 18),
                label: Text(widget.controller.t('times_snooze_5')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            checkInHelper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFFAFBFDA),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _countdownCaption() {
    final tr = widget.controller.tr;
    if (widget.nextPrayer?.name == 'Imsak') {
      return tr('Sebelum Subuh bermula', 'Before Subuh begins');
    }
    return widget.controller.t('times_before_next');
  }

  String _checkInHelper(DateTime now) {
    final tr = widget.controller.tr;
    final current = widget.currentPrayer;
    if (current != null && !current.time.isAfter(now)) {
      return tr('Check-in tersedia sekarang', 'Check-in available now');
    }
    final next = widget.nextPrayer;
    if (next != null && now.isBefore(next.time)) {
      final name = widget.controller.displayPrayerName(next.name);
      return tr('Check-in bila $name bermula', 'Check-in when $name begins');
    }
    return tr('Check-in tersedia sekarang', 'Check-in available now');
  }

  String _checkInNextPrayerLabel() {
    final tr = widget.controller.tr;
    final next = widget.nextPrayer;
    if (next == null) {
      return tr('Belum tersedia', 'Not available yet');
    }
    final name = widget.controller.displayPrayerName(next.name);
    return tr('Check-in bila $name bermula', 'Check-in when $name begins');
  }

  String _compactMeta(String location) {
    final tr = widget.controller.tr;
    final source = switch (widget.controller.lastPrayerDataSource) {
      'cache' => tr('Simpanan', 'Cache'),
      'local_calc' => tr('Tempatan', 'Local'),
      _ => tr('Langsung', 'Live'),
    };
    final updatedAt = widget.controller.lastPrayerDataUpdatedAt;
    final when = updatedAt == null
        ? tr('kini', 'now')
        : (() {
            final age = DateTime.now().difference(updatedAt);
            if (age.inMinutes <= 0) {
              return tr('kini', 'now');
            }
            return '${age.inMinutes}m';
          })();
    return '$location • $source • $when';
  }

  String _formatRemaining(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final h = safe.inHours;
    final m = safe.inMinutes.remainder(60);
    final tr = widget.controller.tr;
    final hourLabel = widget.controller.isEnglish
        ? (h == 1 ? 'hour' : 'hours')
        : tr('jam', 'hours');
    final minuteLabel = widget.controller.isEnglish
        ? (m == 1 ? 'minute' : 'minutes')
        : tr('minit', 'minutes');
    return '$h $hourLabel $m $minuteLabel';
  }
}

class NextPrayerCountdownText extends StatelessWidget {
  const NextPrayerCountdownText({
    super.key,
    required this.remainingText,
    required this.caption,
  });

  final String remainingText;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          remainingText,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: const Color(0xFFEAF3FF),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFAFBFDA),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _HeroStatusPill extends StatelessWidget {
  const _HeroStatusPill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0x263B516D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFFBFD0E8),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFFBFD0E8),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
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
    final remaining = (controller.todayPrayerTargetCount -
            controller.todayPrayerCompletedCount)
        .clamp(0, controller.todayPrayerTargetCount);
    final streak = _prayerStreakDays(controller);
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
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => HistoryPage(controller: controller),
                  ),
                ),
                icon: const Icon(Icons.history_outlined, size: 16),
                label: Text(controller.t('history_title')),
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 32),
                  visualDensity: VisualDensity.compact,
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
                label: tr('Selesai', 'Done'),
                value:
                    '${controller.todayPrayerCompletedCount}/${controller.todayPrayerTargetCount}',
              ),
              _InsightChip(
                label: tr('Baki', 'Remaining'),
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
            controller.t('times_tap_to_mark'),
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
                          ? tr('Sembunyi selesai', 'Hide completed')
                          : tr(
                              'Tunjuk selesai (${completedRows.length})',
                              'Show completed (${completedRows.length})',
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
        title: controller.displayPrayerName(entry.name),
        subtitle: DateFormat('HH:mm', _msLocale).format(entry.time),
        isDone: done,
        isCurrent: isCurrent,
        isNext: isNext,
        statusLabel: isCurrent
            ? tr('SEMASA', 'NOW')
            : done
                ? tr('Selesai', 'Done')
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
      constraints: const BoxConstraints(maxWidth: 320),
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
                            if (isNext && !isCurrent) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8FD8FF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 7),
                            ],
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
            tr('Data waktu belum tersedia.', 'Prayer times are unavailable.'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.t('times_pull_refresh'),
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
          const SizedBox(height: 12),
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
