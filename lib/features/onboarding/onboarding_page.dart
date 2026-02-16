import 'package:flutter/material.dart';

import '../../state/app_controller.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onSelesai,
    required this.controller,
  });

  final Future<void> Function() onSelesai;
  final AppController controller;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _notifyEnabled = true;
  bool _autoLocation = true;

  @override
  void initState() {
    super.initState();
    _notifyEnabled = widget.controller.notifyEnabled;
    _autoLocation = widget.controller.autoLocation;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.controller.tr;
    final pages = <_OnboardItem>[
      _OnboardItem(
        icon: Icons.access_time_filled,
        title: tr('Waktu Solat Tepat', 'Accurate Prayer Times'),
        desc: tr(
          'Lihat waktu solat harian dan bulanan mengikut zon Malaysia.',
          'View daily and monthly prayer times by Malaysia zones.',
        ),
      ),
      _OnboardItem(
        icon: Icons.notifications_active,
        title: tr('Notifikasi Pintar', 'Smart Notifications'),
        desc: tr(
          'Aktifkan peringatan masuk waktu, tunda, dan profil bunyi.',
          'Enable prayer alerts, snooze, and sound profiles.',
        ),
      ),
      _OnboardItem(
        icon: Icons.explore,
        title: tr('Qiblat & Zikir', 'Qibla & Tasbih'),
        desc: tr(
          'Gunakan kompas qiblat dan zikir digital dengan statistik.',
          'Use qibla compass and digital tasbih with stats.',
        ),
      ),
      _OnboardItem(
        icon: Icons.tune,
        title: tr('Tetapan Permulaan', 'Quick Setup'),
        desc: tr(
          'Tetapkan notifikasi dan lokasi auto sebelum mula guna.',
          'Set notifications and auto location before you start.',
        ),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                  });
                },
                itemBuilder: (context, i) => _OnboardCard(item: pages[i]),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF6B7897),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                if (_index < pages.length - 1) {
                  await _controller.nextPage(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                  );
                  return;
                }
                await widget.controller.setNotifyEnabled(_notifyEnabled);
                await widget.controller.setAutoLocation(_autoLocation);
                await widget.onSelesai();
              },
              child: Text(
                _index < pages.length - 1
                    ? tr('Seterusnya', 'Next')
                    : tr('Mula Guna App', 'Start App'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await widget.controller.setNotifyEnabled(_notifyEnabled);
                await widget.controller.setAutoLocation(_autoLocation);
                await widget.onSelesai();
              },
              child: Text(tr('Langkau', 'Skip')),
            ),
            if (_index == pages.length - 1) ...[
              const SizedBox(height: 10),
              _SetupToggle(
                title: tr(
                  'Aktifkan notifikasi waktu solat',
                  'Enable prayer notifications',
                ),
                value: _notifyEnabled,
                onChanged: (value) {
                  setState(() {
                    _notifyEnabled = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              _SetupToggle(
                title: tr('Guna lokasi automatik', 'Use automatic location'),
                value: _autoLocation,
                onChanged: (value) {
                  setState(() {
                    _autoLocation = value;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnboardItem {
  const _OnboardItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}

class _OnboardCard extends StatelessWidget {
  const _OnboardCard({required this.item});

  final _OnboardItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2748), Color(0xFF0E1E3E)],
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(item.icon, size: 34, color: const Color(0xFFF4C542)),
          ),
          const SizedBox(height: 26),
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            item.desc,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFC7D3E8),
                ),
          ),
        ],
      ),
    );
  }
}

class _SetupToggle extends StatelessWidget {
  const _SetupToggle({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF122A4C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2F4F76)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFEAF2FF),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
