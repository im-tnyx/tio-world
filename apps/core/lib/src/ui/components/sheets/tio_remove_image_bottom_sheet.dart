import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Displays the exact modal bottom sheet for confirming image removal.
///
/// Features:
/// - Top-right circular close button
/// - "Remove Image" headline
/// - "Are you sure you want to remove this image?" description
/// - Full-width "Remove 🗑️" capsule button
/// - Full-width "Cancel ✕" capsule button
Future<bool?> showTioRemoveImageConfirmationBottomSheet(BuildContext context) {
  final colors = TioTheme.colors(context);

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: colors.surfaceRaised,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top-right close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(false),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // Title: Remove Image
              Text(
                'Remove Image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Are you sure you want to remove this image?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 26),

              // Remove Button (Capsule with Trash Icon)
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remove',
                        style: TextStyle(
                          color: colors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.delete_outline_rounded,
                        color: colors.danger,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button (Capsule with Close Icon)
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.close_rounded,
                        color: colors.textPrimary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
