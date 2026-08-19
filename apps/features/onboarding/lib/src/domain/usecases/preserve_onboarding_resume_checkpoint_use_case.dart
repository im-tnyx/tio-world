import '../models/models.dart';
import 'build_onboarding_flow_use_case.dart';
import 'build_workout_flow_plan_use_case.dart';
import 'profile_step_validator.dart';
import 'target_step_validator.dart';
import 'workout_step_validator.dart';

/// Separates the currently visible Back-navigation cursor from the durable
/// resume cursor written to the onboarding draft repository.
///
/// The controller may navigate backward freely in memory. Persistence keeps the
/// furthest still-valid cursor so a later authenticated session resumes where
/// forward progress last reached instead of where Back navigation stopped.
class PreserveOnboardingResumeCheckpointUseCase {
  const PreserveOnboardingResumeCheckpointUseCase({
    BuildOnboardingFlowUseCase flowPlanner = const BuildOnboardingFlowUseCase(),
    BuildWorkoutFlowPlanUseCase workoutPlanner =
        const BuildWorkoutFlowPlanUseCase(),
    ProfileStepValidator profileValidator = const ProfileStepValidator(),
    WorkoutStepValidator workoutValidator = const WorkoutStepValidator(),
    TargetStepValidator targetValidator = const TargetStepValidator(),
  })  : _flowPlanner = flowPlanner,
        _workoutPlanner = workoutPlanner,
        _profileValidator = profileValidator,
        _workoutValidator = workoutValidator,
        _targetValidator = targetValidator;

  final BuildOnboardingFlowUseCase _flowPlanner;
  final BuildWorkoutFlowPlanUseCase _workoutPlanner;
  final ProfileStepValidator _profileValidator;
  final WorkoutStepValidator _workoutValidator;
  final TargetStepValidator _targetValidator;

  OnboardingDraft call({
    required OnboardingEntryPath entryPath,
    required OnboardingDraft visibleDraft,
    OnboardingDraft? previousPersistedDraft,
    @Deprecated('Mobile belongs to Account Setup and is never included here.')
    bool includeMobile = false,
  }) {
    final flowPlan = _flowPlanner(
      entryPath: entryPath,
      mode: visibleDraft.selectedMode,
      workoutIntroChoice: visibleDraft.workoutIntroChoice,
      includeMobile: includeMobile,
    );
    final workoutFlowPlan = _workoutPlanner(
      gymAccess: visibleDraft.workout.gymAccess,
    );

    final visibleCursor = _ResumeCursor.fromDraft(visibleDraft);
    final fallbackCursor = _reconcileCursor(
      visibleCursor,
      fallback: visibleCursor,
      flowPlan: flowPlan,
      workoutFlowPlan: workoutFlowPlan,
    );
    final previousCursor = previousPersistedDraft == null
        ? fallbackCursor
        : _reconcileCursor(
            _ResumeCursor.fromDraft(previousPersistedDraft),
            fallback: fallbackCursor,
            flowPlan: flowPlan,
            workoutFlowPlan: workoutFlowPlan,
          );

    final desiredCursor = _compareCursor(
              fallbackCursor,
              previousCursor,
              flowPlan: flowPlan,
              workoutFlowPlan: workoutFlowPlan,
            ) >=
            0
        ? fallbackCursor
        : previousCursor;

    final resolved = _clampToStillValidCheckpoint(
      desiredCursor,
      draft: visibleDraft,
      flowPlan: flowPlan,
      workoutFlowPlan: workoutFlowPlan,
    );

    return visibleDraft.copyWith(
      currentStepId: resolved.cursor.stepId,
      profile: visibleDraft.profile.copyWith(
        currentStepId: resolved.cursor.profileStepId,
      ),
      workout: visibleDraft.workout.copyWith(
        currentStepId: resolved.cursor.workoutStepId,
      ),
      targets: visibleDraft.targets.copyWith(
        currentStepId: resolved.cursor.targetStepId,
      ),
      completedStepIds: resolved.completedStepIds,
    );
  }

  _ResumeCursor _reconcileCursor(
    _ResumeCursor cursor, {
    required _ResumeCursor fallback,
    required OnboardingFlowPlan flowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final stepId = flowPlan.contains(cursor.stepId)
        ? cursor.stepId
        : flowPlan.contains(fallback.stepId)
            ? fallback.stepId
            : flowPlan.steps.first.id;
    final workoutStepId = workoutFlowPlan.contains(cursor.workoutStepId)
        ? cursor.workoutStepId
        : workoutFlowPlan.contains(fallback.workoutStepId)
            ? fallback.workoutStepId
            : workoutFlowPlan.steps.first;

    return _ResumeCursor(
      stepId: stepId,
      profileStepId: cursor.profileStepId,
      workoutStepId: workoutStepId,
      targetStepId: cursor.targetStepId,
    );
  }

  int _compareCursor(
    _ResumeCursor left,
    _ResumeCursor right, {
    required OnboardingFlowPlan flowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final leftTop = flowPlan.indexOf(left.stepId);
    final rightTop = flowPlan.indexOf(right.stepId);
    if (leftTop != rightTop) return leftTop.compareTo(rightTop);

    return switch (left.stepId) {
      OnboardingStepId.profileBasics => _profileIndex(left.profileStepId)
          .compareTo(_profileIndex(right.profileStepId)),
      OnboardingStepId.workoutPreferences => workoutFlowPlan
          .indexOf(left.workoutStepId)
          .compareTo(workoutFlowPlan.indexOf(right.workoutStepId)),
      OnboardingStepId.targets => _targetIndex(left.targetStepId)
          .compareTo(_targetIndex(right.targetStepId)),
      _ => 0,
    };
  }

  _ResolvedCheckpoint _clampToStillValidCheckpoint(
    _ResumeCursor desired, {
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final desiredTopIndex = flowPlan.indexOf(desired.stepId);
    final completed = <OnboardingStepId>{};

    for (var index = 0; index < desiredTopIndex; index++) {
      final stepId = flowPlan.steps[index].id;
      final invalid = _firstInvalidCursorForCompletedSection(
        stepId,
        draft: draft,
        workoutFlowPlan: workoutFlowPlan,
      );
      if (invalid != null) {
        return _ResolvedCheckpoint(
          cursor: invalid,
          completedStepIds: completed,
        );
      }
      completed.add(stepId);
    }

    final invalidBeforeDesired = _firstInvalidCursorBeforeDesired(
      desired,
      draft: draft,
      workoutFlowPlan: workoutFlowPlan,
    );
    if (invalidBeforeDesired != null) {
      return _ResolvedCheckpoint(
        cursor: invalidBeforeDesired,
        completedStepIds: completed,
      );
    }

    return _ResolvedCheckpoint(
      cursor: desired,
      completedStepIds: completed,
    );
  }

  _ResumeCursor? _firstInvalidCursorForCompletedSection(
    OnboardingStepId stepId, {
    required OnboardingDraft draft,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    return switch (stepId) {
      OnboardingStepId.profileBasics => _firstInvalidProfileCursor(
          draft,
          beforeExclusive: ProfileFlowPlan.orderedSteps.length,
        ),
      OnboardingStepId.workoutIntro => draft.workoutIntroChoice == null
          ? _ResumeCursor.fromDraft(
              draft,
              stepId: OnboardingStepId.workoutIntro,
            )
          : null,
      OnboardingStepId.workoutPreferences => _firstInvalidWorkoutCursor(
          draft,
          workoutFlowPlan: workoutFlowPlan,
          beforeExclusive: workoutFlowPlan.stepCount,
        ),
      OnboardingStepId.targets => _firstInvalidTargetCursor(
          draft,
          beforeExclusive: TargetsFlowPlan.orderedSteps.length,
        ),
      _ => null,
    };
  }

  _ResumeCursor? _firstInvalidCursorBeforeDesired(
    _ResumeCursor desired, {
    required OnboardingDraft draft,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    return switch (desired.stepId) {
      OnboardingStepId.profileBasics => _firstInvalidProfileCursor(
          draft,
          beforeExclusive: _profileIndex(desired.profileStepId),
        ),
      OnboardingStepId.workoutPreferences => _firstInvalidWorkoutCursor(
          draft,
          workoutFlowPlan: workoutFlowPlan,
          beforeExclusive: workoutFlowPlan.indexOf(desired.workoutStepId),
        ),
      OnboardingStepId.targets => _firstInvalidTargetCursor(
          draft,
          beforeExclusive: _targetIndex(desired.targetStepId),
        ),
      _ => null,
    };
  }

  _ResumeCursor? _firstInvalidProfileCursor(
    OnboardingDraft draft, {
    required int beforeExclusive,
  }) {
    final limit = beforeExclusive.clamp(0, ProfileFlowPlan.orderedSteps.length);
    for (var index = 0; index < limit; index++) {
      final stepId = ProfileFlowPlan.orderedSteps[index];
      final candidate = draft.profile.copyWith(currentStepId: stepId);
      if (!_profileValidator.isCurrentStepValid(candidate)) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: OnboardingStepId.profileBasics,
          profileStepId: stepId,
        );
      }
    }
    return null;
  }

  _ResumeCursor? _firstInvalidWorkoutCursor(
    OnboardingDraft draft, {
    required WorkoutFlowPlan workoutFlowPlan,
    required int beforeExclusive,
  }) {
    final limit = beforeExclusive.clamp(0, workoutFlowPlan.stepCount);
    for (var index = 0; index < limit; index++) {
      final stepId = workoutFlowPlan.steps[index];
      final candidate = draft.workout.copyWith(currentStepId: stepId);
      if (_workoutValidator
          .validate(draft: candidate, flowPlan: workoutFlowPlan)
          .isNotEmpty) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: OnboardingStepId.workoutPreferences,
          workoutStepId: stepId,
        );
      }
    }
    return null;
  }

  _ResumeCursor? _firstInvalidTargetCursor(
    OnboardingDraft draft, {
    required int beforeExclusive,
  }) {
    final limit = beforeExclusive.clamp(0, TargetsFlowPlan.orderedSteps.length);
    for (var index = 0; index < limit; index++) {
      final stepId = TargetsFlowPlan.orderedSteps[index];
      final candidate = draft.targets.copyWith(currentStepId: stepId);
      if (!_targetValidator.isCurrentStepValid(
        candidate,
        profile: draft.profile,
      )) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: OnboardingStepId.targets,
          targetStepId: stepId,
        );
      }
    }
    return null;
  }

  int _profileIndex(ProfileStepId stepId) {
    final index = ProfileFlowPlan.orderedSteps.indexOf(stepId);
    return index < 0 ? 0 : index;
  }

  int _targetIndex(TargetStepId stepId) {
    final index = TargetsFlowPlan.orderedSteps.indexOf(stepId);
    return index < 0 ? 0 : index;
  }
}

class _ResolvedCheckpoint {
  const _ResolvedCheckpoint({
    required this.cursor,
    required this.completedStepIds,
  });

  final _ResumeCursor cursor;
  final Set<OnboardingStepId> completedStepIds;
}

class _ResumeCursor {
  const _ResumeCursor({
    required this.stepId,
    required this.profileStepId,
    required this.workoutStepId,
    required this.targetStepId,
  });

  factory _ResumeCursor.fromDraft(
    OnboardingDraft draft, {
    OnboardingStepId? stepId,
    ProfileStepId? profileStepId,
    WorkoutStepId? workoutStepId,
    TargetStepId? targetStepId,
  }) {
    return _ResumeCursor(
      stepId: stepId ?? draft.currentStepId,
      profileStepId: profileStepId ?? draft.profile.currentStepId,
      workoutStepId: workoutStepId ?? draft.workout.currentStepId,
      targetStepId: targetStepId ?? draft.targets.currentStepId,
    );
  }

  final OnboardingStepId stepId;
  final ProfileStepId profileStepId;
  final WorkoutStepId workoutStepId;
  final TargetStepId targetStepId;
}
