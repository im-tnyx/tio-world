import 'dart:async';

import 'package:flutter/widgets.dart';

import 'app_theme_controller.dart';

class AppThemeBootstrap extends StatefulWidget {
  const AppThemeBootstrap({
    required this.controller,
    required this.child,
    super.key,
  });

  final AppThemeController controller;
  final Widget child;

  @override
  State<AppThemeBootstrap> createState() => _AppThemeBootstrapState();
}

class _AppThemeBootstrapState extends State<AppThemeBootstrap> {
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
