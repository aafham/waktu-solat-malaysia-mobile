import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final count = controller.tasbihCount;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tasbih Digital',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Semantics(
                  button: true,
                  label: 'Tambah kiraan tasbih',
                  child: InkWell(
                    onTap: controller.incrementTasbih,
                    borderRadius: BorderRadius.circular(120),
                    child: Ink(
                      width: 210,
                      height: 210,
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
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.incrementTasbih,
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
                      onPressed: count == 0 ? null : controller.resetTasbih,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
