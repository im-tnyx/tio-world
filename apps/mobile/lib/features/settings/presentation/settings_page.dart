import 'package:flutter/material.dart';
import '../../../shared/widgets/placeholder_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const PlaceholderPage(
        title: 'Settings',
        description: 'Configure your app preferences and notifications.',
      ),
    );
  }
}
