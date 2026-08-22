import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('legacy profileBasics snapshot resumes into active userProfile section', () {
    const mapper = OnboardingDraftSnapshotDtoMapper();
    final snapshot = mapper.fromJson({
      'schema_version': 4,
      'status': 'inProgress',
      'selected_mode': 'nutrition',
      'goal_selection': {
        'primary_goal': 'maintainWeight',
        'supporting_goal': null,
      },
      'current_step_id': 'profileBasics',
      'completed_step_ids': <String>[],
      'profile': {
        'current_step_id': 'activity',
        'name': 'Legacy User',
        'gender': 'female',
        'goals': <String>[],
        'date_of_birth': '1994-05-06',
        'height_cm': 168.0,
        'weight_unit': 'kg',
        'height_unit': 'cm',
        'distance_unit': 'km',
        'volume_unit': 'ml',
        'current_weight_kg': 64.0,
        'target_weight_kg': null,
        'target_weight_direction': null,
        'activity_level': 'active',
        'health_conditions': ['none'],
        'other_health_condition': '',
        'mobile': '',
        'is_mobile_verified': false,
      },
      'updated_at': '2026-08-21T00:00:00.000Z',
    });

    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: snapshot.draft,
    );
    addTearDown(controller.dispose);

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.currentSection, OnboardingSectionId.userProfile);
    expect(controller.state.draft.profile.name, 'Legacy User');
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.activity,
    );
    expect(controller.state.draft.profile.heightCm, 168.0);
    expect(controller.state.draft.profile.currentWeightKg, 64.0);
  });

  testWidgets('active userProfile renders the existing ProfileSection UI',
      (tester) async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          name: 'Tio User',
          gender: ProfileGender.female,
          dateOfBirth: DateTime(1994, 5, 6),
          heightCm: 168,
          currentWeightKg: 64,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
      ),
    );
    addTearDown(controller.dispose);

    expect(controller.state.currentSection, OnboardingSectionId.userProfile);

    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          child: Scaffold(
            body: OnboardingSectionRenderer(
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ProfileSection), findsOneWidget);
  });

  testWidgets('legacy profile section identity stays renderable for compatibility',
      (tester) async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          name: 'Legacy User',
          gender: ProfileGender.female,
          dateOfBirth: DateTime(1994, 5, 6),
          heightCm: 168,
          currentWeightKg: 64,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
      ),
    );
    addTearDown(controller.dispose);

    final legacyPlan = OnboardingFlowPlan(
      entryPath: OnboardingEntryPath.resumeDraft,
      mode: AppMode.nutrition,
      steps: const [
        OnboardingStepDefinition(
          id: OnboardingStepId.profileBasics,
          section: OnboardingSectionId.profile,
          owner: OnboardingStepOwner.profile,
          progressTitle: 'About you',
        ),
      ],
    );
    final legacyState = controller.state.copyWith(flowPlan: legacyPlan);

    expect(legacyState.currentSection, OnboardingSectionId.profile);

    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          child: Scaffold(
            body: OnboardingSectionRenderer(
              state: legacyState,
              controller: controller,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ProfileSection), findsOneWidget);
  });
}
