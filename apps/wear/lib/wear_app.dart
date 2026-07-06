import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import 'src/home/presentation/wear_home_screen.dart';

class TioWearApp extends StatelessWidget {
  const TioWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tio Wear',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const WearHomeScreen(),
      builder: (context, child) {
        return TioTheme(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
