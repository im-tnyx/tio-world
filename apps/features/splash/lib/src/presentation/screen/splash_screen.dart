import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({
    super.key,
    this.onCheckInitialDestination,
    this.failureMessage,
    this.onRetry,
  });

  final Future<String> Function()? onCheckInitialDestination;
  final String? failureMessage;
  final Future<void> Function()? onRetry;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startInitFlow();
    });
  }

  Future<void> _startInitFlow() async {
    final destinationResolver = widget.onCheckInitialDestination;
    if (destinationResolver == null) {
      // Passive mode: app-level router/bootstrap state owns product navigation.
      return;
    }

    String destination;
    try {
      destination = await destinationResolver()
          .timeout(const Duration(seconds: 4), onTimeout: () => AppRoutes.auth.path);
    } catch (_) {
      destination = AppRoutes.auth.path;
    }

    if (mounted) {
      context.go(destination);
    }
  }

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
    final colors = TioTheme.colors(context);
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Center Brand Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/dark_logo.jpg',
                  package: 'tio_feature_splash',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 48),
              if (failureMessage == null || _isRetrying)
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        failureMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: widget.onRetry == null ? null : _handleRetry,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
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
