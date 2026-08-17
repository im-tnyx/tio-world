import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class MeasurementUnitsSettingsPage extends StatefulWidget {
  const MeasurementUnitsSettingsPage({
    required this.initialPreferences,
    required this.onSave,
    super.key,
  });

  final MeasurementUnitPreferences initialPreferences;
  final Future<void> Function(MeasurementUnitPreferences preferences) onSave;

  @override
  State<MeasurementUnitsSettingsPage> createState() =>
      _MeasurementUnitsSettingsPageState();
}

class _MeasurementUnitsSettingsPageState
    extends State<MeasurementUnitsSettingsPage> {
  late MeasurementUnitPreferences _preferences;
  var _isSaving = false;
  String? _errorMessage;

  bool get _hasChanges => _preferences != widget.initialPreferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.initialPreferences;
  }

  @override
  void didUpdateWidget(covariant MeasurementUnitsSettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasChanges && oldWidget.initialPreferences != widget.initialPreferences) {
      _preferences = widget.initialPreferences;
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_hasChanges) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await widget.onSave(_preferences);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save your unit preferences. Please try again.';
      });
    }
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
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Measurement Units',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.large,
                  TioSpacing.medium,
                  TioSpacing.large,
                  TioSpacing.extraLarge,
                ),
                children: [
                  Text(
                    'Choose how measurements are displayed across Tio. Your stored body and target values remain unchanged when you switch units.',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.extraLarge),
                  TioMeasurementUnitPreferencesEditor(
                    preferences: _preferences,
                    onChanged: (preferences) {
                      if (_isSaving) return;
                      setState(() {
                        _preferences = preferences;
                        _errorMessage = null;
                      });
                    },
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: TioSpacing.large),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorMessage!,
                        key: const ValueKey('measurement-units-save-error'),
                        style: TextStyle(
                          color: colors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                TioSpacing.large,
                TioSpacing.medium,
                TioSpacing.large,
                TioSpacing.large,
              ),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  top: BorderSide(color: colors.outlineStrong.withAlpha(24)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: TioButton.primary(
                  key: const ValueKey('measurement-units-save'),
                  label: 'Save',
                  onPressed: _hasChanges && !_isSaving ? _save : null,
                  isLoading: _isSaving,
                  expand: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
