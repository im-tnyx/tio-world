import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/models.dart';

/// The primary user profile page showing avatar, demographics, plan, and biometric metrics.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    required this.onSettingsPressed,
    required this.onAvatarPressed,
    this.profileData,
    this.isLoading = false,
    this.avatarFrame = TioAvatarFrame.none,
    this.planName,
    super.key,
  });

  final VoidCallback onSettingsPressed;
  final VoidCallback onAvatarPressed;
  final ProfileSetupData? profileData;
  final bool isLoading;
  final TioAvatarFrame avatarFrame;
  final String? planName;

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
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

  String _activityLabel(ProfileActivityLevel activity) {
    return switch (activity) {
      ProfileActivityLevel.sedentary => 'Sedentary',
      ProfileActivityLevel.light => 'Light',
      ProfileActivityLevel.active => 'Active',
      ProfileActivityLevel.veryActive => 'Very active',
      ProfileActivityLevel.dynamic => 'Dynamic',
    };
  }

  String _goalLabel(ProfileGoal goal) {
    return switch (goal) {
      ProfileGoal.buildMuscle => 'Build muscle',
      ProfileGoal.loseWeight => 'Lose weight',
      ProfileGoal.keepFit => 'Keep fit',
      ProfileGoal.boostStrength => 'Boost strength',
      ProfileGoal.manageStress => 'Manage stress',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    final data = profileData;
    final name = data?.name.isNotEmpty == true ? data!.name : 'User';
    final username = data?.username?.isNotEmpty == true
        ? '@${data!.username}'
        : '@${name.toLowerCase().replaceAll(' ', '')}';

    final age = data != null ? _calculateAge(data.dateOfBirth) : 23;
    final genderStr = data != null ? _genderLabel(data.gender) : 'Male';
    final heightCm = data?.heightCm ?? 175.0;
    final weightKg = data?.currentWeightKg ?? 70.0;
    final targetWeightKg = data?.targetWeightKg;
    final bmr = data != null
        ? _calculateBmr(
            weightKg: weightKg,
            heightCm: heightCm,
            age: age,
            gender: data.gender,
          )
        : _calculateBmr(
            weightKg: 70,
            heightCm: 175,
            age: 23,
            gender: ProfileGender.male,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            key: const ValueKey('profile-settings-action'),
            tooltip: 'Settings',
            onPressed: onSettingsPressed,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  // Avatar with Frame
                  Center(
                    child: Tooltip(
                      message: 'Open profile photo',
                      child: Semantics(
                        key: const ValueKey('profile-avatar-entry'),
                        button: true,
                        label: 'Open profile photo',
                        child: ExcludeSemantics(
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onAvatarPressed,
                            child: TioAvatar(
                              size: TioAvatarSize.large,
                              frame: avatarFrame,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Name
                  Center(
                    child: Text(
                      name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Username
                  Center(
                    child: Text(
                      username,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Demographics & Plan Pills Row
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Age & Gender Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant.withAlpha(120),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colors.outlineStrong.withAlpha(40),
                          ),
                        ),
                        child: Text(
                          '$age years old • $genderStr',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),

                      // Plan Pill (from Supabase profileData or prop)
                      Builder(
                        builder: (context) {
                          final rawPlan = profileData?.plan ?? planName ?? 'free';
                          final planTrimmed = rawPlan.trim();
                          final displayPlan = planTrimmed.isNotEmpty
                              ? planTrimmed[0].toUpperCase() + planTrimmed.substring(1).toLowerCase()
                              : 'Free';

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colors.primary.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  size: 15,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  displayPlan,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Biometrics Overview Title
                  Text(
                    'Biometrics & Targets',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Metrics 2x2 Grid Cards
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          key: const ValueKey('profile-weight-metric'),
                          icon: Icons.monitor_weight_outlined,
                          label: 'Weight',
                          value: '${weightKg.toStringAsFixed(weightKg % 1 == 0 ? 0 : 1)} kg',
                          subtitle: targetWeightKg != null
                              ? 'Target: ${targetWeightKg.toStringAsFixed(targetWeightKg % 1 == 0 ? 0 : 1)} kg'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          key: const ValueKey('profile-height-metric'),
                          icon: Icons.height_rounded,
                          label: 'Height',
                          value: '${heightCm.toStringAsFixed(heightCm % 1 == 0 ? 0 : 1)} cm',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          key: const ValueKey('profile-bmr-metric'),
                          icon: Icons.local_fire_department_outlined,
                          label: 'BMR Baseline',
                          value: '$bmr kcal',
                          subtitle: 'Energy at rest',
                        ),
                      ),
                      if (targetWeightKg != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            key: const ValueKey('profile-target-metric'),
                            icon: Icons.flag_outlined,
                            label: 'Target Weight',
                            value: '${targetWeightKg.toStringAsFixed(targetWeightKg % 1 == 0 ? 0 : 1)} kg',
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (data != null && data.goals.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Goals & Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.outlineStrong.withAlpha(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.track_changes_rounded,
                            title: 'Primary Goals',
                            value: data.goals.map(_goalLabel).join(', '),
                          ),
                          Divider(
                            height: 24,
                            color: colors.outlineStrong.withAlpha(30),
                          ),
                          _DetailRow(
                            icon: Icons.directions_run_rounded,
                            title: 'Activity Level',
                            value: _activityLabel(data.activityLevel),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
