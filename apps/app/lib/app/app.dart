import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import 'router.dart';

class TioApp extends ConsumerWidget {
  const TioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Tio',
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final theme = Theme.of(context);
        return TioTheme(
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: theme.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              systemNavigationBarContrastEnforced: false,
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: theme.brightness == Brightness.light
                  ? Brightness.dark
                  : Brightness.light,
              statusBarBrightness: theme.brightness,
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
