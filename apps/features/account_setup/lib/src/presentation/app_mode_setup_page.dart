import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

/// Pre-auth App Mode selection owned by Account Setup.
///
/// The visual contract intentionally matches the former Product Onboarding
/// App Mode step: fixed 48dp Back chrome, no progress indicator, the same
/// content geometry, and the same bottom gradient action treatment.
class AppModeSetupPage extends StatefulWidget {
  const AppModeSetupPage({
    required this.onBack,
    required this.onModeConfirmed,
    super.key,
    this.initialMode,
  });

  final AppMode? initialMode;
  final VoidCallback onBack;
  final Future<void> Function(AppMode mode) onModeConfirmed;

  @override
  State<AppModeSetupPage> createState() => _AppModeSetupPageState();
}

class _AppModeSetupPageState extends State<AppModeSetupPage> {
  AppMode? _selectedMode;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  Future<void> _continue() async {
    final mode = _selectedMode;
    if (mode == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onModeConfirmed(mode);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorText = 'Could not save your mode. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleBack() {
    if (_isSaving) return;
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _AppModeSetupTopBar(
                busy: _isSaving,
                onBack: _handleBack,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SingleChildScrollView(
                        key: const ValueKey('app-mode-setup-content'),
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          TioSpacing.lg,
                          TioSpacing.lg,
                          TioSpacing.lg,
                          TioSize.dp100,
                        ),
                        child: AppModeSelectionContent(
                          selectedMode: _selectedMode,
                          enabled: !_isSaving,
                          onModeSelected: (mode) {
                            setState(() {
                              _selectedMode = mode;
                              _errorText = null;
                            });
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _AppModeSetupBottomBar(
                        errorText: _errorText,
                        loading: _isSaving,
                        enabled: _selectedMode != null && !_isSaving,
                        onContinue: _continue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppModeSetupTopBar extends StatelessWidget {
  const _AppModeSetupTopBar({
    required this.busy,
    required this.onBack,
  });

  final bool busy;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.tioColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.sm,
          0,
          TioSpacing.lg,
          0,
        ),
        child: SizedBox(
          height: TioSize.dp48,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('app-mode-setup-back'),
                tooltip: 'Back',
                onPressed: busy ? null : onBack,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: TioSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppModeSetupBottomBar extends StatelessWidget {
  const _AppModeSetupBottomBar({
    required this.enabled,
    required this.loading,
    required this.onContinue,
    this.errorText,
  });

  static const _gradientStops = <double>[0.0, 0.25, 0.70, 1.0];

  final bool enabled;
  final bool loading;
  final Future<void> Function() onContinue;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: _gradientStops,
          colors: [
            colors.background.withValues(alpha: TioOpacity.opacity0),
            colors.background.withValues(alpha: TioOpacity.opacity50),
            colors.background.withValues(alpha: TioOpacity.opacity95),
            colors.background.withValues(alpha: TioOpacity.opacity100),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          left: TioSpacing.lg,
          right: TioSpacing.lg,
          top: TioSpacing.xl,
          bottom: TioSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (errorText case final error?) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  key: const ValueKey('app-mode-setup-error'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.danger,
                      ),
                ),
              ),
              const SizedBox(height: TioSpacing.md),
            ],
            TioButton.primary(
              label: 'Continue',
              loading: loading,
              loadingLabel: 'Saving',
              expand: true,
              enabled: enabled,
              onPressed: () => unawaited(onContinue()),
              trailing: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable App Mode content owned by Account Setup.
///
/// Product Onboarding may keep a compatibility wrapper temporarily, but new
/// first-run presentation should use [AppModeSetupPage].
class AppModeSelectionContent extends StatelessWidget {
  const AppModeSelectionContent({
    required this.selectedMode,
    required this.onModeSelected,
    super.key,
    this.enabled = true,
  });

  final AppMode? selectedMode;
  final ValueChanged<AppMode> onModeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TioScreenHeader(
          title: 'How will you use Tio?',
          subtitle: 'Choose the experience you want to start with. This '
              'shapes your setup steps and guided navigation, and you can '
              'change it later in Settings.',
        ),
        const SizedBox(height: TioSpacing.xl),
        for (final mode in AppMode.values) ...[
          _ModeChoiceCard(
            mode: mode,
            selected: selectedMode == mode,
            onTap: enabled ? () => onModeSelected(mode) : null,
          ),
          const SizedBox(height: TioSpacing.md),
        ],
        const SizedBox(height: TioSpacing.sm),
        Stack(
          children: [
            for (final mode in AppMode.values)
              ExcludeSemantics(
                excluding: selectedMode != mode,
                child: AnimatedOpacity(
                  key: selectedMode == mode
                      ? const ValueKey('app-mode-next-setup')
                      : null,
                  opacity: selectedMode == mode ? 1 : 0,
                  duration: const Duration(milliseconds: TioDuration.ms200),
                  child: Text(
                    _nextSetupText(mode),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: TioFontSize.size13,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AppMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Semantics(
      button: true,
      selected: selected,
      label: '${_label(mode)} mode. ${_description(mode)}',
      child: Material(
        color: selected
            ? colors.primary.withValues(
                alpha: TioCardTokens.selectedContainerAlpha,
              )
            : colors.surface,
        borderRadius: BorderRadius.circular(TioCardTokens.radius),
        child: InkWell(
          key: ValueKey('app-mode-${mode.storageValue}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(TioCardTokens.radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: TioDuration.ms200),
            padding: const EdgeInsets.all(TioSpacing.lg),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TioCardTokens.radius),
              border: Border.all(
                color: selected
                    ? colors.primary
                    : colors.outlineStrong.withValues(
                        alpha: TioOpacity.opacity35,
                      ),
                width: TioStroke.width1,
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
                        _label(mode),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioFontSize.size16,
                        ),
                      ),
                      const SizedBox(height: TioSize.dp3),
                      Text(
                        _description(mode),
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
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.outlineStrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _nextSetupText(AppMode mode) {
  return switch (mode) {
    AppMode.workout =>
      'After signup, Tio will focus setup on your workout routine and preferences.',
    AppMode.nutrition =>
      'After signup, Tio will focus setup on nutrition targets and meal preferences.',
    AppMode.hybrid =>
      'After signup, Tio will set up your workout preferences, then nutrition targets.',
  };
}

String _label(AppMode mode) {
  return switch (mode) {
    AppMode.workout => 'Workout',
    AppMode.nutrition => 'Nutrition',
    AppMode.hybrid => 'Hybrid',
  };
}

String _description(AppMode mode) {
  return switch (mode) {
    AppMode.workout =>
      'Focus entirely on workouts, routines, and training history.',
    AppMode.nutrition =>
      'Focus on daily calories, macros, and nutrition logging.',
    AppMode.hybrid =>
      'Complete experience with combined workout and nutrition tracking.',
  };
}

IconData _icon(AppMode mode) {
  return switch (mode) {
    AppMode.workout => Icons.fitness_center_rounded,
    AppMode.nutrition => Icons.restaurant_menu_rounded,
    AppMode.hybrid => Icons.bolt_rounded,
  };
}
