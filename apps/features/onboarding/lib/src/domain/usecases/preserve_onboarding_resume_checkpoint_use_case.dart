import '../models/models.dart';
import 'build_body_goal_flow_plan_use_case.dart';
import 'build_onboarding_flow_use_case.dart';
import 'build_wellness_flow_plan_use_case.dart';
import 'build_workout_flow_plan_use_case.dart';
import 'goal_intent_selection_policy.dart';
import 'profile_step_validator.dart';
import 'target_step_validator.dart';
import 'weight_goal_flow_policy.dart';
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
    BuildBodyGoalFlowPlanUseCase bodyGoalPlanner =
        const BuildBodyGoalFlowPlanUseCase(),
    BuildWellnessFlowPlanUseCase wellnessPlanner =
        const BuildWellnessFlowPlanUseCase(),
    BuildWorkoutFlowPlanUseCase workoutPlanner =
        const BuildWorkoutFlowPlanUseCase(),
    ProfileStepValidator profileValidator = const ProfileStepValidator(),
    GoalIntentSelectionPolicy goalSelectionPolicy =
        const GoalIntentSelectionPolicy(),
    WeightGoalFlowPolicy weightGoalPolicy = const WeightGoalFlowPolicy(),
    WorkoutStepValidator workoutValidator = const WorkoutStepValidator(),
    TargetStepValidator targetValidator = const TargetStepValidator(),
  })  : _flowPlanner = flowPlanner,
        _bodyGoalPlanner = bodyGoalPlanner,
        _wellnessPlanner = wellnessPlanner,
        _workoutPlanner = workoutPlanner,
        _profileValidator = profileValidator,
        _goalSelectionPolicy = goalSelectionPolicy,
        _weightGoalPolicy = weightGoalPolicy,
        _workoutValidator = workoutValidator,
        _targetValidator = targetValidator;

  final BuildOnboardingFlowUseCase _flowPlanner;
  final BuildBodyGoalFlowPlanUseCase _bodyGoalPlanner;
  final BuildWellnessFlowPlanUseCase _wellnessPlanner;
  final BuildWorkoutFlowPlanUseCase _workoutPlanner;
  final ProfileStepValidator _profileValidator;
  final GoalIntentSelectionPolicy _goalSelectionPolicy;
  final WeightGoalFlowPolicy _weightGoalPolicy;
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
    final bodyGoalFlowPlan = _bodyGoalPlanner(
      mode: visibleDraft.selectedMode,
      goalSelection: visibleDraft.goalSelection,
    );
    final wellnessFlowPlan = _wellnessPlanner();
    final workoutFlowPlan = _workoutPlanner(
      gymAccess: visibleDraft.workout.gymAccess,
    );

    final visibleCursor = _ResumeCursor.fromDraft(visibleDraft);
    final fallbackCursor = _reconcileCursor(
      visibleCursor,
      fallback: visibleCursor,
      flowPlan: flowPlan,
      bodyGoalFlowPlan: bodyGoalFlowPlan,
      wellnessFlowPlan: wellnessFlowPlan,
      workoutFlowPlan: workoutFlowPlan,
    );
    final previousCursor = previousPersistedDraft == null
        ? fallbackCursor
        : _reconcileCursor(
            _ResumeCursor.fromDraft(previousPersistedDraft),
            fallback: fallbackCursor,
            flowPlan: flowPlan,
            bodyGoalFlowPlan: bodyGoalFlowPlan,
            wellnessFlowPlan: wellnessFlowPlan,
            workoutFlowPlan: workoutFlowPlan,
          );

    final desiredCursor = _compareCursor(
              fallbackCursor,
              previousCursor,
              flowPlan: flowPlan,
              bodyGoalFlowPlan: bodyGoalFlowPlan,
              wellnessFlowPlan: wellnessFlowPlan,
              workoutFlowPlan: workoutFlowPlan,
            ) >=
            0
        ? fallbackCursor
        : previousCursor;

    final resolved = _clampToStillValidCheckpoint(
      desiredCursor,
      draft: visibleDraft,
      flowPlan: flowPlan,
      bodyGoalFlowPlan: bodyGoalFlowPlan,
      wellnessFlowPlan: wellnessFlowPlan,
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
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required WellnessFlowPlan wellnessFlowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    var stepId = cursor.stepId;

    // O3B migration: pre-O3 durable cursors stored Body-owned nested children
    // under the top-level `profileBasics` step. Move only those known child
    // identities to `bodyGoal`; common Profile children stay in userProfile.
    if (stepId == OnboardingStepId.profileBasics &&
        BodyGoalFlowPlan.orderedSteps.contains(cursor.profileStepId) &&
        flowPlan.contains(OnboardingStepId.bodyGoal)) {
      stepId = OnboardingStepId.bodyGoal;
    } else if (!flowPlan.contains(stepId)) {
      stepId = flowPlan.contains(fallback.stepId)
          ? fallback.stepId
          : flowPlan.steps.first.id;
    }

    var profileStepId = cursor.profileStepId;
    if (stepId == OnboardingStepId.profileBasics &&
        !ProfileFlowPlan.orderedSteps.contains(profileStepId)) {
      profileStepId = ProfileFlowPlan.orderedSteps.contains(fallback.profileStepId)
          ? fallback.profileStepId
          : ProfileFlowPlan.orderedSteps.first;
    } else if (stepId == OnboardingStepId.bodyGoal &&
        !bodyGoalFlowPlan.contains(profileStepId)) {
      profileStepId = bodyGoalFlowPlan.contains(fallback.profileStepId)
          ? fallback.profileStepId
          : bodyGoalFlowPlan.steps.first;
    }

    var workoutStepId = cursor.workoutStepId;
    final activeWorkoutSteps = workoutFlowPlan.stepsFor(stepId);
    if (activeWorkoutSteps.isNotEmpty) {
      if (!activeWorkoutSteps.contains(workoutStepId)) {
        workoutStepId = fallback.stepId == stepId &&
                activeWorkoutSteps.contains(fallback.workoutStepId)
            ? fallback.workoutStepId
            : activeWorkoutSteps.first;
      }
    } else if (!workoutFlowPlan.contains(workoutStepId)) {
      workoutStepId = workoutFlowPlan.contains(fallback.workoutStepId)
          ? fallback.workoutStepId
          : workoutFlowPlan.steps.first;
    }

    var targetStepId = cursor.targetStepId;
    if (stepId == OnboardingStepId.wellnessGoals &&
        !wellnessFlowPlan.contains(targetStepId)) {
      targetStepId = wellnessFlowPlan.contains(fallback.targetStepId)
          ? fallback.targetStepId
          : wellnessFlowPlan.steps.first;
    } else if (stepId == OnboardingStepId.targets &&
        !TargetsFlowPlan.orderedSteps.contains(targetStepId)) {
      targetStepId = TargetsFlowPlan.orderedSteps.contains(fallback.targetStepId)
          ? fallback.targetStepId
          : TargetsFlowPlan.orderedSteps.first;
    }

    return _ResumeCursor(
      stepId: stepId,
      profileStepId: profileStepId,
      workoutStepId: workoutStepId,
      targetStepId: targetStepId,
    );
  }

  int _compareCursor(
    _ResumeCursor left,
    _ResumeCursor right, {
    required OnboardingFlowPlan flowPlan,
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required WellnessFlowPlan wellnessFlowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final leftTop = flowPlan.indexOf(left.stepId);
    final rightTop = flowPlan.indexOf(right.stepId);
    if (leftTop != rightTop) return leftTop.compareTo(rightTop);

    return switch (left.stepId) {
      OnboardingStepId.profileBasics => _profileIndex(left.profileStepId)
          .compareTo(_profileIndex(right.profileStepId)),
      OnboardingStepId.bodyGoal => _bodyGoalIndex(
          left.profileStepId,
          bodyGoalFlowPlan,
        ).compareTo(
          _bodyGoalIndex(right.profileStepId, bodyGoalFlowPlan),
        ),
      OnboardingStepId.wellnessGoals => wellnessFlowPlan
          .indexOf(left.targetStepId)
          .compareTo(wellnessFlowPlan.indexOf(right.targetStepId)),
      OnboardingStepId.workoutProfile || OnboardingStepId.workoutTargets =>
        _workoutIndex(
          left.workoutStepId,
          workoutFlowPlan.stepsFor(left.stepId),
        ).compareTo(
          _workoutIndex(
            right.workoutStepId,
            workoutFlowPlan.stepsFor(right.stepId),
          ),
        ),
      OnboardingStepId.targets => _targetIndex(left.targetStepId)
          .compareTo(_targetIndex(right.targetStepId)),
      _ => 0,
    };
  }

  _ResolvedCheckpoint _clampToStillValidCheckpoint(
    _ResumeCursor desired, {
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required WellnessFlowPlan wellnessFlowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final desiredTopIndex = flowPlan.indexOf(desired.stepId);
    final completed = <OnboardingStepId>{};

    for (var index = 0; index < desiredTopIndex; index++) {
      final stepId = flowPlan.steps[index].id;
      final invalid = _firstInvalidCursorForCompletedSection(
        stepId,
        draft: draft,
        bodyGoalFlowPlan: bodyGoalFlowPlan,
        wellnessFlowPlan: wellnessFlowPlan,
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
      bodyGoalFlowPlan: bodyGoalFlowPlan,
      wellnessFlowPlan: wellnessFlowPlan,
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
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required WellnessFlowPlan wellnessFlowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    return switch (stepId) {
      OnboardingStepId.profileBasics => _firstInvalidProfileCursor(
          draft,
          beforeExclusive: ProfileFlowPlan.orderedSteps.length,
        ),
      OnboardingStepId.bodyGoal => _firstInvalidBodyGoalCursor(
          draft,
          bodyGoalFlowPlan: bodyGoalFlowPlan,
          beforeExclusive: bodyGoalFlowPlan.stepCount,
        ),
      OnboardingStepId.wellnessGoals => _firstInvalidWellnessCursor(
          draft,
          wellnessFlowPlan: wellnessFlowPlan,
          beforeExclusive: wellnessFlowPlan.stepCount,
        ),
      OnboardingStepId.workoutIntro => draft.workoutIntroChoice == null
          ? _ResumeCursor.fromDraft(
              draft,
              stepId: OnboardingStepId.workoutIntro,
            )
          : null,
      OnboardingStepId.workoutProfile || OnboardingStepId.workoutTargets =>
        _firstInvalidWorkoutCursor(
          draft,
          topLevelStepId: stepId,
          workoutFlowPlan: workoutFlowPlan,
          steps: workoutFlowPlan.stepsFor(stepId),
          beforeExclusive: workoutFlowPlan.stepsFor(stepId).length,
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
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required WellnessFlowPlan wellnessFlowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    return switch (desired.stepId) {
      OnboardingStepId.profileBasics => _firstInvalidProfileCursor(
          draft,
          beforeExclusive: _profileIndex(desired.profileStepId),
        ),
      OnboardingStepId.bodyGoal => _firstInvalidBodyGoalCursor(
          draft,
          bodyGoalFlowPlan: bodyGoalFlowPlan,
          beforeExclusive: _bodyGoalIndex(
            desired.profileStepId,
            bodyGoalFlowPlan,
          ),
        ),
      OnboardingStepId.wellnessGoals => _firstInvalidWellnessCursor(
          draft,
          wellnessFlowPlan: wellnessFlowPlan,
          beforeExclusive: wellnessFlowPlan.indexOf(desired.targetStepId),
        ),
      OnboardingStepId.workoutProfile || OnboardingStepId.workoutTargets =>
        _firstInvalidWorkoutCursor(
          draft,
          topLevelStepId: desired.stepId,
          workoutFlowPlan: workoutFlowPlan,
          steps: workoutFlowPlan.stepsFor(desired.stepId),
          beforeExclusive: _workoutIndex(
            desired.workoutStepId,
            workoutFlowPlan.stepsFor(desired.stepId),
          ),
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

  _ResumeCursor? _firstInvalidBodyGoalCursor(
    OnboardingDraft draft, {
    required BodyGoalFlowPlan bodyGoalFlowPlan,
    required int beforeExclusive,
  }) {
    final mode = draft.selectedMode;
    if (mode == null) {
      return _ResumeCursor.fromDraft(
        draft,
        stepId: OnboardingStepId.bodyGoal,
        profileStepId: ProfileStepId.goal,
      );
    }

    final direction = _weightGoalPolicy.directionFor(
      mode: mode,
      selection: draft.goalSelection,
    );
    final limit = beforeExclusive.clamp(0, bodyGoalFlowPlan.stepCount);
    for (var index = 0; index < limit; index++) {
      final stepId = bodyGoalFlowPlan.steps[index];
      if (stepId == ProfileStepId.goal) {
        if (_goalSelectionPolicy.validate(
              mode: mode,
              selection: draft.goalSelection,
            ) !=
            null) {
          return _ResumeCursor.fromDraft(
            draft,
            stepId: OnboardingStepId.bodyGoal,
            profileStepId: ProfileStepId.goal,
          );
        }
        continue;
      }

      final candidate = draft.profile.copyWith(currentStepId: stepId);
      if (!_profileValidator.isCurrentStepValid(
        candidate,
        weightGoalDirection: direction,
      )) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: OnboardingStepId.bodyGoal,
          profileStepId: stepId,
        );
      }
    }
    return null;
  }

  _ResumeCursor? _firstInvalidWellnessCursor(
    OnboardingDraft draft, {
    required WellnessFlowPlan wellnessFlowPlan,
    required int beforeExclusive,
  }) {
    final limit = beforeExclusive.clamp(0, wellnessFlowPlan.stepCount);
    for (var index = 0; index < limit; index++) {
      final stepId = wellnessFlowPlan.steps[index];
      final candidate = draft.targets.copyWith(currentStepId: stepId);
      if (!_targetValidator.isCurrentStepValid(
        candidate,
        profile: draft.profile,
      )) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: OnboardingStepId.wellnessGoals,
          targetStepId: stepId,
        );
      }
    }
    return null;
  }

  _ResumeCursor? _firstInvalidWorkoutCursor(
    OnboardingDraft draft, {
    required OnboardingStepId topLevelStepId,
    required WorkoutFlowPlan workoutFlowPlan,
    required List<WorkoutStepId> steps,
    required int beforeExclusive,
  }) {
    final limit = beforeExclusive.clamp(0, steps.length);
    for (var index = 0; index < limit; index++) {
      final stepId = steps[index];
      final candidate = draft.workout.copyWith(currentStepId: stepId);
      if (_workoutValidator
          .validate(draft: candidate, flowPlan: workoutFlowPlan)
          .isNotEmpty) {
        return _ResumeCursor.fromDraft(
          draft,
          stepId: topLevelStepId,
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

  int _bodyGoalIndex(
    ProfileStepId stepId,
    BodyGoalFlowPlan bodyGoalFlowPlan,
  ) {
    final index = bodyGoalFlowPlan.indexOf(stepId);
    return index < 0 ? 0 : index;
  }

  int _workoutIndex(WorkoutStepId stepId, List<WorkoutStepId> steps) {
    final index = steps.indexOf(stepId);
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
