import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/hydration_preferences.dart';
import '../hydration_preferences_editor_controller.dart';
import 'daily_wellness_editor_sheet.dart';

String formatGlassSize(int millilitres, VolumeUnit unit) {
  if (unit == VolumeUnit.ml) return '$millilitres ml';
  return '~${UnitFormatters.formatVolume(millilitres.toDouble(), unit)}';
}

/// The page keeps these listenables current even while its modal is open.
class GlassSizeBottomSheet extends StatefulWidget {
  const GlassSizeBottomSheet({
    required this.canonical,
    required this.volumeUnit,
    required this.onSave,
    super.key,
  });

  final ValueListenable<HydrationPreferences> canonical;
  final ValueListenable<VolumeUnit> volumeUnit;
  final Future<void> Function(HydrationPreferences) onSave;

  @override
  State<GlassSizeBottomSheet> createState() => _GlassSizeBottomSheetState();
}

class _GlassSizeBottomSheetState extends State<GlassSizeBottomSheet> {
  late final HydrationPreferencesEditorController _editor;

  @override
  void initState() {
    super.initState();
    _editor = HydrationPreferencesEditorController(widget.canonical.value);
    widget.canonical.addListener(_refresh);
  }

  void _refresh() => _editor.refresh(widget.canonical.value);

  @override
  void dispose() {
    widget.canonical.removeListener(_refresh);
    _editor.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _editor.save(widget.onSave);
    if (mounted && saved != null) Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([_editor, widget.volumeUnit]),
        builder: (context, _) {
          final colors = context.tioColors;
          final unit = widget.volumeUnit.value;
          return PopScope(
            canPop: !_editor.isSaving,
            child: DailyWellnessEditorSheet(
              title: 'Default Glass Size',
              supportingText: 'Amount logged when you add one glass of water.',
              canDismiss: !_editor.isSaving,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: TioSpacing.sm,
                    runSpacing: TioSpacing.sm,
                    children: [
                      for (final ml in HydrationPreferences.presetsMl)
                        ChoiceChip(
                          key: ValueKey('glass-size-preset-$ml'),
                          label: Text(formatGlassSize(ml, unit)),
                          selected: !_editor.isCustom && _editor.draftMl == ml,
                          selectedColor:
                              colors.primary.withAlpha(TioAlpha.alpha24),
                          onSelected: _editor.isSaving
                              ? null
                              : (_) => _editor.selectPreset(ml),
                        ),
                      ChoiceChip(
                        key: const ValueKey('glass-size-custom'),
                        label: const Text('Custom'),
                        selected: _editor.isCustom,
                        selectedColor:
                            colors.primary.withAlpha(TioAlpha.alpha24),
                        onSelected: _editor.isSaving
                            ? null
                            : (_) => _editor.selectCustom(),
                      ),
                    ],
                  ),
                  if (_editor.isCustom) ...[
                    const SizedBox(height: TioSpacing.lg),
                    TioInput(
                      key: const ValueKey('glass-size-custom-input'),
                      value: _editor.customText,
                      label: 'Custom amount (ml)',
                      helperText: '50–2000 ml · increments of 10 ml',
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      errorText: _editor.validationError,
                      enabled: !_editor.isSaving,
                      onChanged: _editor.setCustomText,
                    ),
                    if (unit == VolumeUnit.flOz)
                      Padding(
                        padding: const EdgeInsets.only(top: TioSpacing.sm),
                        child: Text(
                            'Enter ml to keep the exact amount. '
                            '${_editor.validationError == null ? formatGlassSize(_editor.draftMl, unit) : ''}',
                            style: TextStyle(color: colors.textSecondary)),
                      ),
                  ],
                  const SizedBox(height: TioSpacing.md),
                  Text(
                    _editor.validationError == null
                        ? formatGlassSize(_editor.draftMl, unit)
                        : 'Check custom amount',
                    key: const ValueKey('glass-size-draft-summary'),
                    style: TextStyle(color: colors.textPrimary),
                  ),
                  if (_editor.saveError != null) ...[
                    const SizedBox(height: TioSpacing.md),
                    Semantics(
                      liveRegion: true,
                      child: Text(_editor.saveError!,
                          key: const ValueKey('glass-size-save-error'),
                          style: TextStyle(color: colors.danger)),
                    ),
                  ],
                ],
              ),
              actions: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: TioSpacing.xs,
                    children: [
                      TextButton(
                        key: const ValueKey('glass-size-reset-default'),
                        onPressed:
                            _editor.isSaving ? null : _editor.resetToDefault,
                        child: Text('Reset to Default',
                            style: TextStyle(color: colors.danger)),
                      ),
                      TextButton(
                        key: const ValueKey('glass-size-cancel'),
                        onPressed: _editor.isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                  const SizedBox(height: TioSpacing.sm),
                  TioButton.primary(
                    key: const ValueKey('glass-size-save'),
                    label: 'Save',
                    expand: true,
                    loading: _editor.isSaving,
                    onPressed: _editor.canSave ? _save : null,
                  ),
                ],
              ),
            ),
          );
        },
      );
}
