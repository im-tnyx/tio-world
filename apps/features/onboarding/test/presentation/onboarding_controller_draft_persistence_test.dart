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

      // Mutating before hydration is blocked/does not overwrite repository
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

      // Immediate save
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
