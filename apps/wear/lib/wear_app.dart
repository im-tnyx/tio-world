import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import 'src/device/wear_display_shape.dart';
import 'src/home/presentation/wear_home_screen.dart';

class TioWearApp extends StatelessWidget {
  const TioWearApp({
    this.appMode,
    this.displayShape = WearDisplayShape.rectangular,
    super.key,
  });

  final AppMode? appMode;
  final WearDisplayShape displayShape;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tio Wear',
      debugShowCheckedModeBanner: false,
      home: WearHomeScreen(
        appMode: appMode,
        displayShape: displayShape,
      ),
      builder: (context, child) {
        return TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.oled),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
