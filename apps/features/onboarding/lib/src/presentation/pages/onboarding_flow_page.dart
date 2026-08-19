import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../dialogs/age_verification_dialogs.dart';
import '../state/state.dart';
import '../widgets/widgets.dart';

class OnboardingFlowPage extends ConsumerWidget {
  const OnboardingFlowPage({
    required this.seed,
    required this.onFinishRequested,
    super.key,
    this.onExitRequested,
    this.onAuthRequired,
    this.stepBuilder,
  });

  final OnboardingControllerSeed seed;
  final OnboardingStepBuilder? stepBuilder;
  final Future<void> Function(OnboardingDraft draft) onFinishRequested;
  final Future<void> Function()? onExitRequested;

  /// Retained temporarily for source compatibility with older app wiring.
  /// Product Onboarding is authenticated-only, so active flow navigation no
  /// longer invokes a mid-onboarding authentication checkpoint.
  final Future<bool> Function()? onAuthRequired;

  Future<void> _handleContinue(
    BuildContext context,
    OnboardingState state,
    OnboardingController controller,
  ) async {
    if (state.stepId == OnboardingStepId.profileBasics &&
        state.draft.profile.currentStepId == ProfileStepId.age) {
      final dob = state.draft.profile.dateOfBirth ?? DateTime.now();
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      if (age < 13) {
        final confirmed =
            await AgeVerificationDialogs.showConfirmation(context, dob);
        if (confirmed == true && context.mounted) {
          await AgeVerificationDialogs.showUnderageRejection(context);
        }
        return;
      }
    }

    await controller.next(
      onFinish: onFinishRequested,
    );
  }

  void _handleBack(
    BuildContext context,
    OnboardingController controller,
  ) {
    final state = controller.state;
    if (state.isBusy) return;

    if (state.hasPreviousScreen) {
      controller.previous();
      return;
    }

    if (onExitRequested != null) {
      unawaited(_confirmRootExit(context));
    }
  }

  Future<void> _confirmRootExit(BuildContext context) async {
    final exit = onExitRequested;
    if (exit == null) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.lg),
            child: TioConfirmationCard(
              key: const ValueKey('onboarding-exit-confirmation-card'),
              icon: const Icon(Icons.logout_rounded),
              title: 'Log out of Tio?',
              message:
                  'You’ll return to Welcome. Your onboarding progress will stay saved so you can continue after signing in again.',
              cancelLabel: 'Stay',
              confirmLabel: 'Log out',
              onCancel: () => Navigator.of(sheetContext).pop(false),
              onConfirm: () => Navigator.of(sheetContext).pop(true),
            ),
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await exit();
    }
  }

  void _showGoalDataCollectionSheet(BuildContext context) {
    unawaited(
      showOnboardingDataCollectionSheet(
        context: context,
        body:
            'Your fitness goals help Tio calculate baseline energy expenditure, macro distribution, and customized training splits.\n\n'
            'Primary goals define your target workout intensity, while supporting goals tailor your recovery and mobility recommendations.\n\n'
            'All data is encrypted and used solely for tailoring your personal fitness plan.',
      ),
    );
  }

  void _showActivityDataCollectionSheet(BuildContext context) {
    unawaited(
      showOnboardingDataCollectionSheet(
        context: context,
        body:
            'We value your trust and appreciate the importance of your daily routine in shaping your fitness journey. The reason we ask about your whole-day activity is to design a plan that aligns seamlessly with your lifestyle.\n\n'
            'Your activity levels help us determine the most suitable calorie targets, energy expenditure, and exercise recommendations for you.\n\n'
            'By understanding how active you are throughout the day, we can provide personalized guidance that fits your routine and ensures you stay on track with your goals, one step at a time.',
      ),
    );
  }

  void _showHealthDataCollectionSheet(BuildContext context) {
    unawaited(
      showOnboardingDataCollectionSheet(
        context: context,
        body:
            'We value your trust and understand that your health is personal.\n\n'
            'The reason we ask about health conditions like diabetes, low blood pressure, or high blood pressure is to create a safe and effective plan tailored to your needs.\n\n'
            'This ensures that our recommendations align with your health and fitness goals while prioritizing your well-being every step of the way.',
      ),
    );
  }

  void _showMobileDataCollectionSheet(BuildContext context) {
    unawaited(
      showOnboardingDataCollectionSheet(
        context: context,
        body:
            'Your mobile number can support account recovery, future security options, and optional reminders. Adding it is optional in the current release.\n\n'
            'Entering a number does not mark it as verified. Verification is only recognized when a trusted authentication provider or backend supplies verification evidence.\n\n'
            'We use this information only for account and product features you choose to use and do not sell your contact information.',
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(onboardingControllerProvider(seed));
    final shouldGateHydration = ref.watch(onboardingHydrationGateProvider);

    if (shouldGateHydration && !controller.isHydrated) {
      return Scaffold(
        backgroundColor: context.tioColors.background,
        body: const SizedBox.expand(),
      );
    }

    final state = controller.state;
    final shouldHandleRouteExit = onExitRequested != null;
    final visibleBack = state.hasPreviousScreen || shouldHandleRouteExit
        ? () => _handleBack(context, controller)
        : null;

    OnboardingBottomInfoAction? infoAction;
    if (state.stepId == OnboardingStepId.mobile) {
      infoAction = OnboardingBottomInfoAction(
        label: 'Why do we ask for your mobile number?',
        onTap: () => _showMobileDataCollectionSheet(context),
      );
    } else if (state.stepId == OnboardingStepId.profileBasics) {
      final step = state.draft.profile.currentStepId;
      if (step == ProfileStepId.goal) {
        infoAction = OnboardingBottomInfoAction(
          label: 'Why we collect this data',
          onTap: () => _showGoalDataCollectionSheet(context),
        );
      } else if (step == ProfileStepId.activity) {
        infoAction = OnboardingBottomInfoAction(
          label: 'Why do we need this information?',
          onTap: () => _showActivityDataCollectionSheet(context),
        );
      } else if (step == ProfileStepId.healthConditions) {
        infoAction = OnboardingBottomInfoAction(
          label: 'Why do we need this information?',
          onTap: () => _showHealthDataCollectionSheet(context),
        );
      }
    }

    return PopScope(
      canPop:
          !state.isBusy && !state.hasPreviousScreen && !shouldHandleRouteExit,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context, controller);
      },
      child: Scaffold(
        backgroundColor: context.tioColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              OnboardingTopBar(
                state: state,
                onBack: visibleBack,
                showProgress: state.stepId != OnboardingStepId.mode,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OnboardingContentHost(
                        state: state,
                        controller: controller,
                        stepBuilder: stepBuilder,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: OnboardingBottomBar(
                        state: state,
                        controller: controller,
                        infoAction: infoAction,
                        onContinue: () =>
                            _handleContinue(context, state, controller),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
