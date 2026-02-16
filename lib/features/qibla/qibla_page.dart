import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';

import '../../state/app_controller.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    final hasQibla = widget.controller.qiblaBearing != null;

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1A38), Color(0xFF07142E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
          children: [
            Text(
              'qiblat',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              hasQibla
                  ? 'arah ke kaabah berdasarkan lokasi semasa'
                  : 'aktifkan lokasi untuk kiraan arah qiblat',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB8C4D9),
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFF2F3750),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _enabled && hasQibla
                            ? const Color(0xFF13D66A)
                            : const Color(0xFFE65A5A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _enabled && hasQibla ? 'Kompas aktif' : 'Kompas belum aktif',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    FilledButton(
                      onPressed: hasQibla
                          ? () {
                              setState(() {
                                _enabled = true;
                              });
                            }
                          : null,
                      child: const Text('Aktifkan'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              color: const Color(0xFF2F3750),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: (!_enabled || !hasQibla)
                    ? _buildDisabledCompass(context)
                    : StreamBuilder<CompassEvent>(
                        stream: FlutterCompass.events,
                        builder: (context, snapshot) {
                          final heading = snapshot.data?.heading;
                          if (heading == null) {
                            return _buildDisabledCompass(context);
                          }
                          final turn =
                              ((widget.controller.qiblaBearing! - heading) / 360);
                          final delta = _normalizeDelta(
                            widget.controller.qiblaBearing! - heading,
                          ).abs();
                          return _buildActiveCompass(
                            context,
                            turn: turn,
                            degrees: widget.controller.qiblaBearing!,
                            heading: heading,
                            delta: delta,
                          );
                        },
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
                    Text(
                      'panduan kalibrasi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const _GuideRow(text: 'Pegang telefon dalam posisi rata.'),
                    const _GuideRow(text: 'Gerakkan telefon bentuk angka 8, 5-10 kali.'),
                    const _GuideRow(text: 'Jauhkan dari magnet dan casing bermagnet.'),
                    const _GuideRow(text: 'Tunggu bacaan stabil sebelum ikut arah.'),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showCalibrationGuide(context),
                      icon: const Icon(Icons.tune),
                      label: const Text('Buka panduan penuh'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledCompass(BuildContext context) {
    return Column(
      children: [
        const _CompassFrame(
          child: Center(
            child: Text(
              'Kompas belum aktif',
              style: TextStyle(
                color: Color(0xFFAFC0DE),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '--',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }

  Widget _buildActiveCompass(
    BuildContext context, {
    required double turn,
    required double degrees,
    required double heading,
    required double delta,
  }) {
    return Column(
      children: [
        _CompassFrame(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF49526B)),
                ),
              ),
              Transform.rotate(
                angle: 2 * pi * turn,
                child: const Icon(
                  Icons.navigation,
                  size: 112,
                  color: Color(0xFFF4C542),
                ),
              ),
              _directionLabel('U', Alignment.topCenter),
              _directionLabel('T', Alignment.centerRight),
              _directionLabel('S', Alignment.bottomCenter),
              _directionLabel('B', Alignment.centerLeft),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${degrees.toStringAsFixed(0)} darjah',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Arah semasa ${heading.toStringAsFixed(0)}° | Ralat ${delta.toStringAsFixed(0)}°',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB8C4D9),
              ),
        ),
      ],
    );
  }

  Widget _directionLabel(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD9E4F7),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Future<void> _showCalibrationGuide(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Panduan Kalibrasi Kompas'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Pegang telefon dalam posisi rata.'),
              SizedBox(height: 6),
              Text('2. Gerakkan telefon bentuk angka 8 sebanyak 5-10 kali.'),
              SizedBox(height: 6),
              Text('3. Jauhkan telefon daripada magnet atau casing bermagnet.'),
              SizedBox(height: 6),
              Text('4. Tunggu bacaan stabil sebelum ikut arah anak panah.'),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Faham'),
            ),
          ],
        );
      },
    );
  }
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

class _CompassFrame extends StatelessWidget {
  const _CompassFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 246,
      height: 246,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF242D45),
        border: Border.all(
          color: const Color(0xFF4A5673),
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF97A9C9)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFC7D3E8),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
