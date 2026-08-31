import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

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
  static const defaultWeightKg = 70.0;
  static const defaultPaceKgPerWeek = 0.5;
}

String _goalLabel(BodyGoalType type) => switch (type) {
      BodyGoalType.loseWeight => 'Lose Weight',
      BodyGoalType.gainWeight => 'Gain Weight',
      BodyGoalType.maintainWeight => 'Maintain Weight',
      BodyGoalType.recomposition => 'Recomposition',
    };

IconData _goalIcon(BodyGoalType type) => switch (type) {
      BodyGoalType.loseWeight => Icons.trending_down_rounded,
      BodyGoalType.gainWeight => Icons.trending_up_rounded,
      BodyGoalType.maintainWeight => Icons.balance_rounded,
      BodyGoalType.recomposition => Icons.autorenew_rounded,
    };

/// Direction/range policy for a Target Weight save, shared by the changed-goal
/// wizard step and the direct Target Weight edit. Returns an error message,
/// or null when the value is acceptable.
String? _validateTargetWeight(
  BodyGoalType goalType,
  double? currentWeightKg,
  double targetKg,
) {
  if (currentWeightKg == null) {
    return 'Log your Current Weight before setting a Target Weight.';
  }
  if (goalType == BodyGoalType.loseWeight && targetKg >= currentWeightKg) {
    return 'Target Weight must be below Current Weight.';
  }
  if (goalType == BodyGoalType.gainWeight && targetKg <= currentWeightKg) {
    return 'Target Weight must be above Current Weight.';
  }
  return null;
}

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
    await showTioEditorSheet<double>(
      context: context,
      builder: (context) => _WeightEntrySheet(
        title: 'Current Weight',
        initialKg: bodyState.latestWeight?.weightKg ??
            _BodyWeightLimits.defaultWeightKg,
        weightUnit: weightUnit,
        confirmLabel: 'Save',
        confirmKey: const ValueKey('body-weight-current-weight-save'),
        onConfirm: onRecordCurrentWeight,
      ),
    );
  }

  Future<void> _pickBodyGoal(BuildContext context) async {
    final activeGoal = bodyState.activeGoal;
    if (activeGoal != null) {
      final confirmed = await showTioConfirmationBottomSheet(
        context: context,
        title: 'Change Body Goal?',
        message: 'Changing your Body Goal starts a new goal using your '
            'latest Current Weight.',
        confirmLabel: 'Yes',
        cancelLabel: 'No',
      );
      if (confirmed != true || !context.mounted) return;
    }
    await _openBodyGoalSelection(context);
  }

  Future<void> _openBodyGoalSelection(BuildContext context) async {
    final selectedType = await showTioEditorSheet<BodyGoalType>(
      context: context,
      builder: (context) => _BodyGoalSelectionSheet(
        activeGoal: bodyState.activeGoal,
        onSaveMaintain: () => onSaveBodyGoal(
          const BodyGoalUpdate(goalType: BodyGoalType.maintainWeight),
        ),
      ),
    );
    if (selectedType == null ||
        !_isDirectional(selectedType) ||
        !context.mounted) {
      // null: cancelled. maintainWeight: already saved inside the sheet.
      return;
    }

    final currentWeightKg = bodyState.latestWeight?.weightKg;
    final targetKg = await showTioEditorSheet<double>(
      context: context,
      builder: (context) => _WeightEntrySheet(
        title: 'Target Weight',
        initialKg: bodyState.activeGoal?.targetWeightKg ??
            currentWeightKg ??
            _BodyWeightLimits.defaultWeightKg,
        weightUnit: weightUnit,
        confirmLabel: 'Next',
        confirmKey: const ValueKey('body-weight-target-weight-confirm'),
        validate: (targetKg) =>
            _validateTargetWeight(selectedType, currentWeightKg, targetKg),
        onConfirm: (_) async {},
      ),
    );
    if (targetKg == null || !context.mounted) return;

    await showTioEditorSheet<double>(
      context: context,
      builder: (context) => _GoalPaceStepSheet(
        initialPaceKg: bodyState.activeGoal?.weeklyWeightChangeKg ??
            _BodyWeightLimits.defaultPaceKgPerWeek,
        weightUnit: weightUnit,
        confirmLabel: 'Save',
        onConfirm: (paceKg) => onSaveBodyGoal(
          BodyGoalUpdate(
            goalType: selectedType,
            targetWeightKg: targetKg,
            weeklyWeightChangeKg: paceKg,
          ),
        ),
      ),
    );
  }

  Future<void> _pickTargetWeight(BuildContext context) async {
    final activeGoal = bodyState.activeGoal!;
    final currentWeightKg = bodyState.latestWeight?.weightKg;
    await showTioEditorSheet<double>(
      context: context,
      builder: (context) => _WeightEntrySheet(
        title: 'Target Weight',
        initialKg: activeGoal.targetWeightKg ??
            currentWeightKg ??
            _BodyWeightLimits.defaultWeightKg,
        weightUnit: weightUnit,
        confirmLabel: 'Save',
        confirmKey: const ValueKey('body-weight-target-weight-confirm'),
        validate: (targetKg) => _validateTargetWeight(
            activeGoal.goalType, currentWeightKg, targetKg),
        onConfirm: (targetKg) => onSaveBodyGoal(
          BodyGoalUpdate(
            goalType: activeGoal.goalType,
            targetWeightKg: targetKg,
            weeklyWeightChangeKg: activeGoal.weeklyWeightChangeKg,
          ),
        ),
      ),
    );
  }

  Future<void> _pickGoalPace(BuildContext context) async {
    final activeGoal = bodyState.activeGoal!;
    await showTioEditorSheet<double>(
      context: context,
      builder: (context) => _GoalPaceStepSheet(
        initialPaceKg: activeGoal.weeklyWeightChangeKg ??
            _BodyWeightLimits.defaultPaceKgPerWeek,
        weightUnit: weightUnit,
        confirmLabel: 'Save',
        onConfirm: (paceKg) => onSaveBodyGoal(
          BodyGoalUpdate(
            goalType: activeGoal.goalType,
            targetWeightKg: activeGoal.targetWeightKg,
            weeklyWeightChangeKg: paceKg,
          ),
        ),
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
                    onTap: () => _pickTargetWeight(context),
                  ),
                  const _BodyWeightDivider(),
                  _BodyWeightRow(
                    key: const ValueKey('body-weight-goal-pace-field'),
                    icon: Icons.speed_outlined,
                    label: 'Weekly Goal',
                    value: activeGoal.weeklyWeightChangeKg == null
                        ? 'Not set'
                        : '${UnitFormatters.formatWeight(activeGoal.weeklyWeightChangeKg!, weightUnit, decimals: 1)}/week',
                    isUnset: activeGoal.weeklyWeightChangeKg == null,
                    onTap: () => _pickGoalPace(context),
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

/// Shared weight-entry sheet for Current Weight and Target Weight: a
/// [TioWeightWheel] by default (whole/decimal/kg-lbs drums, matching the
/// accepted onboarding presentation), with a small pencil affordance in the
/// sheet's own title row that swaps in manual numeric entry. Switching modes
/// only updates the local draft -- only [confirmLabel]'s button persists.
///
/// The kg/lbs drum here is a local, editor-only input/display choice: it
/// starts from [weightUnit] (the app-global preference) but never writes
/// back to it. Canonical values always flow through [onConfirm] in kg.
class _WeightEntrySheet extends StatefulWidget {
  const _WeightEntrySheet({
    required this.title,
    required this.initialKg,
    required this.weightUnit,
    required this.confirmLabel,
    required this.confirmKey,
    required this.onConfirm,
    this.validate,
  });

  final String title;
  final double initialKg;
  final WeightUnit weightUnit;
  final String confirmLabel;
  final Key confirmKey;
  final Future<void> Function(double weightKg) onConfirm;

  /// Returns an error message to block the save, or null when acceptable.
  final String? Function(double weightKg)? validate;

  @override
  State<_WeightEntrySheet> createState() => _WeightEntrySheetState();
}

class _WeightEntrySheetState extends State<_WeightEntrySheet> {
  late double _draftKg;
  late WeightUnit _localUnit;
  var _isManualMode = false;
  late final TextEditingController _manualController;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _draftKg = widget.initialKg;
    _localUnit = widget.weightUnit;
    _manualController = TextEditingController(text: _formatDisplay(_draftKg));
  }

  String _formatDisplay(double kg) =>
      _kgToDisplay(kg, _localUnit).toStringAsFixed(1);

  void _handleWheelChanged(double kg) {
    setState(() {
      _draftKg = kg;
      _errorText = null;
    });
    _manualController.text = _formatDisplay(kg);
  }

  void _handleLocalUnitChanged(WeightUnit unit) {
    // Editor-local display choice only -- never writes UnitPreferences.
    setState(() {
      _localUnit = unit;
      _manualController.text = _formatDisplay(_draftKg);
    });
  }

  void _handleManualChanged(String text) {
    final parsed = double.tryParse(text.trim());
    if (parsed == null) return;
    final kg = _displayToKg(parsed, _localUnit)
        .clamp(_BodyWeightLimits.minWeightKg, _BodyWeightLimits.maxWeightKg);
    setState(() {
      _draftKg = kg;
      _errorText = null;
    });
  }

  void _toggleMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      _manualController.text = _formatDisplay(_draftKg);
    });
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_isSaving) return;
    final validationError = widget.validate?.call(_draftKg);
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm(_draftKg);
      if (mounted) Navigator.of(context).pop(_draftKg);
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
      title: widget.title,
      canDismiss: !_isSaving,
      titleTrailing: IconButton(
        key: const ValueKey('body-weight-wheel-mode-toggle'),
        icon: Icon(_isManualMode ? Icons.tune : Icons.edit_outlined),
        color: colors.textSecondary,
        onPressed: _toggleMode,
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isManualMode)
            TextField(
              key: const ValueKey('body-weight-wheel-manual-input'),
              controller: _manualController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: _handleManualChanged,
              style: TextStyle(
                  color: colors.textPrimary, fontSize: TioFontSize.size18),
              decoration: InputDecoration(
                suffixText: _localUnit == WeightUnit.kg ? 'kg' : 'lb',
              ),
            )
          else
            TioWeightWheel(
              key: const ValueKey('body-weight-wheel'),
              valueKg: _draftKg,
              unit: _localUnit,
              onUnitChanged: _handleLocalUnitChanged,
              minKg: _BodyWeightLimits.minWeightKg,
              maxKg: _BodyWeightLimits.maxWeightKg,
              onChanged: _handleWheelChanged,
            ),
          if (_isManualMode) const SizedBox(height: TioSpacing.lg),
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
        key: widget.confirmKey,
        label: widget.confirmLabel,
        loading: _isSaving,
        onPressed: _isSaving ? null : _handleConfirm,
        expand: true,
      ),
    );
  }
}

/// Body Goal-only selection sheet: goal-type chips, no Target Weight or Goal
/// Pace controls. Selecting Maintain performs the one final save right here
/// (there is no follow-on step for a non-directional goal); selecting
/// Lose/Gain just hands the chosen type back so the caller can continue the
/// Target Weight -> Goal Pace sequence.
class _BodyGoalSelectionSheet extends StatefulWidget {
  const _BodyGoalSelectionSheet({
    required this.activeGoal,
    required this.onSaveMaintain,
  });

  final BodyGoalState? activeGoal;
  final Future<void> Function() onSaveMaintain;

  @override
  State<_BodyGoalSelectionSheet> createState() =>
      _BodyGoalSelectionSheetState();
}

class _BodyGoalSelectionSheetState extends State<_BodyGoalSelectionSheet> {
  static const _selectableTypes = [
    BodyGoalType.loseWeight,
    BodyGoalType.gainWeight,
    BodyGoalType.maintainWeight,
  ];

  BodyGoalType? _selectedType;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final active = widget.activeGoal;
    _selectedType = active != null && _selectableTypes.contains(active.goalType)
        ? active.goalType
        : null;
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return;
    final type = _selectedType;
    if (type == null) {
      setState(() => _errorText = 'Choose a Body Goal.');
      return;
    }

    if (type == BodyGoalType.maintainWeight) {
      setState(() {
        _isSaving = true;
        _errorText = null;
      });
      try {
        await widget.onSaveMaintain();
        if (mounted) Navigator.of(context).pop(type);
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

    Navigator.of(context).pop(type);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isMaintainSelected = _selectedType == BodyGoalType.maintainWeight;

    return TioEditorSheet(
      title: 'Body Goal',
      canDismiss: !_isSaving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in _selectableTypes) ...[
            if (type != _selectableTypes.first)
              const SizedBox(height: TioSpacing.sm),
            _BodyGoalOptionTile(
              key: ValueKey('body-goal-option-${type.name}'),
              icon: _goalIcon(type),
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
        key: const ValueKey('body-weight-body-goal-continue'),
        label: isMaintainSelected ? 'Save' : 'Next',
        loading: _isSaving,
        onPressed: _isSaving ? null : _handleContinue,
        expand: true,
      ),
    );
  }
}

/// Goal Pace-only sheet: no Body Goal selector, no Target Weight control, no
/// confirmation. Terminal step for both the changed-goal wizard (where it
/// performs the single real save) and the direct Goal Pace edit.
class _GoalPaceStepSheet extends StatefulWidget {
  const _GoalPaceStepSheet({
    required this.initialPaceKg,
    required this.weightUnit,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final double initialPaceKg;
  final WeightUnit weightUnit;
  final String confirmLabel;
  final Future<void> Function(double paceKg) onConfirm;

  @override
  State<_GoalPaceStepSheet> createState() => _GoalPaceStepSheetState();
}

class _GoalPaceStepSheetState extends State<_GoalPaceStepSheet> {
  late double _paceKgPerWeek;
  late double _lastVibratedPace;
  var _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _paceKgPerWeek = widget.initialPaceKg;
    _lastVibratedPace = _paceKgPerWeek;
  }

  Future<void> _handleConfirm() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm(_paceKgPerWeek);
      if (mounted) Navigator.of(context).pop(_paceKgPerWeek);
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
    final paceDisplay = _kgToDisplay(_paceKgPerWeek, widget.weightUnit);
    final divisions = ((_BodyWeightLimits.maxPaceKgPerWeek -
                _BodyWeightLimits.minPaceKgPerWeek) /
            _BodyWeightLimits.paceIncrementKg)
        .round();

    return TioEditorSheet(
      title: 'Weekly Goal',
      canDismiss: !_isSaving,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              '${paceDisplay.toStringAsFixed(1)} $unitLabel / week',
              key: const ValueKey('body-weight-goal-pace-value-text'),
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: TioFontWeight.w800,
                fontSize: TioFontSize.size32,
                letterSpacing: TioLetterSpacing.negative05,
              ),
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
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
                    if ((rounded - _lastVibratedPace).abs() >= 0.09) {
                      HapticFeedback.selectionClick();
                      _lastVibratedPace = rounded;
                    }
                  },
          ),
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
        key: const ValueKey('body-weight-goal-pace-confirm'),
        label: widget.confirmLabel,
        loading: _isSaving,
        onPressed: _isSaving ? null : _handleConfirm,
        expand: true,
      ),
    );
  }
}

/// Full-width vertically-stacked Body Goal option, matching the accepted
/// Settings selection-row visual language already used by Appearance/Theme
/// selection (bordered card, leading icon circle, trailing checkmark).
class _BodyGoalOptionTile extends StatelessWidget {
  const _BodyGoalOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconData icon;
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
              Container(
                width: TioSize.dp42,
                height: TioSize.dp42,
                decoration: BoxDecoration(
                  color: selected
                      ? colors.primary.withAlpha(TioAlpha.alpha24)
                      : colors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: selected ? colors.primary : colors.textSecondary,
                  size: TioSize.dp22,
                ),
              ),
              const SizedBox(width: TioSize.dp14),
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
