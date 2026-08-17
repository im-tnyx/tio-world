import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../../domain/repositories/profile_account_repository.dart';

class UsernameSetupPage extends StatefulWidget {
  const UsernameSetupPage({
    required this.repository,
    required this.onCompleted,
    super.key,
  });

  final ProfileAccountRepository repository;
  final Future<void> Function() onCompleted;

  @override
  State<UsernameSetupPage> createState() => _UsernameSetupPageState();
}

class _UsernameSetupPageState extends State<UsernameSetupPage> {
  final TextEditingController _usernameController = TextEditingController();
  TioUsernameStatus _status = TioUsernameStatus.idle;
  bool _saving = false;
  String? _saveError;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<UsernameAvailabilityResult> _checkAvailability(String username) async {
    try {
      final available = await widget.repository.isUsernameAvailable(username);
      return UsernameAvailabilityResult(
        isAvailable: available,
        message: available ? null : 'This username is already taken.',
      );
    } catch (_) {
      return const UsernameAvailabilityResult(
        isAvailable: false,
        message: 'Could not verify this username. Please try again.',
      );
    }
  }

  Future<void> _save() async {
    if (_saving || _status != TioUsernameStatus.available) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      await widget.repository.updateUsername(_usernameController.text);
      if (!mounted) return;
      await widget.onCompleted();
    } on UsernameUnavailableException {
      if (!mounted) return;
      setState(() {
        _status = TioUsernameStatus.unavailable;
        _saveError = 'That username was just taken. Please choose another.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = 'Could not save your username. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(TioSpacing.xLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose your username',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: TioSpacing.small),
                  Text(
                    'Your username is your unique public Tio handle. You can use lowercase letters, numbers, dots, and underscores.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: TioSpacing.xLarge),
                  TioUsernameInputField(
                    controller: _usernameController,
                    enabled: !_saving,
                    textInputAction: TextInputAction.done,
                    onCheckAvailability: _checkAvailability,
                    onStatusChanged: (status) {
                      if (!mounted) return;
                      setState(() {
                        _status = status;
                        _saveError = null;
                      });
                    },
                    onSubmitted: (_) => _save(),
                  ),
                  if (_saveError != null) ...[
                    const SizedBox(height: TioSpacing.medium),
                    Text(
                      _saveError!,
                      key: const ValueKey('username-setup-error'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: TioSpacing.xLarge),
                  FilledButton(
                    key: const ValueKey('username-setup-continue'),
                    onPressed: _status == TioUsernameStatus.available && !_saving
                        ? _save
                        : null,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Continue'),
                  ),
                  const SizedBox(height: TioSpacing.medium),
                  Text(
                    'Username is required before continuing.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
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
