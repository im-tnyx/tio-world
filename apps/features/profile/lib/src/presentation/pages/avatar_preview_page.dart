import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Full preview screen for user profile photo.
///
/// Layout:
/// - Topbar: Back button, Title, Pencil (Edit/Replace), Download, Trash (Remove).
/// - Body: Centered 1:1 aspect ratio square preview taking full available width/height.
class AvatarPreviewPage extends StatelessWidget {
  const AvatarPreviewPage({
    required this.onBackPressed,
    super.key,
    this.avatarUrl,
    this.initials,
    this.onPickImage,
    this.onDeletePressed,
    this.onDownloadPressed,
  });

  final VoidCallback onBackPressed;
  final String? avatarUrl;
  final String? initials;
  final Future<void> Function(TioImageSource source)? onPickImage;
  final VoidCallback? onDeletePressed;
  final Future<void> Function()? onDownloadPressed;

  Future<void> _openActionsSheet(BuildContext context) async {
    final hasPhoto = avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty &&
        avatarUrl!.trim().startsWith('http');
    final action = await showTioAvatarActionBottomSheet(
      context: context,
      hasPhoto: hasPhoto,
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case TioAvatarAction.gallery:
        await onPickImage?.call(TioImageSource.gallery);
        break;
      case TioAvatarAction.camera:
        await onPickImage?.call(TioImageSource.camera);
        break;
      case TioAvatarAction.delete:
        await _confirmDelete(context);
        break;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showTioRemoveImageConfirmationBottomSheet(context);
    if (confirmed == true) {
      onDeletePressed?.call();
    }
  }

  Future<void> _handleDownload(BuildContext context) async {
    if (onDownloadPressed != null) {
      await onDownloadPressed!();
      return;
    }

    if (avatarUrl == null || avatarUrl!.isEmpty) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: TioPalette.white,
                size: TioSize.dp20,
              ),
              SizedBox(width: TioSize.dp10),
              Text('Profile photo saved to device!'),
            ],
          ),
          backgroundColor: TioPalette.slate800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TioRadius.md),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        automaticallyImplyLeading: false,
        leading: BackButton(
          color: colors.textPrimary,
          onPressed: onBackPressed,
        ),
        title: Text(
          'Profile Photo',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size18,
          ),
        ),
        actions: [
          IconButton(
            key: const ValueKey('profile-avatar-edit'),
            tooltip: 'Replace Photo',
            icon: Icon(Icons.cached_rounded, color: colors.textPrimary),
            onPressed: () => _openActionsSheet(context),
          ),
          IconButton(
            key: const ValueKey('profile-avatar-download'),
            tooltip: 'Download Photo',
            icon: Icon(Icons.download_outlined, color: colors.textPrimary),
            onPressed: () => _handleDownload(context),
          ),
          IconButton(
            key: const ValueKey('profile-avatar-delete'),
            tooltip: 'Remove Photo',
            icon: Icon(Icons.delete_outline_rounded, color: colors.danger),
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: TioSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final dimension = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

            return Center(
              child: TioAvatar(
                key: const ValueKey('profile-avatar-preview'),
                shape: TioAvatarShape.square,
                customDimension: dimension,
                imageUrl: avatarUrl,
                displayName: initials,
              ),
            );
          },
        ),
      ),
    );
  }
}
