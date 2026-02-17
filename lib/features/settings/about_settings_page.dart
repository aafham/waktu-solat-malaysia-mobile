import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_controller.dart';
import 'settings_components.dart';

class AboutSettingsPage extends StatelessWidget {
  const AboutSettingsPage({super.key, required this.controller});

  final AppController controller;
  static const _appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const _appBuild =
      String.fromEnvironment('APP_BUILD', defaultValue: '1');

  @override
  Widget build(BuildContext context) {
    final tr = controller.tr;
    return SettingsSubpageScaffold(
      title: tr('Tentang', 'About'),
      child: SettingsSection(
        children: [
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.info_outline,
              color: Color(0xFF4EC7F7),
            ),
            title: const Text('JagaSolat'),
            subtitle: Text(
              '${tr('Sumber data', 'Data source')}: JAKIM e-Solat + Malaysia Waktu Solat API',
            ),
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.verified_outlined,
              color: Color(0xFF4EC7F7),
            ),
            title: Text(controller.t('about_version')),
            subtitle: const Text(_appVersion),
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.tag_outlined,
              color: Color(0xFF4EC7F7),
            ),
            title: Text(controller.t('about_build')),
            subtitle: const Text(_appBuild),
          ),
          ListTile(
            leading: const LeadingIcon(
              icon: Icons.update_outlined,
              color: Color(0xFF4EC7F7),
            ),
            title: Text(tr('Status data', 'Data status')),
            subtitle: Text(controller.prayerDataFreshnessLabel),
          ),
          SettingsNavTile(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF4EC7F7),
            title: controller.t('about_privacy'),
            subtitle: tr(
              'Lokasi digunakan untuk zon waktu solat sahaja',
              'Location is used only for prayer time zone',
            ),
            onTap: () => _showPrivacy(context),
          ),
          SettingsNavTile(
            icon: Icons.feedback_outlined,
            iconColor: const Color(0xFF4EC7F7),
            title: controller.t('about_feedback'),
            subtitle: 'support@jagasolat.app',
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: 'support@jagasolat.app'),
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr('Emel disalin.', 'Email copied.')),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacy(BuildContext context) async {
    final tr = controller.tr;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(controller.t('about_privacy')),
        content: Text(
          tr(
            'Aplikasi ini menyimpan tetapan anda secara tempatan pada peranti. Data lokasi digunakan untuk memilih zon waktu solat dan tidak dikongsi ke pihak ketiga.',
            'This app stores your preferences locally on device. Location data is used for prayer zone selection and is not shared with third parties.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('Tutup', 'Close')),
          ),
        ],
      ),
    );
  }
}
