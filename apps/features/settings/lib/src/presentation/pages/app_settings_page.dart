import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({
    required this.currentMode,
    required this.currentThemeMode,
    required this.onAppModePressed,
    required this.onThemePressed,
    required this.onMeasurementUnitsPressed,
    super.key,
  });

  final AppMode currentMode;
  final TioThemeMode currentThemeMode;
  final VoidCallback onAppModePressed;
  final VoidCallback onThemePressed;
  final VoidCallback onMeasurementUnitsPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Preferences')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TioSpacing.xl),
          children: [
            // The canonical grouped surface and row family, the same one every
            // other Settings and Nutrition group uses. This screen was the last
            // one still composing a raw Material Card of raw ListTiles, which is
            // why its card read as a different component to the rest of the app.
            TioGroupCard(
              children: [
                TioSettingsNavigationRow(
                  key: const ValueKey('app-settings-app-mode-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.dashboard_customize_outlined,
                  ),
                  title: 'App Mode',
                  supportingText: _appModeLabel(currentMode),
                  onTap: onAppModePressed,
                ),
                const _AppSettingsDivider(),
                TioSettingsNavigationRow(
                  key: const ValueKey('app-settings-theme-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.palette_outlined,
                  ),
                  title: 'Theme',
                  supportingText: _themeModeLabel(currentThemeMode),
                  onTap: onThemePressed,
                ),
                const _AppSettingsDivider(),
                TioSettingsNavigationRow(
                  key: const ValueKey('app-settings-units-entry'),
                  leading: const TioSettingsLeadingIcon(
                    icon: Icons.straighten_rounded,
                  ),
                  title: 'Units',
                  supportingText: 'Weight, height, distance & volume',
                  onTap: onMeasurementUnitsPressed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Separator between grouped rows, matching the Settings hub.
///
/// Indented past the leading icon so the rule starts at the text column rather
/// than cutting under the icon.
class _AppSettingsDivider extends StatelessWidget {
  const _AppSettingsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSize.dp64,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}

String _appModeLabel(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _themeModeLabel(TioThemeMode mode) {
  return switch (mode) {
    TioThemeMode.system => 'System',
    TioThemeMode.light => 'Light',
    TioThemeMode.dark => 'Dark',
    TioThemeMode.oled => 'OLED',
  };
}
