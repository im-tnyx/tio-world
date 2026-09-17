import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('trims nonblank text and exposes the canonical text draft', () async {
    final repository = _RecordingRepository();
    final controller = MealTextParseController(repository: repository);

    final result = await controller.submit('  2 roti with dal  ');

    expect(repository.inputs, ['2 roti with dal']);
    expect(result, same(repository.result));
    expect(controller.state.status, MealTextParseStatus.succeeded);
    expect(controller.state.submittedText, '2 roti with dal');
    expect(controller.state.draft, same(repository.result));
    expect(controller.state.draft!.captureSource, MealLogCaptureSource.text);
  });

  test('blank input is a no-op and never invokes the repository', () async {
    final repository = _RecordingRepository();
    final controller = MealTextParseController(repository: repository);

    expect(controller.canSubmit('   '), isFalse);
    expect(await controller.submit('   '), isNull);

    expect(repository.inputs, isEmpty);
    expect(controller.state.status, MealTextParseStatus.idle);
    expect(controller.state.submittedText, isNull);
  });

  test('processing state suppresses duplicate in-flight submissions', () async {
    final completer = Completer<MealLoggingDraft>();
    final repository = _RecordingRepository(
      onParse: (_) => completer.future,
    );
    final controller = MealTextParseController(repository: repository);

    final first = controller.submit('roti dal');

    expect(controller.state.status, MealTextParseStatus.processing);
    expect(controller.state.submittedText, 'roti dal');
    expect(controller.canSubmit('another meal'), isFalse);
    expect(await controller.submit('another meal'), isNull);
    expect(repository.inputs, ['roti dal']);

    completer.complete(repository.result);
    expect(await first, same(repository.result));
    expect(controller.state.status, MealTextParseStatus.succeeded);
  });

  test('recoverable failure preserves text and retry can succeed', () async {
    var attempts = 0;
    final repository = _RecordingRepository(
      onParse: (_) async {
        attempts += 1;
        if (attempts == 1) {
          throw const MealTextParseFailure(
            MealTextParseFailureReason.incomplete,
          );
        }
        return _textDraft();
      },
    );
    final controller = MealTextParseController(repository: repository);

    expect(await controller.submit('  dal chawal  '), isNull);
    expect(controller.state.status, MealTextParseStatus.failed);
    expect(controller.state.canRetry, isTrue);
    expect(controller.state.submittedText, 'dal chawal');
    expect(controller.state.message, MealTextParseController.incompleteMessage);

    final result = await controller.retry();

    expect(result, isNotNull);
    expect(repository.inputs, ['dal chawal', 'dal chawal']);
    expect(controller.state.status, MealTextParseStatus.succeeded);
  });

  test('safe failure reasons map to stable controller messages', () async {
    for (final expectation in <
        (MealTextParseFailureReason, String)>[
      (
        MealTextParseFailureReason.unrecognized,
        MealTextParseController.unrecognizedMessage,
      ),
      (
        MealTextParseFailureReason.incomplete,
        MealTextParseController.incompleteMessage,
      ),
      (
        MealTextParseFailureReason.unavailable,
        MealTextParseController.unavailableMessage,
      ),
    ]) {
      final repository = _RecordingRepository(
        onParse: (_) async => throw MealTextParseFailure(expectation.$1),
      );
      final controller = MealTextParseController(repository: repository);

      expect(await controller.submit('meal'), isNull);
      expect(controller.state.status, MealTextParseStatus.failed);
      expect(controller.state.message, expectation.$2);
      expect(controller.state.draft, isNull);
    }
  });

  test('unexpected repository errors are sanitized as unavailable', () async {
    final repository = _RecordingRepository(
      onParse: (_) async => throw StateError('provider secret detail'),
    );
    final controller = MealTextParseController(repository: repository);

    expect(await controller.submit('meal'), isNull);

    expect(controller.state.status, MealTextParseStatus.failed);
    expect(controller.state.message, MealTextParseController.unavailableMessage);
    expect(controller.state.message, isNot(contains('provider secret detail')));
    expect(controller.state.submittedText, 'meal');
  });

  test('rejects a repository result with non-text capture provenance', () async {
    final repository = _RecordingRepository(
      result: MealLoggingDraft(
        captureSource: MealLogCaptureSource.foodSearch,
        items: [
          MealLoggingDraftItem(
            displayName: 'Roti',
            quantity: 2,
            servingUnit: 'piece',
            consumedNutritionSnapshot: NutritionSnapshot(
              schemaVersion: 1,
              nutrients: const {NutrientId.energy: 200},
            ),
          ),
        ],
      ),
    );
    final controller = MealTextParseController(repository: repository);

    expect(await controller.submit('2 roti'), isNull);

    expect(controller.state.status, MealTextParseStatus.failed);
    expect(controller.state.message, MealTextParseController.unavailableMessage);
    expect(controller.state.draft, isNull);
  });

  test('retry is ignored unless a failed submission is available', () async {
    final repository = _RecordingRepository();
    final controller = MealTextParseController(repository: repository);

    expect(await controller.retry(), isNull);
    expect(repository.inputs, isEmpty);
  });
}

final class _RecordingRepository implements MealTextParseRepository {
  _RecordingRepository({
    MealLoggingDraft? result,
    this.onParse,
  }) : result = result ?? _textDraft();

  final MealLoggingDraft result;
  final Future<MealLoggingDraft> Function(String text)? onParse;
  final List<String> inputs = [];

  @override
  Future<MealLoggingDraft> parseMealText(String text) {
    inputs.add(text);
    final callback = onParse;
    if (callback != null) return callback(text);
    return Future.value(result);
  }
}

MealLoggingDraft _textDraft() => MealLoggingDraft(
      mealName: 'Roti and dal',
      captureSource: MealLogCaptureSource.text,
      items: [
        MealLoggingDraftItem(
          displayName: 'Roti',
          quantity: 2,
          servingUnit: 'piece',
          consumedNutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {
              NutrientId.energy: 200,
              NutrientId.protein: 6,
            },
          ),
        ),
        MealLoggingDraftItem(
          displayName: 'Dal',
          quantity: 1,
          servingUnit: 'bowl',
          consumedNutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {
              NutrientId.energy: 180,
              NutrientId.protein: 9,
            },
          ),
        ),
      ],
    );
