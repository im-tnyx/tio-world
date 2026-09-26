import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_welcome/welcome.dart';

import '../../app_mode/app_mode.dart';
import '../../network_providers.dart';

List<RouteBase> buildAuthRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required PendingAppModePreference pendingAppModePreference,
  required Future<void> Function() onExplicitLoginSuccess,
}) {
  return [
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
    unawaited(onExplicitLoginSuccess());
    },
    onAuthSuccess: (result) {
    ref.read(backendUserStateProvider.notifier).state =
    result.backendUserState;
    unawaited(onExplicitLoginSuccess());
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
    unawaited(onExplicitLoginSuccess());
    },
    onAuthSuccess: (result) {
    ref.read(backendUserStateProvider.notifier).state =
    result.backendUserState;
    unawaited(onExplicitLoginSuccess());
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
    unawaited(onExplicitLoginSuccess());
    },
    onAuthSuccess: (result) {
    ref.read(backendUserStateProvider.notifier).state =
    result.backendUserState;
    unawaited(onExplicitLoginSuccess());
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
  ];
}
