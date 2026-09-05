import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';

import 'app/app.dart';
import 'app/app_mode/app_mode.dart';
import 'app/app_theme.dart';
import 'app/bootstrap.dart';
import 'app/calendar_preferences.dart';
import 'app/google_identity_link_controller.dart';
import 'app/network_providers.dart';
import 'app/onboarding/onboarding.dart';
import 'app/profile/canonical_profile_data_reader.dart';
import 'app/startup_hydration.dart';
import 'app/supabase_runtime_config.dart';

void _installSafeDebugPrintPolicy() {
  final upstreamDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message?.startsWith('[Router]') ?? false) {
      return;
    }
    upstreamDebugPrint(message, wrapWidth: wrapWidth);
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installSafeDebugPrintPolicy();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final supabaseConfig = SupabaseRuntimeConfig.fromEnvironment();
  final supabaseInitialized = await initializeSupabaseRuntime(
    config: supabaseConfig,
  );
  if (supabaseInitialized &&
      Supabase.instance.client.auth.currentUser != null) {
    // Sync device in background upon session restore on launch.
    unawaited(
      SupabaseUserDeviceRepository(
        client: Supabase.instance.client,
        deviceIdentityProvider: FlutterDeviceIdentityProvider(),
      ).syncCurrentDevice(),
    );
  }

  final appModeController =
      AppModeController(SharedPreferencesAppModePreference());
  final onboardingStatusRepository =
      SharedPreferencesOnboardingStatusRepository();
  final onboardingStatusController = OnboardingStatusController(
    repository: onboardingStatusRepository,
    appModeController: appModeController,
  );
  final appThemeController =
      AppThemeController(SharedPreferencesAppThemePreference());
  final calendarPreferencesController = CalendarPreferencesController(
    SharedPreferencesCalendarPreferencesRepository(),
  );

  await hydrateStartupControllers(
    appModeController: appModeController,
    onboardingStatusController: onboardingStatusController,
    appThemeController: appThemeController,
    calendarPreferencesController: calendarPreferencesController,
  );

  bootstrap(
    () => ProviderScope(
      overrides: [
        supabaseConfigProvider.overrideWithValue(supabaseConfig),
        googleIdentityLinkControllerProvider.overrideWith(
          (ref) => ref.watch(appGoogleIdentityLinkControllerProvider),
        ),
        appModeControllerProvider.overrideWith((ref) => appModeController),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingStatusRepository),
        onboardingDraftRepositoryProvider.overrideWith(
          (ref) => ref.watch(hybridOnboardingDraftRepositoryProvider),
        ),
        onboardingCompletionValidatorProvider.overrideWith(
          (ref) => ref.watch(appOnboardingCompletionValidatorProvider),
        ),
        onboardingHydrationGateProvider.overrideWith((ref) => true),
        onboardingControllerProvider.overrideWith((ref, seed) {
          final draftRepository =
              ref.watch(hybridOnboardingDraftRepositoryProvider);
          final controller = AppOnboardingController(
            entryPath: seed.entryPath,
            initialDraft: seed.draft,
            statusRepository: ref.watch(onboardingStatusRepositoryProvider),
            draftRepository: draftRepository,
            completionValidator:
                ref.watch(onboardingCompletionValidatorProvider),
            localDraftStore: ref.watch(localOnboardingDraftStoreProvider),
          );
          unawaited(controller.hydrateDraft());
          return controller;
        }),
        profileDataProvider.overrideWith((ref) {
          ref.watch(authSessionStateProvider);
          final client = ref.watch(supabaseClientProvider);
          if (client == null) {
            return ref.watch(profileSetupRepositoryProvider).watchProfileSetup();
          }

          final reader = CanonicalProfileDataReader(
            profileRepository: SupabaseUserProfileRepository(client: client),
            bodyRepository: SupabaseBodySetupRepository(client: client),
            accountReader:
                SupabaseProfileAccountSnapshotReader(client: client),
          );
          return CanonicalSupabaseProfileDataStream(
            client: client,
            reader: reader,
          ).watch();
        }),
        appThemeControllerProvider.overrideWith((ref) => appThemeController),
        calendarPreferencesControllerProvider
            .overrideWith((ref) => calendarPreferencesController),
      ],
      child: const TioApp(),
    ),
  );
}
