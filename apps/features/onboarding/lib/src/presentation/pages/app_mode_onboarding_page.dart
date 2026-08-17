import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../screens/app_mode/app_mode_screen.dart';

class AppModeOnboardingPage extends StatefulWidget {
  const AppModeOnboardingPage({
    required this.onModeConfirmed,
    super.key,
    this.initialMode,
  });

  final AppMode? initialMode;
  final Future<void> Function(AppMode mode) onModeConfirmed;

  @override
  State<AppModeOnboardingPage> createState() => _AppModeOnboardingPageState();
}

class _AppModeOnboardingPageState extends State<AppModeOnboardingPage> {
  AppMode? _selectedMode;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  Future<void> _continue() async {
    final mode = _selectedMode;
    if (mode == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      await widget.onModeConfirmed(mode);
    } catch (_) {
      if (!mounted) return;
      setState(
          () => _errorText = 'Could not save your mode. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AppModeScreen(
              selectedMode: _selectedMode,
              enabled: !_isSaving,
              onModeSelected: (mode) => setState(() => _selectedMode = mode),
            ),
            if (_errorText case final errorText?) ...[
              const SizedBox(height: 16),
              Semantics(
                liveRegion: true,
                child: Text(
                  errorText,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 24),
            TioButton.primary(
              label: 'Continue',
              loading: _isSaving,
              loadingLabel: 'Saving',
              expand: true,
              enabled: _selectedMode != null && !_isSaving,
              onPressed: _continue,
              trailing: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
    );
  }
}
