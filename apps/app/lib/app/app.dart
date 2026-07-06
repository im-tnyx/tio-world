import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';

import 'router.dart';

class TioApp extends ConsumerWidget {
  const TioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TioTheme(
      child: MaterialApp.router(
        title: 'Tio',
        routerConfig: goRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
