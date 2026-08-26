import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class EmailStep extends StatefulWidget {
  const EmailStep({
    required this.initialEmail,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String initialEmail;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends State<EmailStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TioScreenHeader(
          title: "What's your email address?",
          subtitle:
              'Add an email for account recovery and future security options.',
        ),
        const SizedBox(height: TioSpacing.lg),
        TioInput(
          key: const ValueKey('account-setup-email-input'),
          controller: _controller,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          label: 'Email',
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          'Optional — leave this blank to continue. If you add an email, we will send a confirmation. It stays unverified until you confirm it, and this does not create an Email + Password sign-in method.',
          key: const ValueKey('account-setup-email-helper'),
          style: TextStyle(
            color: colors.textMuted,
            fontSize: TioFontSize.size12,
            height: TioLineHeight.height130,
          ),
        ),
      ],
    );
  }
}
