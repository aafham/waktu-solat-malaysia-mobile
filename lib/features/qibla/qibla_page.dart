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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF071414), Color(0xFF112521)],
              ),
              border: Border.all(color: const Color(0xFF28433D)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QIBLA COMPASS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFFA4C7BF),
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Direction to Kaaba',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasQibla
                        ? 'Qibla direction calculated from your location.'
                        : 'Qibla direction unavailable. Please enable location first.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFD4E8E1),
                        ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _enabled && hasQibla
                              ? const Color(0xFF4BCF90)
                              : const Color(0xFFE8564B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _enabled && hasQibla ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFE3F1ED),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: hasQibla
                        ? () {
                            setState(() {
                              _enabled = true;
                            });
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF57CC99),
                      foregroundColor: const Color(0xFF083326),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text(
                      'Enable Compass',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How to use: Keep your phone flat. The arrow points to the Kaaba.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFB9D4CC),
                        ),
                  ),
                  const SizedBox(height: 14),
                  if (!_enabled || !hasQibla)
                    _buildDisabledCompass(context)
                  else
                    StreamBuilder<CompassEvent>(
                      stream: FlutterCompass.events,
                      builder: (context, snapshot) {
                        final heading = snapshot.data?.heading;
                        if (heading == null) {
                          return _buildDisabledCompass(context);
                        }
                        final turn =
                            ((widget.controller.qiblaBearing! - heading) / 360);
                        return _buildActiveCompass(
                          context,
                          turn: turn,
                          degrees: widget.controller.qiblaBearing!,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              'Sumber data: JAKIM e-Solat dan Malaysia Waktu Solat API.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF51645F),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledCompass(BuildContext context) {
    return Column(
      children: [
        _CompassFrame(
          child: Center(
            child: Text(
              'Compass not active',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA7C2BA),
                  ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '--',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFE3F1ED),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildActiveCompass(
    BuildContext context, {
    required double turn,
    required double degrees,
  }) {
    return Column(
      children: [
        _CompassFrame(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: 2 * pi * turn,
                child: const Icon(
                  Icons.navigation,
                  size: 112,
                  color: Color(0xFF57CC99),
                ),
              ),
              _directionLabel('N', Alignment.topCenter),
              _directionLabel('E', Alignment.centerRight),
              _directionLabel('S', Alignment.bottomCenter),
              _directionLabel('W', Alignment.centerLeft),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${degrees.toStringAsFixed(0)}°',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFE3F1ED),
                fontWeight: FontWeight.w800,
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
            color: Color(0xFFB3D3CB),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
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
        border: Border.all(
          color: const Color(0xFF3A5A53),
          width: 1.4,
        ),
      ),
      child: child,
    );
  }
}
