import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('OnboardingController Draft Persistence & Hydration', () {
    test('hydrates saved draft and resumes accurate macro and child step', () async {
      final savedDraft = OnboardingDraft(
        status: OnboardingStatus.inProgress,
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        currentStepId: OnboardingStepId.profileBasics,
        completedStepIds: {OnboardingStepId.mode},
        profile: ProfileOnboardingDraft(
          name: 'Elena',
          gender: ProfileGender.female,
          currentStepId: ProfileStepId.height,
        ),
      );

      final draftRepo = InMemoryOnboardingDraftRepository(
        initialSnapshot: OnboardingDraftSnapshot(draft: savedDraft),
      );

      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        draftRepository: draftRepo,
      );

      expect(controller.isHydrated, isFalse);

      await controller.hydrateDraft();

      expect(controller.isHydrated, isTrue);
      expect(controller.state.draft.selectedMode, AppMode.hybrid);
      expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.setupNow);
      expect(controller.state.draft.currentStepId, OnboardingStepId.profileBasics);
      expect(controller.state.draft.profile.name, 'Elena');
      expect(controller.state.draft.profile.currentStepId, ProfileStepId.height);
    });

    test('legacy target without direction associates from explicit eligible goal', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.targetWeight,
            currentWeightKg: 70,
            targetWeightKg: 64,
          ),
        ),
      );

      expect(controller.state.draft.profile.targetWeightKg, 64);
      expect(
        controller.state.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );
    });

    test('Target Weight survives eligible to ineligible to same direction', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goal,
            currentWeightKg: 70,
            targetWeightKg: 64,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
        ),
      );

      controller.tapGoalIntent(GoalIntent.maintainWeight);
      expect(controller.state.draft.profile.targetWeightKg, 64);
      expect(
        controller.state.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );

      controller.tapGoalIntent(GoalIntent.loseWeight);
      expect(controller.state.draft.profile.targetWeightKg, 64);
      expect(
        controller.state.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );
    });

    test('opposite weight direction explicitly clears incompatible target', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goal,
            currentWeightKg: 70,
            targetWeightKg: 64,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
        ),
      );

      controller.tapGoalIntent(GoalIntent.gainWeight);

      expect(controller.state.draft.profile.targetWeightKg, isNull);
      expect(controller.state.draft.profile.targetWeightDirection, isNull);
    });

    test('hydrated dormant Target Weight restores when same direction returns', () async {
      final savedDraft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.goal,
          currentWeightKg: 70,
          targetWeightKg: 64,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
      );
      final draftRepo = InMemoryOnboardingDraftRepository(
        initialSnapshot: OnboardingDraftSnapshot(draft: savedDraft),
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        draftRepository: draftRepo,
      );

      await controller.hydrateDraft();
      expect(controller.state.draft.profile.targetWeightKg, 64);

      controller.tapGoalIntent(GoalIntent.loseWeight);

      expect(controller.state.draft.profile.targetWeightKg, 64);
      expect(
        controller.state.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );
    });

    test('hydration race protection: autosave does not fire before hydration completes', () async {
      final savedDraft = OnboardingDraft(
        selectedMode: AppMode.workout,
        profile: ProfileOnboardingDraft(name: 'Existing User'),
      );

      final draftRepo = InMemoryOnboardingDraftRepository(
        initialSnapshot: OnboardingDraftSnapshot(draft: savedDraft),
      );

      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        draftRepository: draftRepo,
      );

      expect(controller.isHydrated, isFalse);
      expect((await draftRepo.loadDraft())?.draft.profile.name, 'Existing User');

      await controller.hydrateDraft();
      expect(controller.state.draft.profile.name, 'Existing User');
    });

    test('immediate autosave on mode selection and step moves', () async {
      final draftRepo = InMemoryOnboardingDraftRepository();
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        draftRepository: draftRepo,
      );

      await controller.hydrateDraft();
      expect(await draftRepo.loadDraft(), isNull);

      controller.selectMode(AppMode.nutrition);

      final savedSnapshot = await draftRepo.loadDraft();
      expect(savedSnapshot, isNotNull);
      expect(savedSnapshot!.draft.selectedMode, AppMode.nutrition);
    });

    test('save failure does not erase in-memory answers', () async {
      final draftRepo = InMemoryOnboardingDraftRepository()..shouldFailOnSave = true;
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        draftRepository: draftRepo,
      );

      await controller.hydrateDraft();

      controller.updateProfileName('Marcus');

      expect(controller.state.draft.profile.name, 'Marcus');
    });
  });
}
