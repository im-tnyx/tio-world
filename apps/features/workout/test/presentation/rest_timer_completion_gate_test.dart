import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/src/presentation/controllers/rest_timer_completion_gate.dart';

void main() {
  test('one natural completion is delivered once per enabled rest', () {
    final gate = RestTimerCompletionGate();
    gate.observeRest(
      restId: 'first',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    expect(gate.complete('first', vibrationEnabled: true), isTrue);
    expect(gate.complete('first', vibrationEnabled: true), isFalse);
    gate.observeRest(
      restId: 'second',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    expect(gate.complete('second', vibrationEnabled: true), isTrue);
  });

  test('OFF, cancellation and enabling mid-rest cannot produce vibration', () {
    final gate = RestTimerCompletionGate();
    gate.observeRest(
      restId: 'off',
      remainingPositive: true,
      vibrationEnabled: false,
    );
    expect(gate.complete('off', vibrationEnabled: true), isFalse);
    gate.observeRest(
      restId: 'cancelled',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    gate.observeRest(
      restId: null,
      remainingPositive: false,
      vibrationEnabled: true,
    );
    expect(gate.complete('cancelled', vibrationEnabled: true), isFalse);
    gate.observeRest(
      restId: 'disabled-before-expiry',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    expect(gate.complete('disabled-before-expiry', vibrationEnabled: false),
        isFalse);
  });

  test('background expiry and already-expired restored rest are silent', () {
    final gate = RestTimerCompletionGate();
    gate.observeRest(
      restId: 'background',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    gate.setForeground(false);
    expect(gate.complete('background', vibrationEnabled: true), isFalse);
    gate.setForeground(true);
    expect(gate.complete('background', vibrationEnabled: true), isFalse);

    gate.observeRest(
      restId: 'expired-on-restore',
      remainingPositive: false,
      vibrationEnabled: true,
    );
    expect(gate.complete('expired-on-restore', vibrationEnabled: true),
        isFalse);
  });

  test('resuming before deadline can rearm an eligible ongoing rest', () {
    final gate = RestTimerCompletionGate();
    gate.observeRest(
      restId: 'still-active',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    gate.setForeground(false);
    gate.setForeground(true);
    gate.observeRest(
      restId: 'still-active',
      remainingPositive: true,
      vibrationEnabled: true,
    );
    expect(gate.complete('still-active', vibrationEnabled: true), isTrue);
  });
}
