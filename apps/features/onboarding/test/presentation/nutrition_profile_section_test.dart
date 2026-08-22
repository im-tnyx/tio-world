import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('Diet Type renders approved options and updates draft', (tester) async {
    final controller = NutritionAwareOnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.nutritionProfile,
      ),
      statusRepository: const NoOpOnboardingStatusRepository(),
      completionValidator: const OnboardingCompletionValidator(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      TioTheme(
        child: MaterialApp(
          home: Scaffold(
            body: NutritionProfileSection(
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Vegetarian'), findsOneWidget);
    expect(find.text('Non-Vegetarian'), findsOneWidget);
    expect(find.text('Vegan'), findsOneWidget);
    expect(find.text('Eggitarian'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nutrition-diet-vegan')));
    await tester.pump();
    expect(controller.state.draft.nutrition.dietType, NutritionDietType.vegan);
  });

  testWidgets('Allergy None is exclusive', (tester) async {
    final controller = NutritionAwareOnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.nutritionProfile,
        nutrition: const NutritionOnboardingDraft(
          currentStepId: NutritionProfileStepId.allergiesRestrictions,
          dietType: NutritionDietType.vegetarian,
          allergyRestrictions: {NutritionAllergyRestriction.gluten},
        ),
      ),
      statusRepository: const NoOpOnboardingStatusRepository(),
      completionValidator: const OnboardingCompletionValidator(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      TioTheme(
        child: MaterialApp(
          home: Scaffold(
            body: NutritionProfileSection(
              state: controller.state,
              controller: controller,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('nutrition-allergy-none')));
    await tester.pump();
    expect(controller.state.draft.nutrition.allergyRestrictions, {
      NutritionAllergyRestriction.none,
    });
  });
}
