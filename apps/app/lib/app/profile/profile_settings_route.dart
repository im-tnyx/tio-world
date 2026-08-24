import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_progress/progress.dart';
import 'package:tio_feature_settings/settings.dart';

import '../network_providers.dart';
import 'canonical_profile_settings_repository.dart';
import 'profile_completion.dart';

final profileSettingsRepositoryProvider =
    Provider<ProfileSettingsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  return CanonicalProfileSettingsRepository(
    profileRepository: SupabaseUserProfileRepository(client: client),
    bodyRepository: SupabaseBodySetupRepository(client: client),
  );
});

final saveProfileSettingsUseCaseProvider =
    Provider<SaveProfileSettingsUseCase?>((ref) {
  final accountRepository = ref.watch(profileAccountRepositoryProvider);
  final settingsRepository = ref.watch(profileSettingsRepositoryProvider);
  if (accountRepository == null || settingsRepository == null) return null;
  return SaveProfileSettingsUseCase(
    accountRepository: accountRepository,
    profileSettingsRepository: settingsRepository,
  );
});

class ProfileSettingsRoute extends ConsumerWidget {
  const ProfileSettingsRoute({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileDataProvider);
    final profileData = profileAsync.valueOrNull;

    if (profileData == null) {
      if (profileAsync.hasError) {
        return const _ProfileSettingsUnavailablePage(
          message: 'Could not load your profile. Please go back and try again.',
        );
      }
      if (profileAsync.hasValue) {
        return const _ProfileSettingsUnavailablePage(
          message: 'Your profile is not available yet. Please try again.',
        );
      }
      return const _ProfileSettingsLoadingPage();
    }

    final avatarFrame = switch (profileData.plan.toLowerCase()) {
      'plus' => TioAvatarFrame.plusRing,
      'pro' || 'premium' => TioAvatarFrame.proHexagon,
      _ => TioAvatarFrame.none,
    };

    return ProfileSettingsPage(
      name: profileData.name,
      username: profileData.username ?? '',
      gender: profileData.gender.name,
      dateOfBirth: profileData.dateOfBirth,
      heightCm: profileData.heightCm,
      currentWeightKg: profileData.currentWeightKg,
      avatarUrl: profileData.avatarUrl,
      avatarFrame: avatarFrame,
      plan: profileData.plan,
      onAvatarPressed: () => context.push(AppRoutes.profileAvatar.path),
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
        final avatarRepository = ref.read(profileAvatarRepositoryProvider);
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
        final avatarRepository = ref.read(profileAvatarRepositoryProvider);
        if (avatarRepository == null) {
          throw StateError('Profile avatar persistence is unavailable.');
        }
        await avatarRepository.deleteAvatarImage();
        ref.invalidate(profileDataProvider);
      },
      onSave: ({
        required name,
        required username,
        required gender,
        required dateOfBirth,
        required heightCm,
        required currentWeightKg,
      }) async {
        final saveProfileSettings =
            ref.read(saveProfileSettingsUseCaseProvider);
        if (saveProfileSettings == null) {
          throw StateError('Profile settings persistence is unavailable.');
        }

        final parsedGender = ProfileGender.values.firstWhere(
          (value) => value.name.toLowerCase() == gender.toLowerCase(),
          orElse: () => profileData.gender,
        );

        await saveProfileSettings(
          persistedUsername: profileData.username,
          requestedUsername: username,
          update: ProfileSettingsUpdate(
            name: name,
            gender: parsedGender,
            dateOfBirth: dateOfBirth,
            heightCm: heightCm,
            currentWeightKg: currentWeightKg,
          ),
        );
        ref.invalidate(profileDataProvider);
        ref.invalidate(profileCompletionSummaryProvider);
      },
    );
  }
}

class _ProfileSettingsLoadingPage extends StatelessWidget {
  const _ProfileSettingsLoadingPage();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Profile Settings',
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
}

class _ProfileSettingsUnavailablePage extends StatelessWidget {
  const _ProfileSettingsUnavailablePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Profile Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.lg),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size16,
                fontWeight: TioFontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
