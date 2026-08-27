import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'production AppOnboardingController preserves Nutrition Profile selection and two-step navigation',
      (tester) async {
    final localStore = _MemoryLocalDraftStore();
    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
      currentStepId: OnboardingStepId.nutritionProfile,
      profile: _validProfile(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingControllerProvider.overrideWith((ref, seed) {
            return AppOnboardingController(
              entryPath: seed.entryPath,
              initialDraft: seed.draft,
              includeMobile: seed.includeMobile,
              localDraftStore: localStore,
            );
          }),
        ],
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

    expect(find.byType(DietTypeScreen), findsOneWidget);
    expect(find.byType(AllergiesRestrictionsScreen), findsNothing);

    final vegan = find.byKey(const ValueKey('nutrition-diet-vegan'));
    await tester.tap(vegan);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: vegan,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<DietTypeScreen>(find.byType(DietTypeScreen)).selectedDietType,
      NutritionDietType.vegan,
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(DietTypeScreen), findsNothing);
    expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);

    final lactose = find.byKey(const ValueKey('nutrition-allergy-lactose'));
    await tester.tap(lactose);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: lactose,
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AllergiesRestrictionsScreen>(
            find.byType(AllergiesRestrictionsScreen),
          )
          .selectedRestrictions,
      contains(NutritionAllergyRestriction.lactose),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NutritionProfileSection), findsNothing);
    expect(find.byType(WellnessSection), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(AllergiesRestrictionsScreen), findsOneWidget);
    expect(
      tester
          .widget<AllergiesRestrictionsScreen>(
            find.byType(AllergiesRestrictionsScreen),
          )
          .selectedRestrictions,
      contains(NutritionAllergyRestriction.lactose),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(DietTypeScreen), findsOneWidget);
    expect(
      tester.widget<DietTypeScreen>(find.byType(DietTypeScreen)).selectedDietType,
      NutritionDietType.vegan,
    );
  });
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'member',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

final class _MemoryLocalDraftStore implements LocalOnboardingDraftStore {
  LocalOnboardingDraftRecord? record;

  @override
  Future<void> clear() async {
    record = null;
  }

  @override
  Future<LocalOnboardingDraftRecord?> load() async => record;

  @override
  Future<void> save(LocalOnboardingDraftRecord value) async {
    record = value;
  }
}
