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
    unawaited(widget.controller.loadRpeTracking());
    unawaited(widget.controller.loadSmartSupersetScrolling());
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

  Future<void> _setRpeTracking(bool enabled) async {
    try {
      await widget.controller.setRpeTrackingEnabled(enabled);
    } catch (_) {
      if (mounted) _showMessage('Could not save RPE Tracking. Try again.');
    }
  }

  Future<void> _setSmartSupersetScrolling(bool enabled) async {
    try {
      await widget.controller.setSmartSupersetScrollingEnabled(enabled);
    } catch (_) {
      if (mounted) {
        _showMessage('Could not save Smart Superset Scrolling. Try again.');
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
                      value: controller.isLoading
                          ? const CircularProgressIndicator()
                          : controller.isReady
                              ? Text(
                                  controller.defaultRestLabel,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: colors.textSecondary,
                                    fontWeight: TioFontWeight.w600,
                                    fontSize: TioFontSize.size14,
                                  ),
                                )
                              : TioButton.secondary(
                                  key: const ValueKey(
                                    'workout-settings-retry',
                                  ),
                                  label: 'Retry',
                                  onPressed: () => unawaited(controller.load()),
                                ),
                      showEditAffordance: false,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: colors.textMuted,
                        size: TioSize.dp22,
                      ),
                      onTap: controller.isSaving ||
                              controller.isLoading ||
                              !controller.isReady
                          ? null
                          : _editDefaultRestTimer,
                    ),
                    TioSettingsValueRow(
                      key: const ValueKey('workout-rest-timer-vibration'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.vibration_rounded,
                      ),
                      label: 'Rest Timer Vibration',
                      onTap: null,
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
                    TioSettingsValueRow(
                      key: const ValueKey('workout-rpe-tracking'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.speed_rounded,
                      ),
                      label: 'RPE Tracking',
                      onTap: null,
                      showEditAffordance: false,
                      value: controller.isRpeLoading
                          ? const CircularProgressIndicator()
                          : controller.isRpeReady
                              ? Switch.adaptive(
                                  key: const ValueKey(
                                    'workout-rpe-tracking-switch',
                                  ),
                                  value: controller.rpeTrackingEnabled,
                                  onChanged: controller.isRpeSaving
                                      ? null
                                      : (enabled) =>
                                          unawaited(_setRpeTracking(enabled)),
                                )
                              : TioButton.secondary(
                                  key: const ValueKey(
                                    'workout-rpe-tracking-retry',
                                  ),
                                  label: 'Retry',
                                  onPressed: () =>
                                      unawaited(controller.loadRpeTracking()),
                                ),
                    ),
                    TioSettingsValueRow(
                      key: const ValueKey('workout-smart-superset-scrolling'),
                      leading: const TioSettingsLeadingIcon(
                        icon: Icons.swap_vert_rounded,
                      ),
                      label: 'Smart Superset Scrolling',
                      onTap: null,
                      showEditAffordance: false,
                      value: controller.isSmartSupersetScrollingLoading
                          ? const CircularProgressIndicator()
                          : controller.isSmartSupersetScrollingReady
                              ? Switch.adaptive(
                                  key: const ValueKey(
                                    'workout-smart-superset-scrolling-switch',
                                  ),
                                  value: controller
                                      .smartSupersetScrollingEnabled,
                                  onChanged: controller
                                          .isSmartSupersetScrollingSaving
                                      ? null
                                      : (enabled) => unawaited(
                                            _setSmartSupersetScrolling(enabled),
                                          ),
                                )
                              : TioButton.secondary(
                                  key: const ValueKey(
                                    'workout-smart-superset-scrolling-retry',
                                  ),
                                  label: 'Retry',
                                  onPressed: () => unawaited(
                                    controller.loadSmartSupersetScrolling(),
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
