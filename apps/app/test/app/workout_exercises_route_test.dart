import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/profile/exercise_media_gender.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart'
    hide ProfileActivityLevel, ProfileGender;
import 'package:tio_feature_profile/profile.dart'
    show ProfileActivityLevel, ProfileGender, ProfileSetupData;
import 'package:tio_feature_settings/settings.dart'
    show CalendarPreferences, CalendarPreferencesRepository;
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _programsPath = '/workout/programs';
const _exercisesPath = '/workout/exercises';
const _libraryPath = '/workout/library';

void main() {
  test('Library hides the bottom navigation and root top bar', () {
    final policy = shellChromePolicyForPath(_libraryPath);

    expect(policy, ChromePolicy.noBottomBar);
    expect(policy.showsRootTopBar, isFalse);
    expect(AppRoutes.workoutLibrary.path, _libraryPath);
  });

  test('Programs hides the bottom navigation and root top bar', () {
    final policy = shellChromePolicyForPath(_programsPath);

    expect(policy, ChromePolicy.noBottomBar);
    expect(policy.showsBottomNav, isFalse);
    expect(policy.showsRootTopBar, isFalse);
    expect(AppRoutes.workoutPrograms.path, _programsPath);
  });

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
            redirect(_programsPath),
            redirect(FeatureRoutes.workout.path),
          );
          expect(
            redirect(_exercisesPath),
            redirect(FeatureRoutes.workout.path),
          );
          expect(
            redirect(_libraryPath),
            redirect(FeatureRoutes.workout.path),
          );
          const nutritionOnly = [AppDestination.home, AppDestination.nutrition];
          expect(
            redirect(_programsPath, nutritionOnly),
            redirect(FeatureRoutes.workout.path, nutritionOnly),
          );
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

  testWidgets('Workout Home reaches Exercises only through Library',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.workout);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    expect(find.byType(WorkoutHomePage), findsOneWidget);
    // One Library entry; no direct Exercises shortcut on Workout Home.
    expect(
      find.byKey(const ValueKey('workout-home-library-entry')),
      findsOneWidget,
    );
    expect(find.text('Exercises'), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
  });

  testWidgets(
      'Library renders Programs directly and header opens optional manage route',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(ProgramsPage), findsNothing);
    expect(
      find.byKey(const ValueKey('library-programs-section')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-programs-create')),
      findsOneWidget,
    );
    expect(find.text('Synthetic Route Program'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byKey(const ValueKey('library-programs-header')));
    await tester.pumpAndSettle();

    expect(find.byType(ProgramsPage), findsOneWidget);
    expect(find.byType(LibraryPage), findsNothing);
    expect(find.text('Synthetic Route Program'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(ProgramsPage), findsNothing);
    expect(find.text('Synthetic Route Program'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('Program name opens real owner-scoped Detail and returns to Library',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(_libraryPath);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();

    expect(find.byType(ProgramDetailPage), findsOneWidget);
    expect(find.byType(ProgramsPage), findsNothing);
    expect(find.text('Synthetic Route Routine'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(ProgramDetailPage), findsNothing);
  });

  testWidgets('Program Detail Routine tap opens real composition, not Rename',
      (tester) async {
    final (_, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(
        'program-routine-30000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(find.text('Synthetic Route Routine'), findsOneWidget);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
    expect(find.text('Start Workout'), findsNothing);
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    expect(find.byType(EditRoutinePage), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-routine-page')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramDetailPage), findsOneWidget);
    expect(find.byType(RoutineDetailPage), findsNothing);
    expect(find.byKey(const ValueKey(
        'routine-menu-30000000-0000-4000-8000-000000000001')),
        findsOneWidget);
  });

  testWidgets('Routine preview clears private content on session loss',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-routine-30000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Route Curl'), findsOneWidget);

    final bootstrap = container.read(appSessionBootstrapControllerProvider)
        as _ReadyAppSessionBootstrapController;
    bootstrap.transitionTo(null);
    await tester.pump();
    expect(find.text('Synthetic Route Curl'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Route Curl'), findsNothing);
  });

  testWidgets('Auth/bootstrap mismatch revokes Detail and Edit action',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-routine-30000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();

    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsOneWidget);

    // Bootstrapped test-user is stale; Auth has already switched users.
    container.read(_routineTestAuthStateProvider.notifier).state =
        const AuthSessionAuthenticated(
          AuthSession(userId: 'other-user', loginCycleId: 'other-cycle'),
        );
    await tester.pump();
    expect(find.text('Synthetic Route Curl'), findsNothing);
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsNothing);
  });

  testWidgets('account loss closes nested Routine Exercise picker and editor',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const programId = '20000000-0000-4000-8000-000000000001';
    const routineId = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(
        const ValueKey('library-routine-$programId-$routineId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    expect(find.byType(EditRoutinePage), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineExercisePickerPage), findsOneWidget);
    expect(find.text('Synthetic Route Custom'), findsOneWidget);

    final bootstrap = container.read(appSessionBootstrapControllerProvider)
        as _ReadyAppSessionBootstrapController;
    bootstrap.transitionTo(null);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineExercisePickerPage), findsNothing);
    expect(find.byType(EditRoutinePage), findsNothing);
    expect(find.text('Synthetic Route Custom'), findsNothing);
    expect(find.text('Synthetic Route Curl'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account loss closes open Set sheet and private draft',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const programId = '20000000-0000-4000-8000-000000000001';
    const routineId = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(
        const ValueKey('library-routine-$programId-$routineId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey(
        'routine-set-type-70000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsOneWidget);

    final bootstrap = container.read(appSessionBootstrapControllerProvider)
        as _ReadyAppSessionBootstrapController;
    bootstrap.transitionTo(null);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    expect(find.byType(EditRoutinePage), findsNothing);
    expect(find.text('Select Set Type'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-user new login cycle revokes private Exercise picker',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const p = '20000000-0000-4000-8000-000000000001';
    const r = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(const ValueKey('library-routine-$p-$r')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-add-exercise')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineExercisePickerPage), findsOneWidget);
    expect(find.text('Synthetic Route Custom'), findsOneWidget);

    // No bootstrap transition: same principal, NEW interactive login cycle.
    container.read(_routineTestAuthStateProvider.notifier).state =
        const AuthSessionAuthenticated(
          AuthSession(userId: 'test-user', loginCycleId: 'second-cycle'),
        );
    await tester.pumpAndSettle();
    expect(find.byType(RoutineExercisePickerPage), findsNothing);
    expect(find.byType(EditRoutinePage), findsNothing);
    expect(find.text('Synthetic Route Custom'), findsNothing);
    // Current account remains logged in; re-entry gets a fresh controller.
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-detail-edit')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-user new login cycle closes Set modal and private draft',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const p = '20000000-0000-4000-8000-000000000001';
    const r = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(const ValueKey('library-routine-$p-$r')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'routine-set-type-70000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsOneWidget);

    container.read(_routineTestAuthStateProvider.notifier).state =
        const AuthSessionAuthenticated(
          AuthSession(userId: 'test-user', loginCycleId: 'second-cycle'),
        );
    await tester.pumpAndSettle();
    expect(find.text('Select Set Type'), findsNothing);
    expect(find.byType(RoutineSetEditorSheet), findsNothing);
    expect(find.byType(EditRoutinePage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('same-user new login cycle discards editor while save is pending',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    final compositions = container.read(routineCompositionRepositoryProvider)
        as _RouteCompositions;
    compositions.saveGate = Completer<void>();
    addTearDown(() {
      if (compositions.saveGate?.isCompleted == false) {
        compositions.saveGate!.complete();
      }
    });
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const p = '20000000-0000-4000-8000-000000000001';
    const r = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(const ValueKey('library-routine-$p-$r')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('routine-detail-edit')));
    await tester.pumpAndSettle();
    // Create a valid dirty draft without a keyboard/sheet overlay: this
    // regression exercises in-flight identity revocation, not Set input.
    await tester.tap(find.byKey(const ValueKey(
        'edit-routine-entry-options-60000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Exercise'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-routine-empty')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-routine-update')));
    await tester.pump();
    expect(compositions.saveCount, 1);
    expect(find.byKey(const ValueKey('edit-routine-saving')), findsOneWidget);

    // Same user signs in again before the already-issued write returns.
    container.read(_routineTestAuthStateProvider.notifier).state =
        const AuthSessionAuthenticated(
          AuthSession(userId: 'test-user', loginCycleId: 'next-cycle'),
        );
    // Never pumpAndSettle a deliberately unresolved save Future. Give Auth
    // two bounded frames to revoke private UI before releasing the response.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final oldCycleSavingHidden =
        find.byKey(const ValueKey('edit-routine-saving')).evaluate().isEmpty;

    compositions.saveGate!.complete();
    // Bound completion/route-animation frames too. If a revoked editor does
    // not exit, assert failure directly rather than hanging in settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    // Assert the pre-response privacy observation only AFTER the deferred
    // Future is released so failure cannot strand the test runner.
    expect(oldCycleSavingHidden, isTrue);
    // An old-cycle response must never navigate or restore a saved draft.
    expect(find.byType(EditRoutinePage), findsNothing);
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(compositions.saveCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('account switch discards prior owner Routine before next read',
      (tester) async {
    final (container, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-routine-30000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Route Curl'), findsOneWidget);

    final compositions =
        container.read(routineCompositionRepositoryProvider)
            as _RouteCompositions;
    compositions.nextOwnerReadGate = Completer<void>();
    final bootstrap = container.read(appSessionBootstrapControllerProvider)
        as _ReadyAppSessionBootstrapController;
    bootstrap.transitionTo('second-user');
    await tester.pump();
    expect(find.text('Synthetic Route Curl'), findsNothing);

    compositions.nextOwnerReadGate!.complete();
    await tester.pumpAndSettle();
    // The simulated new owner has no access to the prior owner's snapshot.
    expect(find.text('Synthetic Route Curl'), findsNothing);
  });

  testWidgets('account switch does not reuse the previous Profile weight unit',
      (tester) async {
    final nextProfile = StreamController<ProfileSetupData?>.broadcast();
    addTearDown(nextProfile.close);
    final (container, router) = await _app(
      tester,
      AppMode.hybrid,
      withRoutineComposition: true,
      switchedOwnerProfiles: nextProfile.stream,
    );
    final compositions =
        container.read(routineCompositionRepositoryProvider)
            as _RouteCompositions;
    compositions.testLoadKg = 8;
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-open-20000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey(
        'program-routine-30000000-0000-4000-8000-000000000001')));
    await tester.pumpAndSettle();
    expect(find.text('17.6'), findsOneWidget);

    // ProfileDataProvider can retain A's last value while B is reloading.
    container.read(_routineTestAuthStateProvider.notifier).state =
        const AuthSessionAuthenticated(
            AuthSession(userId: 'second-user', loginCycleId: 'second-cycle'));
    final bootstrap = container.read(appSessionBootstrapControllerProvider)
        as _ReadyAppSessionBootstrapController;
    bootstrap.transitionTo('second-user');
    await tester.pumpAndSettle();
    expect(find.text('Load unavailable'), findsOneWidget);
    expect(find.text('17.6'), findsNothing);

    // Only B's completed Profile load can enable B's unit choice.
    nextProfile.add(_routineUnitProfile(WeightUnit.kg));
    await tester.pumpAndSettle();
    expect(find.text('KG'), findsOneWidget);
    expect(find.text('17.6'), findsNothing);
  });

  testWidgets('expanded Library Routine tap opens same owner-bound preview',
      (tester) async {
    final (_, router) = await _app(
      tester, AppMode.hybrid, withRoutineComposition: true,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const parentId = '20000000-0000-4000-8000-000000000001';
    const routineId = '30000000-0000-4000-8000-000000000001';
    await tester.tap(find.byKey(
        const ValueKey('library-routine-$parentId-$routineId')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailPage), findsOneWidget);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(RoutineDetailPage), findsNothing);
  });

  testWidgets('no composition source never opens a fake Routine Detail',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    const parentId = '20000000-0000-4000-8000-000000000001';
    const routineId = '30000000-0000-4000-8000-000000000001';
    final card = find.byKey(
        const ValueKey('library-routine-$parentId-$routineId'));
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.byType(RoutineDetailPage), findsNothing);
    expect(find.byKey(const ValueKey('routine-name-field')), findsNothing);
  });

  testWidgets('new Routine created in Program Detail appears under Library Program',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(_libraryPath);
    await tester.pumpAndSettle();

    const programId = '20000000-0000-4000-8000-000000000001';
    const existingRoutineId = '30000000-0000-4000-8000-000000000001';
    expect(
      find.byKey(const ValueKey('library-routine-$programId-$existingRoutineId')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('program-open-$programId')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('program-detail-add-routine')));
    await tester.pumpAndSettle();
    final nameField = find.descendant(
      of: find.byKey(const ValueKey('routine-name-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(nameField, 'Added From Detail');
    await tester.tap(find.byKey(const ValueKey('routine-name-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Added From Detail'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    final programRoutines = find.byKey(const ValueKey('library-routines-$programId'));
    expect(find.descendant(of: programRoutines,
        matching: find.text('Added From Detail')), findsOneWidget);
  });

  testWidgets('Program Detail fails closed when Routine repository is unavailable',
      (tester) async {
    final (_, router) = await _app(
      tester,
      AppMode.hybrid,
      withRoutineRepository: false,
    );
    router.go(_libraryPath);
    await tester.pumpAndSettle();
    expect(find.text('Synthetic Route Program'), findsOneWidget);
    expect(
      find.byKey(const ValueKey(
          'program-open-20000000-0000-4000-8000-000000000001')),
      findsNothing,
    );
    expect(find.byType(ProgramDetailPage), findsNothing);
  });

  testWidgets(
      'Workout Home → Library → Exercises, and back through the same stack',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();
    // Imperative push keeps the reported URL at the branch root (go_router's
    // default), so the assertions follow the rendered pages and chrome.
    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(WorkoutHomePage), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TioShellStatusTopBar), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesPage), findsNothing);
    expect(
      find.byKey(const ValueKey('library-create-exercise-entry')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('library-exercises-entry')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-exercises-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(find.byType(LibraryPage), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.text('Synthetic Route Custom'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey(
          'exercise-custom-badge-10000000-0000-4000-8000-000000000001',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.workout.path,
    );
    expect(find.byType(WorkoutHomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
      'Library Create Exercise opens directly and back returns to selected Library',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ExercisesPage), findsNothing);
    expect(
      find.byKey(const ValueKey('library-category-clear')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('library-create-exercise-card')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CreateExercisePage), findsOneWidget);
    expect(find.byType(CustomExerciseEditorPage), findsOneWidget);
    expect(
      find.byType(ExercisesPage, skipOffstage: false),
      findsNothing,
      reason: 'Library Create must not add Exercises to the back stack',
    );
    expect(
      find.byType(LibraryPage, skipOffstage: false),
      findsOneWidget,
      reason: 'Library remains the owner route under the editor',
    );

    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(CreateExercisePage), findsNothing);
    expect(find.byType(CustomExerciseEditorPage), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-clear')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-create-exercise-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-card')),
      findsOneWidget,
    );
  });

  testWidgets(
      'saving a Library Create Exercise returns to selected Library',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-create-exercise-card')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CustomExerciseEditorPage), findsOneWidget);
    expect(find.byType(ExercisesPage, skipOffstage: false), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('custom-exercise-name')),
      'Direct Library Exercise',
    );
    await tester.tap(find.byKey(const ValueKey('custom-exercise-save')));
    await tester.pumpAndSettle();

    expect(find.byType(CreateExercisePage), findsNothing);
    expect(find.byType(CustomExerciseEditorPage), findsNothing);
    expect(find.byType(ExercisesPage), findsNothing);
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-category-clear')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-exercises')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-category-programs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-create-exercise-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-card')),
      findsOneWidget,
    );
  });

  testWidgets(
      'Library hides Create Exercise when durable repository is unavailable',
      (tester) async {
    final (_, router) = await _app(
      tester,
      AppMode.hybrid,
      withUserExerciseRepository: false,
    );
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('library-category-exercises')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('library-create-exercise-card')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('library-exercises-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('library-exercises-card')));
    await tester.pumpAndSettle();

    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(find.byType(CustomExerciseEditorPage), findsNothing);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
  });

  testWidgets(
      'opening Library leaves Workout Home and its chrome still while it '
      'slides in', (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();
    // The page transition may slide Workout Home sideways, but its vertical
    // geometry and the shell chrome around it must not jump.
    (double, double) vertical(Finder finder) {
      final rect = tester.getRect(finder);
      return (rect.top, rect.bottom);
    }

    final home = find.byType(WorkoutHomePage);
    final nav = find.byType(NavigationBar);
    final homeSpan = vertical(home);
    final navSpan = vertical(nav);

    Future<void> expectStillMidTransition() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LibraryPage), findsOneWidget);
      expect(vertical(home), homeSpan);
      expect(vertical(nav), navSpan);
      expect(find.byType(TioShellStatusTopBar), findsOneWidget);
    }

    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await expectStillMidTransition();

    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(TioShellStatusTopBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await expectStillMidTransition();

    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsNothing);
    expect(vertical(home), homeSpan);
  });

  testWidgets('Library search opens Exercises with the search field active',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(FeatureRoutes.workout.path);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-home-library-entry')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('library-search')));
    await tester.pumpAndSettle();

    expect(find.byType(ExercisesPage), findsOneWidget);
    final field = find.byKey(const ValueKey('exercises-search'));
    expect(field, findsOneWidget);
    final editable = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
  });

  testWidgets('legacy custom query no longer creates a Custom-only screen',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go('$_exercisesPath?custom=true');
    await tester.pumpAndSettle();

    expect(find.byType(ExercisesPage), findsOneWidget);
    expect(find.text('Synthetic Route Curl'), findsOneWidget);
    expect(find.text('Synthetic Route Custom'), findsOneWidget);
    expect(find.byKey(const ValueKey('all-exercises-section')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-exercises-section')), findsOneWidget);
  });

  testWidgets('the search deep link opens Exercises in search mode',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go('$_exercisesPath?search=true');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('exercises-search')), findsOneWidget);
  });

  testWidgets('a direct Library deep link lands above Workout Home',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.hybrid);
    router.go(_libraryPath);
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // Workout Home is revealed with its chrome already in place.
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(TioShellStatusTopBar), findsOneWidget);

    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.workout.path,
    );
    expect(find.byType(WorkoutHomePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a mode without Workout cannot deep link into Library',
      (tester) async {
    final (_, router) = await _app(tester, AppMode.nutrition);
    router.go(_libraryPath);
    await tester.pumpAndSettle();

    expect(find.byType(LibraryPage), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      FeatureRoutes.home.path,
    );
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

final _routineTestAuthStateProvider = StateProvider<AuthSessionState>((ref) =>
    const AuthSessionAuthenticated(
        AuthSession(userId: 'test-user', loginCycleId: 'test-cycle')));

ProfileSetupData _routineUnitProfile(WeightUnit weightUnit) => ProfileSetupData(
      name: 'Routine test member',
      gender: ProfileGender.values.first,
      goals: const {},
      dateOfBirth: DateTime(1990, 1, 1),
      heightCm: 175,
      currentWeightKg: 70,
      activityLevel: ProfileActivityLevel.values.first,
      healthConditions: const {},
      unitPreferences: UnitPreferences(weightUnit: weightUnit),
    );

Future<(ProviderContainer, GoRouter)> _app(
  WidgetTester tester,
  AppMode mode, {
  bool withProgramRepository = true,
  bool withRoutineRepository = true,
  bool withRoutineComposition = false,
  bool withRoutineCreate = false,
  bool withUserExerciseRepository = true,
  Stream<ProfileSetupData?>? switchedOwnerProfiles,
}) async {
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
  final routeRoutines = _RouteRoutines();

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
      programRepositoryProvider.overrideWithValue(
        withProgramRepository ? _RoutePrograms() : null,
      ),
      routineRepositoryProvider.overrideWithValue(
        withRoutineRepository ? routeRoutines : null,
      ),
      routineCreateRepositoryProvider.overrideWithValue(
        withRoutineCreate ? _RouteCreate(routeRoutines) : null,
      ),
      routineCompositionRepositoryProvider.overrideWithValue(
        withRoutineComposition ? _RouteCompositions() : null,
      ),
      userExerciseRepositoryProvider.overrideWithValue(
        withUserExerciseRepository ? _RouteUserExercises() : null,
      ),
      // Routine Detail tests need a consistent authenticated/bootstrap pair;
      // otherwise the production fail-closed owner gate correctly hides data.
      if (withRoutineComposition || switchedOwnerProfiles != null) ...[
        authSessionStateProvider.overrideWith((ref) =>
            Stream.value(ref.watch(_routineTestAuthStateProvider))),
        profileDataProvider.overrideWith((ref) {
          final session = ref.watch(authSessionStateProvider).valueOrNull;
          if (session is AuthSessionAuthenticated &&
              session.session.userId == 'test-user') {
            return Stream.value(_routineUnitProfile(WeightUnit.lb));
          }
          return switchedOwnerProfiles ??
              Stream<ProfileSetupData?>.value(null);
        }),
      ],
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

final class _RoutePrograms implements ProgramRepository {
  final List<Program> _programs = [
    Program(
      id: ProgramId('20000000-0000-4000-8000-000000000001'),
      name: 'Synthetic Route Program',
    ),
  ];

  @override
  Future<List<Program>> list() async => List.unmodifiable(_programs);

  @override
  Future<void> create(Program program) async {
    _programs.add(program);
  }

  @override
  Future<void> rename({
    required ProgramId id,
    required String name,
  }) async {
    final index = _programs.indexWhere((program) => program.id == id);
    if (index < 0) return;
    _programs[index] = Program(id: id, name: name);
  }
}

final class _RouteRoutines implements RoutineRepository {
  final List<Routine> rows = [
    Routine(
      id: RoutineId('30000000-0000-4000-8000-000000000001'),
      programId: ProgramId('20000000-0000-4000-8000-000000000001'),
      name: 'Synthetic Route Routine',
    ),
  ];

  @override
  Future<List<Routine>> list(ProgramId programId) async =>
      List.unmodifiable(rows.where((item) => item.programId == programId));

  @override
  Future<void> create(Routine routine) async => rows.add(routine);

  @override
  Future<void> rename({required RoutineId id, required String name}) async {
    final index = rows.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Routine missing');
    rows[index] = Routine(id: id, programId: rows[index].programId, name: name);
  }
}

final class _RouteCreate implements RoutineCreateRepository {
  _RouteCreate(this._routines);

  final _RouteRoutines _routines;

  @override
  Future<int> create(RoutineCreateCommand command) async {
    // Test fixture models an acknowledged atomic Create, not metadata-only
    // production persistence. The real service boundary remains #536.
    await _routines.create(command.routine);
    return 1;
  }
}

final class _RouteCompositions implements RoutineCompositionRepository {
  int _readCount = 0;
  Completer<void>? nextOwnerReadGate;
  double? testLoadKg;
  Completer<void>? saveGate;
  int saveCount = 0;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async {
    _readCount++;
    if (_readCount > 1 && nextOwnerReadGate != null) {
      await nextOwnerReadGate!.future;
      return null;
    }
    return RoutineCompositionSnapshot(
      routineId: routineId,
      revision: 1,
      entries: [
        RoutineCompositionEntry(
          id: '60000000-0000-4000-8000-000000000001',
          exercise: ExerciseRef.catalog('ex_synthetic_route_curl'),
          sets: [
            RoutineCompositionSet(
              id: '70000000-0000-4000-8000-000000000001',
              prescription: SetPrescription(reps: 8, loadKg: testLoadKg),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<int> save(RoutineCompositionSave command) async {
    saveCount++;
    if (saveGate != null) await saveGate!.future;
    return command.expectedRevision + 1;
  }
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

final class _RouteUserExercises implements UserExerciseRepository {
  final List<Exercise> _exercises = [
    Exercise(
      ref: UserCreatedExerciseRef(
        '10000000-0000-4000-8000-000000000001',
      ),
      displayName: 'Synthetic Route Custom',
      primaryMuscles: const ['biceps_brachii'],
      primaryEquipment: 'dumbbell',
      status: ExerciseStatus.active,
    ),
  ];

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async =>
      List<Exercise>.unmodifiable(
        _exercises.where(
          (exercise) =>
              includeArchived || exercise.status == ExerciseStatus.active,
        ),
      );

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {}

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {}

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {}

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {}
}

class _ReadyAppSessionBootstrapController
    extends AppSessionBootstrapController {
  _ReadyAppSessionBootstrapController({
    required super.onboardingStatusController,
  }) : super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  AppSessionBootstrapState _testState =
      const AppSessionBootstrapReady(userId: 'test-user');

  @override
  AppSessionBootstrapState get state => _testState;

  void transitionTo(String? userId) {
    _testState = userId == null
        ? const AppSessionBootstrapUnauthenticated()
        : AppSessionBootstrapReady(userId: userId);
    notifyListeners();
  }

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
