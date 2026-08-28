import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('DeleteCurrentAccountUseCase', () {
    test('delegates permanent deletion exactly once', () async {
      final repository = _FakeAccountDeletionRepository();
      final useCase = DeleteCurrentAccountUseCase(repository: repository);

      await useCase();

      expect(repository.deleteCalls, 1);
    });

    test('forwards repository failure without converting it to success', () async {
      final repository = _FakeAccountDeletionRepository(
        error: StateError('delete failed'),
      );
      final useCase = DeleteCurrentAccountUseCase(repository: repository);

      await expectLater(useCase(), throwsStateError);
      expect(repository.deleteCalls, 1);
    });
  });
}

class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  _FakeAccountDeletionRepository({this.error});

  final Object? error;
  int deleteCalls = 0;

  @override
  Future<void> deleteCurrentAccount() async {
    deleteCalls++;
    final failure = error;
    if (failure != null) throw failure;
  }
}
