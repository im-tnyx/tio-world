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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const ValueKey('profile-settings-action'),
            tooltip: 'Settings',
            onPressed: onSettingsPressed,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
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
          ],
        ),
      ),
    );
  }
}
