import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Available actions from the Avatar Action Bottom Sheet.
enum TioAvatarAction {
  gallery,
  camera,
  delete,
}

/// Image source contract for image selection decoupled from platform plugins.
enum TioImageSource {
  gallery,
  camera,
}

/// Displays modern bottom sheet for Avatar actions:
/// - Choose from Gallery
/// - Take Photo (Camera)
/// - Remove Current Photo (if photo exists)
Future<TioAvatarAction?> showTioAvatarActionBottomSheet({
  required BuildContext context,
  bool hasPhoto = false,
}) {
  final colors = context.tioColors;

  return showModalBottomSheet<TioAvatarAction>(
    context: context,
    backgroundColor: colors.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(TioRadius.large)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.large,
            vertical: TioSpacing.medium,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.outlineStrong.withAlpha(50),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TioSpacing.large),

              Text(
                'Profile Photo',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: TioSpacing.medium),

              // Option 1: Gallery
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library_outlined, color: colors.primary, size: 20),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(sheetContext).pop(TioAvatarAction.gallery),
              ),

              // Option 2: Camera
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: colors.primary, size: 20),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.of(sheetContext).pop(TioAvatarAction.camera),
              ),

              const SizedBox(height: TioSpacing.small),
            ],
          ),
        ),
      );
    },
  );
}
