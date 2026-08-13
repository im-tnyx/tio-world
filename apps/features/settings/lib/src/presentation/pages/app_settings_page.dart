import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class AppSettingsPage extends StatelessWidget {
  const AppSettingsPage({
    required this.currentMode,
    required this.currentThemeMode,
    required this.onAppModePressed,
    required this.onThemePressed,
    super.key,
  });

  final AppMode currentMode;
  final TioThemeMode currentThemeMode;
  final VoidCallback onAppModePressed;
  final VoidCallback onThemePressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    key: const ValueKey('app-settings-app-mode-entry'),
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('App Mode'),
                    subtitle: Text(_appModeLabel(currentMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onAppModePressed,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    key: const ValueKey('app-settings-theme-entry'),
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Theme'),
                    subtitle: Text(_themeModeLabel(currentThemeMode)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onThemePressed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
