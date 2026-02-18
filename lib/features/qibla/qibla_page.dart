import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../state/app_controller.dart';
import 'qibla_tokens.dart';

enum AccuracyStatus { low, good }

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return QiblaScreen(controller: controller);
  }
}

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  StreamSubscription<CompassEvent>? _compassSub;
  bool isActive = true;
  bool isCalibrating = false;
  DateTime? lastHapticTime;
  DateTime? _lastUpdated;
  double? _heading;

  @override
  void initState() {
    super.initState();
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted || !isActive) {
        return;
      }
      final heading = event.heading;
      if (heading == null) {
        return;
      }
      setState(() {
        _heading = heading;
        _lastUpdated = DateTime.now();
      });
      _tryHapticAlign();
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.controller.tr;
    final qibla = widget.controller.qiblaBearing;
    final location = widget.controller.activeZone?.location ??
        tr('Lokasi tidak diketahui', 'Unknown location');
    final hasQibla = qibla != null;

    final delta = (!hasQibla || _heading == null)
        ? 180.0
        : _normalizeDelta(qibla - _heading!).abs();
    final accuracy = delta <= 20 ? AccuracyStatus.good : AccuracyStatus.low;

    final rotationTurns =
        (!hasQibla || _heading == null) ? 0.0 : (qibla - _heading!) / 360;
    final statusText = isActive ? tr('Aktif', 'Active') : tr('Jeda', 'Paused');
    final gpsText = hasQibla
        ? tr('GPS tersedia', 'GPS ready')
        : tr('GPS tidak tersedia', 'GPS unavailable');

    return Scaffold(
      backgroundColor: QiblaTokens.matteBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 96,
        titleSpacing: QiblaTokens.s16,
        title: _QiblaAppBarTitle(
          title: widget.controller.t('page_title_qibla'),
          subtitle: '$location • $gpsText',
          isActive: isActive,
          statusText: statusText,
        ),
        actions: [
          TextButton(
            onPressed: hasQibla
                ? () {
                    setState(() {
                      isActive = !isActive;
                    });
                  }
                : null,
            style: TextButton.styleFrom(
              minimumSize: const Size(64, 44),
            ),
            child: Text(isActive ? tr('Stop', 'Stop') : tr('Start', 'Start')),
          ),
          const SizedBox(width: QiblaTokens.s8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final heroSize = (math.min(
                    size.width - (QiblaTokens.s24 * 2), size.height * 0.56))
                .clamp(260.0, 420.0);

            return Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        QiblaTokens.s24,
                        QiblaTokens.s16,
                        QiblaTokens.s24,
                        260,
                      ),
                      child: CompassHero(
                        size: heroSize,
                        turns: rotationTurns,
                        isActive: isActive,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: QiblaInfoSheet(
                    controller: widget.controller,
                    qiblaDegrees: qibla,
                    heading: _heading,
                    delta: delta,
                    isCalibrating: isCalibrating,
                    accuracy: accuracy,
                    lastUpdated: _lastUpdated,
                    onPrimaryAction: hasQibla
                        ? () async {
                            if (accuracy == AccuracyStatus.low) {
                              await _calibrate();
                              return;
                            }
                            await _recenter();
                          }
                        : null,
                    onViewTips: _showCalibrationTips,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    await HapticFeedback.selectionClick();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.controller.tr(
            'Kompas dipusatkan semula.',
            'Compass recentered.',
          ),
        ),
      ),
    );
  }

  Future<void> _calibrate() async {
    if (isCalibrating) {
      return;
    }
    setState(() {
      isCalibrating = true;
    });
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) {
      return;
    }
    setState(() {
      isCalibrating = false;
    });
    await _showCalibrationTips();
  }

  Future<void> _showCalibrationTips() async {
    final tr = widget.controller.tr;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: QiblaTokens.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QiblaTokens.radius + 4),
        ),
      ),
      builder: (context) {
        return CalibrationTipsSheet(
          title: tr('Calibration tips', 'Calibration tips'),
          points: [
            tr(
              'Pegang telefon dalam posisi rata.',
              'Hold your phone flat.',
            ),
            tr(
              'Gerakkan telefon bentuk angka 8, 5-10 kali.',
              'Move your phone in an 8-shape, 5-10 times.',
            ),
            tr(
              'Jauhkan dari magnet atau casing bermagnet.',
              'Keep away from magnets or magnetic cases.',
            ),
            tr(
              'Tunggu bacaan stabil sebelum ikut arah.',
              'Wait for stable readings before following direction.',
            ),
          ],
          closeLabel: tr('Tutup', 'Close'),
        );
      },
    );
  }

  void _tryHapticAlign() {
    final qibla = widget.controller.qiblaBearing;
    final heading = _heading;
    if (!isActive || qibla == null || heading == null) {
      return;
    }
    final aligned = _normalizeDelta(qibla - heading).abs() <= 3;
    if (!aligned) {
      return;
    }
    final now = DateTime.now();
    final last = lastHapticTime;
    if (last != null && now.difference(last).inSeconds < 3) {
      return;
    }
    lastHapticTime = now;
    HapticFeedback.selectionClick();
  }
}

class _QiblaAppBarTitle extends StatelessWidget {
  const _QiblaAppBarTitle({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.statusText,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 40,
                height: 1.0,
              ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: QiblaTokens.textMuted,
                    ),
              ),
            ),
            const SizedBox(width: QiblaTokens.s8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: QiblaTokens.sheetBgSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF19D26D)
                          : const Color(0xFF8A9CB8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFDCE7F8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CompassHero extends StatelessWidget {
  const CompassHero({
    super.key,
    required this.size,
    required this.turns,
    required this.isActive,
  });

  final double size;
  final double turns;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Qibla compass',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: _CompassRingPainter(),
            ),
            AnimatedOpacity(
              opacity: isActive ? 1 : 0.55,
              duration: const Duration(milliseconds: 180),
              child: AnimatedRotation(
                turns: turns,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: Icon(
                  Icons.navigation_rounded,
                  size: size * 0.34,
                  color: QiblaTokens.accent,
                ),
              ),
            ),
            const _DirectionLabel(text: 'N', alignment: Alignment.topCenter),
            const _DirectionLabel(text: 'E', alignment: Alignment.centerRight),
            const _DirectionLabel(text: 'S', alignment: Alignment.bottomCenter),
            const _DirectionLabel(text: 'W', alignment: Alignment.centerLeft),
          ],
        ),
      ),
    );
  }
}

class QiblaInfoSheet extends StatelessWidget {
  const QiblaInfoSheet({
    super.key,
    required this.controller,
    required this.qiblaDegrees,
    required this.heading,
    required this.delta,
    required this.isCalibrating,
    required this.accuracy,
    required this.lastUpdated,
    required this.onPrimaryAction,
    required this.onViewTips,
  });

  final AppController controller;
  final double? qiblaDegrees;
  final double? heading;
  final double delta;
  final bool isCalibrating;
  final AccuracyStatus accuracy;
  final DateTime? lastUpdated;
  final VoidCallback? onPrimaryAction;
  final VoidCallback onViewTips;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final hasData = qiblaDegrees != null;
    final degreeText = hasData ? '${qiblaDegrees!.round()}°' : '--';
    final badgeLabel =
        accuracy == AccuracyStatus.low ? tr('Low', 'Low') : tr('Good', 'Good');
    final badgeBg = accuracy == AccuracyStatus.low
        ? const Color(0xFF3A2D2A)
        : const Color(0xFF1E4036);
    final badgeFg = accuracy == AccuracyStatus.low
        ? const Color(0xFFFFC5B8)
        : const Color(0xFFA8E8D0);
    final helper = accuracy == AccuracyStatus.low
        ? tr('Kalibrasi disyorkan', 'Calibration recommended')
        : tr('Arah stabil', 'Direction stable');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        QiblaTokens.s16,
        QiblaTokens.s16,
        QiblaTokens.s16,
        QiblaTokens.s16,
      ),
      decoration: const BoxDecoration(
        color: QiblaTokens.sheetBg,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(QiblaTokens.radius + 4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              degreeText,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${tr('Accuracy', 'Accuracy')}: $badgeLabel',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: badgeFg,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              helper,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QiblaTokens.textMuted,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            child: !hasData
                ? const SizedBox.shrink()
                : isCalibrating
                    ? SizedBox(
                        key: const ValueKey<String>('calibrating'),
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Text(tr('Calibrating...', 'Calibrating...')),
                          ],
                        ),
                      )
                    : SizedBox(
                        key: ValueKey<String>('cta-${accuracy.name}'),
                        width: double.infinity,
                        child: accuracy == AccuracyStatus.low
                            ? FilledButton(
                                onPressed: onPrimaryAction,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: Text(tr('Calibrate', 'Calibrate')),
                              )
                            : OutlinedButton(
                                onPressed: onPrimaryAction,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                ),
                                child: Text(tr('Recenter', 'Recenter')),
                              ),
                      ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onViewTips,
              style: TextButton.styleFrom(
                minimumSize: const Size(88, 44),
              ),
              child: Text(tr('View tips', 'View tips')),
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 8),
              title: Text(
                controller.t('qibla_details'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFDCE7F8),
                    ),
              ),
              children: [
                _DetailRow(
                  label: tr('Current heading', 'Current heading'),
                  value: heading == null
                      ? '--'
                      : '${heading!.toStringAsFixed(0)}°',
                ),
                _DetailRow(
                  label: tr('Error', 'Error'),
                  value:
                      heading == null ? '--' : '${delta.toStringAsFixed(0)}°',
                ),
                _DetailRow(
                  label: tr('Last updated', 'Last updated'),
                  value: lastUpdated == null
                      ? '--'
                      : '${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')}:${lastUpdated!.second.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalibrationTipsSheet extends StatelessWidget {
  const CalibrationTipsSheet({
    super.key,
    required this.title,
    required this.points,
    required this.closeLabel,
  });

  final String title;
  final List<String> points;
  final String closeLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QiblaTokens.s24,
        QiblaTokens.s16,
        QiblaTokens.s24,
        QiblaTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: QiblaTokens.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: QiblaTokens.s16),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: QiblaTokens.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFCFDBEE),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(88, 44),
              ),
              child: Text(closeLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: QiblaTokens.textMuted,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DirectionLabel extends StatelessWidget {
  const _DirectionLabel({
    required this.text,
    required this.alignment,
  });

  final String text;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: QiblaTokens.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CompassRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = const Color(0xFF334664);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF2A3C58);

    canvas.drawCircle(center, radius - 2, outer);
    canvas.drawCircle(center, radius * 0.78, inner);

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF3B506F);

    for (var i = 0; i < 4; i++) {
      final angle = (math.pi / 2) * i;
      final start = Offset(
        center.dx + math.cos(angle) * (radius - 12),
        center.dy + math.sin(angle) * (radius - 12),
      );
      final end = Offset(
        center.dx + math.cos(angle) * (radius - 2),
        center.dy + math.sin(angle) * (radius - 2),
      );
      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double _normalizeDelta(double value) {
  var result = value % 360;
  if (result > 180) {
    result -= 360;
  } else if (result < -180) {
    result += 360;
  }
  return result;
}
