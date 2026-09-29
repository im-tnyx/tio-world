import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('SetPrescription', () {
    test('stores reps with optional canonical load and rest', () {
      final prescription = SetPrescription(
        reps: 8,
        loadKg: 72.5,
        restSeconds: 120,
      );

      expect(prescription.reps, 8);
      expect(prescription.loadKg, 72.5);
      expect(prescription.restSeconds, 120);
    });

    test('keeps optional load and rest unspecified when omitted', () {
      final prescription = SetPrescription(reps: 12);

      expect(prescription.loadKg, isNull);
      expect(prescription.restSeconds, isNull);
    });

    test('allows explicit zero load and zero rest', () {
      final prescription = SetPrescription(
        reps: 15,
        loadKg: 0,
        restSeconds: 0,
      );

      expect(prescription.loadKg, 0);
      expect(prescription.restSeconds, 0);
    });

    test('rejects non-positive reps', () {
      for (final reps in [0, -1]) {
        expect(
          () => SetPrescription(reps: reps),
          throwsArgumentError,
          reason: '$reps',
        );
      }
    });

    test('rejects invalid load values', () {
      for (final load in [-0.1, double.nan, double.infinity]) {
        expect(
          () => SetPrescription(reps: 8, loadKg: load),
          throwsArgumentError,
          reason: '$load',
        );
      }
    });

    test('rejects negative rest', () {
      expect(
        () => SetPrescription(reps: 8, restSeconds: -1),
        throwsArgumentError,
      );
    });

    test('uses value equality', () {
      final a = SetPrescription(reps: 5, loadKg: 100, restSeconds: 180);
      final b = SetPrescription(reps: 5, loadKg: 100, restSeconds: 180);
      final changed = SetPrescription(reps: 6, loadKg: 100, restSeconds: 180);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(changed));
    });
  });
}
