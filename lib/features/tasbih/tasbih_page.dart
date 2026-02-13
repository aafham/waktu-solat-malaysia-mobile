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

  @override
  Widget build(BuildContext context) {
    final count = widget.controller.tasbihCount;
    const cycleTarget = 33;
    final cycle = count ~/ cycleTarget;
    final inCycle = count % cycleTarget;
    final progress = inCycle / cycleTarget;

    return SafeArea(
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
                          tooltip: 'Focus mode',
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
                      'Tap bulatan untuk tambah kiraan',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
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
                                Text('Pusingan: $cycle'),
                                Text('$inCycle/$cycleTarget'),
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
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _TapOrb(
                      onTap: () async {
                        await HapticFeedback.lightImpact();
                        await widget.controller.incrementTasbih();
                      },
                    ),
                    const Spacer(),
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
                            ),
                            label: const Text('Tambah'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: count == 0
                                ? null
                                : () => _confirmReset(context),
                            icon: const Icon(Icons.restart_alt),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                            ),
                            label: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                'Focus Mode',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Keluar focus mode',
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
            label: const Text('Reset kiraan'),
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
          title: const Text('Reset kiraan tasbih?'),
          content: const Text('Kiraan akan kembali ke 0.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
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
                'TAP\n+1',
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
