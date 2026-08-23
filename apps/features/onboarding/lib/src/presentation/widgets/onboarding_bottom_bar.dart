import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../state/state.dart';
import 'wheels/onboarding_dob_wheel.dart';
import 'wheels/onboarding_height_wheel.dart';
import 'wheels/onboarding_weight_wheel.dart';

/// Clean data class for contextual stationary info link pinned on the bottom gradient bar.
class OnboardingBottomInfoAction {
  const OnboardingBottomInfoAction({
    required this.label,
    required this.onTap,
    this.icon = Icons.info_outline,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;
}

/// Optional secondary action for the fixed Product Onboarding bottom surface.
class OnboardingBottomSecondaryAction {
  const OnboardingBottomSecondaryAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
}

/// Unified dynamic onboarding bottom action bar.
///
/// Features:
/// - On normal screens: Smooth gradient backdrop with pinned action button and optional fixed info link.
/// - On wheel screens: Expands into full-width solid surface bottom sheet housing the drum wheel
///   while keeping the action button in the exact same pixel-precise bottom elevation and safe area.
class OnboardingBottomBar extends StatelessWidget {
  const OnboardingBottomBar({
    required this.state,
    required this.onContinue,
    this.controller,
    this.infoAction,
    this.primaryLabel,
    this.primaryEnabled,
    this.primaryLoading,
    this.primaryLoadingLabel,
    this.secondaryAction,
    super.key,
  });

  static const _normalGradientStops = <double>[0.0, 0.25, 0.70, 1.0];

  final OnboardingState state;
  final OnboardingController? controller;
  final Future<void> Function() onContinue;
  final OnboardingBottomInfoAction? infoAction;
  final String? primaryLabel;
  final bool? primaryEnabled;
  final bool? primaryLoading;
  final String? primaryLoadingLabel;
  final OnboardingBottomSecondaryAction? secondaryAction;

  bool get _isWheelStep {
    final step = state.draft.profile.currentStepId;
    if (state.stepId == OnboardingStepId.profileBasics) {
      return step == ProfileStepId.height || step == ProfileStepId.age;
    }
    if (state.stepId == OnboardingStepId.bodyGoal) {
      return step == ProfileStepId.currentWeight ||
          step == ProfileStepId.targetWeight;
    }
    return false;
  }

  ProfileStepId? get _currentProfileStep {
    if (state.stepId == OnboardingStepId.profileBasics ||
        state.stepId == OnboardingStepId.bodyGoal) {
      return state.draft.profile.currentStepId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final effectivePrimaryLabel = primaryLabel ?? state.primaryActionLabel;
    final effectivePrimaryEnabled = primaryEnabled ?? state.canContinue;
    final effectivePrimaryLoading =
        primaryLoading ?? (state.isCompleting || state.isSaving);
    final effectiveLoadingLabel = primaryLoadingLabel ??
        (state.isCompleting ? 'Finishing' : state.isSaving ? 'Saving' : null);

    if (_isWheelStep && controller != null) {
      final profileStep = _currentProfileStep;
      final draft = state.draft.profile;

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border(
            top: BorderSide(
              color: colors.outlineStrong.withAlpha(TioAlpha.alpha45),
              width: TioStroke.width1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: TioSpacing.md),
            if (profileStep == ProfileStepId.height)
              OnboardingHeightWheel(
                valueCm: draft.heightCm,
                unit: draft.heightUnit,
                onChanged: controller!.updateProfileHeight,
                onUnitChanged: controller!.updateProfileHeightUnit,
              )
            else if (profileStep == ProfileStepId.currentWeight)
              OnboardingWeightWheel(
                key: const ValueKey('current-weight-wheel'),
                valueKg: draft.currentWeightKg,
                unit: draft.weightUnit,
                onChanged: controller!.updateProfileCurrentWeight,
                onUnitChanged: controller!.updateProfileWeightUnit,
              )
            else if (profileStep == ProfileStepId.targetWeight)
              OnboardingWeightWheel(
                key: const ValueKey('target-weight-wheel'),
                valueKg: draft.targetWeightKg ?? draft.currentWeightKg,
                unit: draft.weightUnit,
                onChanged: controller!.updateProfileTargetWeight,
                onUnitChanged: controller!.updateProfileWeightUnit,
              )
            else if (profileStep == ProfileStepId.age)
              OnboardingDobWheel(
                value: draft.dateOfBirth,
                onChanged: controller!.updateProfileDateOfBirth,
              ),
            SafeArea(
              top: false,
              minimum: EdgeInsets.only(
                left: TioSpacing.lg,
                right: TioSpacing.lg,
                top: TioSpacing.sm,
                bottom:
                    TioSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.retryableError != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorMessage(state.retryableError!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.danger,
                            ),
                      ),
                    ),
                    const SizedBox(height: TioSpacing.md),
                  ],
                  TioButton.primary(
                    label: effectivePrimaryLabel,
                    loading: effectivePrimaryLoading,
                    loadingLabel: effectiveLoadingLabel,
                    expand: true,
                    enabled: effectivePrimaryEnabled,
                    onPressed: () => unawaited(onContinue()),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                  if (secondaryAction != null) ...[
                    const SizedBox(height: TioSpacing.sm),
                    TioButton.secondary(
                      label: secondaryAction!.label,
                      expand: true,
                      enabled: secondaryAction!.enabled,
                      onPressed: secondaryAction!.onTap,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: _normalGradientStops,
          colors: [
            colors.background.withValues(alpha: TioOpacity.opacity0),
            colors.background.withValues(alpha: TioOpacity.opacity50),
            colors.background.withValues(alpha: TioOpacity.opacity95),
            colors.background.withValues(alpha: TioOpacity.opacity100),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          left: TioSpacing.lg,
          right: TioSpacing.lg,
          bottom: TioSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
          top: TioSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (infoAction != null) ...[
              GestureDetector(
                onTap: infoAction!.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: TioSpacing.sm,
                    top: TioSize.dp2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        infoAction!.icon,
                        size: TioSize.dp16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: TioSpacing.sm),
                      Text(
                        infoAction!.label,
                        style: TextStyle(
                          fontSize: TioFontSize.size12,
                          fontWeight: TioFontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (state.retryableError != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _errorMessage(state.retryableError!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.danger,
                      ),
                ),
              ),
              const SizedBox(height: TioSpacing.md),
            ],
            TioButton.primary(
              label: effectivePrimaryLabel,
              loading: effectivePrimaryLoading,
              loadingLabel: effectiveLoadingLabel,
              expand: true,
              enabled: effectivePrimaryEnabled,
              onPressed: () => unawaited(onContinue()),
              trailing: state.stepId == OnboardingStepId.review
                  ? const Icon(Icons.check)
                  : const Icon(Icons.arrow_forward),
            ),
            if (secondaryAction != null) ...[
              const SizedBox(height: TioSpacing.sm),
              TioButton.secondary(
                label: secondaryAction!.label,
                expand: true,
                enabled: secondaryAction!.enabled,
                onPressed: secondaryAction!.onTap,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is StateError) return error.message;
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isNotEmpty && !raw.startsWith('Instance of')) return raw;
  return 'Could not finish setup. Please try again.';
}
