import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('SupabaseMealTextParseRepository request', () {
    test('invokes the exact function name with schemaVersion and mealText',
        () async {
      final gateway = _RecordingGateway(response: _successResponse());
      final repository = _repository(gateway);

      await repository.parseMealText('2 roti with dal');

      expect(gateway.functionNames, ['nutrition-meal-text-parse']);
      expect(gateway.bodies.single, {
        'schemaVersion': 1,
        'mealText': '2 roti with dal',
      });
      expect(gateway.abortSignals.single, isNotNull);
    });

    test('client timeout aborts the gateway and maps to unavailable', () async {
      final gateway = _AbortAwareGateway();
      final repository = _repository(
        gateway,
        requestTimeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        repository.parseMealText('2 roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );

      expect(gateway.abortSignalWasProvided, isTrue);
    });
  });

  group('SupabaseMealTextParseRepository success decoding', () {
    test('maps mealName, ordered items, quantity, servingUnit, snapshot, '
        'and captureSource', () async {
      final gateway = _RecordingGateway(
        response: _successResponse(
          mealName: 'Lunch',
          items: [
            _item(displayName: 'Roti', quantity: 2, servingUnit: 'piece'),
            _item(displayName: 'Dal', quantity: 150, servingUnit: 'g'),
          ],
        ),
      );
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('2 roti with dal');

      expect(draft.mealName, 'Lunch');
      expect(draft.captureSource, MealLogCaptureSource.text);
      expect(draft.items, hasLength(2));
      expect(draft.items[0].displayName, 'Roti');
      expect(draft.items[0].quantity, 2);
      expect(draft.items[0].servingUnit, 'piece');
      expect(draft.items[1].displayName, 'Dal');
      expect(draft.items[1].quantity, 150);
      expect(draft.items[1].servingUnit, 'g');
    });

    test('succeeds without a mealName', () async {
      final gateway = _RecordingGateway(response: _successResponse());
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('2 roti');

      expect(draft.mealName, isNull);
      expect(draft.items, hasLength(1));
    });

    test('present non-string mealName maps to unavailable', () async {
      final response = _successResponse()..['mealName'] = 123;
      final gateway = _RecordingGateway(response: response);
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('2 roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('item ordering is preserved', () async {
      final gateway = _RecordingGateway(
        response: _successResponse(
          items: [
            _item(displayName: 'First'),
            _item(displayName: 'Second'),
            _item(displayName: 'Third'),
          ],
        ),
      );
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('three items');

      expect(
        draft.items.map((item) => item.displayName),
        ['First', 'Second', 'Third'],
      );
    });

    test('canonical zero nutrient remains explicit zero', () async {
      final gateway = _RecordingGateway(
        response: _successResponse(
          items: [
            _item(
              nutrients: {'added_sugar': 0, 'energy': 120},
            ),
          ],
        ),
      );
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('roti');

      final snapshot = draft.items.single.consumedNutritionSnapshot!;
      expect(snapshot.amountFor(NutrientId.addedSugar), 0);
      expect(snapshot.containsNutrient(NutrientId.addedSugar), isTrue);
      expect(snapshot.amountFor(NutrientId.protein), isNull);
    });

    test('unknown future nutrient identity is ignored, not remapped',
        () async {
      final gateway = _RecordingGateway(
        response: _successResponse(
          items: [
            _item(
              nutrients: {'energy': 120, 'future_nutrient_xyz': 42},
            ),
          ],
        ),
      );
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('roti');

      final snapshot = draft.items.single.consumedNutritionSnapshot!;
      expect(snapshot.amountFor(NutrientId.energy), 120);
      expect(snapshot.nutrients, hasLength(1));
    });

    test('raw/provider-specific response fields do not enter the draft',
        () async {
      final response = _successResponse();
      (response['items'] as List).cast<Map<String, Object?>>().first
        ..['providerId'] = 'fatsecret:12345'
        ..['confidence'] = 0.87;
      response['providerRequestId'] = 'req_abc123';
      final gateway = _RecordingGateway(response: response);
      final repository = _repository(gateway);

      final draft = await repository.parseMealText('roti');

      expect(draft.items.single.displayName, 'Roti');
      // MealLoggingDraft/MealLoggingDraftItem have no fields for provider
      // identity/confidence/request-id, so a successful decode already
      // proves none of that crossed into Tio-owned domain state.
    });
  });

  group('SupabaseMealTextParseRepository outcome failures', () {
    test('unrecognized outcome throws a typed failure', () async {
      final gateway = _RecordingGateway(
        response: {'schemaVersion': 1, 'outcome': 'unrecognized'},
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('gibberish'),
        _throwsReason(MealTextParseFailureReason.unrecognized),
      );
    });

    test('incomplete outcome throws a typed failure', () async {
      final gateway = _RecordingGateway(
        response: {'schemaVersion': 1, 'outcome': 'incomplete'},
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('some roti'),
        _throwsReason(MealTextParseFailureReason.incomplete),
      );
    });

    test('unavailable outcome throws a typed failure', () async {
      final gateway = _RecordingGateway(
        response: {'schemaVersion': 1, 'outcome': 'unavailable'},
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });
  });

  group('SupabaseMealTextParseRepository defensive decoding', () {
    test('malformed top-level response maps to unavailable', () async {
      final gateway = _RecordingGateway(response: 'not a map');
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('wrong schemaVersion maps to unavailable', () async {
      final gateway = _RecordingGateway(
        response: {
          'schemaVersion': 2,
          'outcome': 'success',
          'items': <Object?>[],
        },
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('unknown outcome maps to unavailable', () async {
      final gateway = _RecordingGateway(
        response: {'schemaVersion': 1, 'outcome': 'mystery'},
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('success with absent items maps to unavailable', () async {
      final gateway = _RecordingGateway(
        response: {'schemaVersion': 1, 'outcome': 'success'},
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('success with empty items maps to unavailable', () async {
      final gateway = _RecordingGateway(
        response: {
          'schemaVersion': 1,
          'outcome': 'success',
          'items': <Object?>[],
        },
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('malformed item maps to unavailable', () async {
      for (final malformedItem in <Object?>[
        'not a map',
        {'quantity': 2, 'servingUnit': 'g', 'nutritionSnapshot': _snapshot()},
        {
          'displayName': '  ',
          'quantity': 2,
          'servingUnit': 'g',
          'nutritionSnapshot': _snapshot(),
        },
        {
          'displayName': 'Roti',
          'quantity': -1,
          'servingUnit': 'g',
          'nutritionSnapshot': _snapshot(),
        },
        {
          'displayName': 'Roti',
          'quantity': 2,
          'servingUnit': '',
          'nutritionSnapshot': _snapshot(),
        },
        {'displayName': 'Roti', 'quantity': 2, 'servingUnit': 'g'},
      ]) {
        final gateway = _RecordingGateway(
          response: {
            'schemaVersion': 1,
            'outcome': 'success',
            'items': [malformedItem],
          },
        );
        final repository = _repository(gateway);

        await expectLater(
          repository.parseMealText('roti'),
          _throwsReason(MealTextParseFailureReason.unavailable),
          reason: 'malformed item: $malformedItem',
        );
      }
    });

    test('malformed nutrition snapshot maps to unavailable', () async {
      final gateway = _RecordingGateway(
        response: {
          'schemaVersion': 1,
          'outcome': 'success',
          'items': [
            {
              'displayName': 'Roti',
              'quantity': 2,
              'servingUnit': 'piece',
              'nutritionSnapshot': {'schemaVersion': 'not-an-int'},
            },
          ],
        },
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('unsupported nutrition snapshot schemaVersion maps to unavailable',
        () async {
      final gateway = _RecordingGateway(
        response: {
          'schemaVersion': 1,
          'outcome': 'success',
          'items': [
            _item()..['nutritionSnapshot'] = {
                'schemaVersion': 2,
                'nutrients': {'energy': 100},
              },
          ],
        },
      );
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('transport/network exception maps to unavailable', () async {
      final gateway = _ThrowingGateway(StateError('network unreachable'));
      final repository = _repository(gateway);

      await expectLater(
        repository.parseMealText('roti'),
        _throwsReason(MealTextParseFailureReason.unavailable),
      );
    });

    test('error details never appear in the thrown domain failure',
        () async {
      final gateway = _ThrowingGateway(
        StateError('leaked provider detail: sk_live_secret_token'),
      );
      final repository = _repository(gateway);

      try {
        await repository.parseMealText('roti');
        fail('expected MealTextParseFailure');
      } on MealTextParseFailure catch (error) {
        expect(error.toString(), isNot(contains('sk_live_secret_token')));
        expect(error.toString(), isNot(contains('leaked provider detail')));
        expect(error.toString(), 'MealTextParseFailure(unavailable)');
      }
    });
  });
}

SupabaseMealTextParseRepository _repository(
  MealTextParseFunctionGateway gateway, {
  Duration requestTimeout = const Duration(seconds: 50),
}) {
  return SupabaseMealTextParseRepository(
    client: _UnusedSupabaseClient(),
    gateway: gateway,
    requestTimeout: requestTimeout,
  );
}

Matcher _throwsReason(MealTextParseFailureReason reason) {
  return throwsA(
    isA<MealTextParseFailure>().having(
      (failure) => failure.reason,
      'reason',
      reason,
    ),
  );
}

Map<String, Object?> _successResponse({
  String? mealName,
  List<Map<String, Object?>>? items,
}) {
  return {
    'schemaVersion': 1,
    'outcome': 'success',
    if (mealName != null) 'mealName': mealName,
    'items': items ?? [_item()],
  };
}

Map<String, Object?> _item({
  String displayName = 'Roti',
  num quantity = 1,
  String servingUnit = 'piece',
  Map<String, num>? nutrients,
}) {
  return {
    'displayName': displayName,
    'quantity': quantity,
    'servingUnit': servingUnit,
    'nutritionSnapshot': _snapshot(nutrients: nutrients),
  };
}

Map<String, Object?> _snapshot({Map<String, num>? nutrients}) {
  return {
    'schemaVersion': 1,
    'nutrients': nutrients ?? {'energy': 100},
  };
}

final class _RecordingGateway implements MealTextParseFunctionGateway {
  _RecordingGateway({required Object? response}) : _response = response;

  final Object? _response;
  final List<String> functionNames = [];
  final List<Object?> bodies = [];
  final List<Future<void>?> abortSignals = [];

  @override
  Future<Object?> invoke(
    String functionName, {
    required Object? body,
    Future<void>? abortSignal,
  }) async {
    functionNames.add(functionName);
    bodies.add(body);
    abortSignals.add(abortSignal);
    return _response;
  }
}

final class _ThrowingGateway implements MealTextParseFunctionGateway {
  _ThrowingGateway(this._error);

  final Object _error;

  @override
  Future<Object?> invoke(
    String functionName, {
    required Object? body,
    Future<void>? abortSignal,
  }) async {
    throw _error;
  }
}

final class _AbortAwareGateway implements MealTextParseFunctionGateway {
  bool abortSignalWasProvided = false;

  @override
  Future<Object?> invoke(
    String functionName, {
    required Object? body,
    Future<void>? abortSignal,
  }) async {
    abortSignalWasProvided = abortSignal != null;
    if (abortSignal == null) {
      throw StateError('expected a bounded abort signal');
    }
    await abortSignal;
    throw StateError('simulated request abort');
  }
}

/// Never invoked because every test supplies an explicit [gateway]; it exists
/// only to satisfy the repository's `required SupabaseClient client` seam.
final class _UnusedSupabaseClient extends Fake implements SupabaseClient {}
