import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/device/wear_display_shape.dart';
import 'wear_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final displayShape = await const MethodChannelWearDisplayShapeReader().read();

  runApp(
    ProviderScope(
      child: TioWearApp(displayShape: displayShape),
    ),
  );
}
