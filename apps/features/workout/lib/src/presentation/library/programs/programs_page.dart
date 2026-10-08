import 'package:flutter/material.dart';

import '../../../domain/repositories/program_repository.dart';
import '../../../domain/usecases/program_id_generator.dart';
import 'programs_surface.dart';

/// Persisted user Program collection/manage screen.
///
/// Library also renders this collection directly. This route remains an
/// optional secondary management surface rather than a mandatory intermediate
/// step.
class ProgramsPage extends StatelessWidget {
  const ProgramsPage({
    required this.repository,
    super.key,
    this.idGenerator,
  });

  /// Null means durable Program persistence is unavailable in app composition.
  final ProgramRepository? repository;
  final ProgramIdGenerator? idGenerator;

  @override
  Widget build(BuildContext context) => ProgramsSurface.standalone(
        repository: repository,
        idGenerator: idGenerator,
      );
}
