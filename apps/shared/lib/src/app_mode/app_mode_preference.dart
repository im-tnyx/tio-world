import 'app_mode_contract.dart';

abstract interface class AppModePreference {
  Future<AppMode?> read();

  Future<void> write(AppMode mode);

  Future<void> clear();
}
