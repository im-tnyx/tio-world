import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/hydration_preferences_session_boundary.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  test('ordinary restart/restored session retains the local 300 ml override',
      () async {
    final repository = _MemoryHydrationPreferencesRepository(300);
    final boundary = HydrationPreferencesSessionBoundary(repository);

    expect(await repository.read(),
        const HydrationPreferences(defaultGlassSizeMl: 300));
    expect(repository.clearCalls, 0);
    expect(boundary, isNotNull);
  });

  test('successful sign-out clears local Glass Size before a new login',
      () async {
    final repository = _MemoryHydrationPreferencesRepository(300);
    final boundary = HydrationPreferencesSessionBoundary(repository);

    await boundary.clearAfterSuccessfulSignOut(() async {});
    expect(await repository.read(), const HydrationPreferences());

    await repository.write(const HydrationPreferences(defaultGlassSizeMl: 350));
    await boundary.clearForNewExplicitLogin();
    expect(await repository.read(), const HydrationPreferences());
  });

  test('failed sign-out leaves the local Glass Size override untouched',
      () async {
    final repository = _MemoryHydrationPreferencesRepository(300);
    final boundary = HydrationPreferencesSessionBoundary(repository);

    await expectLater(
      boundary.clearAfterSuccessfulSignOut(
          () async => throw StateError('sign-out failed')),
      throwsStateError,
    );

    expect(await repository.read(),
        const HydrationPreferences(defaultGlassSizeMl: 300));
    expect(repository.clearCalls, 0);
  });

  test('confirmed account deletion clears even when best-effort sign-out fails',
      () async {
    final repository = _MemoryHydrationPreferencesRepository(300);
    final boundary = HydrationPreferencesSessionBoundary(repository);

    await boundary.clearAfterConfirmedAccountDeletion(
        () async => throw StateError('sign-out failed'));

    expect(await repository.read(), const HydrationPreferences());
    expect(repository.clearCalls, 1);
  });

  test('account A at 300 ml cannot leak into account B after logout/login',
      () async {
    final repository = _MemoryHydrationPreferencesRepository(300);
    final boundary = HydrationPreferencesSessionBoundary(repository);

    await boundary.clearAfterSuccessfulAccountEnd();
    await boundary.clearForNewExplicitLogin();

    expect(await repository.read(), const HydrationPreferences());
    expect(repository.clearCalls, 2);
  });
}

class _MemoryHydrationPreferencesRepository
    implements HydrationPreferencesRepository {
  _MemoryHydrationPreferencesRepository(this._value);

  int _value;
  var clearCalls = 0;

  @override
  Future<void> clear() async {
    clearCalls++;
    _value = HydrationPreferences.defaultGlassSizeMlDefault;
  }

  @override
  Future<HydrationPreferences> read() async =>
      HydrationPreferences(defaultGlassSizeMl: _value);

  @override
  Future<void> write(HydrationPreferences preferences) async {
    _value = preferences.defaultGlassSizeMl;
  }
}
