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
    backgroundColor: Colors.transparent,
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.textMuted.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
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
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how Tio looks on this device',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 10),
              _ThemeOptionTile(
                key: const ValueKey('theme-option-oled'),
                mode: TioThemeMode.oled,
                title: 'OLED (Pure Black)',
                subtitle: 'Pitch black background for AMOLED & battery efficiency',
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
        : colors.outlineStrong.withAlpha(40);

    final backgroundColor = isSelected
        ? colors.primary.withAlpha(12)
        : colors.surfaceRaised;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withAlpha(24)
                      : colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colors.primary : colors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outlineStrong.withAlpha(100),
                    width: 2,
                  ),
                  color: isSelected ? colors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 14,
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
