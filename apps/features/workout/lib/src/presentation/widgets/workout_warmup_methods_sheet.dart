import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/routine_composition_limits.dart';
import '../../domain/models/workout_warmup_calculator.dart';

/// Opens the shared selector used by Workout Settings, Log Workout and
/// Routine Create/Edit. The returned value contains the staged library edits
/// and selection; callers persist it only after accepting the operation.
Future<WorkoutWarmupSettings?> showWorkoutWarmupMethodsSheet(
  BuildContext context, {
  required WorkoutWarmupSettings settings,
  int? availableSetSlots,
}) =>
    showTioEditorSheet<WorkoutWarmupSettings>(
      context: context,
      useSafeArea: true,
      builder: (_) => _WorkoutWarmupMethodsSheet(
        settings: settings,
        availableSetSlots: availableSetSlots,
      ),
    );

class _WorkoutWarmupMethodsSheet extends StatefulWidget {
  const _WorkoutWarmupMethodsSheet({
    required this.settings,
    this.availableSetSlots,
  });

  final WorkoutWarmupSettings settings;
  final int? availableSetSlots;

  @override
  State<_WorkoutWarmupMethodsSheet> createState() =>
      _WorkoutWarmupMethodsSheetState();
}

class _WorkoutWarmupMethodsSheetState
    extends State<_WorkoutWarmupMethodsSheet> {
  late List<WorkoutWarmupMethod> _methods;
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _methods = [...widget.settings.methods];
    _selectedId = widget.settings.selectedMethodId;
  }

  bool _fits(WorkoutWarmupMethod method) =>
      widget.availableSetSlots == null ||
      method.sets.length <= widget.availableSetSlots!;

  Future<void> _addMethod() async {
    if (_methods.length >= WorkoutWarmupSettings.maxMethods) return;
    final method = await showWarmupMethodEditorSheet(
      context,
      existingNames: _methods.map((item) => item.name).toList(),
    );
    if (!mounted || method == null) return;
    setState(() {
      _methods = [..._methods, method];
      _selectedId = method.id;
    });
  }

  void _accept() {
    final selected = _methods.where((method) => method.id == _selectedId);
    if (selected.length != 1 || !_fits(selected.single)) return;
    Navigator.of(context).pop(widget.settings.copyWith(
      methods: _methods,
      selectedMethodId: _selectedId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioEditorSheet(
      key: const ValueKey('warmup-methods-sheet'),
      title: 'Warm-up methods',
      titleTrailing: IconButton(
        key: const ValueKey('warmup-method-add'),
        tooltip: 'Add warm-up method',
        onPressed: _methods.length >= WorkoutWarmupSettings.maxMethods
            ? null
            : _addMethod,
        icon: const Icon(Icons.add_rounded),
      ),
      pinHeader: true,
      content: Column(
        children: [
          if (widget.availableSetSlots != null &&
              widget.availableSetSlots! <= 0)
            Padding(
              padding: const EdgeInsets.only(bottom: TioSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This Exercise has no available Set slots.',
                  key: const ValueKey('warmup-methods-no-slots'),
                  style: TextStyle(color: colors.warning),
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('warmup-methods-list'),
              shrinkWrap: true,
              itemCount: _methods.length,
              separatorBuilder: (_, __) => Divider(
                color: colors.outlineStrong.withValues(
                  alpha: TioOpacity.opacity10,
                ),
                height: TioSize.dp1,
              ),
              itemBuilder: (context, index) {
                final method = _methods[index];
                final selected = method.id == _selectedId;
                final fits = _fits(method);
                return Semantics(
                  button: true,
                  selected: selected,
                  enabled: fits,
                  label: '${method.name}. ${method.summary}',
                  child: InkWell(
                    key: ValueKey('warmup-method-${method.id}'),
                    onTap: fits
                        ? () => setState(() => _selectedId = method.id)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TioSpacing.md,
                        vertical: TioSpacing.lg,
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: TioSpacing.sm,
                                runSpacing: TioSpacing.xs,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    method.name,
                                    style: TextStyle(
                                      color: fits
                                          ? colors.textPrimary
                                          : colors.textMuted,
                                      fontSize: TioFontSize.size16,
                                      fontWeight: TioFontWeight.w500,
                                    ),
                                  ),
                                  if (method.isRecommended)
                                    Text(
                                      'Recommended',
                                      style: TextStyle(
                                        color: colors.workout,
                                        fontSize: TioFontSize.size13,
                                        fontWeight: TioFontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: TioSpacing.xs),
                              Text(
                                fits
                                    ? method.summary
                                    : '${method.summary} · Needs ${method.sets.length} Set slots',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: TioFontSize.size14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selected && fits) ...[
                          const SizedBox(width: TioSpacing.sm),
                          Icon(Icons.check_rounded, color: colors.workout),
                        ],
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: TioButton.primary(
        key: const ValueKey('warmup-methods-done'),
        label: 'Done',
        expand: true,
        enabled: _methods.any(
          (method) => method.id == _selectedId && _fits(method),
        ),
        onPressed: _accept,
      ),
    );
  }
}

Future<WorkoutWarmupMethod?> showWarmupMethodEditorSheet(
  BuildContext context, {
  List<String> existingNames = const [],
}) =>
    showTioEditorSheet<WorkoutWarmupMethod>(
      context: context,
      useSafeArea: true,
      builder: (_) => _WarmupMethodEditorSheet(existingNames: existingNames),
    );

class _WarmupMethodEditorSheet extends StatefulWidget {
  const _WarmupMethodEditorSheet({required this.existingNames});

  final List<String> existingNames;

  @override
  State<_WarmupMethodEditorSheet> createState() =>
      _WarmupMethodEditorSheetState();
}

class _WarmupMethodEditorSheetState extends State<_WarmupMethodEditorSheet> {
  final TextEditingController _name = TextEditingController();
  final List<WarmupMethodSet> _sets = [
    const WarmupMethodSet(type: WarmupSetLoadType.percent, value: .4, reps: 5),
  ];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _replaceSet(int index, WarmupMethodSet value) {
    setState(() {
      _sets[index] = value;
      _error = null;
    });
  }

  Future<double?> _pickNumber({
    required String title,
    required double value,
    required double minimum,
    required double maximum,
    required double step,
    String suffix = '',
  }) =>
      showTioEditorSheet<double>(
        context: context,
        useSafeArea: true,
        builder: (_) => _WarmupNumberPicker(
          title: title,
          value: value,
          minimum: minimum,
          maximum: maximum,
          step: step,
          suffix: suffix,
        ),
      );

  Future<void> _changeValue(int index) async {
    final current = _sets[index];
    final percent = current.type == WarmupSetLoadType.percent;
    final value = current.value ?? (percent ? .4 : 20);
    final chosen = await _pickNumber(
      title: percent ? 'Percent' : 'Fixed weight (kg)',
      value: percent ? value * 100 : value,
      minimum: percent ? 10 : .5,
      maximum: percent ? 100 : 500,
      step: percent ? 1 : .5,
      suffix: percent ? '%' : ' kg',
    );
    if (!mounted || chosen == null) return;
    _replaceSet(
      index,
      WarmupMethodSet(
        type: current.type,
        value: percent ? chosen / 100 : chosen,
        reps: current.reps,
      ),
    );
  }

  Future<void> _changeReps(int index) async {
    final current = _sets[index];
    final chosen = await _pickNumber(
      title: 'Reps',
      value: current.reps.toDouble(),
      minimum: 1,
      maximum: 30,
      step: 1,
    );
    if (!mounted || chosen == null) return;
    _replaceSet(
      index,
      WarmupMethodSet(
        type: current.type,
        value: current.value,
        reps: chosen.round(),
      ),
    );
  }

  void _changeType(int index, int selected) {
    final type = WarmupSetLoadType.values[selected];
    final current = _sets[index];
    final value = switch (type) {
      WarmupSetLoadType.percent => .4,
      WarmupSetLoadType.fixed => 20.0,
      WarmupSetLoadType.bar => null,
    };
    _replaceSet(
      index,
      WarmupMethodSet(type: type, value: value, reps: current.reps),
    );
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a method name.');
      return;
    }
    if (widget.existingNames.any(
      (existing) => existing.trim().toLowerCase() == name.toLowerCase(),
    )) {
      setState(() => _error = 'A method with this name already exists.');
      return;
    }
    try {
      final method = WorkoutWarmupMethod(
        id: const Uuid().v4(),
        name: name,
        sets: _sets,
      );
      Navigator.of(context).pop(method);
    } on ArgumentError {
      setState(() => _error = 'Review the method Sets and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioEditorSheet(
      key: const ValueKey('warmup-method-editor'),
      title: 'Add warm-up method',
      pinHeader: true,
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TioInput(
              key: const ValueKey('warmup-method-name'),
              controller: _name,
              label: 'Method name',
              hint: 'Enter a name',
              maxLength: 40,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: TioSpacing.lg),
            for (var index = 0; index < _sets.length; index++) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Set ${index + 1}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: TioFontSize.size15,
                        fontWeight: TioFontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    key: ValueKey('warmup-method-remove-set-$index'),
                    onPressed: _sets.length <= 1
                        ? null
                        : () => setState(() => _sets.removeAt(index)),
                    child: Text(
                      'Remove',
                      style: TextStyle(color: colors.danger),
                    ),
                  ),
                ],
              ),
              TioGroupCard(children: [
                Padding(
                  padding: const EdgeInsets.all(TioSpacing.md),
                  child: TioTabSwitcher(
                    tabs: const ['Percent', 'Fixed', 'Bar'],
                    selectedIndex: _sets[index].type.index,
                    onSelected: (value) => _changeType(index, value),
                  ),
                ),
                Divider(
                  color: colors.outlineStrong.withValues(
                    alpha: TioOpacity.opacity10,
                  ),
                  height: TioSize.dp1,
                ),
                if (_sets[index].type != WarmupSetLoadType.bar) ...[
                  _MethodValueRow(
                    key: ValueKey('warmup-method-value-$index'),
                    label: _sets[index].type == WarmupSetLoadType.percent
                        ? 'Percent'
                        : 'Fixed (kg)',
                    value: _sets[index].type == WarmupSetLoadType.percent
                        ? '${(_sets[index].value! * 100).round()}'
                        : _formatNumber(_sets[index].value!),
                    onTap: () => _changeValue(index),
                  ),
                  Divider(
                    color: colors.outlineStrong.withValues(
                      alpha: TioOpacity.opacity10,
                    ),
                    height: TioSize.dp1,
                  ),
                ],
                _MethodValueRow(
                  key: ValueKey('warmup-method-reps-$index'),
                  label: 'Reps',
                  value: '${_sets[index].reps}',
                  onTap: () => _changeReps(index),
                ),
              ]),
              if (index < _sets.length - 1)
                const SizedBox(height: TioSpacing.lg),
            ],
            const SizedBox(height: TioSpacing.lg),
            TioButton.secondary(
              key: const ValueKey('warmup-method-add-set'),
              label: 'Add set',
              leading: const Icon(Icons.add_rounded),
              enabled:
                  _sets.length < RoutineCompositionLimits.maxSetsPerExercise,
              onPressed: () => setState(() {
                _sets.add(const WarmupMethodSet(
                  type: WarmupSetLoadType.percent,
                  value: .4,
                  reps: 5,
                ));
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: TioSpacing.md),
              Text(
                _error!,
                key: const ValueKey('warmup-method-error'),
                style: TextStyle(color: colors.danger),
              ),
            ],
          ],
        ),
      ),
      actions: TioButton.primary(
        key: const ValueKey('warmup-method-save'),
        label: 'Done',
        expand: true,
        enabled: _sets.isNotEmpty,
        onPressed: _save,
      ),
    );
  }
}

class _MethodValueRow extends StatelessWidget {
  const _MethodValueRow({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSpacing.lg,
        ),
        child: Row(children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioFontSize.size15,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size16,
            ),
          ),
        ]),
      ),
    );
  }
}

class _WarmupNumberPicker extends StatefulWidget {
  const _WarmupNumberPicker({
    required this.title,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.step,
    this.suffix = '',
  });

  final String title;
  final double value;
  final double minimum;
  final double maximum;
  final double step;
  final String suffix;

  @override
  State<_WarmupNumberPicker> createState() => _WarmupNumberPickerState();
}

class _WarmupNumberPickerState extends State<_WarmupNumberPicker> {
  late int _selectedIndex;
  late final FixedExtentScrollController _wheel;

  int get _itemCount =>
      ((widget.maximum - widget.minimum) / widget.step).round() + 1;
  double get _selectedValue => widget.minimum + _selectedIndex * widget.step;

  @override
  void initState() {
    super.initState();
    _selectedIndex =
        ((widget.value - widget.minimum) / widget.step).round().clamp(
              0,
              _itemCount - 1,
            );
    _wheel = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return TioEditorSheet(
      title: widget.title,
      pinHeader: true,
      content: SizedBox(
        height: TioSize.dp180,
        child: ListWheelScrollView.useDelegate(
          key: const ValueKey('warmup-method-number-wheel'),
          controller: _wheel,
          itemExtent: TioWheelPickerTokens.itemExtent,
          perspective: TioWheelPickerTokens.perspective,
          diameterRatio: TioWheelPickerTokens.diameterRatio,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            HapticFeedback.selectionClick();
            setState(() => _selectedIndex = index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: _itemCount,
            builder: (context, index) {
              final value = widget.minimum + index * widget.step;
              final selected = index == _selectedIndex;
              return Center(
                child: Container(
                  width: TioSize.dp160,
                  height: TioSize.dp36,
                  alignment: Alignment.center,
                  decoration: selected
                      ? BoxDecoration(
                          color: colors.textPrimary.withValues(
                            alpha: TioOpacity.opacity05,
                          ),
                          borderRadius: BorderRadius.circular(TioRadius.sm),
                        )
                      : null,
                  child: Text(
                    '${_formatNumber(value)}${widget.suffix}',
                    style: TextStyle(
                      color: colors.textPrimary.withValues(
                        alpha: selected
                            ? TioOpacity.opacity100
                            : TioOpacity.opacity38,
                      ),
                      fontSize: TioFontSize.size20,
                      fontWeight:
                          selected ? TioFontWeight.w700 : TioFontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: TioButton.primary(
        label: 'Done',
        expand: true,
        onPressed: () => Navigator.of(context).pop(_selectedValue),
      ),
    );
  }
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
