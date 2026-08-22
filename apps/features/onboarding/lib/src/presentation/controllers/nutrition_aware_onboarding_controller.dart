import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/domain.dart';
import 'onboarding_controller.dart';

final onboardingControllerProvider = ChangeNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingControllerSeed>((ref, seed) {
  final controller = NutritionAwareOnboardingController(
    entryPath: seed.entryPath,
    initialDraft: seed.draft,
    includeMobile: seed.includeMobile,
    statusRepository: ref.watch(onboardingStatusRepositoryProvider),
    draftRepository: ref.watch(onboardingDraftRepositoryProvider),
    completionValidator: ref.watch(onboardingCompletionValidatorProvider),
  );
  unawaited(controller.hydrateDraft());
  return controller;
});

class NutritionAwareOnboardingController extends OnboardingController {
  NutritionAwareOnboardingController({
    required super.entryPath,
    super.initialDraft,
    super.includeMobile,
    required super.statusRepository,
    required super.completionValidator,
    super.draftRepository,
  })  : _statusRepository = statusRepository,
        _draftRepository = draftRepository;

  final OnboardingStatusRepository _statusRepository;
  final OnboardingDraftRepository? _draftRepository;
  final NutritionProfileStepValidator _nutritionValidator =
      const NutritionProfileStepValidator();

  void updateNutritionDietType(NutritionDietType value) {
    if (state.isBusy) return;
    _updateNutrition(
      state.draft.nutrition.copyWith(dietType: value),
    );
  }

  void toggleNutritionAllergyRestriction(
    NutritionAllergyRestriction restriction,
  ) {
    if (state.isBusy) return;
    final current = state.draft.nutrition;
    final next = <NutritionAllergyRestriction>{
      ...?current.allergyRestrictions,
    };

    if (restriction == NutritionAllergyRestriction.none) {
      next
        ..clear()
        ..add(NutritionAllergyRestriction.none);
    } else {
      next.remove(NutritionAllergyRestriction.none);
      if (!next.remove(restriction)) next.add(restriction);
    }

    _updateNutrition(current.copyWith(allergyRestrictions: next));
  }

  @override
  void previous() {
    if (state.isBusy) return;
    if (state.stepId == OnboardingStepId.nutritionProfile) {
      final previous =
          state.nutritionProfileFlowPlan.previous(state.draft.nutrition.currentStepId);
      if (previous != null) {
        _moveNutritionStep(previous);
        return;
      }
    }
    super.previous();
  }

  @override
  Future<void> next({
    required Future<void> Function(OnboardingDraft draft) onFinish,
    Future<bool> Function()? onAuthRequired,
  }) async {
    if (state.isBusy) return;
    if (state.stepId == OnboardingStepId.nutritionProfile) {
      final error = _nutritionValidator.validateCurrentStep(state.draft.nutrition);
      if (error != null) {
        setValidationErrors({state.draft.nutrition.currentStepId.name: error});
        return;
      }
      final nextStep =
          state.nutritionProfileFlowPlan.next(state.draft.nutrition.currentStepId);
      if (nextStep != null) {
        _moveNutritionStep(nextStep);
        return;
      }
    }
    await super.next(onFinish: onFinish, onAuthRequired: onAuthRequired);
  }

  void _updateNutrition(NutritionOnboardingDraft nutrition) {
    final completed = {...state.completedStepIds}
      ..remove(OnboardingStepId.nutritionProfile);
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      nutrition: nutrition,
      completedStepIds: completed,
    );
    super.initialize(nextDraft);
    unawaited(_persistNutritionDraft(writeStatus: true));
  }

  void _moveNutritionStep(NutritionProfileStepId stepId) {
    final nextDraft = state.draft.copyWith(
      nutrition: state.draft.nutrition.copyWith(currentStepId: stepId),
    );
    super.initialize(nextDraft);
    unawaited(_persistNutritionDraft());
  }

  Future<void> _persistNutritionDraft({bool writeStatus = false}) async {
    if (writeStatus) {
      try {
        await _statusRepository.write(OnboardingStatus.inProgress);
      } catch (_) {}
    }
    final repository = _draftRepository;
    if (repository == null) return;
    try {
      await repository.saveDraft(OnboardingDraftSnapshot(draft: state.draft));
    } catch (_) {
      // Keep the in-memory draft authoritative for the active session.
    }
  }
}

extension NutritionProfileOnboardingActions on OnboardingController {
  NutritionAwareOnboardingController get _nutritionAware {
    final controller = this;
    if (controller is NutritionAwareOnboardingController) return controller;
    throw StateError('Nutrition Profile requires the O5B onboarding controller.');
  }

  void updateNutritionDietType(NutritionDietType value) =>
      _nutritionAware.updateNutritionDietType(value);

  void toggleNutritionAllergyRestriction(
    NutritionAllergyRestriction restriction,
  ) =>
      _nutritionAware.toggleNutritionAllergyRestriction(restriction);
}
