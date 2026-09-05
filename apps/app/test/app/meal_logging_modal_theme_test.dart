import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

/// Meal Logging's modals resolve the app's theme — asserted through the real
/// composition root.
///
/// The Nutrition package has its own theme tests, but they build their own
/// `MaterialApp` host. That host is a copy of production composition, so it
/// cannot notice production composition changing: move `TioTheme` below the
/// router in `app.dart` and every one of those tests would still pass while a
/// root-navigator modal silently fell back to Light.
///
/// This one boots `TioApp` itself, navigates the real router to Nutrition and
/// opens the real sheets, so the invariant it protects is the one that ships.
void main() {
  const addAction = ValueKey('meal-diary-add-food-action');
  const sheet = ValueKey('meal-diary-add-food-sheet');
  const quickAddCard = ValueKey('add-food-quick-add');
  const editorSheet = ValueKey('tio-editor-sheet');

  Future<void> pumpApp(WidgetTester tester, TioThemeMode mode) async {
    final appMode = AppModeController(_MemoryAppModePreference(AppMode.hybrid));
    await appMode.load();

    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatus = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: appMode,
    );
    await onboardingStatus.load();

    final theme = AppThemeController(_MemoryAppThemePreference(mode));
    await theme.load();

    final calendar =
        CalendarPreferencesController(_MemoryCalendarPreferencesRepository());
    await calendar.load();

    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => appMode),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatus),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => theme),
        calendarPreferencesControllerProvider.overrideWith((ref) => calendar),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatus,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(goRouterProvider).go(FeatureRoutes.nutrition.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        // The real composition root, not a stand-in for it.
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Material materialOf(WidgetTester tester, Finder scope) {
    final self = scope.evaluate();
    if (self.isNotEmpty && self.first.widget is Material) {
      return self.first.widget as Material;
    }
    return tester.widget<Material>(
      find.descendant(of: scope, matching: find.byType(Material)).first,
    );
  }

  for (final mode in const [
    (TioThemeMode.dark, 'Dark'),
    (TioThemeMode.oled, 'OLED'),
  ]) {
    testWidgets(
        'Add Food and Quick Add resolve ${mode.$2} through the real app',
        (tester) async {
      final expected = switch (mode.$1) {
        TioThemeMode.dark => TioColors.dark,
        TioThemeMode.oled => TioColors.oled,
        _ => TioColors.light,
      };

      await pumpApp(tester, mode.$1);
      expect(find.byKey(addAction), findsOneWidget);

      // Root-navigator modal, opened from a shell branch route.
      await tester.tap(find.byKey(addAction));
      await tester.pumpAndSettle();
      expect(find.byKey(sheet), findsOneWidget);
      expect(
        materialOf(tester, find.byKey(sheet)).color,
        expected.surface,
        reason: '${mode.$2}: the Add Food sheet must inherit the app theme',
      );
      expect(
        materialOf(tester, find.byKey(sheet)).color,
        isNot(TioColors.light.surface),
        reason: '${mode.$2}: a root modal must not fall back to Light',
      );

      await tester.tap(find.byKey(quickAddCard));
      await tester.pumpAndSettle();
      expect(
        materialOf(tester, find.byKey(editorSheet)).color,
        expected.surfaceRaised,
        reason: '${mode.$2}: the Quick Add editor must inherit it too',
      );
      expect(
        materialOf(tester, find.byKey(editorSheet)).color,
        isNot(TioColors.light.surfaceRaised),
      );
    });
  }
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

class _FixedAppSessionBootstrapController extends AppSessionBootstrapController {
  _FixedAppSessionBootstrapController({
    required AppSessionBootstrapState state,
    required super.onboardingStatusController,
  })  : fixedState = state,
        super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  final AppSessionBootstrapState fixedState;

  @override
  AppSessionBootstrapState get state => fixedState;

  @override
  void start() {}
}
