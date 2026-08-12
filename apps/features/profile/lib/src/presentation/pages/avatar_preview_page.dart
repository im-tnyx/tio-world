import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class AvatarPreviewPage extends StatelessWidget {
  const AvatarPreviewPage({
    required this.onBackPressed,
    super.key,
    this.image,
    this.onEditPressed,
    this.onDeletePressed,
    this.onDownloadPressed,
  });

  final VoidCallback onBackPressed;
  final ImageProvider<Object>? image;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final VoidCallback? onDownloadPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: onBackPressed),
        title: const Text('Profile photo'),
        actions: [
          IconButton(
            key: const ValueKey('profile-avatar-edit'),
            tooltip: 'Edit profile photo',
            onPressed: onEditPressed,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            key: const ValueKey('profile-avatar-delete'),
            tooltip: 'Delete profile photo',
            color: onDeletePressed == null
                ? null
                : Theme.of(context).colorScheme.error,
            onPressed: onDeletePressed,
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            key: const ValueKey('profile-avatar-download'),
            tooltip: 'Download profile photo',
            onPressed: onDownloadPressed,
            icon: const Icon(Icons.download_outlined),
          ),
          const SizedBox(width: TioSpacing.small),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dimension = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            return Center(
              child: SizedBox.square(
                dimension: dimension,
                child: AspectRatio(
                  key: const ValueKey('profile-avatar-preview'),
                  aspectRatio: 1,
                  child: ColoredBox(
                    color: context.tioColors.surface,
                    child: image == null
                        ? _avatarFallback('Profile photo placeholder')
                        : Image(
                            image: image!,
                            fit: BoxFit.cover,
                            semanticLabel: 'Profile photo',
                            errorBuilder: (context, error, stackTrace) =>
                                _avatarFallback('Profile photo unavailable'),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _avatarFallback(String semanticLabel) {
    return Center(
      child: TioAvatar(
        size: TioAvatarSize.extraLarge,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
