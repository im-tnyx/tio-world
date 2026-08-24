import '../repositories/account_deletion_repository.dart';

class DeleteCurrentAccountUseCase {
  const DeleteCurrentAccountUseCase({
    required AccountDeletionRepository repository,
  }) : _repository = repository;

  final AccountDeletionRepository _repository;

  Future<void> call() => _repository.deleteCurrentAccount();
}
