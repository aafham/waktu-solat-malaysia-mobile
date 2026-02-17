import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'settings_styles.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: settingsTextMuted,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: settingsSurface,
            borderRadius: BorderRadius.circular(settingsRadius),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsNavTile extends StatelessWidget {
  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: LeadingIcon(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
      secondary: LeadingIcon(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class DropdownTile extends StatelessWidget {
  const DropdownTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: LeadingIcon(icon: icon, color: iconColor),
      title: Text(title),
      subtitle: Text(value),
      trailing: DropdownButton<String>(
        value: options.contains(value) ? value : options.first,
        items: options
            .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            onChanged(v);
          }
        },
      ),
    );
  }
}

class PrayerAdjustTile extends StatelessWidget {
  const PrayerAdjustTile({
    super.key,
    required this.prayerName,
    required this.value,
    required this.onChanged,
  });

  final String prayerName;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const LeadingIcon(icon: Icons.tune, color: Color(0xFF5CA9FF)),
      title: Text(prayerName),
      subtitle: Text('${value >= 0 ? '+' : ''}$value min'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value <= -30 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          IconButton(
            onPressed: value >= 30 ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class SettingsSubpageScaffold extends StatelessWidget {
  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: settingsBgBottom,
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [settingsBgTop, settingsBgBottom],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [child],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
      ),
      onChanged: onChanged,
    );
  }
}

class LeadingIcon extends StatelessWidget {
  const LeadingIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: settingsSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: color),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2F2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFFFD7C8),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class ZoneQuickChips extends StatelessWidget {
  const ZoneQuickChips({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final codes = <String>[
      ...controller.favoriteZones,
      ...controller.recentZones,
    ].where((c) => seen.add(c)).take(10).toList();

    if (codes.isEmpty) {
      return const SizedBox.shrink();
    }

    final zonesByCode = {for (final zone in controller.zones) zone.code: zone};

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: codes
            .where((code) => zonesByCode.containsKey(code))
            .map(
              (code) => ActionChip(
                label: Text(code),
                avatar: Icon(
                  controller.favoriteZones.contains(code)
                      ? Icons.star
                      : Icons.history,
                  size: 15,
                ),
                onPressed: () => controller.setManualZone(code),
              ),
            )
            .toList(),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: settingsSurface,
        borderRadius: BorderRadius.circular(settingsRadius),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: settingsTextMuted,
            ),
      ),
    );
  }
}
