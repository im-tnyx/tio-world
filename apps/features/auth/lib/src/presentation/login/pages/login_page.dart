import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to continue your fitness journey.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Truecaller Login Placeholder
              _SocialLoginButton(
                icon: Icons.phone_android_outlined,
                label: 'Continue with Truecaller',
                color: const Color(0xFF25D366),
                onTap: () {
                  // Complete auth mock
                  context.go('/');
                },
              ),
              const SizedBox(height: 16),

              // Google Login Placeholder
              _SocialLoginButton(
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                color: Colors.white,
                textColor: Colors.black,
                onTap: () {
                  context.go('/');
                },
              ),
              const SizedBox(height: 16),

              // Phone/Email Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.white10)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'OR',
                      style: TextStyle(color: colors.textMuted, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: Colors.white10)),
                ],
              ),
              const SizedBox(height: 24),

              // Phone Login
              TioButton.secondary(
                label: 'Continue with Phone Number',
                expand: true,
                onPressed: () {
                  context.go('/');
                },
              ),
              const SizedBox(height: 16),

              // Email Login
              TioButton.ghost(
                label: 'Continue with Email Address',
                expand: true,
                onPressed: () {
                  context.go('/');
                },
              ),
              const Spacer(),

              // Legal text disclaimer
              Align(
                alignment: Alignment.center,
                child: Text(
                  'By signing in, you agree to our Terms & Privacy Policy.',
                  style: TextStyle(color: colors.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
