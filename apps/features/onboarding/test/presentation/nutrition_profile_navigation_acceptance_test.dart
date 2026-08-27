import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'fresh Nutrition Profile runs Diet Type then Allergies then Wellness and Back preserves answers',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await _pumpFlow(
        tester,
        OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.maintainWeight,
          ),
          currentStepId: OnboardingStepId.nutritionProfile,
          profile: _validProfile(),
        ),
      );

      expect(find.byType(NutritionProfileSection), findsOneWidget);
      expect(find.byType(DietTypeScreen), findsOneWidget);
      expect(find.byType(AllergiesRestrictionsScreen), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Nutrition profile step 1 of 2, What type of diet do you follow?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nutrition-diet-vegan')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(DietTypeScreen), findsNothing);
      expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Nutrition profile step 2 of 2, Any food allergies or restrictions?',
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('nutrition-allergy-lactose')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nutrition-allergy-gluten')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.byType(NutritionProfileSection), findsNothing);
      expect(find.byType(WellnessSection), findsOneWidget);
      expect(find.byType(BridgeScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);
      final allergiesScreen = tester.widget<AllergiesRestrictionsScreen>(
        find.byType(AllergiesRestrictionsScreen),
      );
      expect(
        allergiesScreen.selectedRestrictions,
        containsAll(const [
          NutritionAllergyRestriction.lactose,
          NutritionAllergyRestriction.gluten,
        ]),
      );

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(DietTypeScreen), findsOneWidget);
      final dietScreen = tester.widget<DietTypeScreen>(
        find.byType(DietTypeScreen),
      );
      expect(dietScreen.selectedDietType, NutritionDietType.vegan);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('Other details show inline and survive Nutrition Back navigation',
      (tester) async {
    await _pumpFlow(
      tester,
      OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.nutritionProfile,
        profile: _validProfile(),
      ),
    );

    expect(
      find.byKey(const ValueKey('nutrition-diet-other-text-field')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('nutrition-diet-other')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('nutrition-diet-other-text-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('nutrition-diet-other-text-field')),
      'Jain',
    );
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('nutrition-allergy-other-text-field')),
      findsNothing,
    );

    final allergyOther =
        find.byKey(const ValueKey('nutrition-allergy-other'));
    await tester.ensureVisible(allergyOther);
    await tester.pumpAndSettle();
    await tester.tap(allergyOther);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('nutrition-allergy-other-text-field')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('nutrition-allergy-other-text-field')),
      'Sesame',
    );
    await tester.pump();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(WellnessSection), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final allergyScreen = tester.widget<AllergiesRestrictionsScreen>(
      find.byType(AllergiesRestrictionsScreen),
    );
    expect(
      allergyScreen.selectedRestrictions,
      contains(NutritionAllergyRestriction.other),
    );
    expect(allergyScreen.otherText, 'Sesame');
    expect(find.text('Sesame'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    final dietScreen = tester.widget<DietTypeScreen>(find.byType(DietTypeScreen));
    expect(dietScreen.selectedDietType, NutritionDietType.other);
    expect(dietScreen.otherText, 'Jain');
    expect(find.text('Jain'), findsOneWidget);
  });

  testWidgets('exact Nutrition Profile resume preserves the Allergies child cursor',
      (tester) async {
    await _pumpFlow(
      tester,
      OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.nutritionProfile,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          currentStepId: NutritionProfileStepId.allergiesRestrictions,
          dietType: NutritionDietType.vegetarian,
          allergyRestrictions: {NutritionAllergyRestriction.none},
        ),
      ),
    );

    expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);
    expect(find.byType(DietTypeScreen), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(DietTypeScreen), findsOneWidget);
    final dietScreen = tester.widget<DietTypeScreen>(
      find.byType(DietTypeScreen),
    );
    expect(dietScreen.selectedDietType, NutritionDietType.vegetarian);
  });

  testWidgets('Hybrid Later enters Nutrition Profile at Diet Type',
      (tester) async {
    await _pumpFlow(
      tester,
      OnboardingDraft(
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(
          targetWeightKg: 65,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
      ),
    );

    expect(find.byType(WorkoutIntroScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NutritionProfileSection), findsOneWidget);
    expect(find.byType(DietTypeScreen), findsOneWidget);
    expect(find.byType(AllergiesRestrictionsScreen), findsNothing);
  });

  testWidgets(
      'Hybrid Setup Now enters Nutrition Profile at Diet Type after Workout Targets',
      (tester) async {
    await _pumpFlow(
      tester,
      OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
          supportingGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.workoutTargets,
        profile: _validProfile(),
        workout: _validWorkout(),
      ),
    );

    expect(find.byType(WorkoutSection), findsOneWidget);
    expect(find.byType(SpecialEventScreen), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NutritionProfileSection), findsOneWidget);
    expect(find.byType(DietTypeScreen), findsOneWidget);
    expect(find.byType(AllergiesRestrictionsScreen), findsNothing);
  });
}

Future<void> _pumpFlow(WidgetTester tester, OnboardingDraft draft) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: TioTheme(
          child: OnboardingFlowPage(
            seed: OnboardingControllerSeed(
              entryPath: OnboardingEntryPath.firstRun,
              draft: draft,
            ),
            onFinishRequested: (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProfileOnboardingDraft _validProfile({
  double targetWeightKg = 70,
  GoalWeightDirection? targetWeightDirection,
}) {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'Nutrition Audit',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: targetWeightKg,
    targetWeightDirection: targetWeightDirection,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    currentStepId: WorkoutStepId.specialEvent,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
  );
}
