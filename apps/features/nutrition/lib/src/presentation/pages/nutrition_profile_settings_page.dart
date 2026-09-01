import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/models.dart';
import '../widgets/nutrition_settings_widgets.dart';

/// Nutrition-owned post-onboarding Nutrition Profile editor.
///
/// V1 edits only the two canonical fields Product Onboarding actually
/// populates: `preferredDiet` and `allergies`. `dislikedFoods` and
/// `medicalConditions` are canonical columns with no approved product flow
/// yet, so they are never shown -- but they are always carried through a save
/// untouched, because the repository's `upsert` replaces the whole row.
class NutritionProfileSettingsPage extends StatelessWidget {
  const NutritionProfileSettingsPage({
    required this.profile,
    required this.onSave,
    super.key,
  });

  /// Current canonical profile. A missing canonical row is represented as an
  /// all-null [NutritionProfileData] rather than a separate empty state, so
  /// first-time editing works without a setup workflow.
  final NutritionProfileData profile;

  /// Persists a fully merged profile through the canonical owner.
  final Future<void> Function(NutritionProfileData profile) onSave;

  /// Rebuilds the whole canonical object, changing one field and preserving
  /// every other field exactly -- including the two this screen never shows.
  NutritionProfileData _mergedWithDiet(
    String? preferredDiet,
    String? otherDietType,
  ) {
    return NutritionProfileData(
      preferredDiet: preferredDiet,
      allergies: profile.allergies,
      dislikedFoods: profile.dislikedFoods,
      medicalConditions: profile.medicalConditions,
      otherDietType: otherDietType,
      otherAllergyRestriction: profile.otherAllergyRestriction,
    );
  }

  NutritionProfileData _mergedWithAllergies(
    Set<String> allergies,
    String? otherAllergyRestriction,
  ) {
    return NutritionProfileData(
      preferredDiet: profile.preferredDiet,
      allergies: allergies,
      dislikedFoods: profile.dislikedFoods,
      medicalConditions: profile.medicalConditions,
      otherDietType: profile.otherDietType,
      otherAllergyRestriction: otherAllergyRestriction,
    );
  }

  Future<void> _editDietType(BuildContext context) async {
    await showTioEditorSheet<void>(
      context: context,
      builder: (context) => _DietTypeEditorSheet(
        initialStorageValue: profile.preferredDiet,
        initialOtherText: profile.otherDietType,
        onSave: (value, otherText) => onSave(_mergedWithDiet(value, otherText)),
      ),
    );
  }

  Future<void> _editAllergies(BuildContext context) async {
    await showTioEditorSheet<void>(
      context: context,
      builder: (context) => _AllergiesEditorSheet(
        initialAllergies: profile.allergies,
        initialOtherText: profile.otherAllergyRestriction,
        onSave: (value, otherText) =>
            onSave(_mergedWithAllergies(value, otherText)),
      ),
    );
  }

  /// A bare `other` says a diet exists without saying which, so the user's own
  /// words replace the generic label whenever they gave any.
  String _dietSummary() {
    if (profile.preferredDiet == NutritionProfileVocabulary.otherValue) {
      final text = profile.otherDietType?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return NutritionProfileVocabulary.dietTypeLabel(profile.preferredDiet) ??
        'Not set';
  }

  String _allergiesSummary() {
    final allergies = profile.allergies;
    if (allergies == null) return 'Not set';
    if (allergies.isEmpty) return 'None';

    final otherText = profile.otherAllergyRestriction?.trim();
    final labels = NutritionProfileVocabulary.allergyLabels(
      allergies,
      otherLabelOverride:
          (otherText != null && otherText.isNotEmpty) ? otherText : null,
    );
    if (labels.isEmpty) return 'Not set';
    return labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Nutrition Profile',
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
            const NutritionSettingsSectionHeader(title: 'DIET'),
            TioGroupCard(
              children: [
                TioSettingsValueRow(
                  key: const ValueKey('nutrition-profile-diet-type-field'),
                  leading: Icon(
                    Icons.local_dining_rounded,
                    size: TioSize.dp24,
                    color: colors.textPrimary,
                  ),
                  label: 'Diet Type',
                  value: TioSettingsValueText(
                    value: _dietSummary(),
                    isUnset: profile.preferredDiet == null,
                  ),
                  onTap: () => _editDietType(context),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const NutritionSettingsSectionHeader(title: 'RESTRICTIONS'),
            TioGroupCard(
              children: [
                TioSettingsValueRow(
                  key: const ValueKey('nutrition-profile-allergies-field'),
                  leading: Icon(
                    Icons.no_food_rounded,
                    size: TioSize.dp24,
                    color: colors.textPrimary,
                  ),
                  label: 'Allergies & Restrictions',
                  labelSingleLine: true,
                  value: TioSettingsValueText(
                    value: _allergiesSummary(),
                    isUnset: profile.allergies == null,
                  ),
                  onTap: () => _editAllergies(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DietTypeEditorSheet extends StatefulWidget {
  const _DietTypeEditorSheet({
    required this.initialStorageValue,
    required this.initialOtherText,
    required this.onSave,
  });

  final String? initialStorageValue;
  final String? initialOtherText;
  final Future<void> Function(String storageValue, String? otherText) onSave;

  @override
  State<_DietTypeEditorSheet> createState() => _DietTypeEditorSheetState();
}

class _DietTypeEditorSheetState extends State<_DietTypeEditorSheet> {
  String? _selected;
  late String _otherText;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStorageValue;
    _otherText = widget.initialOtherText ?? '';
  }

  bool get _isOther => _selected == NutritionProfileVocabulary.otherValue;

  /// Blank is a valid answer: "Other" alone still records that the diet is
  /// outside the listed options.
  String? get _result => _isOther ? _trimmedOrNull(_otherText) : null;

  bool get _changed {
    if (_selected != widget.initialStorageValue) return true;
    return _isOther && _result != _trimmedOrNull(widget.initialOtherText ?? '');
  }

  bool get _canSave => _selected != null && _changed;

  void _select(String storageValue) {
    setState(() {
      _selected = storageValue;
      // Switching away from Other must not leave stale text behind.
      if (storageValue != NutritionProfileVocabulary.otherValue) {
        _otherText = '';
      }
      _errorText = null;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_canSave) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(_selected!, _result);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = "Couldn't save. Check your connection and try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TioEditorSheet(
      title: 'Diet Type',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final choice in NutritionProfileVocabulary.dietTypes) ...[
            if (choice != NutritionProfileVocabulary.dietTypes.first)
              const SizedBox(height: TioSpacing.sm),
            _NutritionChoiceTile(
              key: ValueKey('nutrition-diet-option-${choice.storageValue}'),
              label: choice.label,
              selected: _selected == choice.storageValue,
              onTap: _isSaving ? null : () => _select(choice.storageValue),
              fieldKey:
                  choice.storageValue == NutritionProfileVocabulary.otherValue
                      ? const ValueKey('nutrition-diet-option-other-text-field')
                      : null,
              fieldValue: _otherText,
              fieldHint: 'e.g. Jain, Pescatarian, Keto...',
              onFieldChanged: _isSaving
                  ? null
                  : (value) => setState(() {
                        _otherText = value;
                        _errorText = null;
                      }),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              _errorText!,
              style:
                  TextStyle(color: colors.danger, fontSize: TioFontSize.size13),
            ),
          ],
        ],
      ),
      actions: TioButton.primary(
        key: const ValueKey('nutrition-diet-type-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: (_isSaving || !_canSave) ? null : _handleSave,
        expand: true,
      ),
    );
  }
}

class _AllergiesEditorSheet extends StatefulWidget {
  const _AllergiesEditorSheet({
    required this.initialAllergies,
    required this.initialOtherText,
    required this.onSave,
  });

  /// `null` unanswered, empty set explicitly None, otherwise selections.
  final Set<String>? initialAllergies;
  final String? initialOtherText;
  final Future<void> Function(Set<String> allergies, String? otherText) onSave;

  @override
  State<_AllergiesEditorSheet> createState() => _AllergiesEditorSheetState();
}

class _AllergiesEditorSheetState extends State<_AllergiesEditorSheet> {
  late Set<String> _selected;
  late bool _noneSelected;
  late String _otherText;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAllergies;
    _noneSelected = initial != null && initial.isEmpty;
    _selected = {...?initial};
    _otherText = widget.initialOtherText ?? '';
  }

  bool get _isOtherSelected =>
      _selected.contains(NutritionProfileVocabulary.otherValue);

  String? get _otherResult =>
      _isOtherSelected ? _trimmedOrNull(_otherText) : null;

  /// Mirrors the canonical rule: an answered selection is either explicit
  /// None (empty set) or a non-empty restriction set. Never both, never empty.
  bool get _isAnswered =>
      _noneSelected ? _selected.isEmpty : _selected.isNotEmpty;

  Set<String> get _result => _noneSelected ? <String>{} : _selected;

  bool get _changed {
    final initial = widget.initialAllergies;
    if (initial == null) return true;
    final result = _result;
    if (initial.length != result.length || !initial.containsAll(result)) {
      return true;
    }
    return _otherResult != _trimmedOrNull(widget.initialOtherText ?? '');
  }

  bool get _canSave => _isAnswered && _changed;

  void _toggleNone() {
    setState(() {
      _noneSelected = !_noneSelected;
      // None is exclusive: choosing it clears every restriction, and with
      // them the elaboration that only described one.
      if (_noneSelected) {
        _selected = <String>{};
        _otherText = '';
      }
      _errorText = null;
    });
  }

  void _toggleRestriction(String storageValue) {
    setState(() {
      // Choosing any restriction clears None, preserving exclusivity.
      _noneSelected = false;
      if (_selected.contains(storageValue)) {
        _selected.remove(storageValue);
        // Deselecting Other must not leave its text behind.
        if (storageValue == NutritionProfileVocabulary.otherValue) {
          _otherText = '';
        }
      } else {
        _selected.add(storageValue);
      }
      _errorText = null;
    });
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_canSave) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(_result, _otherResult);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorText = "Couldn't save. Check your connection and try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return TioEditorSheet(
      title: 'Allergies & Restrictions',
      supportingText: 'Select all that apply, or choose None.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NutritionChoiceTile(
            key: const ValueKey('nutrition-allergy-option-none'),
            label: 'None',
            selected: _noneSelected,
            onTap: _isSaving ? null : _toggleNone,
          ),
          for (final choice in NutritionProfileVocabulary.allergies) ...[
            const SizedBox(height: TioSpacing.sm),
            _NutritionChoiceTile(
              key: ValueKey('nutrition-allergy-option-${choice.storageValue}'),
              label: choice.label,
              selected: _selected.contains(choice.storageValue),
              onTap: _isSaving
                  ? null
                  : () => _toggleRestriction(choice.storageValue),
              fieldKey: choice.storageValue ==
                      NutritionProfileVocabulary.otherValue
                  ? const ValueKey('nutrition-allergy-option-other-text-field')
                  : null,
              fieldValue: _otherText,
              fieldHint: 'e.g. Soy, Sesame, specific foods...',
              onFieldChanged: _isSaving
                  ? null
                  : (value) => setState(() {
                        _otherText = value;
                        _errorText = null;
                      }),
            ),
          ],
          if (_errorText != null) ...[
            const SizedBox(height: TioSpacing.sm),
            Text(
              _errorText!,
              style:
                  TextStyle(color: colors.danger, fontSize: TioFontSize.size13),
            ),
          ],
        ],
      ),
      actions: TioButton.primary(
        key: const ValueKey('nutrition-allergies-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: (_isSaving || !_canSave) ? null : _handleSave,
        expand: true,
      ),
    );
  }
}

String? _trimmedOrNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Full-width selectable row used by both Nutrition Profile editors.
///
/// Passing [fieldKey] turns the row into an "Other" row: an inline text field
/// appears while the row is selected, mirroring Product Onboarding. Without
/// the field, "Other" would record that an answer exists without recording
/// what it is.
class _NutritionChoiceTile extends StatefulWidget {
  const _NutritionChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
    this.fieldKey,
    this.fieldValue = '',
    this.fieldHint = '',
    this.onFieldChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Key? fieldKey;
  final String fieldValue;
  final String fieldHint;
  final ValueChanged<String>? onFieldChanged;

  @override
  State<_NutritionChoiceTile> createState() => _NutritionChoiceTileState();
}

class _NutritionChoiceTileState extends State<_NutritionChoiceTile> {
  TextEditingController? _controller;
  FocusNode? _focusNode;

  bool get _hasField => widget.fieldKey != null;

  @override
  void initState() {
    super.initState();
    if (_hasField) {
      _controller = TextEditingController(text: widget.fieldValue);
      _focusNode = FocusNode();
    }
  }

  @override
  void didUpdateWidget(covariant _NutritionChoiceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasField) return;

    // The parent owns the value; only overwrite when it genuinely diverged,
    // so typing does not fight the controller or reset the caret.
    if (widget.fieldValue != _controller!.text) {
      _controller!.text = widget.fieldValue;
    }
    if (widget.selected && !oldWidget.selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _focusNode!.requestFocus();
        // Selecting Other grows this row by a text field. Without this the
        // row can stay below the fold in the taller sheet, so the user is
        // typing into something they cannot see.
        Scrollable.ensureVisible(
          context,
          alignment: 1,
          duration: const Duration(milliseconds: TioDuration.ms200),
          curve: Curves.easeOutCubic,
        );
      });
    } else if (!widget.selected && oldWidget.selected) {
      _focusNode!.unfocus();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final label = widget.label;
    final selected = widget.selected;
    final onTap = widget.onTap;
    final borderColor = selected
        ? colors.primary
        : colors.outlineStrong.withAlpha(TioAlpha.alpha40);
    final backgroundColor = selected
        ? colors.primary.withAlpha(TioAlpha.alpha12)
        : colors.surfaceRaised;

    return Material(
      color: TioPalette.transparent,
      child: InkWell(
        onTap: onTap,
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
              width: selected ? TioStroke.width15 : TioStroke.width1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight:
                            selected ? TioFontWeight.w700 : TioFontWeight.w600,
                        fontSize: TioFontSize.size15,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration:
                        const Duration(milliseconds: TioMotion.selectionMs),
                    width: TioSize.dp22,
                    height: TioSize.dp22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? colors.primary
                            : colors.outlineStrong.withAlpha(TioAlpha.alpha100),
                        width: TioStroke.width2,
                      ),
                      color: selected ? colors.primary : TioPalette.transparent,
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: TioSize.dp14,
                            color: colors.onPrimary,
                          )
                        : null,
                  ),
                ],
              ),
              if (_hasField && selected) ...[
                const SizedBox(height: TioSpacing.sm),
                TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.onFieldChanged != null,
                  minLines: 1,
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  cursorColor: colors.primary,
                  style: TextStyle(
                    fontSize: TioFontSize.size14,
                    color: colors.textPrimary,
                    height: TioLineHeight.height130,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: widget.fieldHint,
                    hintStyle: TextStyle(
                      fontSize: TioFontSize.size13,
                      color: colors.textSecondary.withAlpha(TioAlpha.alpha140),
                    ),
                  ),
                  onChanged: widget.onFieldChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
