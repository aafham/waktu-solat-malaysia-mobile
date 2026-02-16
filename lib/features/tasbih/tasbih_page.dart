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
    final presetTarget = _presets[_activePreset] ?? 33;
    const cycleTarget = 33;
    final cycle = count ~/ cycleTarget;
    final inCycle = count % cycleTarget;
    final cycleProgress = inCycle / cycleTarget;
    final presetCount = count % presetTarget;
    final presetProgress = presetCount / presetTarget;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1A38), Color(0xFF07142E)],
          ),
        ),
        child: focusMode
            ? _buildFocusMode(context, count)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'zikir',
                          style:
                              Theme.of(context).textTheme.displaySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: () {
                          setState(() {
                            focusMode = true;
                          });
                        },
                        icon: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                  Text(
                    'tap bulatan untuk tambah kiraan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFAEBBD3),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF2F3750),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StatChip(
                            icon: Icons.today,
                            text: 'Hari ini ${widget.controller.tasbihTodayCount}',
                          ),
                          _StatChip(
                            icon: Icons.view_week,
                            text: '7 hari ${widget.controller.tasbihWeekCount}',
                          ),
                          _StatChip(
                            icon: Icons.local_fire_department,
                            text: 'Streak ${widget.controller.tasbihStreakDays}',
                          ),
                          _StatChip(
                            icon: Icons.emoji_events,
                            text: 'Terbaik ${widget.controller.tasbihBestDay}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    color: const Color(0xFF2F3750),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Text(
                              '$count',
                              key: ValueKey<int>(count),
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Text(
                            'jumlah semasa',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFAEBBD3),
                                    ),
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 12),
                          _ProgressBlock(
                            title: 'pusingan 33',
                            valueText: '$inCycle/$cycleTarget',
                            value: cycleProgress,
                            color: const Color(0xFF20D167),
                          ),
                          const SizedBox(height: 10),
                          _ProgressBlock(
                            title: _activePreset,
                            valueText: '$presetCount/$presetTarget',
                            value: presetProgress,
                            color: const Color(0xFFF4C542),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set lengkap: $cycle',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFFC9D4E8),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TapOrb(
                    onTap: () async {
                      await HapticFeedback.lightImpact();
                      await widget.controller.incrementTasbih();
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await HapticFeedback.lightImpact();
                            await widget.controller.incrementTasbih();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await HapticFeedback.selectionClick();
                            await widget.controller.addTasbihBatch(presetTarget);
                          },
                          icon: const Icon(Icons.bolt),
                          label: Text('+$presetTarget'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: count == 0 ? null : () => _confirmReset(context),
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset kiraan'),
                  ),
                ],
              ),
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
                'focus mode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              IconButton.filledTonal(
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
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
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
            label: const Text('Reset'),
          ),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: const Color(0xFFD8E5FF)),
      label: Text(text),
      labelStyle: const TextStyle(
        color: Color(0xFFE7EEFB),
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFF3A435D),
      side: const BorderSide(color: Color(0xFF4D5773)),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({
    required this.title,
    required this.valueText,
    required this.value,
    required this.color,
  });

  final String title;
  final String valueText;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Text(
              valueText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC9D4E8),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 9,
            backgroundColor: const Color(0xFF4F5A77),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
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
                colors: <Color>[Color(0xFF19B07A), Color(0xFF0F8F64)],
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
