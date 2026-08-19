import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_core/core.dart';

import '../../../domain/domain.dart';

/// Forgot password screen.
/// Sends a password reset email via Supabase Auth.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    this.sendPasswordResetEmailUseCase,
    super.key,
  });

  final SendPasswordResetEmailUseCase? sendPasswordResetEmailUseCase;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email required';
    final emailReg = RegExp(r'^[\w.+\-]+@[\w\-]+\.\w{2,}$');
    if (!emailReg.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  Future<void> _handleSendReset() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.sendPasswordResetEmailUseCase == null) {
      // Dev mode: simulate success. This is behavior timing, not visual motion.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _emailSent = true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await widget.sendPasswordResetEmailUseCase!(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      switch (result) {
        case SignInSuccess():
          setState(() => _emailSent = true);
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
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        // Intentional framework-transparent app bar; not a palette role.
        backgroundColor: Colors.transparent,
        elevation: TioElevation.none,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: colors.textPrimary,
            size: TioSize.dp24,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: TioSpacing.lg),
            child: _emailSent
                ? _SuccessState(
                    email: _emailController.text.trim(),
                    colors: colors,
                    textTheme: textTheme,
                    onBackToSignIn: () => context.pop(),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TioSpacing.lg),
                        Text(
                          'Reset password',
                          style: textTheme.displayLarge,
                        ),
                        const SizedBox(height: TioSize.dp6),
                        Text(
                          "Enter your email address and we'll send you\na reset link.",
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colors.textSecondary),
                        ),
                        const SizedBox(height: TioSize.dp40),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.email],
                          onFieldSubmitted: (_) => _handleSendReset(),
                          style: textTheme.bodyLarge
                              ?.copyWith(color: colors.textPrimary),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icon(
                              Icons.mail_outline_rounded,
                              color: colors.textMuted,
                              size: TioSize.dp20,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: TioInputTokens.horizontalPadding,
                              vertical:
                                  TioInputTokens.standardContentVerticalPadding,
                            ),
                          ),
                          validator: _validateEmail,
                        ),

                        // Error banner
                        if (_errorMessage != null) ...[
                          const SizedBox(height: TioSpacing.lg),
                          _ErrorBanner(message: _errorMessage!),
                        ],
                        const SizedBox(height: TioSize.dp28),

                        // Send reset button
                        TioButton.primary(
                          label: 'Send Reset Link',
                          expand: true,
                          loading: _isLoading,
                          onPressed: _isLoading ? null : _handleSendReset,
                        ),
                        const SizedBox(height: TioSpacing.xl),

                        // Back to sign in
                        Center(
                          child: TextButton(
                            onPressed: () => context.pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.primary,
                            ),
                            child: Text(
                              'Back to Sign In',
                              style: textTheme.bodyLarge?.copyWith(
                                color: colors.primary,
                                fontWeight: TioFontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({
    required this.email,
    required this.colors,
    required this.textTheme,
    required this.onBackToSignIn,
  });

  final String email;
  final TioColors colors;
  final TextTheme textTheme;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: TioSize.dp48),
        Container(
          width: TioSize.dp80,
          height: TioSize.dp80,
          decoration: BoxDecoration(
            color: colors.success.withValues(alpha: TioOpacity.opacity12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            color: colors.success,
            size: TioSize.dp40,
          ),
        ),
        const SizedBox(height: TioSize.dp28),
        Text(
          'Check your inbox',
          style: textTheme.displayLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TioSize.dp10),
        Text(
          'We sent a password reset link to\n$email',
          style: textTheme.bodyLarge?.copyWith(color: colors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: TioSize.dp40),
        SizedBox(
          width: double.infinity,
          child: TioButton.primary(
            label: 'Back to Sign In',
            expand: true,
            onPressed: onBackToSignIn,
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
    final colors = context.tioColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TioSpacing.lg,
        vertical: TioSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: TioOpacity.opacity10),
        borderRadius: BorderRadius.circular(TioRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.danger,
            size: TioSize.dp18,
          ),
          const SizedBox(width: TioSize.dp10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.danger,
                    fontSize: TioFontSize.size13,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
