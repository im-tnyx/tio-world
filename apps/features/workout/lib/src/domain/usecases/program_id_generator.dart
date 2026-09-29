import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

abstract interface class ProgramIdGenerator {
  ProgramId generate(Iterable<ProgramId> existingIds);
}

/// UUID-v4 generator for user-owned Program identities.
final class UuidProgramIdGenerator implements ProgramIdGenerator {
  UuidProgramIdGenerator({
    String Function()? uuidV4,
    this.maxAttempts = 100,
  }) : _uuidV4 = uuidV4 ?? _defaultUuidV4 {
    if (maxAttempts <= 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'must be positive',
      );
    }
  }

  final String Function() _uuidV4;
  final int maxAttempts;

  static String _defaultUuidV4() => const Uuid().v4();

  @override
  ProgramId generate(Iterable<ProgramId> existingIds) {
    final existing = existingIds.map((id) => id.value).toSet();
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final candidate = ProgramId(_uuidV4());
      if (!existing.contains(candidate.value)) return candidate;
    }
    throw StateError('Unable to generate a unique Program id.');
  }
}
