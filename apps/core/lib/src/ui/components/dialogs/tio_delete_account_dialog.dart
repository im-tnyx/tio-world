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
      backgroundColor: colors.background.withAlpha(245),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Top Right Close Button ──
            Positioned(
              top: TioSpacing.medium,
              right: TioSpacing.large,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.textPrimary.withAlpha(25),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),

            // ── Center Content Step ──
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large),
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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This means all your saved progress will be deleted permanently.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "This action can't be reversed",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.danger,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 36),

        // Keep Account Button (Primary White)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text(
              'Keep Account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Delete Button (Translucent Red)
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () => setState(() => _step = DeleteAccountStep.holdToDelete),
            style: FilledButton.styleFrom(
              backgroundColor: colors.danger.withAlpha(35),
              foregroundColor: colors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'to delete all your progress permanently.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
        ),

        const SizedBox(height: 48),

        // Countdown Text
        AnimatedBuilder(
          animation: _holdController,
          builder: (context, _) {
            final isHolding = _holdController.value > 0;
            return Container(
              height: 44,
              alignment: Alignment.center,
              child: isHolding
                  ? Text(
                      '$_remainingSeconds',
                      style: TextStyle(
                        color: colors.danger,
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),

        const SizedBox(height: 12),

        // ── Interactive 5-Second Hold Button ──
        GestureDetector(
          key: const ValueKey('hold_to_delete_button'),
          onTapDown: (_) => _onHoldStarted(),
          onTapUp: (_) => _onHoldReleased(),
          onTapCancel: () => _onHoldReleased(),
          child: SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Track
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 6,
                    color: colors.textPrimary.withAlpha(25),
                  ),
                ),

                // Animated 5-Second Progress Arc
                AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, _) => SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: _holdController.value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: colors.danger,
                    ),
                  ),
                ),

                // Center Red Circle Button
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: TioDialogTokens.deleteHoldFillColor,
                    boxShadow: [
                      BoxShadow(
                        color: colors.danger.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isDeleting
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: TioDialogTokens.deleteHoldContentColor,
                            strokeWidth: 2.5,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 56),

        // Keep Account Button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text(
              'Keep Account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.primary.withAlpha(30),
          ),
          child: Icon(
            Icons.lock_open_rounded,
            size: 38,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Account Deleted',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Your account and all associated data have been permanently removed.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: colors.textPrimary,
              foregroundColor: colors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}
