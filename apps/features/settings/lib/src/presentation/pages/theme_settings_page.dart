import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({
    required this.currentMode,
    required this.onThemeChanged,
    super.key,
  });

  final TioThemeMode currentMode;
  final Future<void> Function(TioThemeMode mode) onThemeChanged;

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late TioThemeMode _selectedMode;
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
      await widget.onThemeChanged(_selectedMode);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Could not update theme. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TioSpacing.xl),
          children: [
            Text(
              'Choose your app appearance',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: TioSpacing.sm),
            Text(
              'Theme updates the app look instantly and is saved on this device.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: TioSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TioThemeMode>(
                direction: Axis.vertical,
                showSelectedIcon: true,
                segments: const [
                  ButtonSegment(
                    value: TioThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.settings_suggest_outlined),
                  ),
                  ButtonSegment(
                    value: TioThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: TioThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                  ButtonSegment(
                    value: TioThemeMode.oled,
                    label: Text('OLED'),
                    icon: Icon(Icons.brightness_3_outlined),
                  ),
                ],
                selected: {_selectedMode},
                onSelectionChanged: _isSaving
                    ? null
                    : (selection) =>
                        setState(() => _selectedMode = selection.single),
              ),
            ),
            if (_errorText case final errorText?) ...[
              const SizedBox(height: TioSpacing.lg),
              Text(
                errorText,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: TioSpacing.xl),
            TioButton.primary(
              label: 'Save Theme',
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
