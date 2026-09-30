import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';

import '../../network_providers.dart';
import '../../profile/profile_avatar_upload.dart';
import '../../profile/profile_completion.dart';
import '../../profile/profile_settings_route.dart';

List<RouteBase> buildProfileRoutes({
  required GlobalKey<NavigatorState> rootNavigatorKey,
}) {
  return [
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
            onCompletionPressed:
                visibleCompletion == null || reminderScope == null
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

                        final route =
                            visibleCompletion.hasProfileOwnedMissingField
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
            onPickImage: (source) => pickAndUploadProfileImage(
              ref: ref,
              context: context,
              source: source,
            ),
            onDeleteImage: () async {
              final avatarRepository =
                  ref.read(profileAvatarRepositoryProvider);
              if (avatarRepository == null) {
                throw StateError(
                    'Profile avatar persistence is unavailable.');
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
            onPickImage: (source) => pickAndUploadProfileImage(
              ref: ref,
              context: context,
              source: source,
            ),
            onDeletePressed: () async {
              final avatarRepository =
                  ref.read(profileAvatarRepositoryProvider);
              if (avatarRepository == null) {
                throw StateError(
                    'Profile avatar persistence is unavailable.');
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
      path: AppRoutes.profileSettings.path,
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const ProfileSettingsRoute(),
    ),
  ];
}
