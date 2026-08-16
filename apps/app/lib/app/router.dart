import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_onboarding/onboarding.dart'
    hide ProfileGender, ProfileActivityLevel;
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_splash/splash.dart';
import 'package:tio_feature_welcome/welcome.dart';
import 'package:tio_shared/shared.dart';

import 'app_mode/app_mode.dart';
import 'app_theme.dart';
import 'network_providers.dart';
import 'onboarding/onboarding.dart';
import 'session/session.dart';

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
    AppRoutes.profileSettings,
    AppRoutes.accountSettings,
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
  final appSessionBootstrapController =
      ref.read(appSessionBootstrapControllerProvider);
  final appThemeController = ref.read(appThemeControllerProvider);
  final onboardingStatusRepository =
      ref.read(onboardingStatusRepositoryProvider);
  final profileRepository = ref.read(profileSetupRepositoryProvider);
  final workoutRepository = ref.read(workoutPreferencesRepositoryProvider);
  final targetsRepository = ref.read(targetsSetupRepositoryProvider);
  final onboardingDraftRepository =
      ref.read(appOnboardingDraftRepositoryProvider);
  final onboardingCompletionRepository =
      ref.read(onboardingCompletionRepositoryProvider);

  final authProductState = ref.watch(authProductStateProvider);
  final supabaseClient = ref.watch(supabaseClientProvider);
  final isSupabaseReady =
      supabaseClient != null && supabaseClient.auth.currentUser != null;
  final isDurablePersistenceReady = isSupabaseReady ||
      authProductState.isReadyForProtectedBackendCalls ||
      authProductState.isAuthUnavailable ||
      supabaseClient == null;
  const hasDurableStorage = true;

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

              final profileAsync = ref.watch(profileDataProvider);
              final profileData = profileAsync.valueOrNull;

              final planTier = switch (profileData?.plan.toLowerCase()) {
                'plus' => ShellPlanTier.plus,
                'pro' || 'premium' => ShellPlanTier.premium,
                _ => ShellPlanTier.free,
              };

              return TioShell(
                key: ValueKey('shell-${profileData?.avatarUrl}-${profileData?.plan}'),
                state: ShellUiState(
                  selectedTab:
                      ShellTab.fromBranchIndex(navigationShell.currentIndex),
                  visibleTabs: visibleTabs,
                  isBottomNavVisible: chromePolicy.showsBottomNav,
                  isRootTopBarVisible: chromePolicy.showsRootTopBar,
                  userName: profileData?.name ?? profileData?.username,
                  avatarUrl: profileData?.avatarUrl,
                  planTier: planTier,
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
            return AuthLandingPage(
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
            final supabaseSignInUseCase =
                ref.watch(signInWithGoogleUseCaseProvider);
            final googleAuthUseCase = ref.watch(googleAuthUseCaseProvider);
            return LoginPage(
              signInWithEmailUseCase: signInWithEmailUseCase,
              signInWithGoogleUseCase: supabaseSignInUseCase,
              googleAuthUseCase: googleAuthUseCase,
              onSignInSuccess: (_) {
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go(AppRoutes.home.path);
                }
              },
              onAuthSuccess: (result) {
                ref.read(backendUserStateProvider.notifier).state =
                    result.backendUserState;
              },
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
              onSignUpSuccess: (_) {
                if (context.canPop()) {
                  context.pop(true);
                }
              },
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
            debugPrint('[Router] onFinishRequested invoked. Profile name: "${draft.profile.name}"');
            try {
              if (supabaseClient != null && supabaseClient.auth.currentUser == null) {
                debugPrint('[Router] Supabase user is not logged in. Pushing Login...');
                await context.push<bool>(AppRoutes.login.path);
                if (supabaseClient.auth.currentUser == null) {
                  debugPrint('[Router] User still not logged in after login sheet.');
                  throw StateError('Sign in is required to save your setup to Supabase.');
                }
                debugPrint('[Router] Supabase auth succeeded! userId=${supabaseClient.auth.currentUser?.id}');
              }

              final completeOnboarding = CompleteOnboardingUseCase(
                confirmedModePreference:
                    _AppModeControllerPreferenceAdapter(appModeController),
                statusRepository: onboardingStatusRepository,
                completionRepository: onboardingCompletionRepository,
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
              final currentUser = supabaseClient?.auth.currentUser;
              final isPhoneVerified = currentUser?.phone != null && currentUser!.phone!.isNotEmpty;
              final flowPlan = const BuildOnboardingFlowUseCase()(
                entryPath: onboardingStatusController.entryPath,
                mode: draft.selectedMode,
                workoutIntroChoice: draft.workoutIntroChoice,
                includeMobile: !isPhoneVerified,
              );

              debugPrint('[Router] Executing completeOnboarding...');
              await completeOnboarding(
                draft: draft,
                flowPlan: flowPlan,
              );
              debugPrint('[Router] completeOnboarding SUCCESS!');
              onboardingStatusController.markCompleted();
              if (context.mounted) {
                context.go(
                  AppRoutes.congratulations.path,
                  extra: {
                    'userName': draft.profile.name,
                    'isWelcomeBack': false,
                  },
                );
                final completedUserId = supabaseClient?.auth.currentUser?.id;
                if (completedUserId != null && completedUserId.isNotEmpty) {
                  appSessionBootstrapController
                      .markReadyAfterOnboardingCompletion(completedUserId);
                }
              }
            } catch (e, st) {
              debugPrint('[Router] onFinishRequested EXCEPTION: $e');
              debugPrint('[Router] onFinishRequested StackTrace:\n$st');
              rethrow;
            }
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.congratulations.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userName = extra?['userName'] as String?;
          final isWelcomeBack = extra?['isWelcomeBack'] as bool? ?? false;
          return CongratulationsScreen(
            userName: userName,
            isWelcomeBack: isWelcomeBack,
            onContinue: () => context.go(FeatureRoutes.home.path),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(profileDataProvider);
            final profileData = profileAsync.valueOrNull;

            final avatarFrame = switch (profileData?.plan.toLowerCase()) {
              'plus' => TioAvatarFrame.plusRing,
              'pro' || 'premium' => TioAvatarFrame.proHexagon,
              _ => TioAvatarFrame.none,
            };

            return ProfilePage(
              profileData: profileData,
              isLoading: profileAsync.isLoading,
              avatarFrame: avatarFrame,
              onAvatarPressed: () => context.push(AppRoutes.profileAvatar.path),
              onEditPressed: () => context.push(AppRoutes.profileSettings.path),
              onSettingsPressed: () => context.push(AppRoutes.settings.path),
              onPickImage: (source) async {
                final imageSource = source == TioImageSource.gallery
                    ? ImageSource.gallery
                    : ImageSource.camera;
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: imageSource,
                  imageQuality: 85,
                  maxWidth: 1024,
                  maxHeight: 1024,
                );
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                await ref.read(profileSetupRepositoryProvider).uploadAvatarImage(
                      fileName: picked.name,
                      bytes: bytes,
                    );
                ref.invalidate(profileDataProvider);
              },
              onDeleteImage: () async {
                await ref.read(profileSetupRepositoryProvider).deleteAvatarImage();
                ref.invalidate(profileDataProvider);
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileAvatar.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(profileDataProvider);
            final profileData = profileAsync.valueOrNull;
            return AvatarPreviewPage(
              onBackPressed: context.pop,
              avatarUrl: profileData?.avatarUrl,
              initials: profileData?.name.isNotEmpty == true
                  ? profileData!.name
                  : (profileData?.username ?? ''),
              onPickImage: (source) async {
                final imageSource = source == TioImageSource.gallery
                    ? ImageSource.gallery
                    : ImageSource.camera;
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: imageSource,
                  imageQuality: 85,
                  maxWidth: 1024,
                  maxHeight: 1024,
                );
                if (picked == null) return;
                final bytes = await picked.readAsBytes();
                await ref.read(profileSetupRepositoryProvider).uploadAvatarImage(
                      fileName: picked.name,
                      bytes: bytes,
                    );
                ref.invalidate(profileDataProvider);
              },
              onDeletePressed: () async {
                await ref.read(profileSetupRepositoryProvider).deleteAvatarImage();
                ref.invalidate(profileDataProvider);
                if (context.mounted) context.pop();
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.settings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SettingsPage(
          onProfileSettingsPressed: () =>
              context.push(AppRoutes.profileSettings.path),
          onAccountSettingsPressed: () =>
              context.push(AppRoutes.accountSettings.path),
          onAppSettingsPressed: () => context.push(AppRoutes.appSettings.path),
          onLogoutPressed: () async {
            await ref.read(authSessionRepositoryProvider).signOut();
            if (context.mounted) context.go(AppRoutes.auth.path);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final profileAsync = ref.watch(profileDataProvider);
          final profileData = profileAsync.valueOrNull;

          final avatarFrame = switch (profileData?.plan.toLowerCase()) {
            'plus' => TioAvatarFrame.plusRing,
            'pro' || 'premium' => TioAvatarFrame.proHexagon,
            _ => TioAvatarFrame.none,
          };

          return ProfileSettingsPage(
            name: profileData?.name ?? '',
            username: profileData?.username ?? '',
            gender: profileData?.gender.name ?? 'Male',
            dateOfBirth: profileData?.dateOfBirth,
            heightCm: profileData?.heightCm ?? 170.0,
            currentWeightKg: profileData?.currentWeightKg ?? 70.0,
            avatarUrl: profileData?.avatarUrl,
            avatarFrame: avatarFrame,
            plan: profileData?.plan ?? 'free',
            onAvatarPressed: () => context.push(AppRoutes.profileAvatar.path),
            onPickImage: (source) async {
              final imageSource = source == TioImageSource.gallery
                  ? ImageSource.gallery
                  : ImageSource.camera;
              final picker = ImagePicker();
              final picked = await picker.pickImage(
                source: imageSource,
                imageQuality: 85,
                maxWidth: 1024,
                maxHeight: 1024,
              );
              if (picked == null) return;
              final bytes = await picked.readAsBytes();
              await ref.read(profileSetupRepositoryProvider).uploadAvatarImage(
                    fileName: picked.name,
                    bytes: bytes,
                  );
              ref.invalidate(profileDataProvider);
            },
            onDeleteImage: () async {
              await ref.read(profileSetupRepositoryProvider).deleteAvatarImage();
              ref.invalidate(profileDataProvider);
            },
            onSave: ({
              required name,
              required username,
              required gender,
              required dateOfBirth,
              required heightCm,
              required currentWeightKg,
            }) async {
              final parsedGender = ProfileGender.values.firstWhere(
                (g) => g.name.toLowerCase() == gender.toLowerCase(),
                orElse: () => ProfileGender.male,
              );
              final updated = ProfileSetupData(
                name: name,
                username: username.isNotEmpty ? username : null,
                gender: parsedGender,
                goals: profileData?.goals ?? const {},
                dateOfBirth: dateOfBirth,
                heightCm: heightCm,
                currentWeightKg: currentWeightKg,
                targetWeightKg: profileData?.targetWeightKg ?? currentWeightKg,
                activityLevel:
                    profileData?.activityLevel ?? ProfileActivityLevel.active,
                healthConditions: profileData?.healthConditions ?? const {},
                otherHealthCondition: profileData?.otherHealthCondition,
                avatarUrl: profileData?.avatarUrl,
                avatarFrame: profileData?.avatarFrame ?? 'none',
                plan: profileData?.plan ?? 'free',
              );
              await ref.read(profileSetupRepositoryProvider).saveProfileSetup(updated);
              ref.invalidate(profileDataProvider);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accountSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final supabase = ref.watch(supabaseClientProvider);
          final userEmail = supabase?.auth.currentUser?.email;
          final profileAsync = ref.watch(profileDataProvider);
          final profileData = profileAsync.valueOrNull;

          return AccountSettingsPage(
            username: profileData?.username,
            email: userEmail,
            onDeleteAccountConfirmed: () async {
              try {
                await supabase?.rpc<void>('delete_user_account');
              } catch (_) {}
              await ref.read(authSessionRepositoryProvider).signOut();
              if (context.mounted) context.go(AppRoutes.auth.path);
            },
          );
        },
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
