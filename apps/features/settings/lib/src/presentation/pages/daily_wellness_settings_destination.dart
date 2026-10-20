import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress_contracts.dart';

import '../../domain/hydration_preferences.dart';
import 'daily_wellness_settings_page.dart';

/// Settings-owned route states for Daily Wellness.
///
/// The app owns provider watches, user/session key selection and write/retry
/// callbacks. This destination owns only the original loading/error Scaffolds
/// and the existing editor presentation.
class DailyWellnessSettingsDestination extends StatelessWidget {
  const DailyWellnessSettingsDestination({
    required this.hydrationUserId,
    required this.initialTargets,
    required this.volumeUnit,
    required this.hydrationPreferences,
    required this.wellnessLoading,
    required this.wellnessLoadFailed,
    required this.hydrationLoading,
    required this.hydrationLoadFailed,
    required this.onRetryWellness,
    required this.onRetryHydration,
    required this.onSaveHydration,
    required this.onSave,
    super.key,
  });

  final String? hydrationUserId;
  final WellnessTargetsData? initialTargets;
  final VolumeUnit volumeUnit;
  final HydrationPreferences? hydrationPreferences;
  final bool wellnessLoading;
  final bool wellnessLoadFailed;
  final bool hydrationLoading;
  final bool hydrationLoadFailed;
  final VoidCallback onRetryWellness;
  final VoidCallback onRetryHydration;
  final Future<void> Function(HydrationPreferences) onSaveHydration;
  final Future<void> Function(WellnessTargetsData) onSave;

  @override
  Widget build(BuildContext context) {
    if (wellnessLoading && initialTargets == null) {
      return Scaffold(
        backgroundColor: context.tioColors.background,
        appBar: TioAppBar(
          backgroundColor: context.tioColors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: BackButton(color: context.tioColors.textPrimary),
          title: Text(
            'Daily Wellness',
            style: TextStyle(
              color: context.tioColors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: context.tioColors.primary,
            ),
          ),
        ),
      );
    }

    if (wellnessLoadFailed && initialTargets == null) {
      final colors = context.tioColors;
      return Scaffold(
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: BackButton(color: colors.textPrimary),
          title: Text(
            'Daily Wellness',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.xl),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: TioSize.dp48,
                    color: colors.danger,
                  ),
                  const SizedBox(height: TioSpacing.lg),
                  Text(
                    'Could not load wellness targets',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: TioFontSize.size18,
                      fontWeight: TioFontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.sm),
                  Text(
                    'Please check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size14,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xl),
                  TioButton.primary(
                    label: 'Retry',
                    onPressed: onRetryWellness,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return DailyWellnessSettingsPage(
      key: ValueKey(hydrationUserId),
      initialTargets: initialTargets,
      volumeUnit: volumeUnit,
      hydrationPreferences: hydrationPreferences,
      hydrationLoading: hydrationLoading,
      hydrationLoadFailed: hydrationLoadFailed,
      onRetryHydration: onRetryHydration,
      onSaveHydration: onSaveHydration,
      onSave: onSave,
    );
  }
}
