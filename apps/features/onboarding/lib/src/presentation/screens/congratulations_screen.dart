import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

/// 1:1 Pixel-perfect implementation of the Tio Onboarding & Welcome Back Celebration Screen.
///
/// Features:
/// - Hero background image with trophy (`assets/image/congratulations.webp`)
/// - Dynamic falling golden confetti animation
/// - Tio brand wordmark at top-left
/// - "You're in, [Name]!" or "Welcome back, [Name]!" headline
/// - Clean subtitle
/// - High-contrast "Let's go!" primary action button
class CongratulationsScreen extends StatefulWidget {
  const CongratulationsScreen({
    this.userName,
    this.isWelcomeBack = false,
    this.onContinue,
    super.key,
  });

  final String? userName;
  final bool isWelcomeBack;
  final VoidCallback? onContinue;

  @override
  State<CongratulationsScreen> createState() => _CongratulationsScreenState();
}

class _CongratulationsScreenState extends State<CongratulationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;
  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: TioDuration.ms3600),
    )..forward();

    // Confetti physics are one-off celebration composition data, not reusable
    // design-token roles.
    for (int i = 0; i < 65; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble() * 0.4 - 0.45,
          speed: 0.85 + _random.nextDouble() * 0.55,
          size: 7.0 + _random.nextDouble() * 12.0,
          aspectRatio: 0.35 + _random.nextDouble() * 0.5,
          rotation: _random.nextDouble() * math.pi * 2,
          rotationSpeed: (_random.nextDouble() - 0.5) * 5.0,
          flipSpeed: 2.0 + _random.nextDouble() * 4.0,
          swaySpeed: 1.2 + _random.nextDouble() * 2.5,
          swayMagnitude: 12.0 + _random.nextDouble() * 22.0,
          color: _getConfettiColor(_random.nextInt(5)),
        ),
      );
    }
  }

  Color _getConfettiColor(int index) {
    return switch (index) {
      0 => TioDomainColors.celebrationGoldPrimary,
      1 => TioDomainColors.celebrationGoldSecondary,
      2 => TioDomainColors.celebrationWarmAccent,
      3 => TioDomainColors.celebrationGoldHighlight,
      _ => TioDomainColors.celebrationGoldMetallic,
    };
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (widget.onContinue != null) {
      widget.onContinue!();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final displayName =
        (widget.userName != null && widget.userName!.trim().isNotEmpty)
            ? widget.userName!.trim()
            : 'Champion';

    final title = widget.isWelcomeBack
        ? 'Welcome back,\n$displayName!'
        : "You're in,\n$displayName!";

    final subtitle = widget.isWelcomeBack
        ? "Good to see you again — let's jump straight into Tio!"
        : "You're all set — let's jump straight into Tio!";

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Transparent system bars are an edge-to-edge framework requirement; the
      // visible media/background colors are governed below.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: colors.mediaBackground,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.58,
              child: Image.asset(
                'assets/image/congratulations.webp',
                package: 'tio_core',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 1.0],
                    colors: [
                      colors.mediaBackground.withValues(
                        alpha: TioOpacity.opacity0,
                      ),
                      colors.mediaBackground.withAlpha(TioAlpha.alpha221),
                      colors.mediaBackground,
                    ],
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.lg,
                  vertical: TioSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        left: TioSpacing.xs,
                        top: TioSpacing.xs,
                      ),
                      child: Text(
                        'tio',
                        style: TextStyle(
                          fontSize: TioFontSize.size28,
                          fontWeight: TioFontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: colors.onMediaPrimary,
                          letterSpacing: TioLetterSpacing.negative10,
                          shadows: [
                            Shadow(
                              color: colors.mediaBackground.withValues(
                                alpha: TioOpacity.opacity60,
                              ),
                              blurRadius: TioSize.dp8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: TioFontSize.size38,
                              fontWeight: TioFontWeight.w800,
                              color: colors.onMediaPrimary,
                              height: TioLineHeight.height115,
                              letterSpacing: TioLetterSpacing.negative05,
                            ),
                          ),
                          const SizedBox(height: TioSize.dp14),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: TioSpacing.lg,
                            ),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: TioFontSize.size16,
                                fontWeight: TioFontWeight.w400,
                                color: colors.onMediaPrimary.withValues(
                                  alpha: TioOpacity.opacity85,
                                ),
                                height: TioLineHeight.height140,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TioSize.dp48),
                    TioButton.primary(
                      key: const ValueKey('congratulations-lets-go-button'),
                      label: "Let's go!",
                      expand: true,
                      onPressed: _handleContinue,
                    ),
                    const SizedBox(height: TioSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.aspectRatio,
    required this.rotation,
    required this.rotationSpeed,
    required this.flipSpeed,
    required this.swaySpeed,
    required this.swayMagnitude,
    required this.color,
  });

  double x;
  double y;
  final double speed;
  final double size;
  final double aspectRatio;
  double rotation;
  final double rotationSpeed;
  final double flipSpeed;
  final double swaySpeed;
  final double swayMagnitude;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.progress});

  final List<_ConfettiParticle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1.0) return;

    final alpha = progress > 0.85
        ? (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0)
        : 1.0;

    for (final p in particles) {
      final currentY = (p.y + progress * p.speed * 1.3) * size.height;
      if (currentY > size.height + 40 || currentY < -60) continue;

      final sway =
          math.sin(progress * math.pi * 2 * p.swaySpeed + p.x * 10) *
              p.swayMagnitude;
      final currentX = (p.x * size.width) + sway;
      final currentRot = p.rotation + progress * p.rotationSpeed * math.pi * 2;
      final flip = math
          .cos(p.rotation + progress * p.flipSpeed * math.pi * 2)
          .abs()
          .clamp(0.12, 1.0);

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate(currentRot);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      final w = p.size * flip;
      final h = p.size * p.aspectRatio;
      final rRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rRect, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
