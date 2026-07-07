import 'package:flutter/material.dart';

class WelcomeBackdrop extends StatelessWidget {
  const WelcomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        Image.asset(
          'assets/landing_screen.png',
          package: 'tio_feature_welcome',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        // Dark Gradient Overlay to ensure readability of text and buttons
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.85),
                Colors.black,
              ],
              stops: const [0.0, 0.4, 0.75, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
