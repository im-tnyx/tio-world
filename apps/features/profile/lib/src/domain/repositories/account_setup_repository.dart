class AccountSetupAccountState {
  const AccountSetupAccountState({
    this.username,
    this.mobile = '',
    this.isMobileVerified = false,
    this.isCompleted = false,
  });

  final String? username;
  final String mobile;
  final bool isMobileVerified;
  final bool isCompleted;

  bool get hasUsername => username?.trim().isNotEmpty == true;
}

/// Narrow persistence capability owned by the Account Setup boundary.
///
/// Username availability/claiming remains owned by [ProfileAccountRepository].
/// This contract only reads account-setup state and completes the optional
/// mobile step without reconstructing the full profile.
abstract interface class AccountSetupRepository {
  Future<AccountSetupAccountState> readAccountSetupState();

  /// Marks Account Setup complete.
  ///
  /// When [mobile] is null, the current stored mobile is preserved. Passing an
  /// empty string explicitly clears the profile mobile. A changed typed mobile
  /// must never retain provider/backend verification evidence.
  Future<void> completeAccountSetup({String? mobile});
}
