import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../state/app_controller.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kompas Kiblat', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              controller.qiblaBearing == null
                  ? 'Arah kiblat belum tersedia.'
                  : 'Arah kiblat: ${controller.qiblaBearing!.toStringAsFixed(1)} darjah dari utara',
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Jika kompas tidak stabil, gerakkan telefon bentuk angka 8 selama 5-10 saat untuk kalibrasi. Elakkan magnet atau casing bermagnet.',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    final heading = snapshot.data?.heading;
                    if (heading == null || controller.qiblaBearing == null) {
                      return const Text('Sensor kompas atau lokasi belum tersedia.');
                    }

                    final turn = ((controller.qiblaBearing! - heading) / 360);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Transform.rotate(
                          angle: 2 * pi * turn,
                          child: const Icon(Icons.navigation, size: 180, color: Colors.teal),
                        ),
                        const SizedBox(height: 16),
                        Text('Heading: ${heading.toStringAsFixed(1)} darjah'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
