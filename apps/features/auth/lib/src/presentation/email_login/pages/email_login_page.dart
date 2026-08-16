import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Pixel-perfect implementation of Tnyx-Hub Email/Social Login Screen (`EmailAuthScreen.kt`).
///
/// Features:
/// - Outlined Email & Password fields
/// - "Forgot Password?" action link
/// - Full-width "Sign In" button with loading state
/// - "OR" divider
/// - Reusable `TioSocialButton.google`
/// - Reusable `TioSocialButton.truecaller`
/// - Pinned bottom footer: "Don't have an account? Create Account"
class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({
    this.signInWithEmailUseCase,
    this.signInWithGoogleUseCase,
    this.googleAuthUseCase,
    this.onSignInSuccess,
    this.onAuthSuccess,
    this.onTruecallerClick,
    super.key,
  });

  final SignInWithEmailUseCase? signInWithEmailUseCase;
  final SignInWithGoogleUseCase? signInWithGoogleUseCase;
  final GoogleAuthUseCase? googleAuthUseCase;
  final ValueChanged<SignInSuccess>? onSignInSuccess;
  final ValueChanged<GoogleAuthComplete>? onAuthSuccess;
  final VoidCallback? onTruecallerClick;

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final emailReg = RegExp(r'^[\w.+\-]+@[\w\-]+\.\w{2,}$');
    if (!emailReg.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password required';
    return null;
  }

  Future<void> _handleSignIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signInWithEmailUseCase == null) {
      if (mounted) {
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(AppRoutes.onboarding.path);
        }
      }
      return;
    }

    try {
      final result = await widget.signInWithEmailUseCase!(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      switch (result) {
        case SignInSuccess():
          widget.onSignInSuccess?.call(result);
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go(AppRoutes.onboarding.path);
          }
          break;
        case SignInFailure(:final message):
          setState(() => _errorMessage = message);
          break;
        case SignInCancelled():
          break;
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.signInWithGoogleUseCase == null && widget.googleAuthUseCase == null) {
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(AppRoutes.onboarding.path);
      }
      return;
    }

    try {
      if (widget.signInWithGoogleUseCase != null) {
        final result = await widget.signInWithGoogleUseCase!();
        if (!mounted) return;
        if (result is SignInSuccess) {
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go(AppRoutes.onboarding.path);
          }
          return;
        } else if (result is SignInFailure) {
          setState(() => _errorMessage = result.message);
        }
      } else if (widget.googleAuthUseCase != null) {
        final result = await widget.googleAuthUseCase!();
        if (!mounted) return;
        if (result is GoogleAuthComplete) {
          widget.onAuthSuccess?.call(result);
          if (context.canPop()) {
            context.pop(true);
          } else {
            context.go(AppRoutes.onboarding.path);
          }
          return;
        } else if (result is GoogleAuthFailed) {
          setState(() => _errorMessage = result.message);
        }
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(false),
        ),
        title: Text(
          'Sign In',
          style: textTheme.titleLarge?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioSpacing.large,
                  vertical: 8,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null) ...[
                        _ErrorBanner(message: _errorMessage!),
                        const SizedBox(height: 16),
                      ],
                      const SizedBox(height: 16),

                      // Email field
                      TextFormField(
                        key: const ValueKey('signin-email-input'),
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: colors.textPrimary),
                        validator: _validateEmail,
                        decoration: _inputDecoration(
                          context,
                          label: 'Email address',
                          hint: 'you@example.com',
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      TextFormField(
                        key: const ValueKey('signin-password-input'),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignIn(),
                        style: TextStyle(color: colors.textPrimary),
                        validator: _validatePassword,
                        decoration: _inputDecoration(
                          context,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: colors.textMuted,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              context.push(AppRoutes.forgotPassword.path),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign in button
                      TioButton.primary(
                        label: 'Sign In',
                        expand: true,
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _handleSignIn,
                      ),
                      const SizedBox(height: 28),

                      // OR Divider
                      _OrDivider(colors: colors),
                      const SizedBox(height: 24),

                      // Social Buttons (Google + Truecaller)
                      TioSocialButton.google(
                        key: const ValueKey('signin-google-button'),
                        loading: _isLoading,
                        onPressed: _handleGoogleSignIn,
                      ),

                      const SizedBox(height: 12),

                      TioSocialButton.truecaller(
                        key: const ValueKey('signin-truecaller-button'),
                        loading: false,
                        onPressed: widget.onTruecallerClick ?? () {},
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Pinned Bottom Footer: Don't have an account? Create Account
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (!_isLoading) {
                        context.go(AppRoutes.onboarding.path);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Sign Up',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      prefixIcon:
          Icon(prefixIcon, color: colors.textMuted, size: 20),
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.colors});
  final TioColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colors.outlineStrong.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
          ),
        ),
        Expanded(
          child: Divider(color: colors.outlineStrong.withValues(alpha: 0.3)),
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
        borderRadius: BorderRadius.circular(TioRadius.large),
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
