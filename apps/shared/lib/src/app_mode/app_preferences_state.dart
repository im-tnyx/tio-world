import 'app_mode_contract.dart';

/// Canonical account-level App Mode/navigation state.
///
/// A missing row is intentionally different from a present row whose fields are
/// partially populated for legacy/recovery purposes.
final class AppPreferencesState {
  const AppPreferencesState.missing()
      : exists = false,
        appMode = null,
        activeTabs = null;

  AppPreferencesState.present({
    required this.appMode,
    List<AppDestination>? activeTabs,
  })  : exists = true,
        activeTabs = activeTabs == null
            ? null
            : _validatedTabs(activeTabs, allowEmpty: false);

  final bool exists;
  final AppMode? appMode;
  final List<AppDestination>? activeTabs;

  bool get isMissing => !exists;
  bool get isPresent => exists;
}

/// Validated write payload for the canonical `user_app_preferences` owner.
///
/// New writes always carry an explicit semantic App Mode and a non-empty,
/// ordered list of supported destinations. The list is defensively copied so
/// callers cannot mutate persisted intent after validation.
final class AppPreferencesUpdate {
  AppPreferencesUpdate({
    required this.appMode,
    required List<AppDestination> activeTabs,
  }) : activeTabs = _validatedTabs(activeTabs, allowEmpty: false);

  factory AppPreferencesUpdate.guided(AppMode appMode) => AppPreferencesUpdate(
        appMode: appMode,
        activeTabs: appMode.guidedDestinations,
      );

  final AppMode appMode;
  final List<AppDestination> activeTabs;
}

List<AppDestination> _validatedTabs(
  Iterable<AppDestination> tabs, {
  required bool allowEmpty,
}) {
  final copy = List<AppDestination>.of(tabs);
  if (!allowEmpty && copy.isEmpty) {
    throw ArgumentError.value(
      copy,
      'activeTabs',
      'Active tabs must contain at least one supported destination.',
    );
  }

  final unique = <AppDestination>{};
  for (final destination in copy) {
    if (!unique.add(destination)) {
      throw ArgumentError.value(
        copy,
        'activeTabs',
        'Active tabs must not contain duplicate destinations.',
      );
    }
  }

  return List<AppDestination>.unmodifiable(copy);
}
