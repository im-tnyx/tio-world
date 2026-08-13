import 'package:tio_core/core.dart';

abstract interface class AppThemePreference {
  Future<TioThemeMode?> read();
  Future<void> write(TioThemeMode mode);
  Future<void> clear();
}
