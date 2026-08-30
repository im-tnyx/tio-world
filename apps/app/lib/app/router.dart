import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_onboarding/onboarding.dart'
    hide ProfileGender, ProfileActivityLevel;
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_feature_splash/splash.dart';
import 'package:tio_feature_welcome/welcome.dart';

import 'account_setup/account_setup.dart';
import 'app_mode/app_mode.dart';
import 'app_theme.dart';
import 'network_providers.dart';
import 'onboarding/onboarding.dart';
import 'profile/profile_completion.dart';
import 'profile/profile_settings_route.dart';
import 'session/session.dart';
import 'settings_persistence_providers.dart';

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

String _linkedAuthProvidersLabel(AuthSession? session) {
  final providers = session?.identityProviders ?? const <String>{};
  if (providers.isEmpty) return 'Current session';

  const orderedKnownProviders = <String>['phone', 'email', 'google'];
  final ordered = <String>[
    ...orderedKnownProviders.where(providers.contains),
    ...(providers.where((provider) => !orderedKnownProviders.contains(provider))
          .toList()
        ..sort()),
  ];

  String label(String provider) => switch (provider) {
        'phone' => 'Phone',
        'email' => 'Email',
        'google' => 'Google',
        _ => provider.isEmpty
            ? 'Unknown'
            : '${provider[0].toUpperCase()}${provider.substring(1)}',
      };

  return ordered.map(label).join(' + ');
}

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
    AppRoutes.profileSettings,
    AppRoutes.accountSettings,
    AppRoutes.appSettings,
    AppRoutes.appModeSettings,
    AppRoutes.measurementUnitsSettings,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final chromePolicy = shellChromePolicyForPath(state.uri.path);

          return Consumer(
            builder: (context, ref, child) {
              final modeState = ref.watch(appModeControllerProvider);
              final selectedMode = modeState.selectedMode;
              final visibleTabs = selectedMode == null
                  ? (onboardingStatusController.status == OnboardingStatus.completed
                      ? missingModeCompatibilityShellTabs
                      : const [ShellTab.home])
                  : shellTabsForDestinations(
                      modeState.activeDestinations ??
                          selectedMode.guidedDestinations,
                    );

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
      GoRoute(
        path: AppRoutes.auth.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WelcomeRoute(),
      ),
      GoRoute(
        path: AppRoutes.appModeSetup.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => PreAuthAppModeRoute(
          pendingPreference: pendingAppModePreference,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.auth.path);
            }
          },
          onContinueToSignup: () async {
            if (context.mounted) {
              await context.push<void>(AppRoutes.emailSignup.path);
            }
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.login.path,
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
                unawaited(clearGlassSizeForNewExplicitLogin());
              },
              onAuthSuccess: (result) {
                ref.read(backendUserStateProvider.notifier).state =
                    result.backendUserState;
                unawaited(clearGlassSizeForNewExplicitLogin());
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
                unawaited(clearGlassSizeForNewExplicitLogin());
              },
              onAuthSuccess: (result) {
                ref.read(backendUserStateProvider.notifier).state =
                    result.backendUserState;
                unawaited(clearGlassSizeForNewExplicitLogin());
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
            final supabaseSignInUseCase =
                ref.watch(signInWithGoogleUseCaseProvider);
            final googleAuthUseCase = ref.watch(googleAuthUseCaseProvider);
            return EmailSignupPage(
              signUpWithEmailUseCase: signUpWithEmailUseCase,
              signInWithGoogleUseCase: supabaseSignInUseCase,
              googleAuthUseCase: googleAuthUseCase,
              onSignUpSuccess: (_) {
                unawaited(clearGlassSizeForNewExplicitLogin());
              },
              onAuthSuccess: (result) {
                ref.read(backendUserStateProvider.notifier).state =
                    result.backendUserState;
                unawaited(clearGlassSizeForNewExplicitLogin());
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
        path: AppRoutes.accountSetup.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final usernameRepository = ref.read(profileAccountRepositoryProvider);
          final setupRepository = ref.read(accountSetupRepositoryProvider);
          if (usernameRepository == null || setupRepository == null) {
            return const SplashScreen(
              failureMessage: 'Account setup is unavailable right now.',
            );
          }
          final authState = ref.read(authSessionStateProvider).valueOrNull;
          final currentPhone = authState is AuthSessionAuthenticated
              ? authState.session.phone?.trim()
              : null;
          return AccountSetupFlowPage(
            usernameRepository: usernameRepository,
            accountSetupRepository: setupRepository,
            hasTrustedPhoneIdentity:
                currentPhone != null && currentPhone.isNotEmpty,
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
          );
        },
      ),
      GoRoute(
        path: AppRoutes.usernameSetup.path,
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) => AppRoutes.accountSetup.path,
      ),
      GoRoute(
        path: AppRoutes.onboarding.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final selectedMode = appModeController.selectedMode;
          return OnboardingFlowPage(
            seed: OnboardingControllerSeed(
              entryPath: onboardingStatusController.entryPath,
              draft: selectedMode == null
                  ? null
                  : OnboardingDraft(
                      selectedMode: selectedMode,
                      currentStepId: OnboardingStepId.profileBasics,
                    ),
            ),
            onExitRequested: () async {
              await signOutAndClearGlassSize();
              await appSessionBootstrapController.refresh();
            },
            onAuthRequired: () async {
              final sessionState = await ref
                  .read(authSessionRepositoryProvider)
                  .currentSessionState;
              if (sessionState is AuthSessionAuthenticated) {
                return true;
              }

              final authProductState = ref.read(authProductStateProvider);
              final hasDurableProfileOwner =
                  ref.read(userProfileRepositoryProvider) != null;
              if (authProductState.isAuthUnavailable &&
                  !hasDurableProfileOwner) {
                return true;
              }

              if (!context.mounted) return false;
              final result = await context.push<bool>(AppRoutes.emailSignup.path);
              return result ?? false;
            },
            onFinishRequested: (draft) async {
              debugPrint('[Router] onFinishRequested invoked. Profile name: "${draft.profile.name}"');
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
                final completedUserId =
                    finalSessionState is AuthSessionAuthenticated
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
            },
          );
        },
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
            final completion =
                ref.watch(profileCompletionSummaryProvider).valueOrNull;
            final reminderScope =
                ref.watch(profileCompletionReminderScopeProvider);
            final dismissedAsync = reminderScope == null
                ? null
                : ref.watch(
                    profileCompletionReminderDismissedProvider(reminderScope),
                  );
            final visibleCompletion = reminderScope != null &&
                    dismissedAsync?.hasValue == true &&
                    dismissedAsync?.valueOrNull != true &&
                    completion != null &&
                    !completion.isComplete
                ? completion
                : null;

            final avatarFrame = switch (profileData?.plan.toLowerCase()) {
              'plus' => TioAvatarFrame.plusRing,
              'pro' || 'premium' => TioAvatarFrame.proHexagon,
              _ => TioAvatarFrame.none,
            };

            return ProfilePage(
              profileData: profileData,
              completionSummary: visibleCompletion,
              onCompletionPressed: visibleCompletion == null ||
                      reminderScope == null
                  ? null
                  : () async {
                      await ref
                          .read(profileCompletionReminderPreferenceProvider)
                          .dismiss(reminderScope);
                      ref.invalidate(
                        profileCompletionReminderDismissedProvider(
                          reminderScope,
                        ),
                      );

                      final route = visibleCompletion.hasProfileOwnedMissingField
                          ? AppRoutes.profileSettings.path
                          : AppRoutes.accountSettings.path;
                      if (context.mounted) {
                        await context.push<void>(route);
                      }
                    },
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
                final avatarRepository =
                    ref.read(profileAvatarRepositoryProvider);
                if (avatarRepository == null) {
                  throw StateError('Profile avatar persistence is unavailable.');
                }
                await avatarRepository.uploadAvatarImage(
                  fileName: picked.name,
                  bytes: bytes,
                );
                ref.invalidate(profileDataProvider);
              },
              onDeleteImage: () async {
                final avatarRepository =
                    ref.read(profileAvatarRepositoryProvider);
                if (avatarRepository == null) {
                  throw StateError('Profile avatar persistence is unavailable.');
                }
                await avatarRepository.deleteAvatarImage();
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
                final avatarRepository =
                    ref.read(profileAvatarRepositoryProvider);
                if (avatarRepository == null) {
                  throw StateError('Profile avatar persistence is unavailable.');
                }
                await avatarRepository.uploadAvatarImage(
                  fileName: picked.name,
                  bytes: bytes,
                );
                ref.invalidate(profileDataProvider);
              },
              onDeletePressed: () async {
                final avatarRepository =
                    ref.read(profileAvatarRepositoryProvider);
                if (avatarRepository == null) {
                  throw StateError('Profile avatar persistence is unavailable.');
                }
                await avatarRepository.deleteAvatarImage();
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
          onHealthGoalsPressed: () =>
              context.push(AppRoutes.healthGoalsSettings.path),
          onAppSettingsPressed: () => context.push(AppRoutes.appSettings.path),
          onLogoutPressed: () async {
            await signOutAndClearGlassSize();
            if (context.mounted) context.go(AppRoutes.auth.path);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.healthGoalsSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => HealthGoalsSettingsPage(
          onDailyWellnessPressed: () =>
              context.push(AppRoutes.dailyWellnessSettings.path),
          onBodyWeightPressed: () =>
              context.push(AppRoutes.bodyWeightSettings.path),
        ),
      ),
      GoRoute(
        path: AppRoutes.dailyWellnessSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final wellnessAsync = ref.watch(wellnessTargetsDataProvider);
            final hydrationAsync = ref.watch(hydrationPreferencesDataProvider);
            final hydrationRepository =
                ref.watch(hydrationPreferencesRepositoryProvider);
            final hydrationSession =
                ref.watch(authSessionStateProvider).valueOrNull;
            final hydrationUserId = hydrationSession is AuthSessionAuthenticated
                ? hydrationSession.session.userId
                : null;
            final profileAsync = ref.watch(profileDataProvider);
            final volumeUnit =
                profileAsync.valueOrNull?.unitPreferences.volumeUnit ??
                    VolumeUnit.ml;

            if (wellnessAsync.isLoading && wellnessAsync.valueOrNull == null) {
              return Scaffold(
                backgroundColor: context.tioColors.background,
                appBar: AppBar(
                  backgroundColor: context.tioColors.background,
                  elevation: TioElevation.none,
                  scrolledUnderElevation: TioElevation.none,
                  leading: BackButton(color: context.tioColors.textPrimary),
                  title: Text(
                    'Daily Wellness',
                    style: TextStyle(
                      color: context.tioColors.textPrimary,
                      fontWeight: TioFontWeight.w800,
                      fontSize: TioFontSize.size20,
                    ),
                  ),
                ),
                body: SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.tioColors.primary,
                    ),
                  ),
                ),
              );
            }

            if (wellnessAsync.hasError && wellnessAsync.valueOrNull == null) {
              final colors = context.tioColors;
              return Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  backgroundColor: colors.background,
                  elevation: TioElevation.none,
                  scrolledUnderElevation: TioElevation.none,
                  leading: BackButton(color: colors.textPrimary),
                  title: Text(
                    'Daily Wellness',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w800,
                      fontSize: TioFontSize.size20,
                    ),
                  ),
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TioSpacing.xl),
                    child: Center(
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
                            'Could not load wellness targets',
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
                          TioButton.primary(
                            label: 'Retry',
                            onPressed: () =>
                                ref.invalidate(wellnessTargetsDataProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return DailyWellnessSettingsPage(
              key: ValueKey(hydrationUserId),
              initialTargets: wellnessAsync.valueOrNull,
              volumeUnit: volumeUnit,
              hydrationPreferences: hydrationAsync.valueOrNull,
              hydrationLoading: hydrationAsync.isLoading,
              hydrationLoadFailed: hydrationAsync.hasError,
              onRetryHydration: () =>
                  ref.invalidate(hydrationPreferencesDataProvider),
              onSaveHydration: (preferences) async {
                await hydrationRepository.write(preferences);
                ref.invalidate(hydrationPreferencesDataProvider);
              },
              onSave: (targets) async {
                final repository = ref.read(wellnessTargetsRepositoryProvider);
                await repository.upsert(targets);
                ref.invalidate(wellnessTargetsDataProvider);
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.bodyWeightSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final bodyAsync = ref.watch(bodyStateDataProvider);
            final profileAsync = ref.watch(profileDataProvider);
            final weightUnit =
                profileAsync.valueOrNull?.unitPreferences.weightUnit ??
                    WeightUnit.kg;
            final colors = context.tioColors;

            if (bodyAsync.isLoading && bodyAsync.valueOrNull == null) {
              return Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  backgroundColor: colors.background,
                  elevation: TioElevation.none,
                  scrolledUnderElevation: TioElevation.none,
                  leading: BackButton(color: colors.textPrimary),
                  title: Text(
                    'Body & Weight',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w800,
                      fontSize: TioFontSize.size20,
                    ),
                  ),
                ),
                body: SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  ),
                ),
              );
            }

            if (bodyAsync.hasError && bodyAsync.valueOrNull == null) {
              return Scaffold(
                backgroundColor: colors.background,
                appBar: AppBar(
                  backgroundColor: colors.background,
                  elevation: TioElevation.none,
                  scrolledUnderElevation: TioElevation.none,
                  leading: BackButton(color: colors.textPrimary),
                  title: Text(
                    'Body & Weight',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: TioFontWeight.w800,
                      fontSize: TioFontSize.size20,
                    ),
                  ),
                ),
                body: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TioSpacing.xl),
                    child: Center(
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
                            'Could not load Body & Weight',
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
                          TioButton.primary(
                            label: 'Retry',
                            onPressed: () =>
                                ref.invalidate(bodyStateDataProvider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return BodyWeightSettingsPage(
              bodyState: bodyAsync.valueOrNull ?? const BodyState(),
              weightUnit: weightUnit,
              onRecordCurrentWeight: (weightKg) async {
                final repository = ref.read(bodyRepositoryProvider);
                await repository.recordCurrentWeight(
                  BodyWeightRecord(
                    weightKg: weightKg,
                    measuredAt: DateTime.now(),
                    source: BodyWeightSources.bodyWeightSettings,
                  ),
                );
                ref.invalidate(bodyStateDataProvider);
                ref.invalidate(profileDataProvider);
              },
              onSaveBodyGoal: (update) async {
                final repository = ref.read(bodyRepositoryProvider);
                await repository.setActiveBodyGoal(update);
                ref.invalidate(bodyStateDataProvider);
                ref.invalidate(profileDataProvider);
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.measurementUnitsSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(profileDataProvider);
            final profileData = profileAsync.valueOrNull;

            if (profileAsync.isLoading && profileData == null) {
              return Scaffold(
                body: SafeArea(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: context.tioColors.primary,
                    ),
                  ),
                ),
              );
            }

            return MeasurementUnitsSettingsPage(
              initialPreferences:
                  profileData?.unitPreferences ?? UnitPreferences.metric,
              onSave: (preferences) async {
                final repository =
                    ref.read(measurementUnitPreferencesRepositoryProvider);
                if (repository == null) {
                  throw StateError(
                    'Measurement unit persistence is unavailable.',
                  );
                }
                await repository.updateMeasurementUnitPreferences(preferences);
                ref.invalidate(profileDataProvider);
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.profileSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProfileSettingsRoute(),
      ),
      GoRoute(
        path: AppRoutes.accountSettings.path,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final authState = ref.watch(authSessionStateProvider).valueOrNull;
            final authSession = authState is AuthSessionAuthenticated
                ? authState.session
                : null;
            final profileAsync = ref.watch(profileDataProvider);
            final profileData = profileAsync.valueOrNull;

            return AccountSettingsPage(
              username: profileData?.username,
              email: authSession?.email,
              phoneNumber: authSession?.phone ?? profileData?.mobile,
              isEmailVerified: authSession?.isEmailVerified ?? false,
              isPhoneVerified: authSession?.isPhoneVerified ?? false,
              linkedProvider: _linkedAuthProvidersLabel(authSession),
              onVerifyEmailPressed: (email) async {
                final verificationRepository =
                    ref.read(accountContactVerificationRepositoryProvider);
                if (verificationRepository == null) {
                  throw StateError(
                    'Email verification is unavailable right now.',
                  );
                }

                await verificationRepository
                    .requestCurrentEmailVerification(email);
                if (!context.mounted) return false;
                final token = await showTioOtpVerificationDialog(
                  context: context,
                  targetLabel: 'email ($email)',
                  title: 'Please enter your Code',
                  subtitle: 'Please check your email for the verification code.',
                );
                if (token == null) return false;

                await verificationRepository.verifyCurrentEmail(
                  email: email,
                  token: token,
                );
                ref.invalidate(authSessionStateProvider);
                return true;
              },
              onVerifyPhonePressed: (phoneNumber) async {
                final verificationRepository =
                    ref.read(accountContactVerificationRepositoryProvider);
                if (verificationRepository == null) {
                  throw StateError(
                    'Phone verification is unavailable right now.',
                  );
                }

                await verificationRepository
                    .requestPhoneVerification(phoneNumber);
                if (!context.mounted) return false;
                final token = await showTioOtpVerificationDialog(
                  context: context,
                  targetLabel: 'mobile number ($phoneNumber)',
                  title: 'Please enter your Code',
                  subtitle: 'Please check your mobile for the verification code.',
                );
                if (token == null) return false;

                await verificationRepository.verifyPhoneChange(
                  phoneNumber: phoneNumber,
                  token: token,
                );
                ref.invalidate(authSessionStateProvider);
                ref.invalidate(profileDataProvider);
                ref.invalidate(profileCompletionSummaryProvider);
                return true;
              },
              onSave: ({required username, required phoneNumber}) async {
                final accountRepository =
                    ref.read(profileAccountRepositoryProvider);
                if (accountRepository == null) {
                  throw StateError(
                    'Account settings persistence is unavailable.',
                  );
                }

                // Phone persistence is Auth-owned and occurs only after real
                // provider verification. Save Changes owns username only.
                await accountRepository.updateUsername(username);
                ref.invalidate(profileDataProvider);
                ref.invalidate(profileCompletionSummaryProvider);
              },
              onDeleteAccountConfirmed: () async {
                final deleteCurrentAccount =
                    ref.read(deleteCurrentAccountUseCaseProvider);
                if (deleteCurrentAccount == null) {
                  throw StateError(
                    'Account deletion is unavailable right now.',
                  );
                }
                await deleteCurrentAccount();
              },
              onAccountDeleted: () async {
                // The server-side delete is already confirmed at this point.
                // Local sign-out is best-effort: failure must not turn a real
                // deletion into a false-negative UI state.
                await ref
                    .read(hydrationPreferencesSessionBoundaryProvider)
                    .clearAfterConfirmedAccountDeletion(
                      ref.read(authSessionRepositoryProvider).signOut,
                    );
                ref.invalidate(hydrationPreferencesDataProvider);

                appSessionBootstrapController
                    .markUnauthenticatedAfterAccountDeletion();
                ref.read(backendUserStateProvider.notifier).state =
                    const BackendUserUnknown();
                ref.invalidate(authSessionStateProvider);
                ref.invalidate(profileDataProvider);
                ref.invalidate(profileCompletionSummaryProvider);

                if (context.mounted) {
                  context.go(AppRoutes.auth.path);
                }
              },
            );
          },
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
            onMeasurementUnitsPressed: () =>
                context.push(AppRoutes.measurementUnitsSettings.path),
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
