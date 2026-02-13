import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class TasbihPage extends StatelessWidget {
  const TasbihPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Tasbih Digital', style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            Text(
              '${controller.tasbihCount}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: controller.incrementTasbih,
              style: FilledButton.styleFrom(minimumSize: const Size(220, 64)),
              child: const Text('Tambah'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.resetTasbih,
              style: OutlinedButton.styleFrom(minimumSize: const Size(220, 56)),
              child: const Text('Reset'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
