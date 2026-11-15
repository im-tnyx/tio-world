import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/workout_warmup_calculator.dart';

Future<List<WarmupCalculatedSet>?> showWorkoutWarmupCalculatorSheet(
  BuildContext context, {
  required WorkoutWarmupSettings settings,
  required int availableSlots,
  double? initialWeightKg,
  bool isDumbbell = false,
  VoidCallback? onOpenSettings,
}) =>
    showTioEditorSheet<List<WarmupCalculatedSet>>(
      context: context,
      useSafeArea: true,
      builder: (_) => _WorkoutWarmupCalculatorEditor(
        settings: settings,
        availableSlots: availableSlots,
        initialWeightKg: initialWeightKg,
        isDumbbell: isDumbbell,
        onOpenSettings: onOpenSettings,
      ),
    );

class _WorkoutWarmupCalculatorEditor extends StatefulWidget {
  const _WorkoutWarmupCalculatorEditor({
    required this.settings,
    required this.availableSlots,
    this.initialWeightKg,
    this.isDumbbell = false,
    this.onOpenSettings,
  });

  final WorkoutWarmupSettings settings;
  final int availableSlots;
  final double? initialWeightKg;
  final bool isDumbbell;
  final VoidCallback? onOpenSettings;

  @override
  State<_WorkoutWarmupCalculatorEditor> createState() =>
      _WorkoutWarmupCalculatorEditorState();
}

class _WorkoutWarmupCalculatorEditorState
    extends State<_WorkoutWarmupCalculatorEditor> {
  late final TextEditingController _weight;

  WorkoutWarmupMethod get _method => widget.settings.selectedMethod;
  double get _roundingKg => widget.isDumbbell
      ? widget.settings.dumbbellRoundingKg
      : widget.settings.plateRoundingKg;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: widget.initialWeightKg != null && widget.initialWeightKg! > 0
          ? _formatWeight(widget.initialWeightKg!)
          : '',
    );
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  List<WarmupCalculatedSet>? _calculate() {
    final target = double.tryParse(_weight.text);
    final hasPercent =
        _method.sets.any((set) => set.type == WarmupSetLoadType.percent);
    if (hasPercent && (target == null || !target.isFinite || target <= 0)) {
      return null;
    }
    try {
      return WorkoutWarmupCalculator.calculateMethod(
        method: _method,
        workingWeightKg: target,
        roundingKg: _roundingKg,
      );
    } on ArgumentError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final preview = _calculate();
    final canInsert = preview != null &&
        preview.length <= widget.availableSlots &&
        widget.settings.enabled;

    return TioEditorSheet(
      key: const ValueKey('warmup-calculator-sheet'),
      title: 'Warm-up Calculator',
      titleTrailing: widget.onOpenSettings == null
          ? null
          : IconButton(
              key: const ValueKey('warmup-calculator-settings'),
              tooltip: 'Warm-up Calculator Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenSettings?.call();
              },
            ),
      pinHeader: true,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(
              color: colors.outlineStrong.withValues(
                alpha: TioOpacity.opacity10,
              ),
              height: TioSize.dp1,
            ),
            const SizedBox(height: TioSpacing.lg),
            Text(
              'Working weight (kg)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: TioSpacing.sm),
            SizedBox(
              width: TioSize.dp160,
              child: TioInput.compactNumber(
                key: const ValueKey('warmup-target-weight'),
                controller: _weight,
                hint: '–',
                textStyle: const TextStyle(
                  fontSize: TioFontSize.size32,
                  fontWeight: TioFontWeight.w700,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: TioSpacing.lg),
            Text(
              _method.name,
              key: const ValueKey('warmup-calculator-method-name'),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioFontSize.size16,
                fontWeight: TioFontWeight.w600,
              ),
            ),
            const SizedBox(height: TioSpacing.sm),
            TioGroupCard(children: [
              const _WarmupPreviewHeader(),
              for (var index = 0; index < _method.sets.length; index++) ...[
                _WarmupPreviewRow(
                  key: ValueKey('warmup-preview-set-$index'),
                  rule: _method.sets[index],
                  calculated: preview == null ? null : preview[index],
                ),
                if (index < _method.sets.length - 1)
                  Divider(
                    color: colors.outlineStrong.withValues(
                      alpha: TioOpacity.opacity10,
                    ),
                    height: TioSize.dp1,
                  ),
              ],
            ]),
            if (_method.sets.length > widget.availableSlots) ...[
              const SizedBox(height: TioSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'This method needs ${_method.sets.length} Set slots; only ${widget.availableSlots} are available.',
                  key: const ValueKey('warmup-set-limit-message'),
                  style: TextStyle(color: colors.warning),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TioButton.primary(
            key: const ValueKey('warmup-add-sets'),
            label: 'Insert warm-up sets',
            expand: true,
            enabled: canInsert,
            onPressed: () => Navigator.of(context).pop(preview),
          ),
          TextButton(
            key: const ValueKey('warmup-calculator-cancel'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmupPreviewHeader extends StatelessWidget {
  const _WarmupPreviewHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Container(
      width: double.infinity,
      color: colors.surfaceVariant,
      padding: const EdgeInsets.symmetric(
        vertical: TioSpacing.sm,
        horizontal: TioSpacing.lg,
      ),
      child: Row(children: [
        const SizedBox(width: TioSize.dp32),
        Expanded(
          child: Text(
            'Method',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: TioFontSize.size10,
              fontWeight: TioFontWeight.w700,
              letterSpacing: TioLetterSpacing.positive05,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Warm-up',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: TioFontSize.size10,
              fontWeight: TioFontWeight.w700,
              letterSpacing: TioLetterSpacing.positive05,
            ),
          ),
        ),
      ]),
    );
  }
}

class _WarmupPreviewRow extends StatelessWidget {
  const _WarmupPreviewRow({
    required this.rule,
    required this.calculated,
    super.key,
  });

  final WarmupMethodSet rule;
  final WarmupCalculatedSet? calculated;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.lg,
      ),
      child: Row(children: [
        SizedBox(
          width: TioSize.dp32,
          child: Text(
            'W',
            style: TextStyle(
              color: colors.warning,
              fontWeight: TioFontWeight.w700,
              fontSize: TioFontSize.size15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            rule.summary,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.workout,
              fontSize: TioFontSize.size15,
              fontWeight: TioFontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            calculated?.loadKg == null
                ? '–'
                : '${_formatWeight(calculated!.loadKg)} kg × ${calculated!.reps}',
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: TioFontSize.size15,
              fontWeight: TioFontWeight.w500,
            ),
          ),
        ),
      ]),
    );
  }
}

String _formatWeight(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
