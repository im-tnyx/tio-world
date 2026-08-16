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
    super.key,
  });

  final OnboardingState state;
  final OnboardingController? controller;
  final Future<void> Function() onContinue;
  final OnboardingBottomInfoAction? infoAction;

  bool get _isWheelStep {
    if (state.stepId == OnboardingStepId.profileBasics) {
      final step = state.draft.profile.currentStepId;
      return step == ProfileStepId.height ||
          step == ProfileStepId.currentWeight ||
          step == ProfileStepId.targetWeight ||
          step == ProfileStepId.age;
    }
    return false;
  }

  ProfileStepId? get _currentProfileStep {
    if (state.stepId == OnboardingStepId.profileBasics) {
      return state.draft.profile.currentStepId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    if (_isWheelStep && controller != null) {
      final profileStep = _currentProfileStep;
      final draft = state.draft.profile;

      return Container(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          border: Border(
            top: BorderSide(
              color: colors.outlineStrong.withAlpha(45),
              width: 1.0,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            // Active Dynamic Wheel for current profile step
            if (profileStep == ProfileStepId.height)
              OnboardingHeightWheel(
                valueCm: draft.heightCm,
                unit: draft.heightUnit,
                onChanged: controller!.updateProfileHeight,
                onUnitChanged: controller!.updateProfileHeightUnit,
              )
            else if (profileStep == ProfileStepId.currentWeight)
              OnboardingWeightWheel(
                valueKg: draft.currentWeightKg,
                unit: draft.weightUnit,
                onChanged: controller!.updateProfileCurrentWeight,
                onUnitChanged: controller!.updateProfileWeightUnit,
              )
            else if (profileStep == ProfileStepId.targetWeight)
              OnboardingWeightWheel(
                valueKg: draft.targetWeightKg,
                unit: draft.weightUnit,
                onChanged: controller!.updateProfileTargetWeight,
                onUnitChanged: controller!.updateProfileWeightUnit,
              )
            else if (profileStep == ProfileStepId.age)
              OnboardingDobWheel(
                value: draft.dateOfBirth,
                onChanged: controller!.updateProfileDateOfBirth,
              ),

            // Fixed Action Button pinned inside the sheet with exact same safe area elevation
            SafeArea(
              top: false,
              minimum: EdgeInsets.only(
                left: TioSpacing.large,
                right: TioSpacing.large,
                top: TioSpacing.small,
                bottom: TioSpacing.large + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.retryableError != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Could not finish setup. Please try again.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.danger,
                            ),
                      ),
                    ),
                    const SizedBox(height: TioSpacing.medium),
                  ],
                  TioButton.primary(
                    label: state.primaryActionLabel,
                    loading: state.isCompleting || state.isSaving,
                    loadingLabel: state.isCompleting ? 'Finishing' : 'Saving',
                    expand: true,
                    enabled: state.canContinue,
                    onPressed: () => unawaited(onContinue()),
                    trailing: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Normal screens: Pure smooth gradient fade bar (No solid box, no frosted cut)
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.35, 1.0],
          colors: [
            colors.background.withValues(alpha: 0.0),
            colors.background.withValues(alpha: 0.65),
            colors.background.withValues(alpha: 1.0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          left: TioSpacing.large,
          right: TioSpacing.large,
          bottom: TioSpacing.large + MediaQuery.viewInsetsOf(context).bottom,
          top: TioSpacing.small,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed contextual Info Link on top of smooth gradient
            if (infoAction != null) ...[
              GestureDetector(
                onTap: infoAction!.onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: TioSpacing.small, top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        infoAction!.icon,
                        size: 16,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: TioSpacing.small),
                      Text(
                        infoAction!.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                  'Could not finish setup. Please try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.danger,
                      ),
                ),
              ),
              const SizedBox(height: TioSpacing.medium),
            ],
            TioButton.primary(
              label: state.primaryActionLabel,
              loading: state.isCompleting || state.isSaving,
              loadingLabel: state.isCompleting ? 'Finishing' : 'Saving',
              expand: true,
              enabled: state.canContinue,
              onPressed: () => unawaited(onContinue()),
              trailing: state.stepId == OnboardingStepId.review
                  ? const Icon(Icons.check)
                  : const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
