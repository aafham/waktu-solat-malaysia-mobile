import 'package:flutter/widgets.dart';

import '../../state/app_controller.dart';
import 'about_settings_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AboutSettingsPage(controller: controller);
  }
}
