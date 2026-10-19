import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress_contracts.dart';

import 'body_weight_settings_page.dart';

/// Settings-owned presentation states for the Body & Weight route.
///
/// The app composition root owns the provider watches, retry invalidation and
/// repository callbacks; this widget contains no app provider or persistence.
class BodyWeightSettingsDestination extends StatelessWidget {
  const BodyWeightSettingsDestination({
    required this.bodyState,
    required this.weightUnit,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
    required this.onRecordCurrentWeight,
    required this.onSaveBodyGoal,
    super.key,
  });

  final BodyState? bodyState;
  final WeightUnit weightUnit;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;
  final Future<void> Function(double weightKg) onRecordCurrentWeight;
  final Future<void> Function(BodyGoalUpdate update) onSaveBodyGoal;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    if (isLoading && bodyState == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: BackButton(color: colors.textPrimary),
          title: Text(
            'Body & Weight',
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w800,
              fontSize: TioFontSize.size20,
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: colors.primary),
          ),
        ),
      );
    }

    if (hasError && bodyState == null) {
      return Scaffold(
        backgroundColor: colors.background,
        appBar: TioAppBar(
          backgroundColor: colors.background,
          elevation: TioElevation.none,
          scrolledUnderElevation: TioElevation.none,
          leading: BackButton(color: colors.textPrimary),
          title: Text(
            'Body & Weight',
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
                    'Could not load Body & Weight',
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
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return BodyWeightSettingsPage(
      bodyState: bodyState ?? const BodyState(),
      weightUnit: weightUnit,
      onRecordCurrentWeight: onRecordCurrentWeight,
      onSaveBodyGoal: onSaveBodyGoal,
    );
  }
}
