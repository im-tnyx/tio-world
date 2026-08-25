import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_profile/profile.dart';

import '../network_providers.dart';

class ProfileCompletionReminderScope {
  const ProfileCompletionReminderScope({
    required this.userId,
    required this.loginCycleId,
  });

  final String userId;
  final String loginCycleId;

  String get storageValue => '$userId|$loginCycleId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProfileCompletionReminderScope &&
            userId == other.userId &&
            loginCycleId == other.loginCycleId;
  }

  @override
  int get hashCode => Object.hash(userId, loginCycleId);
}

class ProfileCompletionReminderPreference {
  const ProfileCompletionReminderPreference();

  static const _dismissedScopeKey =
      'profile_completion_reminder_dismissed_scope_v1';

  Future<bool> isDismissed(ProfileCompletionReminderScope scope) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_dismissedScopeKey) == scope.storageValue;
  }

  Future<void> dismiss(ProfileCompletionReminderScope scope) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_dismissedScopeKey, scope.storageValue);
  }
}

final profileCompletionReminderPreferenceProvider =
    Provider<ProfileCompletionReminderPreference>((ref) {
  return const ProfileCompletionReminderPreference();
});

final profileCompletionSummaryProvider =
    FutureProvider<ProfileCompletionSummary?>((ref) async {
  final profile = ref.watch(profileDataProvider).valueOrNull;
  final authState = ref.watch(authSessionStateProvider).valueOrNull;
  final session = authState is AuthSessionAuthenticated ? authState.session : null;
  if (profile == null || session == null) return null;

  return ProfileCompletionSummary.fromFields(
    name: profile.name,
    username: profile.username,
    email: session.email,
    mobile: profile.mobile,
    hasGender: true,
    hasDateOfBirth: true,
  );
});

final profileCompletionReminderScopeProvider =
    Provider<ProfileCompletionReminderScope?>((ref) {
  final authState = ref.watch(authSessionStateProvider).valueOrNull;
  if (authState is! AuthSessionAuthenticated) return null;

  final session = authState.session;
  final userId = session.userId.trim();
  final loginCycleId = session.loginCycleId?.trim();
  if (userId.isEmpty || loginCycleId == null || loginCycleId.isEmpty) {
    return null;
  }

  return ProfileCompletionReminderScope(
    userId: userId,
    loginCycleId: loginCycleId,
  );
});

final profileCompletionReminderDismissedProvider =
    FutureProvider.family<bool, ProfileCompletionReminderScope>(
  (ref, scope) {
    final preference = ref.watch(profileCompletionReminderPreferenceProvider);
    return preference.isDismissed(scope);
  },
);
