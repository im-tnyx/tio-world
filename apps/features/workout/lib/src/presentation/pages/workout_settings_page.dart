import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../controllers/workout_runtime_settings_controller.dart';
import '../library/routines/routine_rest_timer_sheet.dart';

/// Workout-owned preferences; persistence remains device-local and owner-scoped.
class WorkoutSettingsPage extends StatefulWidget {
  const WorkoutSettingsPage({
    required this.controller,
    super.key,
  });

  final WorkoutRuntimeSettingsController controller;

  @override
  State<WorkoutSettingsPage> createState() => _WorkoutSettingsPageState();
}

class _WorkoutSettingsPageState extends State<WorkoutSettingsPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
    unawaited(widget.controller.loadRestTimerVibration());
  }

  Future<void> _editDefaultRestTimer() async {
    final controller = widget.controller;
    await controller.load();
    if (!mounted) return;
    if (!controller.isReady) {
      _showMessage('Could not load Workout Settings. Try again.');
      return;
    }

    final selected = await showRoutineRestTimerSheet(
      context: context,
      initialNormalRestSeconds: controller.effectiveDefaultRestSeconds,
      initialWarmUpRestSeconds: null,
      hasWarmUpSets: false,
    );
    if (!mounted || selected == null) return;

    try {
      await controller.setDefaultRestSeconds(selected.normalRestSeconds);
    } catch (_) {
      if (mounted) _showMessage('Could not save Default Rest Timer. Try again.');
    }
  }

  Future<void> _setRestTimerVibration(bool enabled) async {
    try {
      await widget.controller.setRestTimerVibrationEnabled(enabled);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save Rest Timer Vibration. Try again.');
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: TioAppBar(
        backgroundColor: colors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(color: colors.textPrimary),
        title: Text(
          'Workout Settings',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            if (controller.isLoading) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }
            if (!controller.isReady) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(TioSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load Workout Settings.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                      const SizedBox(height: TioSpacing.md),
                      TioButton.secondary(
                        key: const ValueKey('workout-settings-retry'),
                        label: 'Retry',
                        onPressed: () => unawaited(controller.load()),
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.lg,
                vertical: TioSpacing.md,
              ),
              children: [
                TioGroupCard(
                  children: [
                    TioSettingsValueRow(
                      key: const ValueKey('workout-default-rest-timer'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.timer_outlined,
                      ),
                      label: 'Default Rest Timer',
                      value: Text(
                        controller.defaultRestLabel,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: TioFontWeight.w600,
                          fontSize: TioFontSize.size14,
                        ),
                      ),
                      showEditAffordance: false,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                        size: TioSize.dp22,
                      ),
                      onTap: controller.isSaving ? null : _editDefaultRestTimer,
                    ),
                    TioSettingsValueRow(
                      key: const ValueKey('workout-rest-timer-vibration'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.vibration_rounded,
                      ),
                      label: 'Rest Timer Vibration',
                      showEditAffordance: false,
                      value: controller.isVibrationLoading
                          ? const CircularProgressIndicator()
                          : controller.isVibrationReady
                              ? Switch.adaptive(
                                  key: const ValueKey(
                                    'workout-rest-timer-vibration-switch',
                                  ),
                                  value: controller.restTimerVibrationEnabled,
                                  onChanged: controller.isVibrationSaving
                                      ? null
                                      : (enabled) =>
                                          unawaited(_setRestTimerVibration(enabled)),
                                )
                              : TioButton.secondary(
                                  key: const ValueKey(
                                    'workout-rest-timer-vibration-retry',
                                  ),
                                  label: 'Retry',
                                  onPressed: () => unawaited(
                                    controller.loadRestTimerVibration(),
                                  ),
                                ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
