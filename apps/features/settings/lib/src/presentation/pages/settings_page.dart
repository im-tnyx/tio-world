import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onAppSettingsPressed,
    super.key,
  });

  final VoidCallback onAppSettingsPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Card(
              child: ListTile(
                key: const ValueKey('settings-app-settings-entry'),
                leading: const Icon(Icons.tune_outlined),
                title: const Text('App Settings'),
                subtitle: const Text('App mode and theme'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onAppSettingsPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
