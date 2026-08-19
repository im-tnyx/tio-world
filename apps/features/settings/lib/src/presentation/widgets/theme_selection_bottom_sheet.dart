import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shows the [ThemeSelectionBottomSheet] modal.
Future<TioThemeMode?> showThemeSelectionBottomSheet({
  required BuildContext context,
  required TioThemeMode currentMode,
  required Future<void> Function(TioThemeMode mode) onThemeSelected,
}) {
  return showModalBottomSheet<TioThemeMode>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    backgroundColor: TioPalette.transparent,
    builder: (context) => ThemeSelectionBottomSheet(
      currentMode: currentMode,
      onThemeSelected: onThemeSelected,
    ),
  );
}

/// A modern Material 3 bottom sheet for interactive theme selection.
class ThemeSelectionBottomSheet extends StatefulWidget {
  const ThemeSelectionBottomSheet({
    required this.currentMode,
    required this.onThemeSelected,
    super.key,
  });

  final TioThemeMode currentMode;
  final Future<void> Function(TioThemeMode mode) onThemeSelected;

  @override
  State<ThemeSelectionBottomSheet> createState() =>
      _ThemeSelectionBottomSheetState();
}

class _ThemeSelectionBottomSheetState extends State<ThemeSelectionBottomSheet> {
  late TioThemeMode _selectedMode;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  Future<void> _handleModeSelect(TioThemeMode mode) async {
    if (_isUpdating || _selectedMode == mode) return;

    setState(() {
      _selectedMode = mode;
      _isUpdating = true;
    });

    try {
      await widget.onThemeSelected(mode);
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
        Navigator.of(context).pop(mode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioSize.dp28),
        ),
        boxShadow: [
          BoxShadow(
            color: TioPalette.black.withAlpha(TioAlpha.alpha40),
            blurRadius: TioSize.dp20,
            offset: const Offset(TioSize.dp0, -TioSize.dp4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSize.dp20,
            TioSpacing.md,
            TioSize.dp20,
            TioSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: TioSize.dp36,
                  height: TioSize.dp4,
                  margin: const EdgeInsets.only(bottom: TioSize.dp20),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withAlpha(TioAlpha.alpha80),
                    borderRadius: BorderRadius.circular(TioSize.dp2),
                  ),
                ),
              ),

              // Title and Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: TioFontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.xs),
                      Text(
                        'Choose how Tio looks on this device',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.textSecondary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: TioSize.dp20),

              // Options
              _ThemeOptionTile(
                key: const ValueKey('theme-option-system'),
                mode: TioThemeMode.system,
                title: 'System default',
                subtitle: 'Matches your device display settings',
                icon: Icons.settings_suggest_rounded,
                isSelected: _selectedMode == TioThemeMode.system,
                isUpdating: _isUpdating,
                onTap: () => _handleModeSelect(TioThemeMode.system),
              ),
              const SizedBox(height: TioSize.dp10),
              _ThemeOptionTile(
                key: const ValueKey('theme-option-light'),
                mode: TioThemeMode.light,
                title: 'Light',
                subtitle: 'Clean and bright appearance',
                icon: Icons.light_mode_rounded,
                isSelected: _selectedMode == TioThemeMode.light,
                isUpdating: _isUpdating,
                onTap: () => _handleModeSelect(TioThemeMode.light),
              ),
              const SizedBox(height: TioSize.dp10),
              _ThemeOptionTile(
                key: const ValueKey('theme-option-dark'),
                mode: TioThemeMode.dark,
                title: 'Dark',
                subtitle: 'Subtle dark theme with high contrast',
                icon: Icons.dark_mode_rounded,
                isSelected: _selectedMode == TioThemeMode.dark,
                isUpdating: _isUpdating,
                onTap: () => _handleModeSelect(TioThemeMode.dark),
              ),
              const SizedBox(height: TioSize.dp10),
              _ThemeOptionTile(
                key: const ValueKey('theme-option-oled'),
                mode: TioThemeMode.oled,
                title: 'OLED (Pure Black)',
                subtitle:
                    'Pitch black background for AMOLED & battery efficiency',
                icon: Icons.brightness_2_rounded,
                isSelected: _selectedMode == TioThemeMode.oled,
                isUpdating: _isUpdating,
                onTap: () => _handleModeSelect(TioThemeMode.oled),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.mode,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.isUpdating,
    required this.onTap,
    super.key,
  });

  final TioThemeMode mode;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool isUpdating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final theme = Theme.of(context);

    final borderColor = isSelected
        ? colors.primary
        : colors.outlineStrong.withAlpha(TioAlpha.alpha40);

    final backgroundColor = isSelected
        ? colors.primary.withAlpha(TioAlpha.alpha12)
        : colors.surfaceRaised;

    return Material(
      color: TioPalette.transparent,
      child: InkWell(
        onTap: isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(TioRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSpacing.lg,
            vertical: TioSize.dp14,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(TioRadius.lg),
            border: Border.all(
              color: borderColor,
              width: isSelected ? TioStroke.width15 : TioStroke.width1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: TioSize.dp42,
                height: TioSize.dp42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withAlpha(TioAlpha.alpha24)
                      : colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: TioSize.dp22,
                ),
              ),
              const SizedBox(width: TioSize.dp14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected
                            ? TioFontWeight.w600
                            : TioFontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: TioSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TioSize.dp10),
              AnimatedContainer(
                duration: const Duration(milliseconds: TioMotion.selectionMs),
                width: TioSize.dp22,
                height: TioSize.dp22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colors.primary
                        : colors.outlineStrong.withAlpha(TioAlpha.alpha100),
                    width: TioStroke.width2,
                  ),
                  color:
                      isSelected ? colors.primary : TioPalette.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: TioSize.dp14,
                        color: colors.onPrimary,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
