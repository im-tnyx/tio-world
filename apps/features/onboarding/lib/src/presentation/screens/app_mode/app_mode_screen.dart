import 'package:flutter/material.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_shared/shared.dart';

/// Legacy Product Onboarding compatibility wrapper.
///
/// New first-run App Mode selection is owned by Account Setup via
/// [AppModeSetupPage]. This wrapper remains temporarily so legacy tests/drafts
/// can render the same content without duplicating presentation code.
@Deprecated('Use AppModeSetupPage for first-run App Mode selection.')
class AppModeScreen extends StatelessWidget {
  const AppModeScreen({
    required this.selectedMode,
    required this.onModeSelected,
    super.key,
    this.enabled = true,
  });

  final AppMode? selectedMode;
  final ValueChanged<AppMode> onModeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppModeSelectionContent(
      selectedMode: selectedMode,
      enabled: enabled,
      onModeSelected: onModeSelected,
    );
  }
}
