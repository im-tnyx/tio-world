import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.onSettingsPressed,
    super.key,
  });

  final VoidCallback onSettingsPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(
              child: TioAvatar(
                size: TioAvatarSize.large,
                semanticLabel: 'Profile avatar',
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text('Account', style: textTheme.titleMedium),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                key: const ValueKey('profile-settings-entry'),
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                subtitle: const Text('App mode and preferences'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onSettingsPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
