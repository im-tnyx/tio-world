import 'package:flutter/material.dart';

class WelcomeFeatureItem {
  const WelcomeFeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class WelcomeState {
  const WelcomeState({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.ctaText,
    required this.signInText,
    required this.disclaimerText,
  });

  final String title;
  final String subtitle;
  final List<WelcomeFeatureItem> features;
  final String ctaText;
  final String signInText;
  final String disclaimerText;

  static WelcomeState initial(BuildContext context) {
    return const WelcomeState(
      title: 'TRAIN SMARTER.\nEAT BETTER.\nBE CONSISTENT.',
      subtitle: 'AI guidance.\nPersonalized for you.\nResults that last.',
      features: [
        WelcomeFeatureItem(
          title: 'AI WORKOUT',
          description: 'Smart workout plans for you',
          icon: Icons.fitness_center_outlined,
          color: Color(0xFFEF4444),
        ),
        WelcomeFeatureItem(
          title: 'MEAL PLAN',
          description: 'Personalized diet & meal tracking',
          icon: Icons.restaurant_menu_outlined,
          color: Color(0xFF22C55E),
        ),
        WelcomeFeatureItem(
          title: 'AI COACH',
          description: 'Smart suggestions & real support',
          icon: Icons.psychology_outlined,
          color: Color(0xFF06B6D4),
        ),
      ],
      ctaText: 'Get Started',
      signInText: 'Sign In',
      disclaimerText: 'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
    );
  }
}
