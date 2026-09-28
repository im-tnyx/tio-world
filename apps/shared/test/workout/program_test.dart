import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const uuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';

  group('Program', () {
    test('stores stable identity and supplied non-blank name', () {
      final program = Program(id: ProgramId(uuid), name: 'Program 1');

      expect(program.id, ProgramId(uuid));
      expect(program.name, 'Program 1');
    });

    test('preserves meaningful surrounding whitespace', () {
      final program = Program(id: ProgramId(uuid), name: ' Program 1 ');

      expect(program.name, ' Program 1 ');
    });

    test('rejects blank and whitespace-only names', () {
      for (final name in ['', '   ', '\n\t']) {
        expect(
          () => Program(id: ProgramId(uuid), name: name),
          throwsArgumentError,
          reason: name,
        );
      }
    });

    test('equality includes identity and name', () {
      final a = Program(id: ProgramId(uuid), name: 'Program 1');
      final b = Program(id: ProgramId(uuid), name: 'Program 1');
      final renamed = Program(id: ProgramId(uuid), name: 'Strength');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(renamed));
    });
  });
}
