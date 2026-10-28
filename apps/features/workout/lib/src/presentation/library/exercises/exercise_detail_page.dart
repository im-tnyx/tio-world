import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_repository.dart';
import '../../../domain/exercises/user_exercise_repository.dart';
import 'custom_exercise_editor_page.dart';
import 'custom_exercises_controller.dart';
import 'custom_exercises_state.dart';
import 'exercise_detail_controller.dart';
import 'exercise_detail_state.dart';
import 'exercise_taxonomy_labels.dart';
import 'exercise_video_player.dart';

/// Route payload used by app composition to preserve the owner/login-cycle
/// provenance captured when a Custom row was opened.
final class ExerciseDetailRouteArguments {
  const ExerciseDetailRouteArguments({
    this.ownerId,
    this.loginCycleId,
  });

  final String? ownerId;
  final String? loginCycleId;
}

class ExerciseDetailPage extends StatefulWidget {
  const ExerciseDetailPage({
    required this.exerciseRef,
    required this.catalogRepository,
    this.userExerciseRepository,
    this.viewerMediaGender,
    this.expectedOwnerId,
    this.expectedLoginCycleId,
    this.currentUserId,
    this.currentLoginCycleId,
    this.videoControllerFactory = createExerciseVideoController,
    super.key,
  });

  final ExerciseRef exerciseRef;
  final ExerciseCatalogRepository catalogRepository;
  final UserExerciseRepository? userExerciseRepository;
  final ExerciseMediaGender? viewerMediaGender;
  final String? expectedOwnerId;
  final String? expectedLoginCycleId;
  final ExerciseDetailSessionValue? currentUserId;
  final ExerciseDetailSessionValue? currentLoginCycleId;
  final ExerciseVideoControllerFactory videoControllerFactory;

  @override
  State<ExerciseDetailPage> createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  late ExerciseDetailController _controller;
  CustomExercisesController? _customController;

  @override
  void initState() {
    super.initState();
    _createControllers();
  }

  void _createControllers() {
    _controller = ExerciseDetailController(
      exerciseRef: widget.exerciseRef,
      catalogRepository: widget.catalogRepository,
      userExerciseRepository: widget.userExerciseRepository,
      expectedOwnerId: widget.expectedOwnerId,
      expectedLoginCycleId: widget.expectedLoginCycleId,
      currentUserId: widget.currentUserId,
      currentLoginCycleId: widget.currentLoginCycleId,
    )..addListener(_onControllerChanged);
    if (widget.exerciseRef is UserCreatedExerciseRef &&
        widget.userExerciseRepository != null) {
      _customController = CustomExercisesController(
        repository: widget.userExerciseRepository!,
      )..load();
    }
    unawaited(_controller.load());
  }

  @override
  void didUpdateWidget(covariant ExerciseDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exerciseRef != widget.exerciseRef ||
        oldWidget.catalogRepository != widget.catalogRepository ||
        oldWidget.userExerciseRepository != widget.userExerciseRepository ||
        oldWidget.expectedOwnerId != widget.expectedOwnerId ||
        oldWidget.expectedLoginCycleId != widget.expectedLoginCycleId) {
      _controller
        ..removeListener(_onControllerChanged)
        ..dispose();
      _customController?.dispose();
      _createControllers();
    } else if (oldWidget.currentUserId != widget.currentUserId ||
        oldWidget.currentLoginCycleId != widget.currentLoginCycleId) {
      // The route builder rebuilds on auth changes. Re-resolve a Custom row so
      // stale content cannot remain visible across login cycles.
      unawaited(_controller.load());
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openEdit() async {
    final customController = _customController;
    if (!mounted || customController == null) return;
    if (!await _controller.revalidateCustom()) return;
    final exercise = _controller.state.exercise;
    if (!mounted || exercise == null || !_controller.canEdit) return;
    await customController.load();
    if (!mounted ||
        customController.state.status != CustomExercisesStatus.ready) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CustomExerciseEditorPage(
          controller: customController,
          exercise: exercise,
        ),
      ),
    );
    if (!mounted) return;
    await _controller.load();
    await customController.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final exercise = state.exercise;
    final canEdit = _controller.canEdit;
    return Scaffold(
      key: const ValueKey('exercise-detail-page'),
      backgroundColor: context.tioColors.background,
      appBar: TioAppBar(
        backgroundColor: context.tioColors.background,
        elevation: TioElevation.none,
        scrolledUnderElevation: TioElevation.none,
        leading: BackButton(
          key: const ValueKey('exercise-detail-back'),
          color: context.tioColors.textPrimary,
        ),
        title: Text(
          exercise?.displayName ?? 'Exercise',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.tioColors.textPrimary,
            fontWeight: TioFontWeight.w800,
            fontSize: TioFontSize.size20,
          ),
        ),
        actions: canEdit
            ? [
                PopupMenuButton<String>(
                  key: const ValueKey('exercise-detail-options'),
                  tooltip: 'Exercise options',
                  onSelected: (value) {
                    if (value == 'edit') unawaited(_openEdit());
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Edit Exercise'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: switch (state.status) {
        ExerciseDetailStatus.loading => const Center(
            key: ValueKey('exercise-detail-loading'),
            child: CircularProgressIndicator(),
          ),
        ExerciseDetailStatus.unavailable => const _DetailMessage(
            key: ValueKey('exercise-detail-unavailable'),
            text: 'This Exercise is unavailable for the current account.',
          ),
        ExerciseDetailStatus.failed => _DetailMessage(
            key: const ValueKey('exercise-detail-failed'),
            text: state.errorMessage ?? 'Exercise details are unavailable.',
          ),
        ExerciseDetailStatus.ready => _DetailBody(
            exercise: exercise!,
            viewerMediaGender: widget.viewerMediaGender,
            videoControllerFactory: widget.videoControllerFactory,
          ),
      },
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _customController?.dispose();
    super.dispose();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.exercise,
    required this.viewerMediaGender,
    required this.videoControllerFactory,
  });

  final Exercise exercise;
  final ExerciseMediaGender? viewerMediaGender;
  final ExerciseVideoControllerFactory videoControllerFactory;

  @override
  Widget build(BuildContext context) {
    final videoUrl = exercise.media?.urlFor(
      ExerciseMediaKind.video,
      gender: viewerMediaGender,
    );
    final instructions = _localizedInstructions(context, exercise);
    final title = _localizedTitle(context, exercise);
    final metadata = _metadata(exercise);

    return ListView(
      key: const ValueKey('exercise-detail-scroll'),
      padding: const EdgeInsets.only(bottom: TioSpacing.xl),
      children: [
        _ExerciseVideoMedia(
          url: videoUrl,
          controllerFactory: videoControllerFactory,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.lg,
            TioSpacing.xl,
            TioSpacing.lg,
            TioSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                key: const ValueKey('exercise-detail-name'),
                style: TextStyle(
                  color: context.tioColors.textPrimary,
                  fontSize: TioFontSize.size24,
                  fontWeight: TioFontWeight.w800,
                ),
              ),
              if (metadata != null) ...[
                const SizedBox(height: TioSpacing.sm),
                Text(
                  metadata,
                  key: const ValueKey('exercise-detail-metadata'),
                  style: TextStyle(
                    color: context.tioColors.textSecondary,
                    fontSize: TioFontSize.size14,
                  ),
                ),
              ],
              if (exercise.description != null) ...[
                const SizedBox(height: TioSpacing.lg),
                Text(
                  exercise.description!,
                  key: const ValueKey('exercise-detail-description'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              const SizedBox(height: TioSpacing.xl),
              Text(
                'Instructions',
                key: const ValueKey('exercise-detail-instructions-heading'),
                style: TextStyle(
                  color: context.tioColors.textPrimary,
                  fontSize: TioFontSize.size18,
                  fontWeight: TioFontWeight.w800,
                ),
              ),
              const SizedBox(height: TioSpacing.sm),
              if (instructions.isEmpty)
                const _EmptyInstructions()
              else
                for (var index = 0; index < instructions.length; index++)
                  _InstructionStep(
                    number: index + 1,
                    text: instructions[index],
                  ),
            ],
          ),
        ),
      ],
    );
  }

  static String? _metadata(Exercise exercise) {
    final values = <String>[
      if (exercise.primaryEquipment case final equipment?)
        exerciseTaxonomyLabel(equipment),
      if (exercise.muscleGroup case final muscleGroup?)
        exerciseTaxonomyLabel(muscleGroup),
      if (exercise.primaryMuscles.isNotEmpty)
        exerciseTaxonomyLabel(exercise.primaryMuscles.first),
    ];
    return values.isEmpty ? null : values.join(' • ');
  }
}

/// Keeps the media item alive while the surrounding detail ListView recycles
/// off-screen children. The player must be released when the detail route is
/// disposed, but scrolling must not create a new controller or reload media.
class _ExerciseVideoMedia extends StatefulWidget {
  const _ExerciseVideoMedia({
    required this.url,
    required this.controllerFactory,
  });

  final Uri? url;
  final ExerciseVideoControllerFactory controllerFactory;

  @override
  State<_ExerciseVideoMedia> createState() => _ExerciseVideoMediaState();
}

class _ExerciseVideoMediaState extends State<_ExerciseVideoMedia>
    with AutomaticKeepAliveClientMixin<_ExerciseVideoMedia> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final url = widget.url;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: url == null
          ? const ExerciseMediaFallback(
              message: 'No demonstration video available.',
            )
          : ExerciseVideoPlayer(
              key: const ValueKey('exercise-detail-video'),
              url: url,
              controllerFactory: widget.controllerFactory,
            ),
    );
  }
}

String _localizedTitle(BuildContext context, Exercise exercise) {
  final values = exercise.localizedTitles;
  final locale = Localizations.localeOf(context);
  return values[_localeKey(locale)] ??
      values[locale.languageCode] ??
      values['en'] ??
      exercise.displayName;
}

List<String> _localizedInstructions(BuildContext context, Exercise exercise) {
  final values = exercise.localizedInstructions;
  final locale = Localizations.localeOf(context);
  return values[_localeKey(locale)] ??
      values[locale.languageCode] ??
      values['en'] ??
      const [];
}

String _localeKey(Locale locale) => [
      locale.languageCode,
      if (locale.scriptCode case final script?) script,
      if (locale.countryCode case final country?) country,
    ].join('-');

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        key: ValueKey('exercise-detail-step-$number'),
        container: true,
        label: 'Step $number: $text',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TioSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.tioColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: TioSize.dp32,
                  height: TioSize.dp32,
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: context.tioColors.textPrimary,
                        fontWeight: TioFontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyInstructions extends StatelessWidget {
  const _EmptyInstructions();

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: TioSpacing.md),
          child: Text(
            'Instructions are not available for this Exercise.',
            style: TextStyle(
              color: context.tioColors.textSecondary,
              fontSize: TioFontSize.size14,
            ),
          ),
        ),
      );
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(TioSpacing.xl),
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.tioColors.textSecondary,
                fontSize: TioFontSize.size15,
              ),
            ),
          ),
        ),
      );
}
