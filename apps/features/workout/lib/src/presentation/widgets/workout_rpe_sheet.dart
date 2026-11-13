import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Shows the bottom sheet for logging or selecting a set or workout RPE.
Future<double?> showWorkoutRpeSheet({
  required BuildContext context,
  int? setNumber,
  double? loadKg,
  int? reps,
  double? initialRpe,
  String? title,
  String? subtitle,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => WorkoutRpeSheet(
      setNumber: setNumber,
      loadKg: loadKg,
      reps: reps,
      initialRpe: initialRpe,
      title: title,
      subtitle: subtitle,
      onDone: (rpe) => Navigator.of(sheetContext).pop(rpe),
    ),
  );
}

class RpeMetadata {
  const RpeMetadata({required this.title, required this.description});

  final String title;
  final String description;

  static final Map<double, RpeMetadata> scale = {
    10.0: const RpeMetadata(
      title: 'Max Effort',
      description: "Couldn't have done more reps",
    ),
    9.5: const RpeMetadata(
      title: 'Near Max Effort',
      description: 'Could have maybe done 1 more rep',
    ),
    9.0: const RpeMetadata(
      title: 'Very Hard Effort',
      description: 'Could have done 1 more rep',
    ),
    8.5: const RpeMetadata(
      title: 'Hard Effort',
      description: 'Could have maybe done 2 more reps',
    ),
    8.0: const RpeMetadata(
      title: 'Hard Effort',
      description: 'Could have done 2 more reps',
    ),
    7.5: const RpeMetadata(
      title: 'Vigorous Effort',
      description: 'Could have maybe done 3 more reps',
    ),
    7.0: const RpeMetadata(
      title: 'Moderate Effort',
      description: 'Could have done 3 more reps',
    ),
    6.0: const RpeMetadata(
      title: 'Light Effort',
      description: 'Could have done 4 or more reps',
    ),
  };

  static const List<double> values = [
    6.0,
    7.0,
    7.5,
    8.0,
    8.5,
    9.0,
    9.5,
    10.0,
  ];

  static String format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

class WorkoutRpeSheet extends StatefulWidget {
  const WorkoutRpeSheet({
    required this.onDone,
    this.setNumber,
    this.loadKg,
    this.reps,
    this.initialRpe,
    this.title,
    this.subtitle,
    super.key,
  });

  final int? setNumber;
  final double? loadKg;
  final int? reps;
  final double? initialRpe;
  final String? title;
  final String? subtitle;
  final ValueChanged<double?> onDone;

  @override
  State<WorkoutRpeSheet> createState() => _WorkoutRpeSheetState();
}

class _WorkoutRpeSheetState extends State<WorkoutRpeSheet> {
  double? _selectedRpe;

  @override
  void initState() {
    super.initState();
    _selectedRpe = widget.initialRpe;
  }

  void _onSelect(double value) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedRpe == value) {
        _selectedRpe = null;
      } else {
        _selectedRpe = value;
      }
    });
  }

  void _onDragUpdate(double dx, double totalWidth) {
    if (totalWidth <= 0) return;
    final slotWidth = totalWidth / RpeMetadata.values.length;
    final index =
        (dx / slotWidth).floor().clamp(0, RpeMetadata.values.length - 1);
    final value = RpeMetadata.values[index];
    if (_selectedRpe != value) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedRpe = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isSelected = _selectedRpe != null && _selectedRpe! > 0;
    final metadata = isSelected ? RpeMetadata.scale[_selectedRpe!] : null;

    final weightText = widget.loadKg == null || widget.loadKg == 0
        ? '0kg'
        : '${RpeMetadata.format(widget.loadKg!)}kg';
    final repsText = '${widget.reps ?? 0} reps';
    final resolvedTitle = widget.title ?? 'Log Set RPE';
    final resolvedSubtitle = widget.subtitle ??
        'Set ${widget.setNumber ?? 1}: $weightText x $repsText';

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TioRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.lg,
          TioSpacing.md,
          TioSpacing.lg,
          TioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              width: TioSize.dp40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: TioOpacity.opacity40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: TioSpacing.md),

            // Sheet Title
            Text(
              resolvedTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: TioFontWeight.w600,
                  ),
            ),
            const SizedBox(height: TioSpacing.xs),

            // Subtitle: e.g. How hard was this workout? or Set 1: 0kg x 0 reps
            Text(
              resolvedSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: TioSpacing.xl),

            // Large Number (0 in muted grey or selected RPE in white)
            Text(
              isSelected ? RpeMetadata.format(_selectedRpe!) : '0',
              style: (Theme.of(context).textTheme.displayLarge ??
                      const TextStyle())
                  .copyWith(
                fontWeight: TioFontWeight.w700,
                color: isSelected
                    ? colors.textPrimary
                    : colors.textSecondary.withValues(alpha: TioOpacity.opacity50),
                height: 1.1,
              ),
            ),
            const SizedBox(height: TioSpacing.xs),

            // Effort Title Label (Select RPE or Vigorous Effort)
            Text(
              isSelected ? (metadata?.title ?? '') : 'Select RPE',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: TioFontWeight.w600,
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: TioSpacing.xs),

            // Description Label (Could have maybe done 3 more reps)
            SizedBox(
              height: 20,
              child: Text(
                isSelected ? (metadata?.description ?? '') : '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
              ),
            ),
            const SizedBox(height: TioSpacing.xl),

            // Horizontal Selector Capsule Bar / Slider (6, 7, 7.5, 8, 8.5, 9, 9.5, 10)
            LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final count = RpeMetadata.values.length;
                final slotWidth = totalWidth / count;
                final selectedIndex = _selectedRpe != null
                    ? RpeMetadata.values.indexOf(_selectedRpe!)
                    : -1;

                return GestureDetector(
                  key: const ValueKey('rpe-slider-track'),
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      _onDragUpdate(details.localPosition.dx, totalWidth),
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details.localPosition.dx, totalWidth),
                  child: Container(
                    height: TioSize.dp52,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(TioSize.dp26),
                    ),
                    child: Stack(
                      children: [
                        if (selectedIndex != -1)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: TioDuration.ms150),
                            curve: Curves.easeOutCubic,
                            left: selectedIndex * slotWidth +
                                (slotWidth - TioSize.dp40) / 2,
                            top: (TioSize.dp52 - TioSize.dp40) / 2,
                            width: TioSize.dp40,
                            height: TioSize.dp40,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            for (int i = 0; i < count; i++)
                              Expanded(
                                child: GestureDetector(
                                  key: ValueKey(
                                    'rpe-option-${RpeMetadata.format(RpeMetadata.values[i])}',
                                  ),
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _onSelect(RpeMetadata.values[i]),
                                  child: Center(
                                    child: Text(
                                      RpeMetadata.format(RpeMetadata.values[i]),
                                      style: TextStyle(
                                        color: i == selectedIndex
                                            ? colors.onPrimary
                                            : colors.textPrimary,
                                        fontSize: i == selectedIndex
                                            ? TioFontSize.size15
                                            : TioFontSize.size14,
                                        fontWeight: i == selectedIndex
                                            ? TioFontWeight.w700
                                            : TioFontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: TioSpacing.xl),

            // Reusable Done Button aligned with Core TioButton contract
            Theme(
              data: Theme.of(context).copyWith(
                filledButtonTheme: FilledButtonThemeData(
                  style: FilledButton.styleFrom(
                    backgroundColor: isSelected
                        ? colors.success
                        : colors.surfaceVariant,
                    foregroundColor: TioPalette.white,
                  ),
                ),
              ),
              child: TioButton.primary(
                key: const ValueKey('rpe-sheet-done-button'),
                label: 'Done',
                trailing: const Icon(
                  Icons.check_rounded,
                  size: TioSize.dp20,
                  color: TioPalette.white,
                ),
                expand: true,
                onPressed: () => widget.onDone(_selectedRpe ?? 0.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
