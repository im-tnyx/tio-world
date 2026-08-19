import 'package:flutter/material.dart';
import 'package:tio_feature_account_setup/account_setup.dart';
import 'package:tio_shared/shared.dart';

import '../app_mode/app_mode.dart';

/// App-layer boundary that hydrates/persists the local pre-auth App Mode draft
/// without giving the Account Setup feature package a storage dependency.
class PreAuthAppModeRoute extends StatefulWidget {
  const PreAuthAppModeRoute({
    required this.pendingPreference,
    required this.onBack,
    required this.onContinueToSignup,
    super.key,
  });

  final PendingAppModePreference pendingPreference;
  final VoidCallback onBack;
  final Future<void> Function() onContinueToSignup;

  @override
  State<PreAuthAppModeRoute> createState() => _PreAuthAppModeRouteState();
}

class _PreAuthAppModeRouteState extends State<PreAuthAppModeRoute> {
  late final Future<AppMode?> _initialMode;

  @override
  void initState() {
    super.initState();
    _initialMode = widget.pendingPreference.read();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppMode?>(
      future: _initialMode,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: context.tioColors.background,
            body: const SizedBox.expand(),
          );
        }

        return AppModeSetupPage(
          initialMode: snapshot.data,
          onBack: widget.onBack,
          onModeConfirmed: (mode) async {
            await widget.pendingPreference.write(mode);
            await widget.onContinueToSignup();
          },
        );
      },
    );
  }
}
