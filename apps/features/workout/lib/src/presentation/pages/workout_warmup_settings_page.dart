import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/models/workout_warmup_calculator.dart';
import '../controllers/workout_runtime_settings_controller.dart';
import '../widgets/workout_warmup_methods_sheet.dart';

/// Tio's Warm-up Calculator settings adapted to Tio-World's Core theme.
class WorkoutWarmupSettingsPage extends StatefulWidget {
  const WorkoutWarmupSettingsPage({required this.controller, super.key});
  final WorkoutRuntimeSettingsController controller;

  @override
  State<WorkoutWarmupSettingsPage> createState() =>
      _WorkoutWarmupSettingsPageState();
}

class _WorkoutWarmupSettingsPageState extends State<WorkoutWarmupSettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.controller.loadWarmupSettings());
    });
  }

  void _showError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content: Text('Could not save Warm-up Calculator. Try again.')));
  }

  Future<void> _save(WorkoutWarmupSettings settings) async {
    try {
      await widget.controller.setWarmupSettings(settings);
    } catch (_) {
      _showError();
    }
  }

  Future<void> _chooseMethod(WorkoutWarmupSettings settings) async {
    final chosen = await showWorkoutWarmupMethodsSheet(
      context,
      settings: settings,
    );
    if (chosen != null && mounted) {
      await _save(chosen);
    }
  }

  Future<void> _chooseRounding(
    WorkoutWarmupSettings settings, {
    required bool dumbbell,
  }) async {
    final options = dumbbell
        ? WorkoutWarmupSettings.dumbbellRoundingOptions
        : WorkoutWarmupSettings.plateRoundingOptions;
    final selected = await showTioEditorSheet<double>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => TioEditorSheet(
        title: dumbbell ? 'Dumbbell Rounding' : 'Plate Rounding',
        content: TioCard(
          child: Column(children: [
            for (final value in options)
              ListTile(
                key: ValueKey('warmup-rounding-$value'),
                title: Text('${_formatKg(value)} kg'),
                trailing: value ==
                        (dumbbell
                            ? settings.dumbbellRoundingKg
                            : settings.plateRoundingKg)
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(value),
              ),
          ]),
        ),
      ),
    );
    if (selected != null && mounted) {
      await _save(dumbbell
          ? settings.copyWith(dumbbellRoundingKg: selected)
          : settings.copyWith(plateRoundingKg: selected));
    }
  }

  static String _formatKg(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  Widget _divider(BuildContext context) => Divider(
        color: context.tioColors.outlineStrong,
        height: TioSize.dp1,
      );

  Widget _settingRow(
    BuildContext context, {
    required Key key,
    required String label,
    String? description,
    String? value,
    required VoidCallback? onTap,
  }) {
    final colors = context.tioColors;
    return InkWell(
      key: key,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.lg,
          vertical: TioSize.dp20,
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: TioFontSize.size16,
                      fontWeight: TioFontWeight.w500,
                    )),
                if (description != null) ...[
                  const SizedBox(height: TioSpacing.sm),
                  Text(description,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: TioFontSize.size13,
                        height: 1.4,
                      )),
                ],
              ],
            ),
          ),
          if (value != null) ...[
            Text(value,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: TioFontSize.size16,
                )),
            const SizedBox(width: TioSpacing.sm),
          ],
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        leading: BackButton(color: colors.textPrimary),
        title: Text('Warm-up Calculator',
            style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioFontSize.size20,
                fontWeight: TioFontWeight.w800)),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final settings = controller.warmupSettings;
            if (controller.isWarmupLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (settings == null) {
              return Center(
                child: TioButton.secondary(
                  label: 'Retry',
                  onPressed: () => unawaited(controller.loadWarmupSettings()),
                ),
              );
            }
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TioSpacing.lg,
                  TioSpacing.lg,
                  TioSpacing.lg,
                  TioSpacing.xl,
                ),
                child: Text(
                  'Use the warm-up calculator to quickly add percentage-based warm-up sets to exercises.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: TioFontSize.size14,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                key: const ValueKey('warmup-calculator-enabled'),
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                  vertical: TioSize.dp20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('Warm-up Calculator',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: TioFontSize.size16,
                              fontWeight: TioFontWeight.w500,
                            )),
                      ),
                      Switch.adaptive(
                        key: const ValueKey('warmup-calculator-switch'),
                        value: settings.enabled,
                        onChanged: controller.isWarmupSaving
                            ? null
                            : (enabled) => unawaited(
                                _save(settings.copyWith(enabled: enabled))),
                      ),
                    ]),
                    const SizedBox(height: TioSpacing.sm),
                    Text(
                      'When active, tap the three dots next to an exercise to add warm-up sets.',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: TioFontSize.size13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _divider(context),
              _settingRow(context,
                  key: const ValueKey('warmup-method'),
                  label: 'Warmup Method',
                  value: settings.selectedMethod.name,
                  onTap: controller.isWarmupSaving
                      ? null
                      : () => _chooseMethod(settings)),
              _divider(context),
              _settingRow(context,
                  key: const ValueKey('warmup-plate-rounding'),
                  label: 'Plate Rounding',
                  description:
                      'Set preferred plate weight increments for your warm-up calculations.',
                  value: '${_formatKg(settings.plateRoundingKg)} kg',
                  onTap: controller.isWarmupSaving
                      ? null
                      : () => _chooseRounding(settings, dumbbell: false)),
              _divider(context),
              _settingRow(context,
                  key: const ValueKey('warmup-dumbbell-rounding'),
                  label: 'Dumbbell Rounding',
                  description:
                      'Set preferred dumbbell weight increments for your warm-up calculations.',
                  value: '${_formatKg(settings.dumbbellRoundingKg)} kg',
                  onTap: controller.isWarmupSaving
                      ? null
                      : () => _chooseRounding(settings, dumbbell: true)),
              _divider(context),
              const SizedBox(height: TioSize.dp40),
            ]);
          },
        ),
      ),
    );
  }
}
