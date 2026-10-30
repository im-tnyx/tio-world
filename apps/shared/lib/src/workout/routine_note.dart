import 'exercise_ref.dart';
import 'routine_id.dart';

enum RoutineNoteType {
  pinnedRoutine('pinned_routine'),
  pinnedExercise('pinned_exercise');

  const RoutineNoteType(this.value);

  final String value;

  static RoutineNoteType parse(Object? value) {
    return switch (value) {
      'pinned_routine' => RoutineNoteType.pinnedRoutine,
      'pinned_exercise' => RoutineNoteType.pinnedExercise,
      _ => throw FormatException('Invalid RoutineNoteType: $value.'),
    };
  }
}

final class RoutineNoteScope {
  const RoutineNoteScope._({this.routineId, this.exerciseRef})
      : assert((routineId == null) != (exerciseRef == null));

  const RoutineNoteScope.routine(RoutineId value)
      : this._(routineId: value, exerciseRef: null);

  const RoutineNoteScope.exercise(ExerciseRef value)
      : this._(routineId: null, exerciseRef: value);

  final RoutineId? routineId;
  final ExerciseRef? exerciseRef;

  RoutineNoteType get type => routineId != null
      ? RoutineNoteType.pinnedRoutine
      : RoutineNoteType.pinnedExercise;

  String get key => routineId != null
      ? 'routine:${routineId!.value}'
      : 'exercise:${exerciseRef!.value}';

  @override
  bool operator ==(Object other) =>
      other is RoutineNoteScope &&
      routineId == other.routineId &&
      exerciseRef == other.exerciseRef;

  @override
  int get hashCode => Object.hash(routineId, exerciseRef);
}

final class RoutineNote {
  RoutineNote({
    required String id,
    required String userId,
    required this.scope,
    required String body,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    String? lastMutationId,
  })  : id = _uuid(id, 'id'),
        userId = _uuid(userId, 'userId'),
        body = normalizeBody(body),
        lastMutationId = lastMutationId == null
            ? null
            : _uuid(lastMutationId, 'lastMutationId') {
    if (revision < 0) throw ArgumentError.value(revision, 'revision');
  }

  final String id;
  final String userId;
  final RoutineNoteScope scope;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final String? lastMutationId;

  RoutineNoteType get type => scope.type;
  RoutineId? get routineId => scope.routineId;
  ExerciseRef? get exerciseRef => scope.exerciseRef;

  static String normalizeBody(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized.runes.length > 500) {
      throw ArgumentError.value(value, 'body', 'must contain 1-500 characters');
    }
    return normalized;
  }

  factory RoutineNote.fromJson(Map<String, dynamic> json) {
    final routineId = json['routine_id'];
    final exerciseRef = json['exercise_ref'];
    final scope = routineId is String && exerciseRef == null
        ? RoutineNoteScope.routine(RoutineId(routineId))
        : exerciseRef is String && routineId == null
            ? RoutineNoteScope.exercise(ExerciseRef.parse(exerciseRef))
            : throw const FormatException('Invalid RoutineNote scope.');
    if (RoutineNoteType.parse(json['note_type']) != scope.type) {
      throw const FormatException('Invalid RoutineNote type/scope.');
    }
    final createdAt = _dateTime(json['created_at'], 'created_at');
    final updatedAt = _dateTime(json['updated_at'], 'updated_at');
    final revision = json['revision'];
    if (revision is! int) throw const FormatException('Invalid Note revision.');
    return RoutineNote(
      id: _string(json['id'], 'id'),
      userId: _string(json['user_id'], 'user_id'),
      scope: scope,
      body: _string(json['body'], 'body'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      revision: revision,
      lastMutationId: json['last_mutation_id'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RoutineNote &&
      id == other.id &&
      userId == other.userId &&
      scope == other.scope &&
      body == other.body &&
      createdAt == other.createdAt &&
      updatedAt == other.updatedAt &&
      revision == other.revision &&
      lastMutationId == other.lastMutationId;

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        scope,
        body,
        createdAt,
        updatedAt,
        revision,
        lastMutationId,
      );
}

String _uuid(Object? value, String name) {
  final text = value is String ? value.trim().toLowerCase() : '';
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  ).hasMatch(text)) {
    throw FormatException('Invalid RoutineNote $name.');
  }
  return text;
}

String _string(Object? value, String name) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid RoutineNote $name.');
  }
  return value;
}

DateTime _dateTime(Object? value, String name) {
  if (value is! String) throw FormatException('Invalid RoutineNote $name.');
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid RoutineNote $name.');
  return parsed.toUtc();
}
