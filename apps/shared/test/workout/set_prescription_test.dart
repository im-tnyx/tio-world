import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('SetPrescription', () {
    test('setType wire mapping and default Normal remain stable', () {
      expect(SetPrescription(reps: 1).setType, RoutineSetType.normal);
      expect(SetPrescription(reps: 1).repsMax, isNull);
      for (final type in RoutineSetType.values) {
        expect(RoutineSetType.fromWire(type.wireValue), type);
      }
      expect(() => RoutineSetType.fromWire('unknown'), throwsArgumentError);
    });

    test('Rep Range validates minimum and maximum without changing type', () {
      final base = SetPrescription(
        reps: 8,
        repsMax: 12,
        setType: RoutineSetType.warmUp,
        loadKg: 20.5,
        restSeconds: 30,
      );
      expect(base.isRepRange, isTrue);
      expect(base.reps, 8);
      expect(base.repsMax, 12);
      expect(base.setType, RoutineSetType.warmUp);
      expect(SetPrescription(reps: 8, repsMax: 8).isRepRange, isTrue);
      for (final max in [0, 7, 2147483648]) {
        expect(() => SetPrescription(reps: 8, repsMax: max),
            throwsArgumentError);
      }
      expect(base, SetPrescription(
        reps: 8, repsMax: 12, setType: RoutineSetType.warmUp,
        loadKg: 20.5, restSeconds: 30,
      ));
      expect(base, isNot(SetPrescription(reps: 8)));
      expect(base, isNot(SetPrescription(reps: 8, repsMax: 12)));
    });


    test('allows genuinely unspecified targets and preserves equal-value identity', () {
      final blank = SetPrescription();
      expect(blank.reps, isNull);
      expect(blank.repsMax, isNull);
      expect(blank.loadKg, isNull);
      expect(blank.distanceMeters, isNull);
      expect(blank.durationSeconds, isNull);
      expect(blank, SetPrescription(reps: null));
      expect(blank.hashCode, SetPrescription().hashCode);
      expect(blank, isNot(SetPrescription(reps: 1)));
      expect(blank, isNot(SetPrescription(durationSeconds: 0)));
    });

    test('validates exact canonical distance and time independently of Reps', () {
      final treadmill = SetPrescription(
        distanceMeters: 2500.5,
        durationSeconds: 905,
      );
      expect(treadmill.distanceMeters, 2500.5);
      expect(treadmill.durationSeconds, 905);
      expect(treadmill.reps, isNull);
      expect(treadmill, isNot(SetPrescription(durationSeconds: 905)));
      expect(SetPrescription(durationSeconds: 0).durationSeconds, 0);
      expect(SetPrescription(distanceMeters: 0).distanceMeters, 0);
      for (final value in [-1.0, double.nan, double.infinity]) {
        expect(() => SetPrescription(distanceMeters: value),
            throwsArgumentError);
      }
      for (final seconds in [-1, 2147483648]) {
        expect(() => SetPrescription(durationSeconds: seconds),
            throwsArgumentError);
      }
      expect(() => SetPrescription(reps: null, repsMax: 10),
          throwsArgumentError);
      expect(() => SetPrescription(reps: 2147483648),
          throwsArgumentError);
    });

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
