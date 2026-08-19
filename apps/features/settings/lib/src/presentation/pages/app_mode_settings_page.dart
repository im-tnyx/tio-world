import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class AppModeSettingsPage extends StatefulWidget {
  const AppModeSettingsPage({
    required this.currentMode,
    required this.onModeChanged,
    super.key,
  });

  final AppMode currentMode;
  final Future<void> Function(AppMode mode) onModeChanged;

  @override
  State<AppModeSettingsPage> createState() => _AppModeSettingsPageState();
}

class _AppModeSettingsPageState extends State<AppModeSettingsPage> {
  late AppMode _selectedMode;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  Future<void> _save() async {
    if (_isSaving || _selectedMode == widget.currentMode) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onModeChanged(_selectedMode);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorText = 'Could not update App Mode. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          'App Mode',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.md,
            TioSpacing.lg,
            TioSpacing.xl,
          ),
          children: [
            Text(
              'Choose your guided experience',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w800,
                fontSize: TioFontSize.size22,
              ),
            ),
            const SizedBox(height: TioSize.dp6),
            Text(
              'Changing mode updates your main tabs. It does not delete your workout, nutrition, or progress history.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size14,
                fontWeight: TioFontWeight.w400,
              ),
            ),

            const SizedBox(height: TioSpacing.lg),

            // ── Top Navigation Preview Card ──
            _AppModeNavPreviewCard(mode: _selectedMode),

            const SizedBox(height: TioSpacing.lg),

            // ── Mode Choice Cards ──
            for (final mode in AppMode.values) ...[
              _ModeOptionCard(
                mode: mode,
                selected: _selectedMode == mode,
                enabled: !_isSaving,
                onTap: () => setState(() => _selectedMode = mode),
              ),
              if (mode != AppMode.values.last)
                const SizedBox(height: TioSpacing.md),
            ],

            if (_errorText case final errorText?) ...[
              const SizedBox(height: TioSpacing.lg),
              Text(
                errorText,
                style: TextStyle(color: colors.danger),
              ),
            ],

            const SizedBox(height: TioSpacing.lg),
          ],
        ),
      ),
      // ── Fixed Bottom Action Bar with Gradient Blur ──
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: TioSize.dp8,
            sigmaY: TioSize.dp8,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  colors.background.withValues(alpha: TioOpacity.opacity0),
                  colors.background.withValues(alpha: TioOpacity.opacity75),
                  colors.background.withValues(alpha: TioOpacity.opacity98),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.all(TioSpacing.lg),
              child: TioButton.primary(
                label: 'Save App Mode',
                loading: _isSaving,
                loadingLabel: 'Saving',
                expand: true,
                enabled: !_isSaving && _selectedMode != widget.currentMode,
                onPressed: _save,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic Bottom Navigation Preview Card showing actual destination icons
class _AppModeNavPreviewCard extends StatelessWidget {
  const _AppModeNavPreviewCard({required this.mode});

  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Container(
      padding: const EdgeInsets.all(TioSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(TioRadius.lg),
        border: Border.all(
          color: colors.outlineStrong.withAlpha(TioAlpha.alpha30),
          width: TioStroke.width1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.navigation_outlined,
                size: TioSize.dp15,
                color: colors.primary,
              ),
              const SizedBox(width: TioSize.dp6),
              Text(
                'BOTTOM NAVIGATION PREVIEW',
                style: TextStyle(
                  color: colors.textMuted,
                  fontWeight: TioFontWeight.w800,
                  fontSize: TioFontSize.size11,
                  letterSpacing: TioLetterSpacing.positive08,
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSize.dp14),
          // Mock Bottom Navigation Bar Preview Box
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: TioSize.dp10,
              horizontal: TioSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(TioRadius.md),
              border: Border.all(
                color: colors.outlineStrong.withAlpha(TioAlpha.alpha25),
                width: TioStroke.width1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: TioMotion.normalMs),
              child: Row(
                key: ValueKey(mode),
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final destination in mode.guidedDestinations)
                    _NavPreviewItem(
                      destination: destination,
                      isSelected: destination == mode.guidedDestinations.first,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: TioSize.dp14),

          // ── Watch Experience Preview ──
          Row(
            children: [
              Icon(
                Icons.watch_outlined,
                size: TioSize.dp15,
                color: colors.textSecondary,
              ),
              const SizedBox(width: TioSize.dp6),
              Text(
                'WATCH TILES & HOME CARDS',
                style: TextStyle(
                  color: colors.textMuted,
                  fontWeight: TioFontWeight.w800,
                  fontSize: TioFontSize.size11,
                  letterSpacing: TioLetterSpacing.positive08,
                ),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.sm),
          Wrap(
            spacing: TioSize.dp6,
            runSpacing: TioSize.dp6,
            children: [
              for (final card in mode.watchCards)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSize.dp10,
                    vertical: TioSize.dp5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(TioRadius.sm),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(TioAlpha.alpha20),
                      width: TioStroke.width1,
                    ),
                  ),
                  child: Text(
                    card.label,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size11,
                      fontWeight: TioFontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Navigation Icon & Label Item inside Preview
class _NavPreviewItem extends StatelessWidget {
  const _NavPreviewItem({
    required this.destination,
    required this.isSelected,
  });

  final AppDestination destination;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    final label = switch (destination) {
      AppDestination.home => 'Home',
      AppDestination.workout => 'Workout',
      AppDestination.nutrition => 'Nutrition',
      AppDestination.progress => 'Progress',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TioSize.dp14,
            vertical: TioSize.dp4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withAlpha(TioAlpha.alpha24)
                : TioPalette.transparent,
            borderRadius: BorderRadius.circular(TioRadius.md),
          ),
          child: TioDestinationNavIcon(
            destination: destination,
            isSelected: isSelected,
            size: TioSize.dp22,
          ),
        ),
        const SizedBox(height: TioSize.dp3),
        Text(
          label,
          style: TextStyle(
            fontSize: TioFontSize.size11,
            fontWeight:
                isSelected ? TioFontWeight.w700 : TioFontWeight.w500,
            color: isSelected ? colors.primary : colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.mode,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppMode mode;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Opacity(
      opacity: enabled ? TioOpacity.opacity100 : TioOpacity.opacity64,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${_appModeLabel(mode)}. ${_appModeDescription(mode)}',
        child: Material(
          color: selected ? colors.surfaceRaised : colors.surface,
          borderRadius: BorderRadius.circular(TioRadius.lg),
          child: InkWell(
            key: ValueKey('app-mode-settings-${mode.storageValue}'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(TioRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(TioSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TioRadius.lg),
                border: Border.all(
                  color: selected
                      ? colors.primary
                      : colors.outlineStrong.withAlpha(TioAlpha.alpha35),
                  width:
                      selected ? TioStroke.width2 : TioStroke.width1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: TioSize.dp44,
                    height: TioSize.dp44,
                    decoration: BoxDecoration(
                      color: (selected ? colors.primary : colors.textSecondary)
                          .withAlpha(
                        selected ? TioAlpha.alpha20 : TioAlpha.alpha12,
                      ),
                      borderRadius: BorderRadius.circular(TioRadius.md),
                    ),
                    child: Icon(
                      _icon(mode),
                      size: TioSize.dp22,
                      color: selected ? colors.primary : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appModeLabel(mode),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size16,
                          ),
                        ),
                        const SizedBox(height: TioSize.dp3),
                        Text(
                          _appModeDescription(mode),
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: TioFontSize.size12,
                            fontWeight: TioFontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TioSpacing.md),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? colors.primary : colors.outlineStrong,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _appModeLabel(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _appModeDescription(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Training, routines, workout history, and progress.',
    AppMode.nutrition => 'Meals, water, nutrition targets, and progress.',
    AppMode.hybrid =>
      'Workout and nutrition together in one guided experience.',
  };
}

IconData _icon(AppMode mode) {
  return switch (mode) {
    AppMode.workout => Icons.fitness_center_rounded,
    AppMode.nutrition => Icons.restaurant_rounded,
    AppMode.hybrid => Icons.all_inclusive_rounded,
  };
}
