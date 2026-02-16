import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    final count = controller.tasbihCount;
    final cycleTarget = controller.tasbihCycleTarget;
    final cycle = count ~/ cycleTarget;
    final inCycle = count % cycleTarget;
    final progress = cycleTarget == 0 ? 0.0 : inCycle / cycleTarget;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF0A1A38), Color(0xFF07142E)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr('Tasbih Digital', 'Digital Tasbih'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('Tap bulatan untuk tambah kiraan',
                    'Tap circle to increase count'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                color: const Color(0xFF2F3750),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 12,
                                backgroundColor: const Color(0xFF3A4460),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF3C623),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(
                                '$count',
                                key: ValueKey<int>(count),
                                style: Theme.of(context)
                                    .textTheme
                                    .displayMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFEAF2FF),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$inCycle/$cycleTarget',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFFEAF2FF),
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('Pusingan: $cycle', 'Cycle: $cycle'),
                            style: const TextStyle(color: Color(0xFFC8D3E8)),
                          ),
                          Text(
                            '$inCycle/$cycleTarget',
                            style: const TextStyle(color: Color(0xFFC8D3E8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tr('Milestone: 33 • 66 • 99',
                            'Milestones: 33 • 66 • 99'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9EB0CC),
                            ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: progress,
                          backgroundColor: const Color(0xFF425072),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFF3C623),
                          ),
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
                          colors: <Color>[Color(0xFF147A70), Color(0xFF0E5A53)],
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
                      child: Center(
                        child: Text(
                          '${tr('TAP', 'TAP')}\n+1',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
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
                      label: Text(tr('Tambah', 'Add')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: count == 0 ? null : controller.resetTasbih,
                      icon: const Icon(Icons.restart_alt),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: Color(0xFF56739E)),
                        foregroundColor: const Color(0xFFEAF2FF),
                      ),
                      label: Text(tr('Reset', 'Reset')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.addTasbihBatch(cycleTarget),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF56739E)),
                        foregroundColor: const Color(0xFFEAF2FF),
                      ),
                      child: Text('+${cycleTarget.clamp(1, 999)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          controller.addTasbihBatch(cycleTarget * 3),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF56739E)),
                        foregroundColor: const Color(0xFFEAF2FF),
                      ),
                      child: Text('+${(cycleTarget * 3).clamp(1, 999)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tr(
                  'Petua: target set semasa = $cycleTarget kiraan',
                  'Tip: current set target = $cycleTarget counts',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9EB0CC),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
