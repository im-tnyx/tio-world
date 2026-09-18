import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/meal_text_parse_repository.dart';

/// Narrow seam around the Supabase Functions transport this repository needs,
/// so focused tests do not require a live Supabase project or client.
abstract interface class MealTextParseFunctionGateway {
  Future<Object?> invoke(
    String functionName, {
    required Object? body,
    Future<void>? abortSignal,
  });
}

/// Default gateway backed by the real `supabase_flutter` functions client.
final class SupabaseMealTextParseFunctionGateway
    implements MealTextParseFunctionGateway {
  const SupabaseMealTextParseFunctionGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(
    String functionName, {
    required Object? body,
    Future<void>? abortSignal,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      body: body,
      abortSignal: abortSignal,
    );
    return response.data;
  }
}

/// Supabase adapter for [MealTextParseRepository].
///
/// This repository owns exactly one thing: turning normalized meal text into
/// a [MealLoggingDraft] by calling the `nutrition-meal-text-parse` Edge
/// Function and decoding its provider-neutral response strictly. Auth, whole
/// meal validation, retry, and presentation-safe messaging all stay owned by
/// the caller/controller; none of it is duplicated here.
final class SupabaseMealTextParseRepository implements MealTextParseRepository {
  SupabaseMealTextParseRepository({
    required SupabaseClient client,
    MealTextParseFunctionGateway? gateway,
    Duration requestTimeout = const Duration(seconds: 50),
  })  : _gateway = gateway ?? SupabaseMealTextParseFunctionGateway(client),
        _requestTimeout = requestTimeout {
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        'requestTimeout',
        'must be positive',
      );
    }
  }

  static const String _functionName = 'nutrition-meal-text-parse';
  static const int _supportedSchemaVersion = 1;
  static const int _supportedNutritionSchemaVersion = 1;

  final MealTextParseFunctionGateway _gateway;
  final Duration _requestTimeout;

  @override
  Future<MealLoggingDraft> parseMealText(String text) async {
    final abortCompleter = Completer<void>();
    final timeoutTimer = Timer(_requestTimeout, abortCompleter.complete);

    final Object? data;
    try {
      data = await _gateway.invoke(
        _functionName,
        body: {
          'schemaVersion': _supportedSchemaVersion,
          'mealText': text,
        },
        abortSignal: abortCompleter.future,
      );
    } on MealTextParseFailure {
      rethrow;
    } on Object {
      // Any transport failure (HTTP/relay/fetch/abort/network/auth) is not a
      // safe UI-facing detail. It always collapses to the same recoverable
      // reason so provider/status/response internals never escape.
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    } finally {
      timeoutTimer.cancel();
    }

    return _decodeDraft(data);
  }

  MealLoggingDraft _decodeDraft(Object? data) {
    try {
      if (data is! Map) {
        throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
      }
      final response = Map<String, Object?>.from(data);

      if (response['schemaVersion'] != _supportedSchemaVersion) {
        throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
      }

      return switch (response['outcome']) {
        'unrecognized' => throw const MealTextParseFailure(
            MealTextParseFailureReason.unrecognized,
          ),
        'incomplete' => throw const MealTextParseFailure(
            MealTextParseFailureReason.incomplete,
          ),
        'unavailable' => throw const MealTextParseFailure(
            MealTextParseFailureReason.unavailable,
          ),
        'success' => _decodeSuccess(response),
        _ => throw const MealTextParseFailure(
            MealTextParseFailureReason.unavailable,
          ),
      };
    } on MealTextParseFailure {
      rethrow;
    } on Object {
      // Any other malformed/unexpected shape (wrong types, missing fields,
      // decode exceptions from nested values) must never escape as a raw
      // FormatException or transport-shaped error.
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }
  }

  MealLoggingDraft _decodeSuccess(Map<String, Object?> response) {
    final rawItems = response['items'];
    if (rawItems is! List || rawItems.isEmpty) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    final items = <MealLoggingDraftItem>[
      for (final rawItem in rawItems) _decodeItem(rawItem),
    ];

    final String? mealName;
    if (response.containsKey('mealName')) {
      final rawMealName = response['mealName'];
      if (rawMealName is! String) {
        throw const MealTextParseFailure(
          MealTextParseFailureReason.unavailable,
        );
      }
      mealName = rawMealName;
    } else {
      mealName = null;
    }

    return MealLoggingDraft(
      mealName: mealName,
      captureSource: MealLogCaptureSource.text,
      items: items,
    );
  }

  MealLoggingDraftItem _decodeItem(Object? rawItem) {
    if (rawItem is! Map) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }
    final item = Map<String, Object?>.from(rawItem);

    final displayName = item['displayName'];
    if (displayName is! String || displayName.trim().isEmpty) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    final quantity = item['quantity'];
    if (quantity is! num || !quantity.isFinite || quantity <= 0) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    final servingUnit = item['servingUnit'];
    if (servingUnit is! String || servingUnit.trim().isEmpty) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    final rawSnapshot = item['nutritionSnapshot'];
    if (rawSnapshot is! Map) {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    final NutritionSnapshot snapshot;
    try {
      final snapshotJson = Map<String, Object?>.from(rawSnapshot);
      if (snapshotJson['schemaVersion'] != _supportedNutritionSchemaVersion) {
        throw const MealTextParseFailure(
          MealTextParseFailureReason.unavailable,
        );
      }
      snapshot = NutritionSnapshot.fromJson(snapshotJson);
    } on MealTextParseFailure {
      rethrow;
    } on Object {
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
    }

    return MealLoggingDraftItem(
      displayName: displayName,
      quantity: quantity,
      servingUnit: servingUnit,
      consumedNutritionSnapshot: snapshot,
    );
  }
}
