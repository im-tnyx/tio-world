import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.onSettingsPressed,
    required this.onAvatarPressed,
    super.key,
    this.avatarFrame = TioAvatarFrame.none,
  });

  final VoidCallback onSettingsPressed;
  final VoidCallback onAvatarPressed;
  final TioAvatarFrame avatarFrame;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Tooltip(
                message: 'Open profile photo',
                child: Semantics(
                  key: const ValueKey('profile-avatar-entry'),
                  button: true,
                  label: 'Open profile photo',
                  child: ExcludeSemantics(
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAvatarPressed,
                      child: TioAvatar(
                        size: TioAvatarSize.large,
                        frame: avatarFrame,
                      ),
                    ),
                  ),
                ),
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
