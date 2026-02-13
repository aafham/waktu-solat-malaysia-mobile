import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';

class TasbihPage extends StatefulWidget {
  const TasbihPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TasbihPage> createState() => _TasbihPageState();
}

class _TasbihPageState extends State<TasbihPage> {
  bool focusMode = false;
  final Map<String, int> _presets = const {
    'Subhanallah': 33,
    'Alhamdulillah': 33,
    'Allahu Akbar': 34,
    'Istighfar': 100,
  };
  String _activePreset = 'Subhanallah';

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.tasbihCount;
    const cycleTarget = 33;
    final cycle = count ~/ cycleTarget;
    final inCycle = count % cycleTarget;
    final progress = inCycle / cycleTarget;
    final presetTarget = _presets[_activePreset] ?? 33;
    final presetCount = count % presetTarget;
    final presetProgress = presetCount / presetTarget;
    final compact = MediaQuery.sizeOf(context).height < 760;
    final orbSize = compact ? 170.0 : 210.0;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Color(0xFFF4F7F6), Color(0xFFE7EFEC)],
                  ),
                ),
                child: focusMode
                    ? _buildFocusMode(context, count)
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                        child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Tasbih Digital',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Mod fokus',
                          onPressed: () {
                            setState(() {
                              focusMode = true;
                            });
                          },
                          icon: const Icon(Icons.center_focus_strong),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sentuh bulatan untuk tambah kiraan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presets.entries
                          .map(
                            (entry) => ChoiceChip(
                              label: Text('${entry.key} (${entry.value})'),
                              selected: _activePreset == entry.key,
                              onSelected: (_) {
                                setState(() {
                                  _activePreset = entry.key;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: 0.72),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.today, size: 16),
                              label:
                                  Text('Hari ini ${widget.controller.tasbihTodayCount}'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.view_week, size: 16),
                              label: Text(
                                '7 hari ${widget.controller.tasbihWeekCount}',
                              ),
                            ),
                            Chip(
                              avatar: const Icon(Icons.local_fire_department, size: 16),
                              label:
                                  Text('Streak ${widget.controller.tasbihStreakDays}'),
                            ),
                            Chip(
                              avatar: const Icon(Icons.emoji_events, size: 16),
                              label:
                                  Text('Terbaik ${widget.controller.tasbihBestDay}'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: 0.82),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                '$count',
                                key: ValueKey<int>(count),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Pusingan 33: $cycle'),
                                Text('$inCycle/$cycleTarget'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Zikir: $_activePreset'),
                                Text('$presetCount/$presetTarget'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: progress,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Kemajuan $_activePreset'),
                                Text('$presetCount/$presetTarget'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 8,
                                value: presetProgress,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2B9C8D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 22),
                    _TapOrb(
                      size: orbSize,
                      onTap: () async {
                        await HapticFeedback.lightImpact();
                        await widget.controller.incrementTasbih();
                      },
                    ),
                    SizedBox(height: compact ? 14 : 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await HapticFeedback.lightImpact();
                              await widget.controller.incrementTasbih();
                            },
                            icon: const Icon(Icons.add),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: const Text('Tambah'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await HapticFeedback.selectionClick();
                              await widget.controller.addTasbihBatch(
                                _presets[_activePreset] ?? 0,
                              );
                            },
                            icon: const Icon(Icons.bolt),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: Text('+$presetTarget'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    OutlinedButton.icon(
                      onPressed: count == 0 ? null : () => _confirmReset(context),
                      icon: const Icon(Icons.delete_outline),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      label: const Text('Tetapkan semula kiraan'),
                    ),
                    SizedBox(height: compact ? 4 : 8),
                    Text(
                      'Petua: biasanya satu set zikir = 33 kiraan',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFocusMode(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Mod Fokus',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Keluar mod fokus',
                onPressed: () {
                  setState(() {
                    focusMode = false;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$count',
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          _TapOrb(
            size: 250,
            onTap: () async {
              await HapticFeedback.lightImpact();
              await widget.controller.incrementTasbih();
            },
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: count == 0 ? null : () => _confirmReset(context),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Tetapkan semula kiraan'),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tetapkan semula kiraan tasbih?'),
          content: const Text('Kiraan akan kembali ke 0.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetapkan semula'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await HapticFeedback.mediumImpact();
      await widget.controller.resetTasbih();
    }
  }
}

class _TapOrb extends StatelessWidget {
  const _TapOrb({
    required this.onTap,
    this.size = 210,
  });

  final Future<void> Function() onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: 'Tambah kiraan tasbih',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(160),
          child: Ink(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: <Color>[Color(0xFF0D8C7B), Color(0xFF0A6A60)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'SENTUH\n+1',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
