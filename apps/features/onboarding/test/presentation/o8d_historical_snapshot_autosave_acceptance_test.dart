import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O8D historical snapshots and autosave recovery', () {
    const mapper = OnboardingDraftSnapshotDtoMapper();

    testWidgets('legacy unknown Wellness values stay at Review without fabricated summary',
        (tester) async {
      final restored = mapper.fromJson(_legacyReviewPayload());
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: restored.draft,
      );

      expect(controller.state.stepId, OnboardingStepId.review);
      expect(controller.state.draft.targets.hasDailyStepsValue, isFalse);
      expect(controller.state.draft.targets.hasSleepTargetMinutesValue, isFalse);
      expect(controller.state.draft.targets.hasWaterMlValue, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: TioTheme(
            child: Scaffold(
              body: SingleChildScrollView(
                child: ReviewSection(state: controller.state),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('10000 steps/day'), findsNothing);
      expect(find.text('2500 ml/day'), findsNothing);
      expect(find.text('8h 00m / night'), findsNothing);
      expect(find.text('Not set'), findsNWidgets(3));
    });

    test('legacy unknown Wellness provenance survives controller autosave and reload',
        () async {
      final restored = mapper.fromJson(_legacyReviewPayload());
      final delegate = InMemoryOnboardingDraftRepository(
        initialSnapshot: restored,
      );
      final repository = ResumePreservingOnboardingDraftRepository(
        delegate: delegate,
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        draftRepository: repository,
      );

      await controller.hydrateDraft();
      expect(controller.state.stepId, OnboardingStepId.review);

      controller.updateProfileName('Updated Legacy User');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final persisted = await delegate.loadDraft();
      expect(persisted, isNotNull);
      expect(persisted!.draft.currentStepId, OnboardingStepId.review);
      expect(persisted.draft.profile.name, 'Updated Legacy User');
      expect(persisted.draft.targets.hasDailyStepsValue, isFalse);
      expect(persisted.draft.targets.hasSleepTargetMinutesValue, isFalse);
      expect(persisted.draft.targets.hasSleepTimeMinutesValue, isFalse);
      expect(persisted.draft.targets.hasWakeTimeMinutesValue, isFalse);
      expect(persisted.draft.targets.hasWaterMlValue, isFalse);

      final reloaded = mapper.fromJson(mapper.toJson(persisted));
      expect(reloaded.draft.targets.hasDailyStepsValue, isFalse);
      expect(reloaded.draft.targets.hasSleepTargetMinutesValue, isFalse);
      expect(reloaded.draft.targets.hasSleepTimeMinutesValue, isFalse);
      expect(reloaded.draft.targets.hasWakeTimeMinutesValue, isFalse);
      expect(reloaded.draft.targets.hasWaterMlValue, isFalse);

      final canonical = const WellnessTargetsMapper().map(reloaded.draft.targets);
      expect(canonical.dailySteps, isNull);
      expect(canonical.waterMl, isNull);
      expect(canonical.sleepTargetMinutes, isNull);
      expect(canonical.bedTimeMinutes, isNull);
      expect(canonical.wakeTimeMinutes, isNull);
    });

    test('hydrate failure preserves safe seed state and completes hydration', () async {
      final seed = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(name: 'Seed User'),
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: seed,
        draftRepository: _ThrowingLoadDraftRepository(),
      );

      await controller.hydrateDraft();

      expect(controller.isHydrated, isTrue);
      expect(controller.state.draft.selectedMode, AppMode.nutrition);
      expect(controller.state.draft.profile.name, 'Seed User');
      expect(controller.state.stepId, OnboardingStepId.profileBasics);
    });

    test('failed autosave preserves answer and next edit retries latest value', () async {
      final initial = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(name: 'Original'),
      );
      final delegate = InMemoryOnboardingDraftRepository(
        initialSnapshot: OnboardingDraftSnapshot(draft: initial),
      );
      final repository = ResumePreservingOnboardingDraftRepository(
        delegate: delegate,
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        draftRepository: repository,
      );

      await controller.hydrateDraft();
      delegate.shouldFailOnSave = true;

      controller.updateProfileName('First Edit');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(controller.state.draft.profile.name, 'First Edit');
      expect((await delegate.loadDraft())!.draft.profile.name, 'Original');

      delegate.shouldFailOnSave = false;
      controller.updateProfileName('Recovered Latest');
      await Future<void>.delayed(const Duration(milliseconds: 450));

      final persisted = await delegate.loadDraft();
      expect(controller.state.draft.profile.name, 'Recovered Latest');
      expect(persisted!.draft.profile.name, 'Recovered Latest');
    });
  });
}

Map<String, dynamic> _legacyReviewPayload() {
  return <String, dynamic>{
    'schema_version': 2,
    'status': 'inProgress',
    'selected_mode': 'nutrition',
    'goal_selection': <String, dynamic>{
      'primary_goal': 'maintainWeight',
      'supporting_goal': null,
    },
    'current_step_id': 'review',
    'completed_step_ids': <String>[
      'profileBasics',
      'bodyGoal',
      'wellnessGoals',
      'nutritionProfile',
      'nutritionGoals',
      'healthConnections',
    ],
    'profile': <String, dynamic>{
      'current_step_id': 'healthConditions',
      'name': 'Legacy User',
      'gender': 'other',
      'date_of_birth': '2000-01-01',
      'height_cm': 171.0,
      'current_weight_kg': 70.0,
      'activity_level': 'active',
      'health_conditions': <String>['none'],
    },
    'targets': <String, dynamic>{
      'current_step_id': 'nutritionTarget',
      'goal_pace_kg_per_week': 0.5,
    },
  };
}

ProfileOnboardingDraft _validProfile({required String name}) {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.name,
    name: name,
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

class _ThrowingLoadDraftRepository implements OnboardingDraftRepository {
  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    throw UnsupportedError('historical payload cannot be decoded');
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {}

  @override
  Future<void> clearDraft() async {}
}
