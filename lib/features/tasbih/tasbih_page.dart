import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';
import 'tasbih_tokens.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return TasbihScreen(controller: controller);
  }
}

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  bool _pressed = false;
  String? _milestoneLabel;
  Timer? _milestoneTimer;
  double _pulseGlow = 0;

  @override
  void dispose() {
    _milestoneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final tr = controller.tr;
    final count = controller.tasbihCount;
    final target =
        controller.tasbihCycleTarget <= 0 ? 33 : controller.tasbihCycleTarget;
    final cycle = count ~/ target;
    final inCycle = count % target;
    final progress = target == 0 ? 0.0 : (inCycle / target).clamp(0.0, 1.0);
    final selectedSegment = _selectedTargetValue(target);

    return SafeArea(
      child: Container(
        color: TasbihTokens.matteBg,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TasbihTokens.s24,
                TasbihTokens.s16,
                TasbihTokens.s24,
                TasbihTokens.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('Digital Tasbih', 'Digital Tasbih'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'Target: $target • Pusingan: $cycle',
                      'Target: $target • Cycle: $cycle',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TasbihTokens.textMuted,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(
                      'Hari ini ${controller.tasbihTodayCount} • Jumlah ${controller.tasbihLifetimeCount}',
                      'Today ${controller.tasbihTodayCount} • Total ${controller.tasbihLifetimeCount}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TasbihTokens.textMuted,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final heroSize = math
                      .min(
                        constraints.maxWidth - (TasbihTokens.s24 * 2),
                        constraints.maxHeight * 0.72,
                      )
                      .clamp(260.0, 420.0);

                  return Column(
                    children: [
                      const SizedBox(height: TasbihTokens.s8),
                      MilestoneBanner(
                        controller: controller,
                        label: _milestoneLabel,
                      ),
                      const SizedBox(height: TasbihTokens.s8),
                      Expanded(
                        child: Center(
                          child: TasbihHeroDial(
                            size: heroSize,
                            count: count,
                            inCycle: inCycle,
                            target: target,
                            progress: progress,
                            pressed: _pressed,
                            glow: _pulseGlow,
                            controller: controller,
                            onTap: _handleTap,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            TasbihControlPanel(
              controller: controller,
              selectedTarget: selectedSegment,
              onSelectTarget: (value) => _handleTargetSelection(value),
              onUndo: count > 0 ? _handleUndo : null,
              onReset: count > 0 ? _confirmReset : null,
              onQuickAdd: (amount) => _quickAdd(amount),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedTargetValue(int target) {
    if (target == 33 || target == 99) {
      return target;
    }
    return -1;
  }

  Future<void> _handleTap() async {
    final controller = widget.controller;
    final before = controller.tasbihCount;
    setState(() {
      _pressed = true;
    });
    await HapticFeedback.selectionClick();
    await controller.incrementTasbih();
    final after = controller.tasbihCount;
    _checkMilestone(before: before, after: after);
    await Future<void>.delayed(TasbihTokens.tapScaleIn);
    if (!mounted) return;
    setState(() {
      _pressed = false;
    });
  }

  Future<void> _handleUndo() async {
    await HapticFeedback.selectionClick();
    await widget.controller.decrementTasbih();
  }

  Future<void> _quickAdd(int amount) async {
    final before = widget.controller.tasbihCount;
    await widget.controller.addTasbihBatch(amount);
    await HapticFeedback.selectionClick();
    final after = widget.controller.tasbihCount;
    _checkMilestone(before: before, after: after);
  }

  Future<void> _handleTargetSelection(int value) async {
    if (value == -1) {
      await _showCustomTargetInput();
      return;
    }
    await widget.controller.setTasbihCycleTarget(value);
  }

  Future<void> _showCustomTargetInput() async {
    final tr = widget.controller.tr;
    final input = TextEditingController(
      text: widget.controller.tasbihCycleTarget.toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tr('Target Tersuai', 'Custom target')),
          content: TextField(
            controller: input,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: tr('Contoh: 100', 'Example: 100'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Batal', 'Cancel')),
            ),
            FilledButton(
              onPressed: () {
                final parsed = int.tryParse(input.text.trim());
                if (parsed == null || parsed < 1) {
                  return;
                }
                Navigator.pop(context, parsed);
              },
              child: Text(tr('Simpan', 'Save')),
            ),
          ],
        );
      },
    );
    if (value != null && value >= 1) {
      await widget.controller.setTasbihCycleTarget(value);
    }
  }

  Future<void> _confirmReset() async {
    final tr = widget.controller.tr;
    final reset = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: TasbihTokens.controlPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TasbihTokens.radius + 6),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            TasbihTokens.s24,
            TasbihTokens.s16,
            TasbihTokens.s24,
            TasbihTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('Reset kiraan?', 'Reset count?'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'Kiraan semasa akan kembali ke 0.',
                  'Current count will reset to 0.',
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(tr('Batal', 'Cancel')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(tr('Reset', 'Reset')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
    if (reset == true) {
      await HapticFeedback.lightImpact();
      await widget.controller.resetTasbih();
      if (!mounted) return;
      setState(() {
        _milestoneLabel = null;
      });
    }
  }

  void _checkMilestone({required int before, required int after}) {
    final target = widget.controller.tasbihCycleTarget <= 0
        ? 33
        : widget.controller.tasbihCycleTarget;
    final beforeCycle = before % target;
    final afterCycle = after % target;
    final hitTarget = afterCycle == 0 && after > 0;
    final hit33 = before < 33 && after >= 33;
    final hit66 = before < 66 && after >= 66;
    final hit99 = before < 99 && after >= 99;

    String? label;
    if (hitTarget) {
      label = widget.controller.tr(
        'Target capai: $target',
        'Target reached: $target',
      );
    } else if (hit99) {
      label = '99';
    } else if (hit66) {
      label = '66';
    } else if (hit33) {
      label = '33';
    }

    if (label == null || beforeCycle == afterCycle) {
      return;
    }

    HapticFeedback.lightImpact();
    _milestoneTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _milestoneLabel = label;
      _pulseGlow = 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 240), () {
      if (!mounted) return;
      setState(() {
        _pulseGlow = 0;
      });
    });
    _milestoneTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _milestoneLabel = null;
      });
    });
  }
}

class TasbihHeroDial extends StatelessWidget {
  const TasbihHeroDial({
    super.key,
    required this.size,
    required this.count,
    required this.inCycle,
    required this.target,
    required this.progress,
    required this.pressed,
    required this.glow,
    required this.controller,
    required this.onTap,
  });

  final double size;
  final int count;
  final int inCycle;
  final int target;
  final double progress;
  final bool pressed;
  final double glow;
  final AppController controller;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return Semantics(
      button: true,
      label: tr('Tambah kiraan tasbih', 'Increase tasbih count'),
      child: AnimatedScale(
        scale: pressed ? 1.03 : 1.0,
        duration: pressed ? TasbihTokens.tapScaleIn : TasbihTokens.tapScaleOut,
        curve: Curves.easeOut,
        child: InkResponse(
          onTap: onTap,
          radius: size / 2,
          splashColor: TasbihTokens.accent.withValues(alpha: 0.24),
          highlightShape: BoxShape.circle,
          child: AnimatedContainer(
            duration: TasbihTokens.milestoneAnim,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: TasbihTokens.panelSoft,
              boxShadow: [
                BoxShadow(
                  color: TasbihTokens.accent.withValues(alpha: 0.14 * glow),
                  blurRadius: 30 + (8 * glow),
                  spreadRadius: 2 + (4 * glow),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CustomPaint(
                    painter: _TasbihRingPainter(progress: progress),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$inCycle / $target',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: TasbihTokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).round()}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TasbihTokens.textMuted,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tr('Tap anywhere', 'Tap anywhere'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: TasbihTokens.textMuted,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TasbihControlPanel extends StatelessWidget {
  const TasbihControlPanel({
    super.key,
    required this.controller,
    required this.selectedTarget,
    required this.onSelectTarget,
    required this.onUndo,
    required this.onReset,
    required this.onQuickAdd,
  });

  final AppController controller;
  final int selectedTarget;
  final ValueChanged<int> onSelectTarget;
  final VoidCallback? onUndo;
  final VoidCallback? onReset;
  final ValueChanged<int> onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        TasbihTokens.s16,
        TasbihTokens.s16,
        TasbihTokens.s16,
        TasbihTokens.s16,
      ),
      decoration: const BoxDecoration(
        color: TasbihTokens.controlPanel,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(TasbihTokens.radius + 4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<int>(value: 33, label: Text(tr('33', '33'))),
              ButtonSegment<int>(value: 99, label: Text(tr('99', '99'))),
              ButtonSegment<int>(
                  value: -1, label: Text(tr('Custom', 'Custom'))),
            ],
            selected: <int>{selectedTarget},
            onSelectionChanged: (value) => onSelectTarget(value.first),
          ),
          const SizedBox(height: TasbihTokens.s8),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onUndo,
                tooltip: tr('Undo', 'Undo'),
                icon: const Icon(Icons.undo_rounded),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: onReset,
                tooltip: tr('Reset', 'Reset'),
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: TasbihTokens.s8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                onPressed: () => onQuickAdd(10),
                label: const Text('+10'),
              ),
              ActionChip(
                onPressed: () => onQuickAdd(33),
                label: const Text('+33'),
              ),
              ActionChip(
                onPressed: () => onQuickAdd(99),
                label: const Text('+99'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MilestoneBanner extends StatelessWidget {
  const MilestoneBanner({
    super.key,
    required this.controller,
    required this.label,
  });

  final AppController controller;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: TasbihTokens.milestoneAnim,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      child: label == null
          ? const SizedBox(height: 28, width: 1)
          : Container(
              key: ValueKey<String>(label!),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: TasbihTokens.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                controller.tr(
                  'Milestone capai: $label',
                  'Milestone reached: $label',
                ),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TasbihTokens.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
    );
  }
}

class _TasbihRingPainter extends CustomPainter {
  _TasbihRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide / 2) - 14;
    const stroke = 14.0;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = TasbihTokens.ringTrack;

    final active = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = TasbihTokens.accent;

    canvas.drawCircle(center, radius, track);
    final sweep = (2 * math.pi) * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _TasbihRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
