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
import 'package:tio_shared/shared.dart';

/// Route-level coverage for Nutrition Settings: App Mode gating of the
/// Settings entry, navigation into the Nutrition hub and Nutrition Profile,
/// and that a canonical save merges rather than truncates the row.
void main() {
  Future<ProviderContainer> buildContainer({
    required AppMode appMode,
    required _FakeNutritionProfileRepository repository,
  }) async {
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
