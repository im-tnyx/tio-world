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
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            colors.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: colors.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            colors.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Normally this Column is exactly viewport-height (via the
              // ConstrainedBox minHeight), so Expanded fills the remaining
              // space beneath the wordmark as usual. On a short/scaled
              // viewport where the header alone would exceed that height,
              // IntrinsicHeight lets the Column grow to fit instead of
              // overflowing, and the outer SingleChildScrollView makes that
              // extra height scrollable instead of clipped.
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: TioSize.dp100),
                          child: Text(
                            'TIO',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: TioFontSize.size44,
                              fontWeight: TioFontWeight.w900,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: (failureMessage == null || _isRetrying)
                                ? CircularProgressIndicator(
                                    color: colors.textPrimary,
                                    strokeWidth: TioStroke.width25,
                                  )
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: TioSpacing.xxl,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
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
                                        const SizedBox(
                                          height: TioSpacing.lg,
                                        ),
                                        TextButton(
                                          onPressed: widget.onRetry == null
                                              ? null
                                              : _handleRetry,
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
