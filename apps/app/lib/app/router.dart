import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_onboarding/onboarding.dart'
    hide ProfileGender, ProfileActivityLevel;
import 'package:tio_feature_splash/splash.dart';

import 'account_setup/account_setup_providers.dart';
import 'app_mode/app_mode.dart';
import 'app_theme.dart';
import 'network_providers.dart';
import 'onboarding/onboarding.dart';
import 'routing/routes/account_settings_routes.dart';
import 'routing/routes/account_setup_routes.dart';
import 'routing/routes/auth_routes.dart';
import 'routing/routes/body_weight_routes.dart';
import 'routing/routes/daily_wellness_routes.dart';
import 'routing/routes/onboarding_routes.dart';
import 'routing/routes/nutrition_routes.dart';
import 'routing/routes/profile_routes.dart';
import 'routing/routes/settings_routes.dart';
import 'routing/shell/shell_route.dart';
import 'session/session.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

ChromePolicy shellChromePolicyForPath(String location) {
  final appRoutes = [
    AppRoutes.splash,
    AppRoutes.auth,
    AppRoutes.appModeSetup,
    AppRoutes.accountSetup,
    AppRoutes.usernameSetup,
    AppRoutes.onboarding,
    AppRoutes.profile,
    AppRoutes.profileAvatar,
    AppRoutes.settings,
    AppRoutes.healthGoalsSettings,
    AppRoutes.dailyWellnessSettings,
    AppRoutes.bodyWeightSettings,
    AppRoutes.nutritionSettings,
    AppRoutes.nutritionProfileSettings,
    AppRoutes.nutritionTargetsSettings,
    AppRoutes.nutritionMacrosSettings,
    AppRoutes.nutritionAdditionalGoalsSettings,
    AppRoutes.mealDiarySettings,
    AppRoutes.mealCategoriesSettings,
    AppRoutes.archivedMealCategoriesSettings,
    AppRoutes.profileSettings,
    AppRoutes.accountSettings,
    AppRoutes.appSettings,
    AppRoutes.appModeSettings,
    AppRoutes.measurementUnitsSettings,
    AppRoutes.themeSettings,
    AppRoutes.calendarSettings,
    AppRoutes.workoutLibrary,
    AppRoutes.workoutPrograms,
    AppRoutes.workoutExercises,
    AppRoutes.login,
    AppRoutes.emailLogin,
    AppRoutes.emailSignup,
    AppRoutes.forgotPassword,
  ];

  for (final route in appRoutes) {
    if (route.path == location) return route.chromePolicy;
  }

  final isMainTabRoot =
      shellBranchRegistry.any((branch) => branch.route.path == location);
  if (isMainTabRoot) return ChromePolicy.mainChrome;

  return ChromePolicy.noBottomBar;
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final appModeController = ref.read(appModeControllerProvider);
  final pendingAppModePreference = PendingAppModePreference();
  final onboardingStatusController =
      ref.read(onboardingStatusControllerProvider);
  final appSessionBootstrapController =
      ref.read(appSessionBootstrapControllerProvider);
  final appThemeController = ref.read(appThemeControllerProvider);

  Future<void> clearGlassSizeForNewExplicitLogin() async {
    try {
      await ref
          .read(hydrationPreferencesSessionBoundaryProvider)
          .clearForNewExplicitLogin();
    } catch (_) {
      // A completed Auth sign-in still proceeds if local storage is unavailable.
    } finally {
      ref.invalidate(hydrationPreferencesDataProvider);
      await appSessionBootstrapController.refresh();
    }
  }

  Future<void> signOutAndClearGlassSize() => ref
      .read(hydrationPreferencesSessionBoundaryProvider)
      .clearAfterSuccessfulSignOut(
        ref.read(authSessionRepositoryProvider).signOut,
      );

  OnboardingControllerSeed buildOnboardingSeed() {
    final selectedMode = appModeController.selectedMode;
    return OnboardingControllerSeed(
      entryPath: onboardingStatusController.entryPath,
      draft: selectedMode == null
          ? null
          : OnboardingDraft(
              selectedMode: selectedMode,
              currentStepId: OnboardingStepId.profileBasics,
            ),
    );
  }

  Future<void> handleOnboardingExit() async {
    await signOutAndClearGlassSize();
    await appSessionBootstrapController.refresh();
  }

  Future<bool> handleOnboardingAuthRequired(BuildContext context) async {
    final sessionState =
        await ref.read(authSessionRepositoryProvider).currentSessionState;
    if (sessionState is AuthSessionAuthenticated) {
      return true;
    }

    final authProductState = ref.read(authProductStateProvider);
    final hasDurableProfileOwner = ref.read(userProfileRepositoryProvider) != null;
    if (authProductState.isAuthUnavailable && !hasDurableProfileOwner) {
      return true;
    }

    if (!context.mounted) return false;
    final result = await context.push<bool>(AppRoutes.emailSignup.path);
    return result ?? false;
  }

  Future<void> handleOnboardingFinish(
    BuildContext context,
    OnboardingDraft draft,
  ) async {
    debugPrint(
        '[Router] onFinishRequested invoked. Profile name: "${draft.profile.name}"');
    try {
      final authRepository = ref.read(authSessionRepositoryProvider);
      final hasDurableProfileOwner =
          ref.read(userProfileRepositoryProvider) != null;
      var sessionState = await authRepository.currentSessionState;

      if (hasDurableProfileOwner &&
          sessionState is! AuthSessionAuthenticated) {
        debugPrint(
          '[Router] Auth session is not ready. Pushing Signup...',
        );
        if (!context.mounted) return;
        await context.push<bool>(AppRoutes.emailSignup.path);
        sessionState = await authRepository.currentSessionState;
        if (sessionState is! AuthSessionAuthenticated) {
          debugPrint(
            '[Router] User still not authenticated after signup sheet.',
          );
          throw StateError(
            'Sign in is required to save your setup to Supabase.',
          );
        }
        debugPrint(
          '[Router] Auth succeeded! userId=${sessionState.session.userId}',
        );
      }

      final completeOnboarding =
          ref.read(appCompleteOnboardingUseCaseFactoryProvider)();
      if (completeOnboarding == null) {
        throw StateError(
          'Product Onboarding completion is unavailable right now.',
        );
      }
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: onboardingStatusController.entryPath,
        mode: draft.selectedMode,
        workoutIntroChoice: draft.workoutIntroChoice,
      );

      debugPrint('[Router] Executing completeOnboarding...');
      await completeOnboarding(
        draft: draft,
        flowPlan: flowPlan,
      );
      debugPrint('[Router] completeOnboarding SUCCESS!');
      final finalSessionState = await authRepository.currentSessionState;
      final completedUserId = finalSessionState is AuthSessionAuthenticated
          ? finalSessionState.session.userId
          : null;
      if (context.mounted) {
        context.go(
          AppRoutes.congratulations.path,
          extra: {
            'userName': draft.profile.name,
            'isWelcomeBack': false,
          },
        );
      }
      onboardingStatusController.markCompleted();
      if (completedUserId != null && completedUserId.isNotEmpty) {
        appSessionBootstrapController
            .markReadyAfterOnboardingCompletion(completedUserId);
      }
    } catch (e, st) {
      debugPrint('[Router] onFinishRequested EXCEPTION: $e');
      debugPrint('[Router] onFinishRequested StackTrace:\n$st');
      rethrow;
    }
  }

  void handleCongratulationsContinue(BuildContext context) {
    context.go(FeatureRoutes.home.path);
  }
  late final GoRouter router;
  router = GoRouter(
    initialLocation: AppRoutes.splash.path,
    navigatorKey: rootNavigatorKey,
    refreshListenable: Listenable.merge([
      appSessionBootstrapController,
      appModeController,
      onboardingStatusController,
    ]),
    redirect: (context, state) {
      final bootstrapRedirect = appSessionBootstrapRedirect(
        path: state.uri.path,
        state: appSessionBootstrapController.state,
      );
      if (bootstrapRedirect != null) {
        return bootstrapRedirect;
      }

      if (appSessionBootstrapController.state is! AppSessionBootstrapReady) {
        return null;
      }

      return appModeRedirect(
        path: state.uri.path,
        selectedMode: appModeController.selectedMode,
        activeDestinations: appModeController.activeDestinations,
        onboardingStatus: onboardingStatusController.status,
      );
    },
    routes: [
      buildAppShellRoute(
        rootNavigatorKey: rootNavigatorKey,
        chromePolicyForPath: shellChromePolicyForPath,
        isOnboardingCompleted: () =>
            onboardingStatusController.status == OnboardingStatus.completed,
        router: () => router,
      ),
      GoRoute(
        path: AppRoutes.splash.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return ListenableBuilder(
            listenable: appSessionBootstrapController,
            builder: (context, _) {
              final bootstrapState = appSessionBootstrapController.state;
              final isFailure = bootstrapState is AppSessionBootstrapFailure;
              return SplashScreen(
                failureMessage: isFailure
                    ? "Couldn't finish signing you in. Check your connection and try again."
                    : null,
                onRetry: isFailure
                    ? () => appSessionBootstrapController.refresh()
                    : null,
              );
            },
          );
        },
      ),
      ...buildAuthRoutes(
        rootNavigatorKey: rootNavigatorKey,
        pendingAppModePreference: pendingAppModePreference,
        onExplicitLoginSuccess: clearGlassSizeForNewExplicitLogin,
      ),
      ...buildAccountSetupRoutes(
        rootNavigatorKey: rootNavigatorKey,
        profileAccountRepository: () =>
            ref.read(profileAccountRepositoryProvider),
        accountSetupRepository: () => ref.read(accountSetupRepositoryProvider),
        authSessionState: () => ref.read(authSessionStateProvider).valueOrNull,
        onExitRequested: () async {
          await signOutAndClearGlassSize();
          await appSessionBootstrapController.refresh();
        },
        onCompleted: () async {
          final pendingMode = await pendingAppModePreference.read();
          if (pendingMode != null) {
            await appModeController.select(pendingMode);
            await pendingAppModePreference.clear();
          }
          ref.invalidate(profileDataProvider);
          await appSessionBootstrapController.refresh();
        },
      ),
      ...buildOnboardingRoutes(
        rootNavigatorKey: rootNavigatorKey,
        seed: buildOnboardingSeed,
        onExitRequested: handleOnboardingExit,
        onAuthRequired: handleOnboardingAuthRequired,
        onFinishRequested: handleOnboardingFinish,
        onCongratulationsContinue: handleCongratulationsContinue,
      ),
      ...buildProfileRoutes(
        rootNavigatorKey: rootNavigatorKey,
      ),
      ...buildSettingsRoutes(
        rootNavigatorKey: rootNavigatorKey,
        onLogoutRequested: signOutAndClearGlassSize,
        appModeController: appModeController,
        appThemeController: appThemeController,
      ),
      ...buildNutritionRoutes(
        rootNavigatorKey: rootNavigatorKey,
        loadFailureBuilder: ({required title, required onRetry}) =>
            _NutritionLoadFailure(title: title, onRetry: onRetry),
      ),
      ...buildDailyWellnessRoutes(rootNavigatorKey: rootNavigatorKey),
      ...buildBodyWeightRoutes(rootNavigatorKey: rootNavigatorKey),
      ...buildAccountSettingsRoutes(
        rootNavigatorKey: rootNavigatorKey,
        markUnauthenticatedAfterAccountDeletion: () =>
            appSessionBootstrapController.markUnauthenticatedAfterAccountDeletion(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Shared retryable failure state for the Nutrition Settings routes.
///
/// Both Nutrition surfaces load a canonical row before they can render, so the
/// same failure UI serves both rather than each route hand-rolling one.
class _NutritionLoadFailure extends StatelessWidget {
  const _NutritionLoadFailure({required this.title, required this.onRetry});

  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: TioSize.dp48,
                  color: colors.danger,
                ),
                const SizedBox(height: TioSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size18,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                const SizedBox(height: TioSpacing.sm),
                Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: TioFontSize.size14,
                  ),
                ),
                const SizedBox(height: TioSpacing.xl),
                TioButton.primary(label: 'Retry', onPressed: onRetry),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
