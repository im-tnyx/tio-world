import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onAppSettingsPressed,
    this.onProfileSettingsPressed,
    this.onAccountSettingsPressed,
    this.onHealthGoalsPressed,
    this.onNutritionPressed,
    this.showNutritionSection = false,
    this.onLogoutPressed,
    super.key,
  });

  final VoidCallback onAppSettingsPressed;
  final VoidCallback? onProfileSettingsPressed;
  final VoidCallback? onAccountSettingsPressed;
  final VoidCallback? onHealthGoalsPressed;
  final VoidCallback? onNutritionPressed;

  /// App Mode capability gate supplied by app composition.
  ///
  /// Nutrition is a Nutrition/Hybrid capability, so the whole section is
  /// absent in Workout mode rather than rendered empty or disabled. This is
  /// presentation-only: hiding it never touches canonical Nutrition data.
  final bool showNutritionSection;

  final VoidCallback? onLogoutPressed;

  void _showLogoutDialog(BuildContext context) {
    final colors = context.tioColors;

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
    final colors = context.tioColors;

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
                  key: const ValueKey('settings-account-settings-entry'),
                  icon: Icons.shield_outlined,
                  title: 'Account Settings',
                  subtitle: 'Email, mobile, linked account & delete account',
                  onTap: onAccountSettingsPressed,
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'HEALTH & GOALS'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-health-goals-entry'),
                  icon: Icons.track_changes_rounded,
                  title: 'Health & Goals',
                  subtitle: 'Daily Wellness targets',
                  onTap: onHealthGoalsPressed,
                ),
              ],
            ),
            if (showNutritionSection) ...[
              const SizedBox(height: TioSpacing.lg),
              const _SettingsSectionHeader(title: 'NUTRITION'),
              _SettingsGroupCard(
                children: [
                  _SettingsTile(
                    key: const ValueKey('settings-nutrition-entry'),
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Nutrition & Diet',
                    subtitle: 'Diet Type, allergies & restrictions',
                    onTap: onNutritionPressed,
                  ),
                ],
              ),
            ],
            const SizedBox(height: TioSpacing.lg),
            const _SettingsSectionHeader(title: 'PREFERENCES'),
            _SettingsGroupCard(
              children: [
                _SettingsTile(
                  key: const ValueKey('settings-app-settings-entry'),
                  icon: Icons.tune_rounded,
                  title: 'App Preferences',
                  subtitle: 'App Mode, theme & units',
                  onTap: onAppSettingsPressed,
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
    final colors = context.tioColors;
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
    final colors = context.tioColors;
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
    final colors = context.tioColors;
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
    final colors = context.tioColors;
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
                color:
                    (iconColor ?? colors.primary).withAlpha(TioAlpha.alpha18),
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
