import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

import '../widgets/daily_wellness_editor_sheet.dart';

/// Canonical Body Goal range/increment constants for this screen.
///
/// No shared home exists for these yet (onboarding keeps its own copies in
/// `ProfileStepValidator`/`GoalPaceResolver`); duplicated here deliberately
/// rather than adding a new cross-feature dependency for three numbers.
abstract final class _BodyWeightLimits {
  static const minWeightKg = 30.0;
  static const maxWeightKg = 200.0;
  static const minPaceKgPerWeek = 0.1;
  static const maxPaceKgPerWeek = 1.5;
  static const paceIncrementKg = 0.1;
}

String _goalLabel(BodyGoalType type) => switch (type) {
      BodyGoalType.loseWeight => 'Lose Weight',
      BodyGoalType.gainWeight => 'Gain Weight',
      BodyGoalType.maintainWeight => 'Maintain Weight',
      BodyGoalType.recomposition => 'Recomposition',
    };

bool _isDirectional(BodyGoalType type) =>
    type == BodyGoalType.loseWeight || type == BodyGoalType.gainWeight;

double _kgToDisplay(double kg, WeightUnit unit) =>
    unit == WeightUnit.kg ? kg : UnitConverters.kgToLb(kg);

double _displayToKg(double display, WeightUnit unit) =>
    unit == WeightUnit.kg ? display : UnitConverters.lbToKg(display);

String _formatGoalStartedDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

/// Settings-owned Body & Weight surface. Presentation/navigation only --
/// canonical Body business state remains owned by `apps/features/progress`.
class BodyWeightSettingsPage extends StatelessWidget {
  const BodyWeightSettingsPage({
    required this.bodyState,
    required this.weightUnit,
    required this.onRecordCurrentWeight,
    required this.onSaveBodyGoal,
    super.key,
  });

  final BodyState bodyState;
  final WeightUnit weightUnit;
  final Future<void> Function(double weightKg) onRecordCurrentWeight;
  final Future<void> Function(BodyGoalUpdate update) onSaveBodyGoal;

  Future<void> _pickCurrentWeight(BuildContext context) async {
    await showDailyWellnessEditorSheet<void>(
      context: context,
      builder: (context) => _CurrentWeightEditorSheet(
        currentWeightKg: bodyState.latestWeight?.weightKg,
        weightUnit: weightUnit,
        onSave: onRecordCurrentWeight,
      ),
    );
  }

  Future<void> _pickBodyGoal(BuildContext context) async {
    await showDailyWellnessEditorSheet<void>(
      context: context,
      builder: (context) => _BodyGoalEditorSheet(
        activeGoal: bodyState.activeGoal,
        currentWeightKg: bodyState.latestWeight?.weightKg,
        weightUnit: weightUnit,
        onSave: onSaveBodyGoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final activeGoal = bodyState.activeGoal;
    final isDirectional =
        activeGoal != null && _isDirectional(activeGoal.goalType);
    final currentWeightKg = bodyState.latestWeight?.weightKg;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Body & Weight',
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
            const _BodyWeightSectionHeader(title: 'CURRENT'),
            _BodyWeightGroupCard(
              key: const ValueKey('body-weight-current-card'),
              children: [
                _BodyWeightRow(
                  key: const ValueKey('body-weight-current-weight-field'),
                  icon: Icons.monitor_weight_outlined,
                  label: 'Current Weight',
                  value: currentWeightKg == null
                      ? 'Not set'
                      : UnitFormatters.formatWeight(
                          currentWeightKg,
                          weightUnit,
                        ),
                  isUnset: currentWeightKg == null,
                  onTap: () => _pickCurrentWeight(context),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _BodyWeightSectionHeader(title: 'ACTIVE GOAL'),
            _BodyWeightGroupCard(
              key: const ValueKey('body-weight-active-goal-card'),
              children: [
                _BodyWeightRow(
                  key: const ValueKey('body-weight-body-goal-field'),
                  icon: Icons.flag_outlined,
                  label: 'Body Goal',
                  value: activeGoal == null
                      ? 'Not set'
                      : _goalLabel(activeGoal.goalType),
                  isUnset: activeGoal == null,
                  onTap: () => _pickBodyGoal(context),
                ),
                if (isDirectional) ...[
                  const _BodyWeightDivider(),
                  _BodyWeightRow(
                    key: const ValueKey('body-weight-target-weight-field'),
                    icon: Icons.adjust_outlined,
                    label: 'Target Weight',
                    value: activeGoal.targetWeightKg == null
                        ? 'Not set'
                        : UnitFormatters.formatWeight(
                            activeGoal.targetWeightKg!,
                            weightUnit,
                          ),
                    isUnset: activeGoal.targetWeightKg == null,
                    onTap: () => _pickBodyGoal(context),
                  ),
                  const _BodyWeightDivider(),
                  _BodyWeightRow(
                    key: const ValueKey('body-weight-goal-pace-field'),
                    icon: Icons.speed_outlined,
                    label: 'Goal Pace',
                    value: activeGoal.weeklyWeightChangeKg == null
                        ? 'Not set'
                        : '${UnitFormatters.formatWeight(activeGoal.weeklyWeightChangeKg!, weightUnit, decimals: 1)}/week',
                    isUnset: activeGoal.weeklyWeightChangeKg == null,
                    onTap: () => _pickBodyGoal(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: TioSpacing.lg),
            const _BodyWeightSectionHeader(title: 'GOAL DETAILS'),
            _BodyWeightGroupCard(
              key: const ValueKey('body-weight-goal-details-card'),
              children: [
                _BodyWeightReadOnlyRow(
                  key: const ValueKey('body-weight-starting-weight-field'),
                  label: 'Starting Weight',
                  value: activeGoal?.startingWeightKg == null
                      ? 'Not set'
                      : UnitFormatters.formatWeight(
                          activeGoal!.startingWeightKg!,
                          weightUnit,
                        ),
                ),
                const _BodyWeightDivider(indent: TioSpacing.lg),
                _BodyWeightReadOnlyRow(
                  key: const ValueKey('body-weight-goal-started-field'),
                  label: 'Goal Started',
                  value: activeGoal?.startedAt == null
                      ? 'Not set'
                      : _formatGoalStartedDate(activeGoal!.startedAt!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BodyWeightSectionHeader extends StatelessWidget {
  const _BodyWeightSectionHeader({required this.title});
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

class _BodyWeightGroupCard extends StatelessWidget {
  const _BodyWeightGroupCard({required this.children, super.key});
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

class _BodyWeightDivider extends StatelessWidget {
  const _BodyWeightDivider({this.indent = TioSize.dp56});
  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Divider(
      height: TioSize.dp1,
      thickness: TioSize.dp1,
      indent: indent,
      color: colors.outlineStrong.withAlpha(TioAlpha.alpha24),
    );
  }
}

/// Tappable field row: fixed leading icon, label, right-aligned value, and a
/// trailing edit-pencil affordance -- the accepted Daily Wellness pattern.
class _BodyWeightRow extends StatelessWidget {
  const _BodyWeightRow({
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
  final VoidCallback? onTap;

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
            const _EditAffordanceIcon(),
          ],
        ),
      ),
    );
  }
}

/// Read-only Goal Details row -- same geometry as [_BodyWeightRow] minus the
/// tap target and edit affordance, so it cannot look editable.
class _BodyWeightReadOnlyRow extends StatelessWidget {
  const _BodyWeightReadOnlyRow({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md + TioSize.dp4,
      ),
      child: Row(
        children: [
          Expanded(
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
          Text(
            value,
            style: TextStyle(
              color:
                  value == 'Not set' ? colors.textMuted : colors.textSecondary,
              fontSize: TioFontSize.size15,
              fontWeight: TioFontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared edit-pencil affordance, matching the Daily Wellness screen.
class _EditAffordanceIcon extends StatelessWidget {
  const _EditAffordanceIcon();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Container(
      width: TioSize.dp36,
      height: TioSize.dp36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.edit_outlined,
          size: TioSize.dp16, color: colors.textSecondary),
    );
  }
}

class _CurrentWeightEditorSheet extends StatefulWidget {
  const _CurrentWeightEditorSheet({
    required this.currentWeightKg,
    required this.weightUnit,
    required this.onSave,
  });

  final double? currentWeightKg;
  final WeightUnit weightUnit;
  final Future<void> Function(double weightKg) onSave;

  @override
  State<_CurrentWeightEditorSheet> createState() =>
      _CurrentWeightEditorSheetState();
}

class _CurrentWeightEditorSheetState extends State<_CurrentWeightEditorSheet> {
  late final TextEditingController _controller;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentWeightKg == null
        ? ''
        : _kgToDisplay(widget.currentWeightKg!, widget.weightUnit)
            .toStringAsFixed(1);
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      setState(() => _errorText = 'Enter a valid weight.');
      return;
    }
    final weightKg = _displayToKg(parsed, widget.weightUnit);
    if (weightKg < _BodyWeightLimits.minWeightKg ||
        weightKg > _BodyWeightLimits.maxWeightKg) {
      final min =
          _kgToDisplay(_BodyWeightLimits.minWeightKg, widget.weightUnit);
      final max =
          _kgToDisplay(_BodyWeightLimits.maxWeightKg, widget.weightUnit);
      final unitLabel = widget.weightUnit == WeightUnit.kg ? 'kg' : 'lb';
      setState(() {
        _errorText =
            'Enter a weight between ${min.toStringAsFixed(0)} and ${max.toStringAsFixed(0)} $unitLabel.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(weightKg);
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
    final unitLabel = widget.weightUnit == WeightUnit.kg ? 'kg' : 'lb';

    return DailyWellnessEditorSheet(
      title: 'Current Weight',
      canDismiss: !_isSaving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('body-weight-current-weight-input'),
            controller: _controller,
            enabled: !_isSaving,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                color: colors.textPrimary, fontSize: TioFontSize.size18),
            decoration: InputDecoration(
              suffixText: unitLabel,
              errorText: _errorText,
            ),
          ),
        ],
      ),
      actions: TioButton.primary(
        key: const ValueKey('body-weight-current-weight-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: _isSaving ? null : _handleSave,
        expand: true,
      ),
    );
  }
}

class _BodyGoalEditorSheet extends StatefulWidget {
  const _BodyGoalEditorSheet({
    required this.activeGoal,
    required this.currentWeightKg,
    required this.weightUnit,
    required this.onSave,
  });

  final BodyGoalState? activeGoal;
  final double? currentWeightKg;
  final WeightUnit weightUnit;
  final Future<void> Function(BodyGoalUpdate update) onSave;

  @override
  State<_BodyGoalEditorSheet> createState() => _BodyGoalEditorSheetState();
}

class _BodyGoalEditorSheetState extends State<_BodyGoalEditorSheet> {
  static const _selectableTypes = [
    BodyGoalType.loseWeight,
    BodyGoalType.gainWeight,
    BodyGoalType.maintainWeight,
  ];

  BodyGoalType? _selectedType;
  late final TextEditingController _targetController;
  double _paceKgPerWeek = 0.5;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final active = widget.activeGoal;
    _selectedType = active != null && _selectableTypes.contains(active.goalType)
        ? active.goalType
        : null;
    final initialTarget = active?.targetWeightKg;
    _targetController = TextEditingController(
      text: initialTarget == null
          ? ''
          : _kgToDisplay(initialTarget, widget.weightUnit).toStringAsFixed(1),
    );
    _paceKgPerWeek = active?.weeklyWeightChangeKg ?? 0.5;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final type = _selectedType;
    if (type == null) {
      setState(() => _errorText = 'Choose a Body Goal.');
      return;
    }

    if (!_isDirectional(type)) {
      setState(() {
        _isSaving = true;
        _errorText = null;
      });
      try {
        await widget.onSave(BodyGoalUpdate(goalType: type));
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        if (mounted) {
          setState(() {
            _isSaving = false;
            _errorText = "Couldn't save. Check your connection and try again.";
          });
        }
      }
      return;
    }

    final currentWeightKg = widget.currentWeightKg;
    if (currentWeightKg == null) {
      setState(() {
        _errorText = 'Log your Current Weight before setting a directional '
            'Body Goal.';
      });
      return;
    }

    final parsedTarget = double.tryParse(_targetController.text.trim());
    if (parsedTarget == null) {
      setState(() => _errorText = 'Enter a valid Target Weight.');
      return;
    }
    final targetKg = _displayToKg(parsedTarget, widget.weightUnit);
    if (targetKg < _BodyWeightLimits.minWeightKg ||
        targetKg > _BodyWeightLimits.maxWeightKg) {
      setState(() => _errorText = 'Target Weight is out of range.');
      return;
    }
    if (type == BodyGoalType.loseWeight && targetKg >= currentWeightKg) {
      setState(
          () => _errorText = 'Target Weight must be below Current Weight.');
      return;
    }
    if (type == BodyGoalType.gainWeight && targetKg <= currentWeightKg) {
      setState(
          () => _errorText = 'Target Weight must be above Current Weight.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onSave(
        BodyGoalUpdate(
          goalType: type,
          targetWeightKg: targetKg,
          weeklyWeightChangeKg: _paceKgPerWeek,
        ),
      );
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
    final unitLabel = widget.weightUnit == WeightUnit.kg ? 'kg' : 'lb';
    final isDirectionalSelection =
        _selectedType != null && _isDirectional(_selectedType!);
    final paceDisplay = _kgToDisplay(_paceKgPerWeek, widget.weightUnit);
    final divisions = ((_BodyWeightLimits.maxPaceKgPerWeek -
                _BodyWeightLimits.minPaceKgPerWeek) /
            _BodyWeightLimits.paceIncrementKg)
        .round();

    return DailyWellnessEditorSheet(
      title: 'Body Goal',
      canDismiss: !_isSaving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: TioSpacing.sm,
            runSpacing: TioSpacing.sm,
            children: [
              for (final type in _selectableTypes)
                _BodyGoalTypeChip(
                  key: ValueKey('body-goal-option-${type.name}'),
                  label: _goalLabel(type),
                  selected: _selectedType == type,
                  onTap: _isSaving
                      ? null
                      : () => setState(() {
                            _selectedType = type;
                            _errorText = null;
                          }),
                ),
            ],
          ),
          if (isDirectionalSelection) ...[
            const SizedBox(height: TioSpacing.lg),
            Text(
              'Target Weight',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
                fontWeight: TioFontWeight.w600,
              ),
            ),
            const SizedBox(height: TioSpacing.xs),
            TextField(
              key: const ValueKey('body-weight-target-weight-input'),
              controller: _targetController,
              enabled: !_isSaving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: colors.textPrimary, fontSize: TioFontSize.size18),
              decoration: InputDecoration(suffixText: unitLabel),
            ),
            const SizedBox(height: TioSpacing.lg),
            Text(
              'Goal Pace',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size13,
                fontWeight: TioFontWeight.w600,
              ),
            ),
            Text(
              '${paceDisplay.toStringAsFixed(1)} $unitLabel/week',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w700,
                fontSize: TioFontSize.size15,
              ),
            ),
            Slider(
              key: const ValueKey('body-weight-goal-pace-slider'),
              value: _paceKgPerWeek,
              min: _BodyWeightLimits.minPaceKgPerWeek,
              max: _BodyWeightLimits.maxPaceKgPerWeek,
              divisions: divisions,
              onChanged: _isSaving
                  ? null
                  : (value) {
                      final rounded = (value * 10).round() / 10.0;
                      setState(() {
                        _paceKgPerWeek = rounded;
                        _errorText = null;
                      });
                    },
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
        key: const ValueKey('body-weight-body-goal-save'),
        label: 'Save',
        loading: _isSaving,
        onPressed: _isSaving ? null : _handleSave,
        expand: true,
      ),
    );
  }
}

class _BodyGoalTypeChip extends StatelessWidget {
  const _BodyGoalTypeChip({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TioRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.md,
          vertical: TioSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(TioRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.onPrimary : colors.textPrimary,
            fontWeight: TioFontWeight.w700,
            fontSize: TioFontSize.size13,
          ),
        ),
      ),
    );
  }
}
