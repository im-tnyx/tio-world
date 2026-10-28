import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  testWidgets('renders canonical identity and ordered localized instructions',
      (tester) async {
    final exercise = _exercise(
      'ex_detail_squat',
      'Squat',
      localizedTitles: const {'en': 'Squat (Barbell)'},
      localizedInstructions: const {
        'en': ['Brace your core.', 'Lower with control.', 'Stand tall.'],
      },
      description: 'A synthetic detail fixture.',
      equipment: 'barbell',
      muscleGroup: 'quadriceps',
    );

    final semantics = tester.ensureSemantics();
    await _pumpDetail(tester, exercise: exercise);

    expect(find.byKey(const ValueKey('exercise-detail-page')), findsOneWidget);
    expect(find.text('Squat (Barbell)'), findsOneWidget);
    expect(find.text('Brace your core.'), findsOneWidget);
    expect(find.text('Lower with control.'), findsOneWidget);
    expect(find.text('Stand tall.'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('exercise-detail-step-1')),
          )
          .getSemanticsData()
          .label,
      contains('Step 1: Brace your core.'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('exercise-detail-step-2')),
          )
          .getSemanticsData()
          .label,
      contains('Step 2: Lower with control.'),
    );
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('exercise-detail-step-3')),
          )
          .getSemanticsData()
          .label,
      contains('Step 3: Stand tall.'),
    );
    expect(find.text('Barbell • Quadriceps'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shows truthful fallback when video and instructions are absent',
      (tester) async {
    final exercise = _exercise('ex_detail_empty', 'Empty Exercise');

    await _pumpDetail(tester, exercise: exercise);

    expect(find.text('No demonstration video available.'), findsOneWidget);
    expect(
      find.text('Instructions are not available for this Exercise.'),
      findsOneWidget,
    );
  });

  testWidgets('owner can explicitly open Edit Exercise from Custom Detail',
      (tester) async {
    final exercise = _exercise(
      '10000000-0000-4000-8000-000000000001',
      'Owner Custom',
      custom: true,
    );
    const owner = 'owner-1';
    const cycle = 'cycle-1';

    await _pumpDetail(
      tester,
      exercise: exercise,
      userExerciseRepository: _FakeUserExerciseRepository([exercise]),
      expectedOwnerId: owner,
      expectedLoginCycleId: cycle,
      currentUserId: () => owner,
      currentLoginCycleId: () => cycle,
    );

    final options = find.byKey(const ValueKey('exercise-detail-options'));
    expect(options, findsOneWidget);
    await tester.tap(options);
    await tester.pumpAndSettle();
    expect(find.text('Edit Exercise'), findsOneWidget);
    await tester.tap(find.text('Edit Exercise'));
    await tester.pumpAndSettle();
    expect(find.byType(CustomExerciseEditorPage), findsOneWidget);
  });

  testWidgets('wrong-owner Custom Detail fails closed and hides edit',
      (tester) async {
    final exercise = _exercise(
      '10000000-0000-4000-8000-000000000002',
      'Other Custom',
      custom: true,
    );

    await _pumpDetail(
      tester,
      exercise: exercise,
      userExerciseRepository: _FakeUserExerciseRepository([exercise]),
      expectedOwnerId: 'owner-1',
      expectedLoginCycleId: 'cycle-1',
      currentUserId: () => 'owner-2',
      currentLoginCycleId: () => 'cycle-2',
    );

    expect(
      find.text('This Exercise is unavailable for the current account.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('exercise-detail-options')), findsNothing);
  });

  testWidgets(
      'video player loops, autoplays, pauses on next route and disposes',
      (tester) async {
    late _FakeVideoHandle handle;
    final url = Uri.parse('https://media.example/squat.mp4');

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [exerciseDetailRouteObserver],
        home: Scaffold(
          body: ExerciseVideoPlayer(
            url: url,
            controllerFactory: (receivedUrl) {
              expect(receivedUrl, url);
              return handle = _FakeVideoHandle();
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(handle.loopingCalls, 1);
    expect(handle.playCalls, 1);
    expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    expect(handle.pauseCalls, greaterThanOrEqualTo(1));

    navigator.pop();
    await tester.pumpAndSettle();
    expect(handle.playCalls, greaterThanOrEqualTo(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(handle.disposeCalls, 1);
  });

  testWidgets('scrolling detail does not recreate the video controller',
      (tester) async {
    final url = Uri.parse('https://media.example/scroll-stable.mp4');
    final exercise = _exercise(
      'ex_detail_scroll',
      'Scroll Stable Exercise',
      localizedInstructions: {
        'en': List<String>.generate(14, (index) => 'Step content $index.'),
      },
      media: ExerciseMedia(
        type: ExerciseMediaType.video,
        defaultGender: ExerciseMediaGender.male,
        male: ExerciseMediaVariant(videoUrl: url),
        female: ExerciseMediaVariant(),
      ),
    );
    var factoryCalls = 0;
    final handles = <_FakeVideoHandle>[];

    await _pumpDetail(
      tester,
      exercise: exercise,
      videoControllerFactory: (receivedUrl) {
        expect(receivedUrl, url);
        factoryCalls++;
        final handle = _FakeVideoHandle();
        handles.add(handle);
        return handle;
      },
    );
    expect(factoryCalls, 1);

    final scroll = find.byKey(const ValueKey('exercise-detail-scroll'));
    await tester.drag(scroll, const Offset(0, -1200));
    await tester.pumpAndSettle();
    await tester.drag(scroll, const Offset(0, 1200));
    await tester.pumpAndSettle();

    expect(factoryCalls, 1);
    expect(handles.single.disposeCalls, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(handles.single.disposeCalls, 1);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required Exercise exercise,
  UserExerciseRepository? userExerciseRepository,
  String? expectedOwnerId,
  String? expectedLoginCycleId,
  ExerciseDetailSessionValue? currentUserId,
  ExerciseDetailSessionValue? currentLoginCycleId,
  ExerciseVideoControllerFactory? videoControllerFactory,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: ExerciseDetailPage(
        exerciseRef: exercise.ref,
        catalogRepository: _FakeCatalogRepository(
          exercise.ref is CatalogExerciseRef ? exercise : null,
        ),
        userExerciseRepository: userExerciseRepository,
        expectedOwnerId: expectedOwnerId,
        expectedLoginCycleId: expectedLoginCycleId,
        currentUserId: currentUserId,
        currentLoginCycleId: currentLoginCycleId,
        videoControllerFactory:
            videoControllerFactory ?? createExerciseVideoController,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Exercise _exercise(
  String id,
  String name, {
  bool custom = false,
  String? description,
  Map<String, String> localizedTitles = const {},
  Map<String, List<String>> localizedInstructions = const {},
  String? equipment,
  String? muscleGroup,
  ExerciseMedia? media,
}) =>
    Exercise(
      ref: custom ? ExerciseRef.userCreated(id) : ExerciseRef.catalog(id),
      displayName: name,
      description: description,
      localizedTitles: localizedTitles,
      localizedInstructions: localizedInstructions,
      primaryEquipment: equipment,
      muscleGroup: muscleGroup,
      media: media,
      status: ExerciseStatus.active,
    );

final class _FakeCatalogRepository implements ExerciseCatalogRepository {
  _FakeCatalogRepository(this.exercise);

  final Exercise? exercise;

  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog(
        exercise == null ? const [] : [exercise!],
      );
}

final class _FakeUserExerciseRepository implements UserExerciseRepository {
  _FakeUserExerciseRepository(this.exercises);

  final List<Exercise> exercises;

  @override
  Future<List<Exercise>> list({bool includeArchived = false}) async =>
      List<Exercise>.unmodifiable(
        exercises.where(
          (exercise) =>
              includeArchived || exercise.status == ExerciseStatus.active,
        ),
      );

  @override
  Future<void> archive(UserCreatedExerciseRef id) async {}

  @override
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
    UserExerciseDefinition? definition,
  }) async {}

  @override
  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  }) async {}

  @override
  Future<void> updateDefinition({
    required UserCreatedExerciseRef id,
    required UserExerciseDefinition definition,
  }) async {}
}

final class _FakeVideoHandle implements ExerciseVideoControllerHandle {
  _FakeVideoHandle()
      : _state = ValueNotifier(
          const ExerciseVideoPlayerState(initialized: false),
        );

  final ValueNotifier<ExerciseVideoPlayerState> _state;
  int loopingCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  int disposeCalls = 0;

  @override
  ValueListenable<ExerciseVideoPlayerState> get state => _state;

  @override
  Future<void> initialize() async {
    _state.value = const ExerciseVideoPlayerState(initialized: true);
  }

  @override
  Future<void> setLooping(bool looping) async {
    if (looping) loopingCalls++;
  }

  @override
  Future<void> play() async => playCalls++;

  @override
  Future<void> pause() async => pauseCalls++;

  @override
  Widget build(BuildContext context) => const ColoredBox(
        key: ValueKey('fake-video'),
        color: Colors.black,
      );

  @override
  Future<void> dispose() async => disposeCalls++;
}
