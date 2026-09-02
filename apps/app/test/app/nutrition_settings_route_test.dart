import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

/// Route-level coverage for Nutrition Settings: App Mode gating of the
/// Settings entry, navigation into the Nutrition hub and Nutrition Profile,
/// and that a canonical save merges rather than truncates the row.
void main() {
  Future<ProviderContainer> buildContainer({
    required AppMode appMode,
    required _FakeNutritionProfileRepository repository,
    _FakeNutritionTargetsRepository? targets,
    /// Canonical Profile stream. Supplied so a route can be exercised against
    /// a profile that failed to load, which is a different state from one
    /// that simply has no date of birth.
    Stream<ProfileSetupData?>? profileStream,
  }) async {
    final targetsRepository = targets ?? _FakeNutritionTargetsRepository();
    final preference = _MemoryAppModePreference(appMode);
    final appModeController = AppModeController(preference);
    await appModeController.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: appModeController,
    );
    await onboardingStatusController.load();
    final themeController =
        AppThemeController(_MemoryAppThemePreference(TioThemeMode.system));
    await themeController.load();

    return ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => appModeController),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
        nutritionProfileRepositoryProvider.overrideWith((ref) => repository),
        nutritionTargetsRepositoryProvider
            .overrideWith((ref) => targetsRepository),
        if (profileStream != null)
          profileDataProvider.overrideWith((ref) => profileStream),
      ],
    );
  }

  Future<void> openSettings(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    final router = container.read(goRouterProvider);
    router.go(AppRoutes.settings.path);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pumpAndSettle();
  }

  test('both Nutrition routes are registered in the shell chrome policy', () {
    // Missing entries silently fall through to `noBottomBar`, which would
    // leave these full-screen Settings sub-pages rendering shell chrome.
    expect(
      shellChromePolicyForPath(AppRoutes.nutritionSettings.path),
      ChromePolicy.fullScreen,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.nutritionProfileSettings.path),
      ChromePolicy.fullScreen,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.nutritionTargetsSettings.path),
      ChromePolicy.fullScreen,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.nutritionMacrosSettings.path),
      ChromePolicy.fullScreen,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.nutritionAdditionalGoalsSettings.path),
      ChromePolicy.fullScreen,
    );
    // Negative control: the fallback is a different policy, so the two
    // assertions above genuinely prove registration rather than passing by
    // coincidence.
    expect(
      shellChromePolicyForPath('/settings/nutrition/not-registered'),
      ChromePolicy.noBottomBar,
    );
  });

  for (final mode in [AppMode.nutrition, AppMode.hybrid]) {
    testWidgets('Settings exposes Nutrition in $mode mode', (tester) async {
      final repository = _FakeNutritionProfileRepository();
      final container =
          await buildContainer(appMode: mode, repository: repository);
      addTearDown(container.dispose);

      await openSettings(tester, container);

      expect(
        find.byKey(const ValueKey('settings-nutrition-entry')),
        findsOneWidget,
      );
      // Reading canonical App Mode must not touch the Nutrition owner.
      expect(repository.readCount, 0);
    });
  }

  testWidgets('Settings hides Nutrition in workout mode', (tester) async {
    final repository = _FakeNutritionProfileRepository();
    final container = await buildContainer(
      appMode: AppMode.workout,
      repository: repository,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);

    expect(
        find.byKey(const ValueKey('settings-nutrition-entry')), findsNothing);
    expect(find.text('NUTRITION'), findsNothing);
    expect(repository.readCount, 0);
  });

  testWidgets('changing App Mode updates the entry without any canonical write',
      (tester) async {
    final repository = _FakeNutritionProfileRepository();
    final container = await buildContainer(
      appMode: AppMode.workout,
      repository: repository,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);
    expect(
        find.byKey(const ValueKey('settings-nutrition-entry')), findsNothing);

    await container.read(appModeControllerProvider).select(AppMode.hybrid);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-nutrition-entry')),
      findsOneWidget,
    );
    expect(repository.writes, isEmpty);
    expect(repository.readCount, 0);
  });

  testWidgets('Settings navigates to the Nutrition hub and Nutrition Profile',
      (tester) async {
    final repository = _FakeNutritionProfileRepository(
      stored: const NutritionProfileData(
        preferredDiet: 'vegetarian',
        allergies: {'gluten'},
        dislikedFoods: {'okra'},
        medicalConditions: {'diabetes'},
      ),
    );
    final container = await buildContainer(
      appMode: AppMode.nutrition,
      repository: repository,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);
    await tester.tap(find.byKey(const ValueKey('settings-nutrition-entry')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('nutrition-settings-profile-entry')),
      findsOneWidget,
    );

    await tester
        .tap(find.byKey(const ValueKey('nutrition-settings-profile-entry')));
    await tester.pumpAndSettle();

    expect(find.text('Vegetarian'), findsOneWidget);
    expect(find.text('Gluten'), findsOneWidget);
  });

  testWidgets('Nutrition hub navigates to Nutrition Targets and loads values',
      (tester) async {
    final repository = _FakeNutritionProfileRepository();
    final targets = _FakeNutritionTargetsRepository(
      stored: const NutritionTargetsData(
        caloriesKcal: 1900,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
        fiberGrams: 28,
        customizationState: NutritionTargetCustomizationState.recommended,
        recommendationMetadata: {'source': 'onboarding'},
      ),
    );
    final container = await buildContainer(
      appMode: AppMode.nutrition,
      repository: repository,
      targets: targets,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);
    await tester.tap(find.byKey(const ValueKey('settings-nutrition-entry')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('nutrition-settings-targets-entry')));
    await tester.pumpAndSettle();

    expect(find.text('1900 kcal'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text('28 g'), findsOneWidget);
  });

  testWidgets('a target save preserves the rest of the canonical row',
      (tester) async {
    final repository = _FakeNutritionProfileRepository();
    final targets = _FakeNutritionTargetsRepository(
      stored: const NutritionTargetsData(
        caloriesKcal: 1900,
        proteinGrams: 150,
        carbohydrateGrams: 200,
        fatGrams: 55.6,
        fiberGrams: 28,
        customizationState: NutritionTargetCustomizationState.recommended,
        recommendationMetadata: {'source': 'onboarding', 'bmr': 1600},
      ),
    );
    final container = await buildContainer(
      appMode: AppMode.hybrid,
      repository: repository,
      targets: targets,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);
    await tester.tap(find.byKey(const ValueKey('settings-nutrition-entry')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('nutrition-settings-targets-entry')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('nutrition-target-fiber-field')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nutrition-target-fiber-input')),
      '32',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nutrition-target-fiber-save')));
    await tester.pumpAndSettle();

    expect(targets.writes, hasLength(1));
    final written = targets.writes.single;
    expect(written.fiberGrams, 32);
    expect(written.caloriesKcal, 1900);
    expect(written.proteinGrams, 150);
    expect(written.carbohydrateGrams, 200);
    expect(written.fatGrams, 55.6);
    expect(
        written.recommendationMetadata, {'source': 'onboarding', 'bmr': 1600});
    expect(written.customizedFields, {'fiber'});

    // The route re-read the canonical owner, so the row is not stale.
    expect(targets.readCount, greaterThan(1));
    expect(find.text('32 g'), findsOneWidget);
  });

  testWidgets('a canonical save preserves unrendered fields and refreshes',
      (tester) async {
    final repository = _FakeNutritionProfileRepository(
      stored: const NutritionProfileData(
        preferredDiet: 'vegetarian',
        allergies: {'gluten'},
        dislikedFoods: {'okra'},
        medicalConditions: {'diabetes'},
      ),
    );
    final container = await buildContainer(
      appMode: AppMode.hybrid,
      repository: repository,
    );
    addTearDown(container.dispose);

    await openSettings(tester, container);
    await tester.tap(find.byKey(const ValueKey('settings-nutrition-entry')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('nutrition-settings-profile-entry')));
    await tester.pumpAndSettle();

    await tester
        .tap(find.byKey(const ValueKey('nutrition-profile-diet-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nutrition-diet-option-vegan')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nutrition-diet-type-save')));
    await tester.pumpAndSettle();

    expect(repository.writes, hasLength(1));
    final written = repository.writes.single;
    expect(written.preferredDiet, 'vegan');
    expect(written.allergies, {'gluten'});
    expect(written.dislikedFoods, {'okra'});
    expect(written.medicalConditions, {'diabetes'});

    // The route re-read the canonical owner, so the summary is not stale.
    expect(repository.readCount, greaterThan(1));
    expect(find.text('Vegan'), findsOneWidget);
  });
  group('Additional Nutrient Goals route composition', () {
    Future<void> openAdditionalGoals(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      final router = container.read(goRouterProvider);
      router.go(AppRoutes.nutritionAdditionalGoalsSettings.path);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const TioApp()),
      );
      await tester.pumpAndSettle();
    }

    _FakeNutritionTargetsRepository targetsWithCalories() =>
        _FakeNutritionTargetsRepository(
          stored: const NutritionTargetsData(
            caloriesKcal: 2000,
            customizationState: NutritionTargetCustomizationState.recommended,
          ),
        );

    testWidgets('a profile load failure is reported, not read as no DOB',
        (tester) async {
      final container = await buildContainer(
        appMode: AppMode.nutrition,
        repository: _FakeNutritionProfileRepository(),
        targets: targetsWithCalories(),
        profileStream: Stream<ProfileSetupData?>.error(
          StateError('offline'),
        ),
      );
      addTearDown(container.dispose);

      await openAdditionalGoals(tester, container);

      // Collapsing the error into a null date of birth would render four
      // permanently "Unavailable" nutrients and, under the frozen eligibility
      // rule, block editing — with nothing on screen explaining why.
      expect(find.text('Could not load your profile'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.text('Unavailable'),
        findsNothing,
        reason: 'A network error is not an eligibility outcome.',
      );
    });

    testWidgets('a profile with no date of birth still renders the screen',
        (tester) async {
      final container = await buildContainer(
        appMode: AppMode.nutrition,
        repository: _FakeNutritionProfileRepository(),
        targets: targetsWithCalories(),
        profileStream: Stream<ProfileSetupData?>.value(null),
      );
      addTearDown(container.dispose);

      await openAdditionalGoals(tester, container);

      // The genuinely-absent case is an eligibility outcome, shown on the
      // screen rather than as a load failure.
      expect(find.text('Could not load your profile'), findsNothing);
      expect(find.text('Additional Nutrient Goals'), findsWidgets);
      expect(find.text('Saturated Fat'), findsOneWidget);
    });
  });

}

class _FakeNutritionProfileRepository implements NutritionProfileRepository {
  _FakeNutritionProfileRepository({this.stored});

  NutritionProfileData? stored;
  final writes = <NutritionProfileData>[];
  var readCount = 0;

  @override
  Future<NutritionProfileData?> read() async {
    readCount++;
    return stored;
  }

  @override
  Future<void> upsert(NutritionProfileData profile) async {
    writes.add(profile);
    stored = profile;
  }
}

class _FixedAppSessionBootstrapController
    extends AppSessionBootstrapController {
  _FixedAppSessionBootstrapController({
    required AppSessionBootstrapState state,
    required super.onboardingStatusController,
  })  : fixedState = state,
        super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  AppSessionBootstrapState fixedState;

  @override
  AppSessionBootstrapState get state => fixedState;

  @override
  void start() {}
}

class _MemoryAppModePreference implements AppModePreference {
  _MemoryAppModePreference(this.mode);

  AppMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<AppMode?> read() async => mode;

  @override
  Future<void> write(AppMode mode) async => this.mode = mode;
}

class _MemoryAppThemePreference implements AppThemePreference {
  _MemoryAppThemePreference(this.mode);

  TioThemeMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<TioThemeMode?> read() async => mode;

  @override
  Future<void> write(TioThemeMode mode) async => this.mode = mode;
}

class _MemoryOnboardingStatusRepository implements OnboardingStatusRepository {
  _MemoryOnboardingStatusRepository({
    required this.status,
    required this.hasStoredContractVersion,
  });

  OnboardingStatus? status;
  bool hasStoredContractVersion;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    await ensureInitialized();
    this.status = status;
  }
}

class _FakeNutritionTargetsRepository implements NutritionTargetsRepository {
  _FakeNutritionTargetsRepository({this.stored});

  NutritionTargetsData? stored;
  final writes = <NutritionTargetsData>[];
  /// One entry per nutrient delta, matching the repository contract.
  final additionalGoalWrites = <(NutrientId, AdditionalNutrientGoal?)>[];
  var readCount = 0;

  @override
  Future<NutritionTargetsData?> read() async {
    readCount++;
    return stored;
  }

  @override
  Future<void> upsert(NutritionTargetsData targets) async {
    writes.add(targets);
    stored = targets;
  }

  @override
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
  ) async {
    // Mirrors the real adapter's separation twice over: this write touches
    // only the Additional Nutrient Goals, leaving every core-five value in
    // place, and within them it touches only the one nutrient being edited.
    additionalGoalWrites.add((nutrientId, goal));
    final current = stored ?? const NutritionTargetsData();
    final existing = current.additionalNutrientGoals;
    stored = current.withAdditionalNutrientGoals(
      goal == null ? existing.without(nutrientId) : existing.withGoal(goal),
    );
  }
}
