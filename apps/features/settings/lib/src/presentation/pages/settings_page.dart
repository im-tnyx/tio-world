import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// The central user settings page structured into categorized section cards.
///
/// Sections:
/// - **Account & Profile**: Profile Settings, Manage Subscription, Reset Password, Account Settings.
/// - **Workout & Wearables**: Workout Settings + Wear OS / Watch Settings.
/// - **Nutrition**: Nutrition & Diet (calories, macros, food preferences).
/// - **Preferences**: App Preferences (theme, sound & haptics, alerts, units).
/// - **About**: About Tio (version, terms, privacy policy).
/// - **Session**: Log Out (Danger action).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onAppSettingsPressed,
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
          borderRadius: BorderRadius.circular(TioRadius.large),
        ),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(
            color: colors.textSecondary,
          ),
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
              foregroundColor: Colors.white,
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
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(
          color: colors.textPrimary,
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.large,
            vertical: TioSpacing.medium,
          ),
          children: [
            // ── Account & Profile Section Card ──
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

            const SizedBox(height: TioSpacing.large),

            // ── Workout & Wearables Section ──
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

            const SizedBox(height: TioSpacing.large),

            // ── Nutrition Section ──
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

            const SizedBox(height: TioSpacing.large),

            // ── Preferences Section ──
            const _SettingsSectionHeader(title: 'PREFERENCES'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-app-settings-entry'),
                  icon: Icons.tune_rounded,
                  title: 'App Preferences',
                  subtitle: 'Theme, sound & haptics, alerts, units & calendar',
                  onTap: onAppSettingsPressed,
                ),
              ],
            ),

            const SizedBox(height: TioSpacing.large),

            // ── About Section ──
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

            const SizedBox(height: TioSpacing.large),

            // ── Session Section ──
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

            const SizedBox(height: TioSpacing.extraLarge),
          ],
        ),
      ),
    );
  }
}

/// Category Header for Settings Groups
class _SettingsSectionHeader extends StatelessWidget {
  const _SettingsSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: TioSpacing.small,
        bottom: TioSpacing.small,
      ),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Unified Inset Group Card Container for each Settings Category
class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

/// Subtle Divider between Settings Tiles inside a Group Card
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Divider(
      height: 1,
      thickness: 1,
      indent: 64,
      color: colors.outlineStrong.withAlpha(20),
    );
  }
}

/// Reusable Setting Row Item within a Group Card
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
          horizontal: TioSpacing.large,
          vertical: TioSpacing.medium + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? colors.primary).withAlpha(18),
                borderRadius: BorderRadius.circular(TioRadius.small),
              ),
              child: Icon(
                icon,
                size: 22,
                color: iconColor ?? colors.primary,
              ),
            ),
            const SizedBox(width: TioSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor ?? colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
