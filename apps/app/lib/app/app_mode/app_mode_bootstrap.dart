import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_mode_controller.dart';

class AppModeBootstrap extends StatefulWidget {
  const AppModeBootstrap({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppModeController controller;
  final Widget child;

  @override
  State<AppModeBootstrap> createState() => _AppModeBootstrapState();
}

class _AppModeBootstrapState extends State<AppModeBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(widget.controller.load());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
