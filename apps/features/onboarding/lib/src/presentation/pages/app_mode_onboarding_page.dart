import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

class AppModeOnboardingPage extends StatefulWidget {
  const AppModeOnboardingPage({
    required this.onModeConfirmed,
    super.key,
    this.initialMode,
  });

  final AppMode? initialMode;
  final Future<void> Function(AppMode mode) onModeConfirmed;

  @override
  State<AppModeOnboardingPage> createState() => _AppModeOnboardingPageState();
}

class _AppModeOnboardingPageState extends State<AppModeOnboardingPage> {
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
          () => _errorText = 'Could not save your mode. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your mode')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('How will you use Tio?',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'This controls your guided setup and main navigation. You can change it later in Settings.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 24),
            for (final mode in AppMode.values) ...[
              _ModeChoiceCard(
                mode: mode,
                selected: _selectedMode == mode,
                onTap: _isSaving
                    ? null
                    : () => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedMode case final selectedMode?) ...[
              const SizedBox(height: 8),
              Text(
                _nextSetupText(selectedMode),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: colors.textSecondary),
              ),
            ],
            if (_errorText case final errorText?) ...[
              const SizedBox(height: 16),
              Text(errorText,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            TioButton.primary(
              label: _isSaving ? 'Saving…' : 'Continue',
              expand: true,
              enabled: _selectedMode != null && !_isSaving,
              onPressed: _continue,
              trailing: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }

  String _nextSetupText(AppMode mode) {
    return switch (mode) {
      AppMode.workout =>
        'Next, Tio will focus setup on training preferences and workout goals.',
      AppMode.nutrition =>
        'Next, Tio will focus setup on nutrition targets and meal preferences.',
      AppMode.hybrid =>
        'Next, Tio will include both workout and nutrition setup.',
    };
  }
}

class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard(
      {required this.mode, required this.selected, required this.onTap});

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.radiusLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(context.radiusLarge),
            border: Border.all(
                color: selected ? colors.primary : colors.surfaceVariant,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(_icon(mode),
                  color: selected ? colors.primary : colors.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(mode),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      _description(mode),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(AppMode mode) {
    return switch (mode) {
      AppMode.workout => 'Workout',
      AppMode.nutrition => 'Nutrition',
      AppMode.hybrid => 'Hybrid',
    };
  }

  static String _description(AppMode mode) {
    return switch (mode) {
      AppMode.workout => 'Training, routines, workout history, and progress.',
      AppMode.nutrition => 'Meals, water, nutrition targets, and progress.',
      AppMode.hybrid =>
        'Workout and nutrition together in one guided experience.',
    };
  }

  static IconData _icon(AppMode mode) {
    return switch (mode) {
      AppMode.workout => Icons.fitness_center,
      AppMode.nutrition => Icons.restaurant,
      AppMode.hybrid => Icons.all_inclusive,
    };
  }
}
