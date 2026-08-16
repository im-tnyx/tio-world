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
    _additionalInfoController = TextEditingController(text: widget.additionalInfo);
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
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
          // 2-Column Equipment Grid
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _equipmentData.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: TioSpacing.small,
              mainAxisSpacing: TioSpacing.small,
              childAspectRatio: 1.42,
            ),
            itemBuilder: (context, index) {
              final item = _equipmentData[index];
              final isSelected = widget.selectedEquipment.contains(item.equipment);

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  key: ValueKey('equipment-${item.equipment.name}'),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onToggled(item.equipment);
                  },
                  borderRadius: BorderRadius.circular(TioCardTokens.radius),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(TioSpacing.small),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: TioCardTokens.selectedContainerAlpha)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(TioCardTokens.radius),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outlineStrong.withValues(alpha: TioCardTokens.unselectedOutlineAlpha),
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
                                size: 28,
                                color: isSelected ? colors.primary : colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: textTheme.labelLarge?.copyWith(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? colors.primary : colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: TioSpacing.medium),

          // Additional Info Section
          Text(
            'ADDITIONAL INFO',
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: TioSpacing.small),

          TextField(
            controller: _additionalInfoController,
            onChanged: widget.onAdditionalInfoChanged,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'e.g., rowing machine, kettlebells, cable machine, any specialized equipment...',
              hintStyle: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary.withValues(alpha: 0.6),
                height: 1.4,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.large,
                vertical: TioSpacing.medium,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TioRadius.large),
                borderSide: BorderSide(
                  color: colors.outlineStrong.withValues(alpha: TioCardTokens.unselectedOutlineAlpha),
                  width: TioCardTokens.unselectedBorderWidth,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TioRadius.large),
                borderSide: BorderSide(
                  color: colors.outlineStrong.withValues(alpha: TioCardTokens.unselectedOutlineAlpha),
                  width: TioCardTokens.unselectedBorderWidth,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TioRadius.large),
                borderSide: BorderSide(
                  color: colors.primary,
                  width: TioCardTokens.selectedBorderWidth,
                ),
              ),
              filled: true,
              fillColor: colors.surface,
            ),
          ),

          const SizedBox(height: TioSpacing.medium),
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
