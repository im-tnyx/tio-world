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
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets(
      'confirmed Product Onboarding root exit signs out, refreshes, and reaches Welcome',
      (tester) async {
    final modePreference = _MemoryAppModePreference(AppMode.workout);
    final appModeController = AppModeController(modePreference);
    await appModeController.load();

    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.inProgress,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: appModeController,
    );
    await onboardingStatusController.load();

    final authRepository = _TrackingAuthSessionRepository();
    final bootstrapController = _ExitBootstrapController(
      authSessionRepository: authRepository,
      onboardingStatusController: onboardingStatusController,
    );
    final themeController = await _createThemeController();
    final hydrationRepository = _MemoryHydrationPreferencesRepository(300);

    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => appModeController),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        authSessionRepositoryProvider.overrideWith((ref) => authRepository),
        appSessionBootstrapControllerProvider
            .overrideWith((ref) => bootstrapController),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        hydrationPreferencesRepositoryProvider
            .overrideWithValue(hydrationRepository),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider)
      ..go(AppRoutes.onboarding.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
    expect(find.text('What should Tio call you?'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(TioConfirmationCard), findsOneWidget);
    expect(authRepository.signOutCalls, 0);
    expect(bootstrapController.refreshCalls, 0);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
    expect(authRepository.signOutCalls, 0);
    expect(bootstrapController.refreshCalls, 0);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(authRepository.signOutCalls, 1);
    expect(await hydrationRepository.read(), const HydrationPreferences());
    expect(bootstrapController.refreshCalls, 1);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.auth.path);
  });
}

class _TrackingAuthSessionRepository extends InMemoryAuthSessionRepository {
  _TrackingAuthSessionRepository()
      : super(
          initialSessionState: const AuthSessionAuthenticated(
            AuthSession(userId: 'test-user'),
          ),
        );

  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await super.signOut();
  }
}

class _ExitBootstrapController extends AppSessionBootstrapController {
  _ExitBootstrapController({
    required super.authSessionRepository,
    required super.onboardingStatusController,
  }) : super(onboardingCompletionRepository: null);

  AppSessionBootstrapState _testState =
      const AppSessionBootstrapRequiresOnboarding(userId: 'test-user');
  int refreshCalls = 0;

  @override
  AppSessionBootstrapState get state => _testState;

  @override
  void start() {}

  @override
  Future<void> refresh({bool emitLoading = true}) async {
    refreshCalls++;
    _testState = const AppSessionBootstrapUnauthenticated();
    notifyListeners();
  }
}

class _MemoryHydrationPreferencesRepository
    implements HydrationPreferencesRepository {
  _MemoryHydrationPreferencesRepository(this._value);

  int _value;

  @override
  Future<void> clear() async {
    _value = HydrationPreferences.defaultGlassSizeMlDefault;
  }

  @override
  Future<HydrationPreferences> read() async =>
      HydrationPreferences(defaultGlassSizeMl: _value);

  @override
  Future<void> write(HydrationPreferences preferences) async {
    _value = preferences.defaultGlassSizeMl;
  }
}

Future<AppThemeController> _createThemeController() async {
  final controller =
      AppThemeController(_MemoryAppThemePreference(TioThemeMode.system));
  await controller.load();
  return controller;
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
