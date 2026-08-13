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
          () => _errorText = 'Could not update App Mode. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      appBar: AppBar(title: const Text('App Mode')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Choose your guided experience',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Changing mode updates your main tabs. It does not delete workout, nutrition, or progress history.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            for (final mode in AppMode.values) ...[
              _ModeOptionCard(
                mode: mode,
                selected: _selectedMode == mode,
                enabled: !_isSaving,
                onTap: () => setState(() => _selectedMode = mode),
              ),
              if (mode != AppMode.values.last)
                const SizedBox(height: TioSpacing.medium),
            ],
            const SizedBox(height: 24),
            _TabsPreview(mode: _selectedMode),
            if (_errorText case final errorText?) ...[
              const SizedBox(height: 16),
              Text(errorText,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            TioButton.primary(
              label: 'Save App Mode',
              loading: _isSaving,
              loadingLabel: 'Saving',
              expand: true,
              enabled: !_isSaving && _selectedMode != widget.currentMode,
              onPressed: _save,
            ),
          ],
        ),
      ),
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
    final colors = context.tioColors;

    return Opacity(
      opacity: enabled ? 1 : 0.64,
      child: Semantics(
        button: true,
        selected: selected,
        label: '${_appModeLabel(mode)}. ${_appModeDescription(mode)}',
        child: TioCard(
          key: ValueKey('app-mode-settings-${mode.storageValue}'),
          variant: selected ? TioCardVariant.elevated : TioCardVariant.outlined,
          onTap: enabled ? onTap : null,
          child: Row(
            children: [
              Icon(
                _appModeIcon(mode),
                color: selected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: TioSpacing.large),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _appModeLabel(mode),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: TioSpacing.small),
                    Text(
                      _appModeDescription(mode),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TioSpacing.medium),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: selected ? colors.primary : colors.outlineStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabsPreview extends StatelessWidget {
  const _TabsPreview({required this.mode});

  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final labels = mode.guidedDestinations.map((destination) {
      return switch (destination) {
        AppDestination.home => 'Home',
        AppDestination.workout => 'Workout',
        AppDestination.nutrition => 'Nutrition',
        AppDestination.progress => 'Progress',
      };
    }).join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(context.radiusMedium),
        border: Border.all(color: colors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Main tabs', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(labels,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary)),
        ],
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

IconData _appModeIcon(AppMode mode) {
  return switch (mode) {
    AppMode.workout => Icons.fitness_center,
    AppMode.nutrition => Icons.restaurant,
    AppMode.hybrid => Icons.all_inclusive,
  };
}
