import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

/// Reads Profile-owned completion truth from canonical `user_profiles` and only
/// Account-owned reminder fields from `public.users`.
///
/// Legacy Profile mirrors in `users` are deliberately not selected or accepted
/// as fallback evidence for Name, Gender, or Date of Birth.
final profileCompletionSummaryProvider =
    FutureProvider<ProfileCompletionSummary?>((ref) async {
  ref.watch(authSessionStateProvider);
  final client = ref.watch(supabaseClientProvider);
  final user = client?.auth.currentUser;
  if (client == null || user == null || user.id.isEmpty) return null;

  final profile = await SupabaseUserProfileRepository(client: client).read();
  if (profile == null) return null;

  final accountRow = await client
      .from('users')
      .select('username,mobile')
      .eq('id', user.id)
      .maybeSingle();

  return ProfileCompletionSummary.fromFields(
    name: profile.name,
    username: accountRow?['username'] as String?,
    email: user.email,
    mobile: accountRow?['mobile'] as String?,
    hasGender: true,
    hasDateOfBirth: true,
  );
});

/// Stable for token refreshes, but changes after a real Supabase sign-in.
final profileCompletionReminderScopeProvider =
    Provider<ProfileCompletionReminderScope?>((ref) {
  ref.watch(authSessionStateProvider);
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  if (user == null || user.id.isEmpty) return null;

  final lastSignInAt = user.lastSignInAt?.trim();
  final loginCycleId = lastSignInAt != null && lastSignInAt.isNotEmpty
      ? lastSignInAt
      : user.createdAt;

  return ProfileCompletionReminderScope(
    userId: user.id,
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
