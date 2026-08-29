import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Presentation-only startup surface.
///
/// Session resolution, timeout policy, and destination routing are owned by
/// the app-level bootstrap controller and GoRouter redirect policy.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.failureMessage,
    this.onRetry,
  });

  final String? failureMessage;
  final Future<void> Function()? onRetry;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    final retry = widget.onRetry;
    if (_isRetrying || retry == null) return;

    setState(() => _isRetrying = true);
    try {
      await retry();
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final failureMessage = widget.failureMessage;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: Align(
          alignment: const Alignment(0, -0.3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TIO',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioFontSize.size44,
                  fontWeight: TioFontWeight.w900,
                ),
              ),
              const SizedBox(height: TioSize.dp48),
              if (failureMessage == null || _isRetrying)
                CircularProgressIndicator(
                  color: colors.textPrimary,
                  strokeWidth: TioStroke.width25,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TioSpacing.xxl,
                  ),
                  child: Column(
                    children: [
                      Text(
                        failureMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: TioFontSize.size14,
                          height: TioLineHeight.height140,
                        ),
                      ),
                      const SizedBox(height: TioSpacing.lg),
                      TextButton(
                        onPressed: widget.onRetry == null ? null : _handleRetry,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: TioFontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
