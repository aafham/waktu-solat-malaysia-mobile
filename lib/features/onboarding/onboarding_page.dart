import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.onSelesai,
  });

  final Future<void> Function() onSelesai;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_OnboardItem>[
      const _OnboardItem(
        icon: Icons.access_time_filled,
        title: 'Waktu Solat Tepat',
        desc: 'Lihat waktu solat harian dan bulanan mengikut zon Malaysia.',
      ),
      const _OnboardItem(
        icon: Icons.notifications_active,
        title: 'Notifikasi Pintar',
        desc: 'Aktifkan peringatan masuk waktu, tunda, dan profil bunyi.',
      ),
      const _OnboardItem(
        icon: Icons.explore,
        title: 'Kiblat & Tasbih',
        desc: 'Gunakan kompas kiblat dan tasbih digital dengan statistik.',
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
                        : const Color(0xFFB8CBC7),
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
                await widget.onSelesai();
              },
              child: Text(_index < pages.length - 1 ? 'Seterusnya' : 'Mula Guna App'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                await widget.onSelesai();
              },
              child: const Text('Langkau'),
            ),
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
          colors: [Color(0xFF0D2524), Color(0xFF153533)],
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
            child: Icon(item.icon, size: 34, color: const Color(0xFF7BE3BE)),
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
                  color: const Color(0xFFD2E9E3),
                ),
          ),
        ],
      ),
    );
  }
}
