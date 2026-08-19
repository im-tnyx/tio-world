import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

enum DeleteAccountStep {
  confirm,
  holdToDelete,
  completed,
}

/// Shows the full-screen interactive Delete Account Overlay with 3-step safety:
/// 1. Confirmation: "Are you sure?"
/// 2. Long press/Hold: 5-second animated circular hold button
/// 3. Completed: "Account Deleted"
Future<bool> showTioDeleteAccountOverlay({
  required BuildContext context,
  required Future<void> Function() onDeleteConfirmed,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (dialogContext) => TioDeleteAccountOverlay(
      onDeleteConfirmed: onDeleteConfirmed,
    ),
  );

  return result ?? false;
}

class TioDeleteAccountOverlay extends StatefulWidget {
  const TioDeleteAccountOverlay({
    required this.onDeleteConfirmed,
    super.key,
  });

  final Future<void> Function() onDeleteConfirmed;

  @override
  State<TioDeleteAccountOverlay> createState() =>
      _TioDeleteAccountOverlayState();
}

class _TioDeleteAccountOverlayState extends State<TioDeleteAccountOverlay>
    with SingleTickerProviderStateMixin {
  DeleteAccountStep _step = DeleteAccountStep.confirm;

  late AnimationController _holdController;
  Timer? _countdownTimer;
  int _remainingSeconds = 5;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _executeDelete();
      }
    });

    _holdController.addListener(() {
      final remaining = (5.0 * (1.0 - _holdController.value)).ceil();
      if (remaining != _remainingSeconds && mounted) {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onHoldStarted() {
    if (_isDeleting) return;
    setState(() => _remainingSeconds = 5);
    _holdController.forward(from: 0.0);
  }

  void _onHoldReleased() {
    if (_holdController.isCompleted || _isDeleting) return;
    _holdController.reset();
    setState(() => _remainingSeconds = 5);
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);
    try {
      await widget.onDeleteConfirmed();
      if (mounted) {
        setState(() {
          _step = DeleteAccountStep.completed;
          _isDeleting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Scaffold(
      backgroundColor: colors.background.withAlpha(
        TioDeleteAccountDialogTokens.overlayBackgroundAlpha,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Top Right Close Button ──
            Positioned(
              top: TioSpacing.md,
              right: TioSpacing.lg,
              child: Container(
                width: TioDeleteAccountDialogTokens.closeButtonSize,
                height: TioDeleteAccountDialogTokens.closeButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.textPrimary.withAlpha(
                    TioDeleteAccountDialogTokens.closeContainerAlpha,
                  ),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textPrimary,
                    size: TioDeleteAccountDialogTokens.closeIconSize,
                  ),
                  splashRadius: TioDeleteAccountDialogTokens.closeSplashRadius,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            // ── Center Content Step ──
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
                child: switch (_step) {
                  DeleteAccountStep.confirm => _buildConfirmStep(colors),
                  DeleteAccountStep.holdToDelete => _buildHoldToDeleteStep(colors),
                  DeleteAccountStep.completed => _buildCompletedStep(colors),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1: Confirm Overlay ──
  Widget _buildConfirmStep(TioColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Are you sure?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioDeleteAccountDialogTokens.headlineFontSize,
            fontWeight: TioFontWeight.w800,
            letterSpacing: TioDeleteAccountDialogTokens.headlineLetterSpacing,
          ),
        ),
        const SizedBox(height: TioSpacing.md),
        Text(
          'This means all your saved progress will be deleted permanently.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioDeleteAccountDialogTokens.bodyFontSize,
            height: TioDeleteAccountDialogTokens.bodyLineHeight,
            fontWeight: TioFontWeight.w400,
          ),
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          "This action can't be reversed",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.danger,
            fontSize: TioDeleteAccountDialogTokens.warningFontSize,
            fontWeight: TioFontWeight.w600,
          ),
        ),
        const SizedBox(height: TioDeleteAccountDialogTokens.actionSectionGap),

        // Keep Account Button (Primary White)
        SizedBox(
          width: double.infinity,
          height: TioDeleteAccountDialogTokens.actionButtonHeight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  TioDeleteAccountDialogTokens.actionButtonRadius,
                ),
              ),
            ),
            child: const Text(
              'Keep Account',
              style: TextStyle(
                fontWeight: TioFontWeight.w700,
                fontSize: TioDeleteAccountDialogTokens.actionLabelFontSize,
              ),
            ),
          ),
        ),

        const SizedBox(height: TioSpacing.md),

        // Delete Button (Translucent Red)
        SizedBox(
          width: double.infinity,
          height: TioDeleteAccountDialogTokens.actionButtonHeight,
          child: FilledButton(
            onPressed: () => setState(() => _step = DeleteAccountStep.holdToDelete),
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger.withAlpha(
                TioDeleteAccountDialogTokens.actionContainerAlpha,
              ),
              foregroundColor: colors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  TioDeleteAccountDialogTokens.actionButtonRadius,
                ),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: TioFontWeight.w700,
                fontSize: TioDeleteAccountDialogTokens.actionLabelFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 2: Hold To Delete Overlay (5-Second Hold) ──
  Widget _buildHoldToDeleteStep(TioColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Long press/Hold this\nbutton',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioDeleteAccountDialogTokens.headlineFontSize,
            fontWeight: TioFontWeight.w800,
            letterSpacing: TioDeleteAccountDialogTokens.headlineLetterSpacing,
            height: TioDeleteAccountDialogTokens.holdHeadlineLineHeight,
          ),
        ),
        const SizedBox(height: TioSpacing.md),
        Text(
          'to delete all your progress permanently.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioDeleteAccountDialogTokens.holdBodyFontSize,
            fontWeight: TioFontWeight.w400,
          ),
        ),

        const SizedBox(height: TioDeleteAccountDialogTokens.holdControlTopGap),

        // Countdown Text
        AnimatedBuilder(
          animation: _holdController,
          builder: (context, _) {
            final isHolding = _holdController.value > 0;
            return Container(
              height: TioDeleteAccountDialogTokens.countdownHeight,
              alignment: Alignment.center,
              child: isHolding
                  ? Text(
                      '$_remainingSeconds',
                      style: TextStyle(
                        color: colors.danger,
                        fontSize: TioDeleteAccountDialogTokens.countdownFontSize,
                        fontWeight: TioFontWeight.w900,
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),

        const SizedBox(height: TioSpacing.md),

        // ── Interactive 5-Second Hold Button ──
        GestureDetector(
          key: const ValueKey('hold_to_delete_button'),
          onTapDown: (_) => _onHoldStarted(),
          onTapUp: (_) => _onHoldReleased(),
          onTapCancel: () => _onHoldReleased(),
          child: SizedBox(
            width: TioDeleteAccountDialogTokens.holdControlSize,
            height: TioDeleteAccountDialogTokens.holdControlSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Track
                SizedBox(
                  width: TioDeleteAccountDialogTokens.holdControlSize,
                  height: TioDeleteAccountDialogTokens.holdControlSize,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: TioDeleteAccountDialogTokens.holdStrokeWidth,
                    color: colors.textPrimary.withAlpha(
                      TioDeleteAccountDialogTokens.holdTrackAlpha,
                    ),
                  ),
                ),

                // Animated 5-Second Progress Arc
                AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, _) => SizedBox(
                    width: TioDeleteAccountDialogTokens.holdControlSize,
                    height: TioDeleteAccountDialogTokens.holdControlSize,
                    child: CircularProgressIndicator(
                      value: _holdController.value,
                      strokeWidth: TioDeleteAccountDialogTokens.holdStrokeWidth,
                      strokeCap: StrokeCap.round,
                      color: colors.danger,
                    ),
                  ),
                ),

                // Center Red Circle Button
                Container(
                  width: TioDeleteAccountDialogTokens.holdButtonSize,
                  height: TioDeleteAccountDialogTokens.holdButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TioDeleteAccountDialogTokens.holdFillColor,
                    boxShadow: [
                      BoxShadow(
                        color: colors.danger.withAlpha(
                          TioDeleteAccountDialogTokens.holdGlowAlpha,
                        ),
                        blurRadius: TioDeleteAccountDialogTokens.holdGlowBlurRadius,
                        spreadRadius:
                            TioDeleteAccountDialogTokens.holdGlowSpreadRadius,
                      ),
                    ],
                  ),
                  child: _isDeleting
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: TioDeleteAccountDialogTokens.holdContentColor,
                            strokeWidth:
                                TioDeleteAccountDialogTokens.holdLoadingStrokeWidth,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: TioDeleteAccountDialogTokens.holdActionGap),

        // Keep Account Button
        SizedBox(
          width: double.infinity,
          height: TioDeleteAccountDialogTokens.actionButtonHeight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  TioDeleteAccountDialogTokens.actionButtonRadius,
                ),
              ),
            ),
            child: const Text(
              'Keep Account',
              style: TextStyle(
                fontWeight: TioFontWeight.w700,
                fontSize: TioDeleteAccountDialogTokens.actionLabelFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Completed Overlay ──
  Widget _buildCompletedStep(TioColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: TioDeleteAccountDialogTokens.completedIconContainerSize,
          height: TioDeleteAccountDialogTokens.completedIconContainerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withAlpha(
              TioDeleteAccountDialogTokens.completedIconContainerAlpha,
            ),
          ),
          child: Icon(
            Icons.lock_open_rounded,
            size: TioDeleteAccountDialogTokens.completedIconSize,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: TioDeleteAccountDialogTokens.completedIconGap),
        Text(
          'Account Deleted',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: TioDeleteAccountDialogTokens.completedTitleFontSize,
            fontWeight: TioFontWeight.w800,
          ),
        ),
        const SizedBox(height: TioDeleteAccountDialogTokens.completedTextGap),
        Text(
          'Your account and all associated data have been permanently removed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: TioDeleteAccountDialogTokens.completedBodyFontSize,
            height: TioDeleteAccountDialogTokens.completedBodyLineHeight,
          ),
        ),
        const SizedBox(height: TioDeleteAccountDialogTokens.actionSectionGap),
        SizedBox(
          width: double.infinity,
          height: TioDeleteAccountDialogTokens.actionButtonHeight,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  TioDeleteAccountDialogTokens.actionButtonRadius,
                ),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: TioFontWeight.w700,
                fontSize: TioDeleteAccountDialogTokens.actionLabelFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
