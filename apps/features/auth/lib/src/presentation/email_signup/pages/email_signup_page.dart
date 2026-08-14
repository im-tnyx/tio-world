import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Email + Password sign-up screen.
/// Tnyx-hub EmailSignupScreen equivalent: Name, Email, Password fields
/// with password strength indicator and toggle visibility.
class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({
    this.signUpWithEmailUseCase,
    this.onSignUpSuccess,
    super.key,
  });

  final SignUpWithEmailUseCase? signUpWithEmailUseCase;
  final ValueChanged<SignInSuccess>? onSignUpSuccess;

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().length < 2) {
      return 'Enter your full name (min 2 characters)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final emailReg = RegExp(r'^[\w.+\-]+@[\w\-]+\.\w{2,}$');
    if (!emailReg.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Returns 0..1 password strength score.
  double _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$&*~%^()]'))) score++;
    return score / 4;
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signUpWithEmailUseCase == null) {
      if (mounted) context.go('/onboarding');
      return;
    }

    try {
      final result = await widget.signUpWithEmailUseCase!(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (!mounted) return;
      switch (result) {
        case SignInSuccess():
          widget.onSignUpSuccess?.call(result);
          context.go('/onboarding');
        case SignInCancelled():
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    final textTheme = Theme.of(context).textTheme;
    final password = _passwordController.text;
    final strength = _passwordStrength(password);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Create account',
                    style: textTheme.displayLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start your health and fitness journey today.',
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Full name
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colors.textPrimary),
                    decoration: _inputDecoration(
                      context,
                      label: 'Full Name',
                      hint: 'Rahul Sharma',
                      prefixIcon: Icons.person_outline_rounded,
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colors.textPrimary),
                    decoration: _inputDecoration(
                      context,
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                    ),
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onFieldSubmitted: (_) => _handleSignUp(),
                    onChanged: (_) => setState(() {}),
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colors.textPrimary),
                    decoration: _inputDecoration(
                      context,
                      label: 'Password',
                      hint: 'Min 8 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colors.textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                  ),

                  // Password strength bar
                  if (password.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _PasswordStrengthBar(strength: strength, colors: colors),
                  ],

                  // Error banner
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _ErrorBanner(message: _errorMessage!),
                  ],
                  const SizedBox(height: 28),

                  // Create account button
                  TioButton.primary(
                    label: 'Create Account',
                    expand: true,
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _handleSignUp,
                  ),
                  const SizedBox(height: 16),

                  // Legal text
                  Center(
                    child: Text(
                      'By creating an account, you agree to our\nTerms of Service and Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign in link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account?',
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.pushReplacement('/login/email'),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Sign In',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    final colors = TioTheme.colors(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: colors.textMuted, size: 20),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  const _PasswordStrengthBar(
      {required this.strength, required this.colors});

  final double strength;
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    final String label;
    if (strength <= 0.25) {
      barColor = colors.danger;
      label = 'Weak';
    } else if (strength <= 0.5) {
      barColor = colors.warning;
      label = 'Fair';
    } else if (strength <= 0.75) {
      barColor = colors.info;
      label = 'Good';
    } else {
      barColor = colors.success;
      label = 'Strong';
    }

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength,
              backgroundColor:
                  colors.outlineStrong.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: barColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.danger,
                    fontSize: 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
