import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';
import '../../theme/page_header_style.dart';
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
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      controller.t('page_title_tasbih'),
                      textAlign: TextAlign.left,
                      style: pageTitleStyle(context),
                    ),
                  ),
                  const SizedBox(height: TasbihTokens.s12),
                  TasbihStatsChips(
                    controller: controller,
                    target: target,
                    cycle: cycle,
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
              onCustomTargetSubmit: _handleCustomTargetSubmit,
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
    await widget.controller.setTasbihCycleTarget(value);
  }

  Future<void> _handleCustomTargetSubmit(int value) async {
    await widget.controller.setTasbihCycleTarget(value);
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
    final beforeStep = before ~/ target;
    final afterStep = after ~/ target;
    final hitTarget = after > 0 && afterStep > beforeStep;

    if (!hitTarget) {
      return;
    }

    HapticFeedback.lightImpact();
    _milestoneTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _milestoneLabel = widget.controller.tr(
        'Target tercapai ✅',
        'Target reached ✅',
      );
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
        scale: pressed ? 0.985 : 1.0,
        duration: pressed ? TasbihTokens.tapScaleIn : TasbihTokens.tapScaleOut,
        curve: Curves.easeOut,
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: onTap,
            radius: size / 2,
            containedInkWell: true,
            customBorder: const CircleBorder(),
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
                    child: TweenAnimationBuilder<double>(
                      duration: TasbihTokens.progressAnim,
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0, end: progress),
                      builder: (context, value, _) {
                        return CustomPaint(
                          painter: _TasbihRingPainter(progress: value),
                        );
                      },
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: TasbihTokens.s8),
                      Text(
                        '$inCycle / $target',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: TasbihTokens.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: TasbihTokens.s24,
                    child: Text(
                      controller.t('tasbih_tap_add'),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: TasbihTokens.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TasbihStatsChips extends StatelessWidget {
  const TasbihStatsChips({
    super.key,
    required this.controller,
    required this.target,
    required this.cycle,
  });

  final AppController controller;
  final int target;
  final int cycle;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return Wrap(
      spacing: TasbihTokens.s8,
      runSpacing: TasbihTokens.s8,
      children: [
        _StatChip(
          label: tr('Target', 'Target'),
          value: '$target',
        ),
        _StatChip(
          label: tr('Pusingan', 'Cycle'),
          value: '$cycle',
        ),
        _StatChip(
          label: tr('Hari ini', 'Today'),
          value: '${controller.tasbihTodayCount}',
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TasbihTokens.s12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0x1A3C5478),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x345C7EA6)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFFE8F1FF),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class TasbihControlPanel extends StatefulWidget {
  const TasbihControlPanel({
    super.key,
    required this.controller,
    required this.selectedTarget,
    required this.onSelectTarget,
    required this.onCustomTargetSubmit,
    required this.onUndo,
    required this.onReset,
    required this.onQuickAdd,
  });

  final AppController controller;
  final int selectedTarget;
  final ValueChanged<int> onSelectTarget;
  final Future<void> Function(int) onCustomTargetSubmit;
  final VoidCallback? onUndo;
  final VoidCallback? onReset;
  final ValueChanged<int> onQuickAdd;

  @override
  State<TasbihControlPanel> createState() => _TasbihControlPanelState();
}

class _TasbihControlPanelState extends State<TasbihControlPanel> {
  late final TextEditingController _customController;
  bool _editingCustom = false;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant TasbihControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTarget != -1 && _editingCustom) {
      _editingCustom = false;
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _startCustomEdit() {
    setState(() {
      _editingCustom = true;
      _customController.text = '${widget.controller.tasbihCycleTarget}';
      _customController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _customController.text.length,
      );
    });
  }

  void _cancelCustomEdit() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _editingCustom = false;
    });
  }

  Future<void> _saveCustom() async {
    final parsed = int.tryParse(_customController.text.trim());
    if (parsed == null || parsed < 1) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await widget.onCustomTargetSubmit(parsed);
    if (!mounted) {
      return;
    }
    setState(() {
      _editingCustom = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.controller.tr;
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
          Text(
            tr('Sasaran pusingan', 'Cycle target'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TasbihTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            showSelectedIcon: false,
            style: ButtonStyle(
              minimumSize: WidgetStateProperty.all(const Size(0, 36)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              ButtonSegment<int>(value: 33, label: Text(tr('33', '33'))),
              ButtonSegment<int>(value: 99, label: Text(tr('99', '99'))),
              ButtonSegment<int>(
                  value: -1, label: Text(tr('Tersuai', 'Custom'))),
            ],
            selected: <int>{widget.selectedTarget},
            onSelectionChanged: (value) {
              final selected = value.first;
              if (selected == -1) {
                _startCustomEdit();
                return;
              }
              _cancelCustomEdit();
              widget.onSelectTarget(selected);
            },
          ),
          if (_editingCustom) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: tr('Contoh: 100', 'Example: 100'),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelCustomEdit,
                    child: Text(tr('Batal', 'Cancel')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveCustom,
                    child: Text(tr('Simpan', 'Save')),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            tr('Tindakan', 'Actions'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TasbihTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: Text(tr('Undo', 'Undo')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReset,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: Text(tr('Reset', 'Reset')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr('Tambah pantas', 'Quick add'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TasbihTokens.textMuted,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => widget.onQuickAdd(10),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('+10'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => widget.onQuickAdd(33),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('+33'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => widget.onQuickAdd(99),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('+99'),
                ),
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
                label!,
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
      ..color = TasbihTokens.accentStrong;

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
