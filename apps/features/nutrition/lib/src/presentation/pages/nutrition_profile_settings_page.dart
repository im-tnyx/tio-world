import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/models.dart';

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
  NutritionProfileData _mergedWithDiet(String? preferredDiet) {
    return NutritionProfileData(
      preferredDiet: preferredDiet,
      allergies: profile.allergies,
      dislikedFoods: profile.dislikedFoods,
      medicalConditions: profile.medicalConditions,
    );
  }

  NutritionProfileData _mergedWithAllergies(Set<String> allergies) {
    return NutritionProfileData(
      preferredDiet: profile.preferredDiet,
      allergies: allergies,
      dislikedFoods: profile.dislikedFoods,
      medicalConditions: profile.medicalConditions,
    );
  }

  Future<void> _editDietType(BuildContext context) async {
    await showNutritionEditorSheet<void>(
      context: context,
      builder: (context) => _DietTypeEditorSheet(
        initialStorageValue: profile.preferredDiet,
        onSave: (value) => onSave(_mergedWithDiet(value)),
      ),
    );
  }

  Future<void> _editAllergies(BuildContext context) async {
    await showNutritionEditorSheet<void>(
      context: context,
      builder: (context) => _AllergiesEditorSheet(
        initialAllergies: profile.allergies,
        onSave: (value) => onSave(_mergedWithAllergies(value)),
      ),
    );
  }

  String _dietSummary() =>
      NutritionProfileVocabulary.dietTypeLabel(profile.preferredDiet) ??
      'Not set';

  String _allergiesSummary() {
    final allergies = profile.allergies;
    if (allergies == null) return 'Not set';
    if (allergies.isEmpty) return 'None';
    final labels = NutritionProfileVocabulary.allergyLabels(allergies);
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
            const _NutritionSectionHeader(title: 'DIET'),
            _NutritionGroupCard(
              children: [
                _NutritionRow(
                  key: const ValueKey('nutrition-profile-diet-type-field'),
                  icon: Icons.local_dining_rounded,
                  label: 'Diet Type',
                  value: _dietSummary(),
                  isUnset: profile.preferredDiet == null,
                  onTap: () => _editDietType(context),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _NutritionSectionHeader(title: 'RESTRICTIONS'),
            _NutritionGroupCard(
              children: [
                _NutritionRow(
                  key: const ValueKey('nutrition-profile-allergies-field'),
                  icon: Icons.no_food_rounded,
                  label: 'Allergies & Restrictions',
                  value: _allergiesSummary(),
                  isUnset: profile.allergies == null,
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

/// Opens a Nutrition-owned editor sheet.
Future<T?> showNutritionEditorSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TioPalette.transparent,
      enableDrag: false,
      showDragHandle: false,
      builder: builder,
    );

/// Shared visual shell for the Nutrition Profile editors.
class NutritionEditorSheet extends StatelessWidget {
  const NutritionEditorSheet({
    required this.title,
    required this.content,
    required this.actions,
    super.key,
    this.supportingText,
  });

  final String title;
  final String? supportingText;
  final Widget content;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        key: const ValueKey('nutrition-editor-sheet'),
        color: colors.surfaceRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TioRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TioSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: TioSize.dp36,
                    height: TioSize.dp4,
                    decoration: BoxDecoration(
                      color: colors.outlineStrong.withAlpha(TioAlpha.alpha50),
                      borderRadius: BorderRadius.circular(TioSize.dp2),
                    ),
                  ),
                ),
                const SizedBox(height: TioSpacing.md),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: TioFontWeight.w700,
                            fontSize: TioFontSize.size18,
                          ),
                        ),
                        if (supportingText != null) ...[
                          const SizedBox(height: TioSpacing.sm),
                          Text(
                            supportingText!,
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: TioFontSize.size13,
                            ),
                          ),
                        ],
                        const SizedBox(height: TioSpacing.lg),
                        content,
                        const SizedBox(height: TioSpacing.md),
                        actions,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DietTypeEditorSheet extends StatefulWidget {
  const _DietTypeEditorSheet({
    required this.initialStorageValue,
    required this.onSave,
  });

  final String? initialStorageValue;
  final Future<void> Function(String storageValue) onSave;

  @override
  State<_DietTypeEditorSheet> createState() => _DietTypeEditorSheetState();
}

class _DietTypeEditorSheetState extends State<_DietTypeEditorSheet> {
  String? _selected;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStorageValue;
  }

  bool get _canSave =>
      _selected != null && _selected != widget.initialStorageValue;

  Future<void> _handleSave() async {
    if (_isSaving || !_canSave) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(_selected!);
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

    return NutritionEditorSheet(
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
              onTap: _isSaving
                  ? null
                  : () => setState(() {
                        _selected = choice.storageValue;
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
    required this.onSave,
  });

  /// `null` unanswered, empty set explicitly None, otherwise selections.
  final Set<String>? initialAllergies;
  final Future<void> Function(Set<String> allergies) onSave;

  @override
  State<_AllergiesEditorSheet> createState() => _AllergiesEditorSheetState();
}

class _AllergiesEditorSheetState extends State<_AllergiesEditorSheet> {
  late Set<String> _selected;
  late bool _noneSelected;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAllergies;
    _noneSelected = initial != null && initial.isEmpty;
    _selected = {...?initial};
  }

  /// Mirrors the canonical rule: an answered selection is either explicit
  /// None (empty set) or a non-empty restriction set. Never both, never empty.
  bool get _isAnswered =>
      _noneSelected ? _selected.isEmpty : _selected.isNotEmpty;

  Set<String> get _result => _noneSelected ? <String>{} : _selected;

  bool get _changed {
    final initial = widget.initialAllergies;
    if (initial == null) return true;
    final result = _result;
    return initial.length != result.length || !initial.containsAll(result);
  }

  bool get _canSave => _isAnswered && _changed;

  void _toggleNone() {
    setState(() {
      _noneSelected = !_noneSelected;
      // None is exclusive: choosing it clears every restriction.
      if (_noneSelected) _selected = <String>{};
      _errorText = null;
    });
  }

  void _toggleRestriction(String storageValue) {
    setState(() {
      // Choosing any restriction clears None, preserving exclusivity.
      _noneSelected = false;
      if (_selected.contains(storageValue)) {
        _selected.remove(storageValue);
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
      await widget.onSave(_result);
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

    return NutritionEditorSheet(
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

/// Full-width selectable row used by both Nutrition Profile editors.
class _NutritionChoiceTile extends StatelessWidget {
  const _NutritionChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
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
          child: Row(
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
                duration: const Duration(milliseconds: TioMotion.selectionMs),
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
        ),
      ),
    );
  }
}

class _NutritionSectionHeader extends StatelessWidget {
  const _NutritionSectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding:
          const EdgeInsets.only(left: TioSpacing.sm, bottom: TioSpacing.sm),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textMuted,
          fontWeight: TioFontWeight.w700,
          fontSize: TioFontSize.size11,
          letterSpacing: TioLetterSpacing.positive08,
        ),
      ),
    );
  }
}

class _NutritionGroupCard extends StatelessWidget {
  const _NutritionGroupCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(TioRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isUnset,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isUnset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.md + TioSize.dp4,
        ),
        child: Row(
          children: [
            Icon(icon, size: TioSize.dp24, color: colors.textPrimary),
            const SizedBox(width: TioSpacing.lg),
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w700,
                  fontSize: TioFontSize.size15,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.sm),
            Expanded(
              flex: 2,
              child: Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: isUnset ? colors.textMuted : colors.textPrimary,
                  fontSize: TioFontSize.size15,
                  fontWeight: isUnset ? TioFontWeight.w400 : TioFontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: TioSpacing.lg),
            Container(
              width: TioSize.dp36,
              height: TioSize.dp36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: TioSize.dp16,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
