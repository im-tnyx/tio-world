import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onAppSettingsPressed,
    this.onMeasurementUnitsPressed,
    this.onProfileSettingsPressed,
    this.onAccountSettingsPressed,
    this.onManageSubscriptionPressed,
    this.onResetPasswordPressed,
    this.onWorkoutPressed,
    this.onWearOsPressed,
    this.onNutritionPressed,
    this.onAboutPressed,
    this.onLogoutPressed,
    super.key,
  });

  final VoidCallback onAppSettingsPressed;
  final VoidCallback? onMeasurementUnitsPressed;
  final VoidCallback? onProfileSettingsPressed;
  final VoidCallback? onAccountSettingsPressed;
  final VoidCallback? onManageSubscriptionPressed;
  final VoidCallback? onResetPasswordPressed;
  final VoidCallback? onWorkoutPressed;
  final VoidCallback? onWearOsPressed;
  final VoidCallback? onNutritionPressed;
  final VoidCallback? onAboutPressed;
  final VoidCallback? onLogoutPressed;

  void _showLogoutDialog(BuildContext context) {
    final colors = TioTheme.colors(context);

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TioRadius.lg),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger,
              foregroundColor: TioPalette.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              onLogoutPressed?.call();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSpacing.md,
          ),
          children: [
            const _SettingsSectionHeader(title: 'ACCOUNT & PROFILE'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-profile-settings-entry'),
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Settings',
                  subtitle: 'Name, username, demographics & body metrics',
                  onTap: onProfileSettingsPressed,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  key: const ValueKey('settings-subscription-entry'),
                  icon: Icons.stars_rounded,
                  title: 'Manage Subscription',
                  subtitle: 'Plan tier, Plus/Pro features & billing',
                  onTap: onManageSubscriptionPressed,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  key: const ValueKey('settings-security-entry'),
                  icon: Icons.lock_outline_rounded,
                  title: 'Reset Password',
                  subtitle: 'Change password & security credentials',
                  onTap: onResetPasswordPressed,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  key: const ValueKey('settings-account-settings-entry'),
                  icon: Icons.shield_outlined,
                  title: 'Account Settings',
                  subtitle: 'Email, mobile, linked account & delete account',
                  onTap: onAccountSettingsPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'WORKOUT & WEARABLES'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-workout-hub'),
                  icon: Icons.fitness_center_rounded,
                  title: 'Workout Settings',
                  subtitle: 'Rest timers, warmup, plate calc & wake lock',
                  onTap: onWorkoutPressed,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  key: const ValueKey('settings-wear-os-entry'),
                  icon: Icons.watch_rounded,
                  title: 'Wear OS / Watch Settings',
                  subtitle: 'Watch companion sync, heart rate & complications',
                  onTap: onWearOsPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'NUTRITION'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-nutrition-hub'),
                  icon: Icons.restaurant_menu_rounded,
                  title: 'Nutrition & Diet',
                  subtitle: 'Daily calories, macros & food preferences',
                  onTap: onNutritionPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'PREFERENCES'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-app-settings-entry'),
                  icon: Icons.tune_rounded,
                  title: 'App Preferences',
                  subtitle: 'Theme, sound & haptics, alerts & calendar',
                  onTap: onAppSettingsPressed,
                ),
                const _SettingsDivider(),
                _SettingsTile(
                  key: const ValueKey('settings-measurement-units-entry'),
                  icon: Icons.straighten_rounded,
                  title: 'Measurement Units',
                  subtitle: 'Weight, height, distance & water units',
                  onTap: onMeasurementUnitsPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'ABOUT'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-about-hub'),
                  icon: Icons.info_outline_rounded,
                  title: 'About Tio',
                  subtitle: 'App version, terms of service & privacy policy',
                  onTap: onAboutPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'SESSION'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-logout-entry'),
                  icon: Icons.logout_rounded,
                  iconColor: colors.danger,
                  titleColor: colors.danger,
                  title: 'Log Out',
                  subtitle: 'Sign out of your Tio account on this device',
                  showChevron: false,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.sm,
        bottom: TioSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
        ),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Divider(
      height: TioSize.dp1,
      thickness: TioStroke.width1,
      indent: TioSize.dp64,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.titleColor,
    this.showChevron = true,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? iconColor;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            Container(
              width: TioSize.dp40,
              height: TioSize.dp40,
              decoration: BoxDecoration(
                color: (iconColor ?? colors.primary)
                    .withAlpha(TioAlpha.alpha18),
                borderRadius: BorderRadius.circular(TioRadius.sm),
              ),
              child: Icon(
                icon,
                size: TioSize.dp22,
                color: iconColor ?? colors.primary,
              ),
            ),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.textPrimary,
                      fontWeight: TioFontWeight.w700,
                      fontSize: TioFontSize.size15,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.xxs),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size12,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: TioSize.dp20,
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
