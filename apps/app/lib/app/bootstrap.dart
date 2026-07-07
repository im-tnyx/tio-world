import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

void bootstrap(Widget Function() builder) {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(builder());
}
