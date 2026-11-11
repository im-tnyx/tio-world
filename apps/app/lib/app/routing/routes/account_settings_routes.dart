import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_settings/settings.dart';

import '../../network_providers.dart';
import '../../profile/profile_completion.dart';
import '../../settings_persistence_providers.dart';

String _accountSettingsUsernameMessage(UsernameAvailabilityReason? reason) {
  return switch (reason) {
    UsernameAvailabilityReason.reserved =>
      'That username is reserved. Try one of these instead:',
    UsernameAvailabilityReason.invalid =>
      'Choose a valid username using lowercase letters, numbers, dots, and underscores.',
    UsernameAvailabilityReason.taken =>
      'This username is already taken. Try one of these instead:',
    UsernameAvailabilityReason.profileMissing ||
    UsernameAvailabilityReason.unknown =>
      'Could not verify this username. Please try again.',
    null => 'This username is unavailable. Please try another.',
  };
}

String _accountSettingsUsernameConflictMessage(
  UsernameUnavailableException error,
) {
  return switch (error.reason) {
    UsernameAvailabilityReason.reserved =>
      'That username is reserved. Please choose another.',
    UsernameAvailabilityReason.invalid =>
      'That username is no longer valid. Please choose another.',
    _ => 'That username was just taken. Please choose another.',
  };
}

String _linkedAuthProvidersLabel(AuthSession? session) {
  final providers = session?.identityProviders ?? const <String>{};
  if (providers.isEmpty) return 'Current session';

  const orderedKnownProviders = <String>['phone', 'email', 'google'];
  final ordered = <String>[
    ...orderedKnownProviders.where(providers.contains),
    ...(providers
        .where((provider) => !orderedKnownProviders.contains(provider))
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

/// App-owned Account Settings route composition; GoRouter stays root-owned.
///
/// Preserve username write-only, OTP request/verify and account deletion
/// ordering. The callback marks bootstrap unauthenticated at the same point.
List<RouteBase> buildAccountSettingsRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required VoidCallback markUnauthenticatedAfterAccountDeletion,
}) {
  return [
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
            onCheckUsernameAvailability: (handle) async {
              final accountRepository =
                  ref.read(profileAccountRepositoryProvider);
              if (accountRepository == null) {
                return const UsernameAvailabilityResult(
                  isAvailable: false,
                  message:
                      'Could not verify this username. Please try again.',
                );
              }

              try {
                final check =
                    await accountRepository.checkUsernameAvailability(handle);
                return UsernameAvailabilityResult(
                  isAvailable: check.isAvailable,
                  suggestions: check.suggestions,
                  message: check.isAvailable
                      ? null
                      : _accountSettingsUsernameMessage(check.reason),
                );
              } catch (_) {
                return const UsernameAvailabilityResult(
                  isAvailable: false,
                  message:
                      'Could not verify this username. Please try again.',
                );
              }
            },
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
                subtitle:
                    'Please check your email for the verification code.',
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
                subtitle:
                    'Please check your mobile for the verification code.',
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
              try {
                await accountRepository.updateUsername(username);
              } on UsernameUnavailableException catch (error) {
                throw TioUsernameConflictException(
                  _accountSettingsUsernameConflictMessage(error),
                );
              }
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

              markUnauthenticatedAfterAccountDeletion();
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
  ];
}
