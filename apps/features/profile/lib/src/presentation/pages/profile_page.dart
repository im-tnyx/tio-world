import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/models.dart';

/// The primary user profile page matching the clean, cardless design.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.onSettingsPressed,
    required this.onAvatarPressed,
    this.onBackPressed,
    this.onEditPressed,
    this.onPickImage,
    this.onDeleteImage,
    this.profileData,
    this.isLoading = false,
    this.avatarFrame = TioAvatarFrame.none,
    this.planName,
    super.key,
  });

  final VoidCallback onSettingsPressed;
  final VoidCallback onAvatarPressed;
  final VoidCallback? onBackPressed;
  final VoidCallback? onEditPressed;
  final Future<void> Function(TioImageSource source)? onPickImage;
  final Future<void> Function()? onDeleteImage;
  final ProfileSetupData? profileData;
  final bool isLoading;
  final TioAvatarFrame avatarFrame;
  final String? planName;

  Future<void> _triggerAvatarActionSheet(
    BuildContext context, {
    required bool hasPhoto,
  }) async {
    final action = await showTioAvatarActionBottomSheet(
      context: context,
      hasPhoto: hasPhoto,
    );

    if (action == null || !context.mounted) return;

    switch (action) {
      case TioAvatarAction.gallery:
        await onPickImage?.call(TioImageSource.gallery);
        break;
      case TioAvatarAction.camera:
        await onPickImage?.call(TioImageSource.camera);
        break;
      case TioAvatarAction.delete:
        final confirmed =
            await showTioRemoveImageConfirmationBottomSheet(context);
        if (confirmed == true) {
          await onDeleteImage?.call();
        }
        break;
    }
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  double? _calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 0 || heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  int _calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required ProfileGender gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final bmr = switch (gender) {
      ProfileGender.male => base + 5,
      ProfileGender.female => base - 161,
      ProfileGender.other => base - 78,
    };
    return bmr.round();
  }

  String _genderLabel(ProfileGender gender) {
    return switch (gender) {
      ProfileGender.male => 'Male',
      ProfileGender.female => 'Female',
      ProfileGender.other => 'Other',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    final data = profileData;
    final name =
        data?.name.trim().isNotEmpty == true ? data!.name.trim() : '';
    final rawUsername = data?.username?.trim();
    final hasUsername = rawUsername != null && rawUsername.isNotEmpty;
    final username = hasUsername
        ? (rawUsername.startsWith('@') ? rawUsername : '@$rawUsername')
        : null;

    final age = data != null ? _calculateAge(data.dateOfBirth) : null;
    final genderStr = data != null ? _genderLabel(data.gender) : null;
    final heightCm =
        (data != null && data.heightCm > 0) ? data.heightCm : null;
    final weightKg = (data != null && data.currentWeightKg > 0)
        ? data.currentWeightKg
        : null;
    final bmi = (weightKg != null && heightCm != null)
        ? _calculateBmi(weightKg: weightKg, heightCm: heightCm)
        : null;
    final bmr =
        (data != null && weightKg != null && heightCm != null && age != null)
            ? _calculateBmr(
                weightKg: weightKg,
                heightCm: heightCm,
                age: age,
                gender: data.gender,
              )
            : null;

    final demoParts = <String>[];
    if (age != null) demoParts.add('$age year old');
    if (genderStr != null) demoParts.add(genderStr.toLowerCase());
    final demographics = demoParts.join(' • ');

    final rawPlan = data?.plan.trim().isNotEmpty == true
        ? data!.plan.trim()
        : planName?.trim();
    final normalizedPlan = (rawPlan ?? 'free').toLowerCase();
    final isPro = normalizedPlan == 'pro' || normalizedPlan == 'premium';
    final isPlus = normalizedPlan == 'plus';
    final displayPlan =
        rawPlan != null && rawPlan.isNotEmpty ? rawPlan.toUpperCase() : null;

    final avatarUrl = data?.avatarUrl?.trim();
    final hasValidPhoto = avatarUrl != null &&
        avatarUrl.isNotEmpty &&
        avatarUrl.startsWith('http');

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(
          key: const ValueKey('profile-back-button'),
          onPressed: onBackPressed,
          color: colors.textPrimary,
        ),
        title: username != null
            ? Text(
                username,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              )
            : const SizedBox.shrink(),
        actions: [
          IconButton(
            key: const ValueKey('profile-edit-action'),
            tooltip: 'Edit Profile',
            onPressed: () {
              if (onEditPressed != null) {
                onEditPressed!();
              } else {
                context.push(AppRoutes.profileSettings.path);
              }
            },
            icon: Icon(Icons.edit_outlined, color: colors.textPrimary),
          ),
          IconButton(
            key: const ValueKey('profile-settings-action'),
            tooltip: 'Settings',
            onPressed: onSettingsPressed,
            icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: TioAvatarSize.large.dimension,
                      height: TioAvatarSize.large.dimension,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Center(
                            child: InkWell(
                              key: const ValueKey('profile-avatar-entry'),
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (hasValidPhoto) {
                                  onAvatarPressed();
                                } else {
                                  _triggerAvatarActionSheet(
                                    context,
                                    hasPhoto: false,
                                  );
                                }
                              },
                              child: TioAvatar(
                                size: TioAvatarSize.large,
                                frame: avatarFrame,
                                displayName:
                                    name.isNotEmpty ? name : (username ?? ''),
                                imageUrl: avatarUrl,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _triggerAvatarActionSheet(
                                context,
                                hasPhoto: hasValidPhoto,
                              ),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: isPro
                                      ? const Color(0xFF0F172A)
                                      : isPlus
                                          ? const Color(0xFF1E1B4B)
                                          : const Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.background,
                                    width: 2.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: isPro
                                    ? SvgPicture.asset(
                                        'assets/svg_icon/ic_pro_outline.svg',
                                        package: 'tio_core',
                                        width: 16,
                                        height: 16,
                                        colorFilter: const ColorFilter.mode(
                                          Color(0xFF5EEAD4),
                                          BlendMode.srcIn,
                                        ),
                                      )
                                    : isPlus
                                        ? const Icon(
                                            Icons.star_rounded,
                                            size: 16,
                                            color: Color(0xFFF59E0B),
                                          )
                                        : const Icon(
                                            Icons.edit,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (name.isNotEmpty)
                    Center(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  if (demographics.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        demographics,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (displayPlan != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withAlpha(140),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              displayPlan,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Divider(
                    height: 24,
                    thickness: 1,
                    color: colors.outlineStrong.withAlpha(20),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricColumn(
                        key: const ValueKey('profile-weight-metric'),
                        icon: Icons.crop_square_rounded,
                        label: 'WEIGHT',
                        value: weightKg != null && data != null
                            ? MeasurementFormatters.formatWeight(
                                weightKg,
                                data.unitPreferences.weightUnit,
                              )
                            : '--',
                      ),
                      _MetricColumn(
                        key: const ValueKey('profile-height-metric'),
                        icon: Icons.straighten_rounded,
                        label: 'HEIGHT',
                        value: heightCm != null && data != null
                            ? MeasurementFormatters.formatHeight(
                                heightCm,
                                data.unitPreferences.heightUnit,
                              )
                            : '--',
                      ),
                      _MetricColumn(
                        key: const ValueKey('profile-bmi-metric'),
                        icon: Icons.speed_rounded,
                        label: 'BMI',
                        value: bmi != null ? '$bmi' : '--',
                      ),
                      _MetricColumn(
                        key: const ValueKey('profile-bmr-metric'),
                        icon: Icons.local_fire_department_rounded,
                        label: 'BMR',
                        value: bmr != null ? '$bmr' : '--',
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 22,
          color: colors.textPrimary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
