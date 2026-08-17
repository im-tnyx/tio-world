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
      duration: const Duration(milliseconds: 3600),
    )..forward();

    // Generate 65 celebratory golden confetti particles with depth and 3D flip physics
    for (int i = 0; i < 65; i++) {
      _particles.add(
        _ConfettiParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble() * 0.4 - 0.45, // Staggered start from above top edge
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
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Pure Gold
      case 1:
        return const Color(0xFFFFB300); // Amber Gold
      case 2:
        return const Color(0xFFFF9800); // Deep Warm Gold
      case 3:
        return const Color(0xFFFFE082); // Bright Gold Accent
      default:
        return const Color(0xFFFFC107); // Vivid Metallic Gold
    }
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
    final displayName = (widget.userName != null && widget.userName!.trim().isNotEmpty)
        ? widget.userName!.trim()
        : 'Champion';

    final title = widget.isWelcomeBack
        ? 'Welcome back,\n$displayName!'
        : "You're in,\n$displayName!";

    final subtitle = widget.isWelcomeBack
        ? "Good to see you again — let's jump straight into Tio!"
        : "You're all set — let's jump straight into Tio!";

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Hero Trophy Image Background
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

            // 2. Smooth gradient fade from trophy to black content zone
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.3, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),

            // 3. Falling Gold Confetti Particles with 3D Flip
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

            // 4. Foreground Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.large,
                  vertical: TioSpacing.medium,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top-Left Brand Logo
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child: Text(
                        'tio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                          letterSpacing: -1.0,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Centered Text Content
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Design System Reusable Button from tio_core
                    TioButton.primary(
                      key: const ValueKey('congratulations-lets-go-button'),
                      label: "Let's go!",
                      expand: true,
                      onPressed: _handleContinue,
                    ),

                    const SizedBox(height: 8),
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
    if (progress >= 1.0) return; // Fully completed and idle (zero CPU)

    // Smooth fade out in the last 15% of the burst
    final alpha = progress > 0.85
        ? (1.0 - (progress - 0.85) / 0.15).clamp(0.0, 1.0)
        : 1.0;

    for (final p in particles) {
      final currentY = (p.y + progress * p.speed * 1.3) * size.height;
      if (currentY > size.height + 40 || currentY < -60) continue;

      final sway = math.sin(progress * math.pi * 2 * p.swaySpeed + p.x * 10) * p.swayMagnitude;
      final currentX = (p.x * size.width) + sway;
      final currentRot = p.rotation + progress * p.rotationSpeed * math.pi * 2;

      // 3D paper ribbon flip effect
      final flip = math.cos(p.rotation + progress * p.flipSpeed * math.pi * 2).abs().clamp(0.12, 1.0);

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
