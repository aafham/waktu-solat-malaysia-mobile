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
    final tr = widget.controller.tr;
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
              tr('Qiblat', 'Qibla'),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              hasQibla
                  ? tr(
                      'Arah ke Kaabah berdasarkan lokasi semasa',
                      'Direction to Kaaba based on current location',
                    )
                  : tr(
                      'Aktifkan lokasi untuk kiraan arah qiblat',
                      'Enable location to calculate qibla direction',
                    ),
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
                        _enabled && hasQibla
                            ? tr('Kompas aktif', 'Compass active')
                            : tr('Kompas belum aktif', 'Compass inactive'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    FilledButton(
                      onPressed: hasQibla
                          ? () {
                              setState(() {
                                _enabled = !_enabled;
                              });
                            }
                          : null,
                      child: Text(
                        _enabled
                            ? tr('Hentikan', 'Stop')
                            : tr('Aktifkan', 'Activate'),
                      ),
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
                              ((widget.controller.qiblaBearing! - heading) /
                                  360);
                          final delta = _normalizeDelta(
                            widget.controller.qiblaBearing! - heading,
                          ).abs();
                          final quality = _accuracyLabel(delta, tr);
                          return _buildActiveCompass(
                            context,
                            turn: turn,
                            degrees: widget.controller.qiblaBearing!,
                            heading: heading,
                            delta: delta,
                            quality: quality,
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
                      tr('Panduan Kalibrasi', 'Calibration guide'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    _GuideRow(
                        text: tr('Pegang telefon dalam posisi rata.',
                            'Hold phone flat.')),
                    _GuideRow(
                      text: tr(
                        'Gerakkan telefon bentuk angka 8, 5-10 kali.',
                        'Move phone in an 8-shape, 5-10 times.',
                      ),
                    ),
                    _GuideRow(
                      text: tr(
                        'Jauhkan dari magnet dan casing bermagnet.',
                        'Keep away from magnets and magnetic cases.',
                      ),
                    ),
                    _GuideRow(
                      text: tr(
                        'Tunggu bacaan stabil sebelum ikut arah.',
                        'Wait for stable readings before following direction.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showCalibrationGuide(context),
                      icon: const Icon(Icons.tune),
                      label: Text(tr('Buka panduan penuh', 'Open full guide')),
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
    final tr = widget.controller.tr;
    return Column(
      children: [
        _CompassFrame(
          child: Center(
            child: Text(
              tr('Kompas belum aktif', 'Compass inactive'),
              style: const TextStyle(
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
    required String quality,
  }) {
    final tr = widget.controller.tr;
    final isLow = delta > 20;
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
          '${degrees.toStringAsFixed(0)} ${tr('darjah', 'degrees')}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          tr(
            'Arah semasa ${heading.toStringAsFixed(0)}° | Ralat ${delta.toStringAsFixed(0)}°',
            'Current heading ${heading.toStringAsFixed(0)}° | Error ${delta.toStringAsFixed(0)}°',
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFB8C4D9),
              ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF203354),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF3D577D)),
          ),
          child: Text(
            tr('Ketepatan: $quality', 'Accuracy: $quality'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFD4E2F6),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        if (isLow) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _showCalibrationGuide(context),
            icon: const Icon(Icons.auto_fix_high),
            label: Text(tr('Kalibrasi sekarang', 'Calibrate now')),
          ),
        ],
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
    final tr = widget.controller.tr;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(tr('Panduan Kalibrasi Kompas', 'Compass Calibration Guide')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('1. Pegang telefon dalam posisi rata.',
                  '1. Hold phone flat.')),
              const SizedBox(height: 6),
              Text(tr(
                '2. Gerakkan telefon bentuk angka 8 sebanyak 5-10 kali.',
                '2. Move phone in an 8-shape 5-10 times.',
              )),
              const SizedBox(height: 6),
              Text(tr(
                '3. Jauhkan telefon daripada magnet atau casing bermagnet.',
                '3. Keep phone away from magnets or magnetic cases.',
              )),
              const SizedBox(height: 6),
              Text(tr(
                '4. Tunggu bacaan stabil sebelum ikut arah anak panah.',
                '4. Wait for stable readings before following direction.',
              )),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Faham', 'Understood')),
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

String _accuracyLabel(double delta, String Function(String, String) tr) {
  if (delta <= 8) {
    return tr('Tinggi', 'High');
  }
  if (delta <= 20) {
    return tr('Sederhana', 'Medium');
  }
  return tr('Rendah (kalibrasi semula)', 'Low (recalibrate)');
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
