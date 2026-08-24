/// Permanent account-deletion boundary for the currently authenticated user.
abstract interface class AccountDeletionRepository {
  Future<void> deleteCurrentAccount();
}
