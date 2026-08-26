import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';

import '../network_providers.dart';

final accountSetupRepositoryProvider = Provider<AccountSetupRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;

  final authState = ref.watch(authSessionStateProvider).valueOrNull;
  final authSession = authState is AuthSessionAuthenticated
      ? authState.session
      : null;
  final authUser = client.auth.currentUser;

  return _AppAccountSetupRepository(
    persistence: SupabaseAccountSetupRepository(client: client),
    emailVerification:
        SupabaseAccountContactVerificationRepository(client: client),
    hasTrustedEmailIdentity: authSession?.isEmailVerified ??
        (authUser?.emailConfirmedAt != null),
    hasTrustedPhoneIdentity: authSession?.isPhoneVerified ??
        (authUser?.phoneConfirmedAt != null),
    currentEmail: authSession?.email?.trim() ?? authUser?.email?.trim() ?? '',
  );
});

final class _AppAccountSetupRepository
    implements AccountSetupRepository, AccountSetupAuthContactBridge {
  const _AppAccountSetupRepository({
    required AccountSetupRepository persistence,
    required AccountContactVerificationRepository emailVerification,
    required this.hasTrustedEmailIdentity,
    required this.hasTrustedPhoneIdentity,
    required this.currentEmail,
  })  : _persistence = persistence,
        _emailVerification = emailVerification;

  final AccountSetupRepository _persistence;
  final AccountContactVerificationRepository _emailVerification;

  @override
  final bool hasTrustedEmailIdentity;

  @override
  final bool hasTrustedPhoneIdentity;

  @override
  final String currentEmail;

  @override
  Future<AccountSetupAccountState> readAccountSetupState() {
    return _persistence.readAccountSetupState();
  }

  @override
  Future<void> completeAccountSetup({String? mobile}) {
    return _persistence.completeAccountSetup(mobile: mobile);
  }

  @override
  Future<void> requestOptionalEmailVerification(String email) {
    return _emailVerification.requestEmailVerification(email);
  }
}
