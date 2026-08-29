import 'package:tio_feature_settings/settings.dart';

/// Coordinates the local Glass Size preference at explicit account boundaries.
///
/// Startup/session restoration deliberately does not call this: a restored
/// session must retain its device-local convenience choice.
final class HydrationPreferencesSessionBoundary {
  const HydrationPreferencesSessionBoundary(this._repository);

  final HydrationPreferencesRepository _repository;

  Future<void> clearForNewExplicitLogin() => _repository.clear();

  Future<void> clearAfterSuccessfulSignOut(
    Future<void> Function() signOut,
  ) async {
    await signOut();
    await _clearBestEffort();
  }

  Future<void> clearAfterSuccessfulAccountEnd() => _repository.clear();

  Future<void> clearAfterConfirmedAccountDeletion(
    Future<void> Function() bestEffortSignOut,
  ) async {
    await _clearBestEffort();
    try {
      await bestEffortSignOut();
    } catch (_) {
      // Account deletion is already confirmed; local sign-out is best-effort.
    }
  }

  Future<void> _clearBestEffort() async {
    try {
      await clearAfterSuccessfulAccountEnd();
    } catch (_) {
      // Local storage must not reverse a completed account boundary.
    }
  }
}
