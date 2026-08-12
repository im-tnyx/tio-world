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
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppMode>(
                direction: Axis.vertical,
                segments: const [
                  ButtonSegment(
                      value: AppMode.workout,
                      label: Text('Workout'),
                      icon: Icon(Icons.fitness_center)),
                  ButtonSegment(
                      value: AppMode.nutrition,
                      label: Text('Nutrition'),
                      icon: Icon(Icons.restaurant)),
                  ButtonSegment(
                      value: AppMode.hybrid,
                      label: Text('Hybrid'),
                      icon: Icon(Icons.all_inclusive)),
                ],
                selected: {_selectedMode},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) =>
                        setState(() => _selectedMode = selection.single),
                showSelectedIcon: true,
              ),
            ),
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
