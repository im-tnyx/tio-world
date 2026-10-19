import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  test('Move refresh is scoped to exact owner plus login cycle', () {
    final signal = RoutineMoveRefreshSignal();
    addTearDown(signal.dispose);
    var notifications = 0;
    signal.addListener(() => notifications++);
    expect(signal.version, 0);
    expect(signal.matches(ownerId: 'a', loginCycleId: 'cycle-a'), isFalse);

    signal.request(
      ownerId: 'owner-a',
      loginCycleId: 'cycle-a',
      programsMayHaveChanged: false,
    );
    expect(signal.version, 1);
    expect(notifications, 1);
    expect(signal.programsMayHaveChanged, isFalse);
    expect(signal.matches(ownerId: 'owner-a', loginCycleId: 'cycle-a'),
        isTrue);
    expect(signal.matches(ownerId: 'owner-b', loginCycleId: 'cycle-a'),
        isFalse);
    expect(signal.matches(ownerId: 'owner-a', loginCycleId: 'cycle-b'),
        isFalse);
    expect(signal.matches(ownerId: null, loginCycleId: 'cycle-a'), isFalse);
    expect(signal.matches(ownerId: 'owner-a', loginCycleId: null), isFalse);
  });

  test('atomic write only flags Program-list invalidation, never success',
      () {
    final signal = RoutineMoveRefreshSignal();
    addTearDown(signal.dispose);
    signal.request(ownerId: 'owner-a', loginCycleId: 'cycle-a',
        programsMayHaveChanged: true);
    expect(signal.programsMayHaveChanged, isTrue);
    signal.request(ownerId: 'owner-a', loginCycleId: 'cycle-a',
        programsMayHaveChanged: false);
    expect(signal.programsMayHaveChanged, isFalse);
    expect(signal.version, 2);
  });

  test('empty or unauthenticated identities never broadcast invalidation',
      () {
    final signal = RoutineMoveRefreshSignal();
    addTearDown(signal.dispose);
    var changed = 0;
    signal.addListener(() => changed++);
    signal.request(ownerId: '', loginCycleId: 'cycle',
        programsMayHaveChanged: true);
    signal.request(ownerId: 'owner', loginCycleId: '',
        programsMayHaveChanged: true);
    expect(signal.version, 0);
    expect(changed, 0);
  });
}
