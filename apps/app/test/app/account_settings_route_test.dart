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
import 'package:tio_feature_onboarding/onboarding.dart'
    hide
        ProfileGender,
        ProfileActivityLevel,
        ProfileGoal,
        ProfileHealthCondition;
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_shared/shared.dart';

/// #24-D production-wiring coverage: proves `router.dart`'s real
/// `AccountSettingsPage` composition actually reaches the real
/// `ProfileAccountRepository.checkUsernameAvailability` -- not just that the
/// callback type-checks. Before this migration, `onCheckUsernameAvailability`
/// was never wired at all, so this path was previously untested and, in
/// production, silently fell back to a hardcoded demo taken-list.
void main() {
  Future<ProviderContainer> buildContainer(
    _FakeProfileAccountRepository repository,
  ) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
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

    const session = AuthSession(userId: 'user-1', loginCycleId: 'cycle-1');
    final profile = ProfileSetupData(
      name: 'Member One',
      username: 'member_initial',
      gender: ProfileGender.values.first,
      goals: const <ProfileGoal>{},
      dateOfBirth: DateTime(1990, 1, 1),
      heightCm: 175,
      currentWeightKg: 70,
      activityLevel: ProfileActivityLevel.values.first,
      healthConditions: const <ProfileHealthCondition>{},
      mobile: '+919000000000',
    );

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
            state: const AppSessionBootstrapReady(userId: 'user-1'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
        authSessionStateProvider.overrideWith(
          (ref) => Stream.value(const AuthSessionAuthenticated(session)),
        ),
        profileDataProvider.overrideWith((ref) => Stream.value(profile)),
        profileAccountRepositoryProvider.overrideWith((ref) => repository),
      ],
    );
  }

  testWidgets(
      'Account Settings route wires the real repository availability check '
      'through to the field', (tester) async {
    final repository = _FakeProfileAccountRepository();
    final container = await buildContainer(repository);
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
    router.go(AppRoutes.accountSettings.path);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const TioApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account Settings'), findsOneWidget);

    // Available: reaches TioUsernameInputField's own available icon.
    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'brand_new_free_handle',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(repository.checked, ['brand_new_free_handle']);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // Unavailable: the repository's real decision (and reason-based message)
    // reaches the field too, not just a boolean.
    repository.nextResult = const UsernameAvailabilityCheck(
      normalized: 'reserved_handle',
      isAvailable: false,
      reason: UsernameAvailabilityReason.reserved,
    );
    await tester.enterText(
      find.byKey(const ValueKey('tio-username-input')),
      'reserved_handle',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(
      repository.checked,
      ['brand_new_free_handle', 'reserved_handle'],
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(
      find.text('That username is reserved. Try one of these instead:'),
      findsOneWidget,
    );
  });
}

class _FakeProfileAccountRepository implements ProfileAccountRepository {
  final checked = <String>[];
  UsernameAvailabilityCheck? nextResult;

  @override
  Future<String?> currentUsername() async => 'member_initial';

  @override
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(
    String username,
  ) async {
    final normalized = username.trim().toLowerCase();
    checked.add(normalized);
    return nextResult ??
        UsernameAvailabilityCheck(normalized: normalized, isAvailable: true);
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    return (await checkUsernameAvailability(username)).isAvailable;
  }

  @override
  Future<void> updateUsername(String username) async {}

  @override
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  }) async {}
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
