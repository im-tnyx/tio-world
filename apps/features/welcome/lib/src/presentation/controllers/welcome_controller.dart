import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/welcome_state.dart';

final welcomeProvider = Provider.autoDispose<WelcomeState>((ref) {
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
        icon: Icons.chat_outlined,
        color: Color(0xFF06B6D4),
      ),
    ],
    ctaText: 'Get Started',
    signInText: 'Sign In',
    disclaimerText: 'By continuing, you agree to our Terms & Conditions and Privacy Policy.',
  );
});
