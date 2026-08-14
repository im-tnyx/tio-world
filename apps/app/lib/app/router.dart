import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_splash/splash.dart';
import 'package:tio_feature_welcome/welcome.dart';
import 'package:tio_shared/shared.dart';

import 'app_mode/app_mode.dart';
import 'app_theme.dart';
import 'network_providers.dart';
import 'onboarding/onboarding.dart';


final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

TioShellPlaceholder _page(TioRouteContract route) {
  return TioShellPlaceholder(
      title: route.title, description: route.description);
}

Widget _shellBranchPage(ShellBranchDefinition branch) {
  if (branch.tab == ShellTab.home) {
    return const HomePage();
  }

  return _page(branch.route);
}

ChromePolicy shellChromePolicyForPath(String location) {
  final appRoutes = [
    AppRoutes.splash,
    AppRoutes.auth,
    AppRoutes.onboarding,
    AppRoutes.profile,
    AppRoutes.profileAvatar,
    AppRoutes.settings,
    AppRoutes.appSettings,
    AppRoutes.appModeSettings,
    AppRoutes.themeSettings,
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

void _handleShellAction(GoRouter router,
    StatefulNavigationShell navigationShell, ShellAction action) {
  if (action is ShellTabSelected) {
    navigationShell.goBranch(action.tab.branchIndex);
    return;
  }

  if (action is ShellProfileClicked) {
    router.push(AppRoutes.profile.path);
    return;
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final appModeController = ref.read(appModeControllerProvider);
  final onboardingStatusController =
      ref.read(onboardingStatusControllerProvider);
  final appThemeController = ref.read(appThemeControllerProvider);
  final onboardingStatusRepository =
      ref.read(onboardingStatusRepositoryProvider);
  final profileRepository = ref.read(profileSetupRepositoryProvider);
  final workoutRepository = ref.read(workoutPreferencesRepositoryProvider);
  final targetsRepository = ref.read(targetsSetupRepositoryProvider);
  final onboardingDraftRepository =
      ref.read(appOnboardingDraftRepositoryProvider);

  final authProductState = ref.watch(authProductStateProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isSupabaseReady =
      supabaseClient != null && supabaseClient.auth.currentUser != null;
  final isDurablePersistenceReady =
      isSupabaseReady || authProductState.isReadyForProtectedBackendCalls;
  final hasDurableStorage =
      supabaseClient != null || authProductState.capability.isAvailable;

  late final GoRouter router;
  router = GoRouter(
    initialLocation: AppRoutes.splash.path,
    navigatorKey: rootNavigatorKey,
    refreshListenable:
        Listenable.merge([appModeController, onboardingStatusController]),
    redirect: (context, state) {
      if (state.uri.path == AppRoutes.onboarding.path &&
          authProductState.capability.isAvailable &&
          !authProductState.isFirebaseAuthenticated) {
        return AppRoutes.login.path;
      }
      return appModeRedirect(
        path: state.uri.path,
        selectedMode: appModeController.selectedMode,
        onboardingStatus: onboardingStatusController.status,
      );
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final chromePolicy = shellChromePolicyForPath(state.uri.path);

          return Consumer(
            builder: (context, ref, child) {
              final selectedMode =
                  ref.watch(appModeControllerProvider).selectedMode;
              final visibleTabs = selectedMode == null
                  ? const [ShellTab.home]
                  : guidedShellTabs(selectedMode);

              return TioShell(
                state: ShellUiState(
                  selectedTab:
                      ShellTab.fromBranchIndex(navigationShell.currentIndex),
                  visibleTabs: visibleTabs,
                  isBottomNavVisible: chromePolicy.showsBottomNav,
                  isRootTopBarVisible: chromePolicy.showsRootTopBar,
                ),
                onAction: (action) =>
                    _handleShellAction(router, navigationShell, action),
                child: child!,
              );
            },
            child: navigationShell,
          );
        },
        branches: shellBranchRegistry.map((branch) {
          return StatefulShellBranch(
            routes: [
              GoRoute(
                path: branch.route.path,
                builder: (context, state) => _shellBranchPage(branch),
              ),
            ],
          );
        }).toList(growable: false),
      ),
      GoRoute(
        path: AppRoutes.splash.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WelcomeRoute(),
      ),
      GoRoute(
        path: AppRoutes.login.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final supabaseSignInUseCase =
                ref.watch(signInWithGoogleUseCaseProvider);
            final googleAuthUseCase = ref.watch(googleAuthUseCaseProvider);
            return LoginPage(
              signInWithGoogleUseCase: supabaseSignInUseCase,
              googleAuthUseCase: googleAuthUseCase,
              onAuthSuccess: (result) {
                ref.read(backendUserStateProvider.notifier).state =
                    result.backendUserState;
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.emailLogin.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final signInWithEmailUseCase =
                ref.watch(signInWithEmailUseCaseProvider);
            return EmailLoginPage(
              signInWithEmailUseCase: signInWithEmailUseCase,
              onSignInSuccess: (_) {},
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.emailSignup.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final signUpWithEmailUseCase =
                ref.watch(signUpWithEmailUseCaseProvider);
            return EmailSignupPage(
              signUpWithEmailUseCase: signUpWithEmailUseCase,
              onSignUpSuccess: (_) {},
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final resetUseCase =
                ref.watch(sendPasswordResetEmailUseCaseProvider);
            return ForgotPasswordPage(
              sendPasswordResetEmailUseCase: resetUseCase,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OnboardingFlowPage(
          seed: OnboardingControllerSeed(
            entryPath: onboardingStatusController.entryPath,
          ),
          onExitRequested: () async {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(AppRoutes.auth.path);
          },
          onAuthRequired: () async {
            if (authProductState.isFirebaseAuthenticated || isSupabaseReady) return true;
            if (authProductState.isAuthUnavailable && supabaseClient == null) return true;
            final result = await context.push<bool>(AppRoutes.login.path);
            return result ?? false;
          },
          onFinishRequested: (draft) async {
            final completeOnboarding = CompleteOnboardingUseCase(
              confirmedModePreference:
                  _AppModeControllerPreferenceAdapter(appModeController),
              statusRepository: onboardingStatusRepository,
              draftRepository: onboardingDraftRepository,
              persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
                profileRepository: profileRepository,
                workoutRepository: workoutRepository,
                targetsRepository: targetsRepository,
              ),
              validator: OnboardingCompletionValidator(
                hasDurableOwnerPersistence: hasDurableStorage,
                backendUserReady: isDurablePersistenceReady,
              ),
            );
            final flowPlan = const BuildOnboardingFlowUseCase()(
              entryPath: onboardingStatusController.entryPath,
              mode: draft.selectedMode,
              workoutIntroChoice: draft.workoutIntroChoice,
            );

            await completeOnboarding(
              draft: draft,
              flowPlan: flowPlan,
            );
            onboardingStatusController.markCompleted();
            if (context.mounted) context.go(FeatureRoutes.home.path);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profile.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(profileDataProvider);
            return ProfilePage(
              profileData: profileAsync.valueOrNull,
              isLoading: profileAsync.isLoading,
              onAvatarPressed: () => context.push(AppRoutes.profileAvatar.path),
              onSettingsPressed: () => context.push(AppRoutes.settings.path),
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileAvatar.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AvatarPreviewPage(
          onBackPressed: context.pop,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SettingsPage(
          onAppSettingsPressed: () => context.push(AppRoutes.appSettings.path),
        ),
      ),
      GoRoute(
        path: AppRoutes.appSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final currentMode = appModeController.selectedMode;
          if (currentMode == null) return const SizedBox.shrink();

          return AppSettingsPage(
            currentMode: currentMode,
            currentThemeMode: appThemeController.selectedMode,
            onAppModePressed: () =>
                context.push(AppRoutes.appModeSettings.path),
            onThemePressed: () => showThemeSelectionBottomSheet(
              context: context,
              currentMode: appThemeController.selectedMode,
              onThemeSelected: (mode) => appThemeController.select(mode),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.appModeSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final currentMode = appModeController.selectedMode;
          if (currentMode == null) return const SizedBox.shrink();

          return AppModeSettingsPage(
            currentMode: currentMode,
            onModeChanged: (mode) async {
              await appModeController.select(mode);
              if (context.mounted) context.go(FeatureRoutes.home.path);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.themeSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ThemeSettingsPage(
          currentMode: appThemeController.selectedMode,
          onThemeChanged: (mode) async {
            await appThemeController.select(mode);
            if (context.mounted) context.pop();
          },
        ),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _AppModeControllerPreferenceAdapter implements AppModePreference {
  _AppModeControllerPreferenceAdapter(this._controller);

  final AppModeController _controller;

  @override
  Future<void> clear() => _controller.clear();

  @override
  Future<AppMode?> read() async => _controller.selectedMode;

  @override
  Future<void> write(AppMode mode) => _controller.select(mode);
}
