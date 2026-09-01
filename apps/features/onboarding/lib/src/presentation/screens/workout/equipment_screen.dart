import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';
import 'workout_screen_components.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({
    required this.selectedEquipment,
    required this.flowPlan,
    required this.onToggled,
    super.key,
    this.errorText,
    this.additionalInfo = '',
    this.onAdditionalInfoChanged,
  });

  final Set<WorkoutEquipment> selectedEquipment;
  final WorkoutFlowPlan flowPlan;
  final ValueChanged<WorkoutEquipment> onToggled;
  final String? errorText;
  final String additionalInfo;
  final ValueChanged<String>? onAdditionalInfoChanged;

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  late final TextEditingController _additionalInfoController;

  static const _equipmentData = [
    _EquipmentOption(
      equipment: WorkoutEquipment.dumbbells,
      title: 'Dumbbells',
      imagePath: 'assets/image/equipments/dumbells.webp',
    ),
    _EquipmentOption(
      equipment: WorkoutEquipment.bench,
      title: 'Bench',
      imagePath: 'assets/image/equipments/bench.webp',
    ),
    _EquipmentOption(
      equipment: WorkoutEquipment.mat,
      title: 'Mat',
      imagePath: 'assets/image/equipments/mat.webp',
    ),
    _EquipmentOption(
      equipment: WorkoutEquipment.barbell,
      title: 'Barbell',
      imagePath: 'assets/image/equipments/barbell.webp',
    ),
    _EquipmentOption(
      equipment: WorkoutEquipment.bands,
      title: 'Resistance bands',
      imagePath: 'assets/image/equipments/resistance_bands.webp',
    ),
    _EquipmentOption(
      equipment: WorkoutEquipment.kettlebell,
      title: 'Kettlebell',
      imagePath: 'assets/image/equipments/kettlebell.webp',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _additionalInfoController =
        TextEditingController(text: widget.additionalInfo);
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return WorkoutScreenScaffold(
      stepId: WorkoutStepId.equipment,
      flowPlan: widget.flowPlan,
      title: 'What equipment do you have at home?',
      description:
          'Select all the equipment you can use for your home workouts.',
      errorText: widget.errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _equipmentData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: TioSpacing.sm,
              mainAxisSpacing: TioSpacing.sm,
              // Equipment-card image composition ratio stays local.
              childAspectRatio: 1.42,
            ),
            itemBuilder: (context, index) {
              final item = _equipmentData[index];
              final isSelected =
                  widget.selectedEquipment.contains(item.equipment);

              return Material(
                // Transparent Material host: visible styling comes from the
                // AnimatedContainer below.
                color: TioPalette.transparent,
                child: InkWell(
                  key: ValueKey('equipment-${item.equipment.name}'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onToggled(item.equipment);
                  },
                  borderRadius: BorderRadius.circular(TioCardTokens.radius),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: TioDuration.ms180),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(TioSpacing.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(
                              alpha: TioCardTokens.selectedContainerAlpha,
                            )
                          : colors.surface,
                      borderRadius: BorderRadius.circular(TioCardTokens.radius),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outlineStrong.withValues(
                                alpha: TioCardTokens.unselectedOutlineAlpha,
                              ),
                        width: isSelected
                            ? TioCardTokens.selectedBorderWidth
                            : TioCardTokens.unselectedBorderWidth,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              item.imagePath,
                              package: 'tio_core',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.fitness_center,
                                size: TioSize.dp28,
                                color: isSelected
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: TioSpacing.xxs),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: TioFontSize.size13,
                            fontWeight: isSelected
                                ? TioFontWeight.w700
                                : TioFontWeight.w600,
                            color: isSelected
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: TioSpacing.md),
          Text(
            'ADDITIONAL INFO',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: TioFontWeight.w700,
              letterSpacing: TioLetterSpacing.positive08,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          TioInput.multiline(
            key: const ValueKey('workout-equipment-input'),
            controller: _additionalInfoController,
            onChanged: (value) => widget.onAdditionalInfoChanged?.call(value),
            maxLines: 4,
            minLines: 3,
            hint:
                'e.g., rowing machine, kettlebells, cable machine, any specialized equipment...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary.withValues(
                alpha: TioOpacity.opacity60,
              ),
              height: TioLineHeight.height140,
            ),
            textStyle:
                textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.lg,
              vertical: TioSpacing.md,
            ),
          ),
          const SizedBox(height: TioSpacing.md),
        ],
      ),
    );
  }
}

class _EquipmentOption {
  const _EquipmentOption({
    required this.equipment,
    required this.title,
    required this.imagePath,
  });

  final WorkoutEquipment equipment;
  final String title;
  final String imagePath;
}
