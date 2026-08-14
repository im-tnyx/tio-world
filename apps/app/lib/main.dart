import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/app_mode/app_mode.dart';
import 'app/network_providers.dart';
import 'app/onboarding/onboarding.dart';
import 'app/app_theme.dart';
import 'app/bootstrap.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

Future<void> main() async {
  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oykupyiitspujzpwwvuj.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_pVet6gRi6JRZ-dyxrZtDSg_MAZa9mfq',
  );
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
    } catch (_) {
      // Safe fallback if headless test environment
    }
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

  await appModeController.load();
  await onboardingStatusController.load();
  await appThemeController.load();

  bootstrap(
    () => AppThemeBootstrap(
      controller: appThemeController,
      child: AppModeBootstrap(
        controller: appModeController,
        child: ProviderScope(
          overrides: [
            appModeControllerProvider.overrideWith((ref) => appModeController),
            onboardingStatusControllerProvider
                .overrideWith((ref) => onboardingStatusController),
            onboardingStatusRepositoryProvider
                .overrideWith((ref) => onboardingStatusRepository),
            onboardingDraftRepositoryProvider.overrideWith(
                (ref) => ref.watch(appOnboardingDraftRepositoryProvider)),
            onboardingCompletionValidatorProvider.overrideWith(
                (ref) => ref.watch(appOnboardingCompletionValidatorProvider)),
            appThemeControllerProvider
                .overrideWith((ref) => appThemeController),
          ],
          child: const TioApp(),
        ),
      ),
    ),
  );
}
