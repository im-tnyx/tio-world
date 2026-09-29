import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/usecases/program_id_generator.dart';

enum ProgramsStatus { loading, ready, loadFailed }

final class ProgramsState {
  const ProgramsState.loading()
      : status = ProgramsStatus.loading,
        programs = const [],
        loadError = null,
        creating = false,
        createError = null;

  ProgramsState.ready({
    required List<Program> programs,
    this.creating = false,
    this.createError,
  })  : status = ProgramsStatus.ready,
        programs = List.unmodifiable(programs),
        loadError = null;

  const ProgramsState.loadFailed(this.loadError)
      : status = ProgramsStatus.loadFailed,
        programs = const [],
        creating = false,
        createError = null;

  final ProgramsStatus status;
  final List<Program> programs;
  final String? loadError;
  final bool creating;
  final String? createError;
}

/// Owns persisted Program loading and the bounded empty-Program create flow.
final class ProgramsController extends ChangeNotifier {
  ProgramsController({
    required this.repository,
    ProgramIdGenerator? idGenerator,
  }) : idGenerator = idGenerator ?? UuidProgramIdGenerator();

  final ProgramRepository repository;
  final ProgramIdGenerator idGenerator;

  ProgramsState _state = const ProgramsState.loading();
  ProgramsState get state => _state;

  var _loadVersion = 0;
  var _disposed = false;

  Future<void> load() async {
    final version = ++_loadVersion;
    _publish(const ProgramsState.loading());

    try {
      final programs = await repository.list();
      if (_disposed || version != _loadVersion) return;
      _publish(ProgramsState.ready(programs: programs));
    } catch (_) {
      if (_disposed || version != _loadVersion) return;
      _publish(
        const ProgramsState.loadFailed(
          'Could not load programs. Please try again.',
        ),
      );
    }
  }

  Future<void> retryLoad() => load();

  String suggestedName() {
    final names = _state.programs
        .map((program) => program.name.trim().toLowerCase())
        .toSet();
    var index = 1;
    while (names.contains('program $index')) {
      index++;
    }
    return 'Program $index';
  }

  Future<bool> create(String name) async {
    final current = _state;
    if (current.status != ProgramsStatus.ready || current.creating) {
      return false;
    }

    if (name.trim().isEmpty) {
      _publish(
        ProgramsState.ready(
          programs: current.programs,
          createError: 'Enter a program name.',
        ),
      );
      return false;
    }

    late final Program program;
    try {
      program = Program(
        id: idGenerator.generate(current.programs.map((item) => item.id)),
        name: name,
      );
    } catch (_) {
      _publish(
        ProgramsState.ready(
          programs: current.programs,
          createError: 'Could not create program. Please try again.',
        ),
      );
      return false;
    }

    _publish(
      ProgramsState.ready(
        programs: current.programs,
        creating: true,
      ),
    );

    try {
      await repository.create(program);
      if (_disposed) return false;
      _publish(
        ProgramsState.ready(
          programs: [...current.programs, program],
        ),
      );
      return true;
    } catch (error) {
      if (_disposed) return false;
      _publish(
        ProgramsState.ready(
          programs: current.programs,
          createError: _createFailureMessage(error),
        ),
      );
      return false;
    }
  }

  String _createFailureMessage(Object error) {
    if (error is StateError &&
        error.message.toString() == 'Please sign in to save Programs.') {
      return 'Please sign in to save Programs.';
    }
    return 'Could not create program. Please try again.';
  }

  void _publish(ProgramsState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadVersion++;
    super.dispose();
  }
}
