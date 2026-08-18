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
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TioAvatarActionSheetTokens.sheetRadius),
      ),
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
              Center(
                child: Container(
                  width: TioAvatarActionSheetTokens.dragHandleWidth,
                  height: TioAvatarActionSheetTokens.dragHandleHeight,
                  decoration: BoxDecoration(
                    color: colors.outlineStrong.withAlpha(
                      TioAvatarActionSheetTokens.dragHandleAlpha,
                    ),
                    borderRadius: BorderRadius.circular(
                      TioAvatarActionSheetTokens.dragHandleRadius,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: TioAvatarActionSheetTokens.handleToTitleGap,
              ),
              Text(
                'Profile Photo',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: TioAvatarActionSheetTokens.titleFontSize,
                ),
              ),
              const SizedBox(
                height: TioAvatarActionSheetTokens.titleToOptionsGap,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(
                    TioAvatarActionSheetTokens.optionIconPadding,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: colors.primary,
                    size: TioAvatarActionSheetTokens.optionIconSize,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(TioAvatarAction.gallery),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(
                    TioAvatarActionSheetTokens.optionIconPadding,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: colors.primary,
                    size: TioAvatarActionSheetTokens.optionIconSize,
                  ),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(TioAvatarAction.camera),
              ),
              const SizedBox(height: TioAvatarActionSheetTokens.bottomGap),
            ],
          ),
        ),
      );
    },
  );
}
