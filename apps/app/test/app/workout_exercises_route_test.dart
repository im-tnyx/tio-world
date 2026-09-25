import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/profile/exercise_media_gender.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart' hide ProfileGender;
import 'package:tio_feature_profile/profile.dart' show ProfileGender;
import 'package:tio_feature_settings/settings.dart'
    show CalendarPreferences, CalendarPreferencesRepository;
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _exercisesPath = '/workout/exercises';

void main() {
  test('Exercises hides the bottom navigation and root top bar', () {
    final policy = shellChromePolicyForPath(_exercisesPath);

    expect(policy, ChromePolicy.noBottomBar);
    expect(policy.showsBottomNav, isFalse);
    expect(policy.showsRootTopBar, isFalse);
    expect(AppRoutes.workoutExercises.path, _exercisesPath);
  });

  group('deep links follow /workout gating', () {
    for (final status in OnboardingStatus.values) {
      for (final mode in <AppMode?>[null, ...AppMode.values]) {
        test('${status.name} / ${mode?.name ?? 'no mode'}', () {
          String? redirect(String path, [List<AppDestination>? active]) =>
              appModeRedirect(
                path: path,
                selectedMode: mode,
                onboardingStatus: status,
                activeDestinations: active,
              );

          expect(
            redirect(_exercisesPath),
            redirect(FeatureRoutes.workout.path),
          );
          const nutritionOnly = [AppDestination.home, AppDestination.nutrition];
          expect(
            redirect(_exercisesPath, nutritionOnly),
            redirect(FeatureRoutes.workout.path, nutritionOnly),
          );
        });
      }
    }

    test('a mode without Workout sends Exercises to its first tab', () {
      expect(
        appModeRedirect(
          path: _exercisesPath,
          selectedMode: AppMode.nutrition,
          onboardingStatus: OnboardingStatus.completed,
        ),
        FeatureRoutes.home.path,
      );
      expect(
        appModeRedirect(
          path: _exercisesPath,
          selectedMode: AppMode.hybrid,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
    });

    test('other nested-looking paths keep their existing behavior', () {
      expect(
        appModeRedirect(
          path: AppRoutes.mealDiarySettings.path,
          selectedMode: AppMode.workout,
          onboardingStatus: OnboardingStatus.completed,
        ),
        isNull,
      );
    });
  });

  test('profile gender maps to Exercise media gender', () {
    expect(
      exerciseMediaGenderForProfile(ProfileGender.male),
      ExerciseMediaGender.male,
    );
    expect(
      exerciseMediaGenderForProfile(ProfileGender.female),
      ExerciseMediaGender.female,
    );
    expect(exerciseMediaGenderForProfile(ProfileGender.other), isNull);
    expect(exerciseMediaGenderForProfile(null), isNull);
  });

  testWidgets(
      'a direct deep link opens Exercises inside Workout; back returns to it',
      (tester) async {
    final (container, router) = await _app(tester, AppMode.hybrid);
    router.go(_exercisesPath);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, _exercisesPath);
    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('exercises-page')),
        matching: find.text('Exercises'),
      ),
      findsOneWidget,
    );
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TioShellStatusTopBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.workout.path,
    );
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(WorkoutHomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
        container.read(appModeControllerProvider).selectedMode, AppMode.hybrid);
  });

  testWidgets('Workout Home offers no direct Exercises entry', (tester) async {
    final (_, router) = await _app(tester, AppMode.workout);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutHomePage), findsOneWidget);
    expect(find.text('Exercises'), findsNothing);
    expect(find.text('Library'), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
  });

  testWidgets('a mode without Workout cannot deep link into Exercises',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.nutrition);
    router.go(_exercisesPath);
    await tester.pumpAndSettle();

    expect(find.byType(ExercisesPage), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.home.path,
    );
  });
}

Future<(ProviderContainer, GoRouter)> _app(
  WidgetTester tester,
  AppMode mode,
) async {
  final appModeController = AppModeController(_MemoryAppModePreference(mode));
  await appModeController.load();
  final onboardingRepository = _MemoryOnboardingStatusRepository();
  final onboardingStatusController = OnboardingStatusController(
    repository: onboardingRepository,
    appModeController: appModeController,
  );
  await onboardingStatusController.load();
  final themeController = AppThemeController(_MemoryAppThemePreference());
  await themeController.load();
  final calendarController =
      CalendarPreferencesController(_MemoryCalendarPreferencesRepository());
  await calendarController.load();

  final container = ProviderContainer(
    overrides: [
      appModeControllerProvider.overrideWith((ref) => appModeController),
      onboardingStatusControllerProvider
          .overrideWith((ref) => onboardingStatusController),
      onboardingStatusRepositoryProvider
          .overrideWith((ref) => onboardingRepository),
      appThemeControllerProvider.overrideWith((ref) => themeController),
      calendarPreferencesControllerProvider
          .overrideWith((ref) => calendarController),
      appSessionBootstrapControllerProvider.overrideWith(
        (ref) => _ReadyAppSessionBootstrapController(
          onboardingStatusController: onboardingStatusController,
        ),
      ),
      exerciseCatalogRepositoryProvider.overrideWithValue(_RouteCatalog()),
    ],
  );
  addTearDown(container.dispose);
  final router = container.read(goRouterProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TioApp()),
  );
  await tester.pumpAndSettle();
  return (container, router);
}

final class _RouteCatalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.catalog('ex_synthetic_route_curl'),
          displayName: 'Synthetic Route Curl',
          muscleGroup: 'upper_arms',
          primaryEquipment: 'dumbbell',
          status: ExerciseStatus.active,
        ),
      ]);
}

class _ReadyAppSessionBootstrapController
    extends AppSessionBootstrapController {
  _ReadyAppSessionBootstrapController({
    required super.onboardingStatusController,
  }) : super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  @override
  AppSessionBootstrapState get state =>
      const AppSessionBootstrapReady(userId: 'test-user');

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
  TioThemeMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<TioThemeMode?> read() async => mode;

  @override
  Future<void> write(TioThemeMode mode) async => this.mode = mode;
}

class _MemoryOnboardingStatusRepository implements OnboardingStatusRepository {
  OnboardingStatus? status = OnboardingStatus.completed;
  bool hasStoredContractVersion = true;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async => hasStoredContractVersion = true;

  @override
  Future<OnboardingStatusSnapshot> read() async => OnboardingStatusSnapshot(
        status: status,
        hasStoredContractVersion: hasStoredContractVersion,
      );

  @override
  Future<void> write(OnboardingStatus status) async {
    await ensureInitialized();
    this.status = status;
  }
}

class _MemoryCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  CalendarPreferences value = const CalendarPreferences();

  @override
  Future<void> clear() async => value = const CalendarPreferences();

  @override
  Future<CalendarPreferences> read() async => value;

  @override
  Future<void> write(CalendarPreferences preferences) async =>
      value = preferences;
}
