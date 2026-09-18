import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/meal_text_parse_repository.dart';

/// Narrow seam around the Supabase Functions transport this repository needs,
/// so focused tests do not require a live Supabase project or client.
abstract interface class MealTextParseFunctionGateway {
  Future<Object?> invoke(String functionName, {required Object? body});
}

/// Default gateway backed by the real `supabase_flutter` functions client.
final class SupabaseMealTextParseFunctionGateway
    implements MealTextParseFunctionGateway {
  const SupabaseMealTextParseFunctionGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> invoke(String functionName, {required Object? body}) async {
    final response = await _client.functions.invoke(functionName, body: body);
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
  }) : _gateway = gateway ?? SupabaseMealTextParseFunctionGateway(client);

  static const String _functionName = 'nutrition-meal-text-parse';
  static const int _supportedSchemaVersion = 1;

  final MealTextParseFunctionGateway _gateway;

  @override
  Future<MealLoggingDraft> parseMealText(String text) async {
    final Object? data;
    try {
      data = await _gateway.invoke(
        _functionName,
        body: {
          'schemaVersion': _supportedSchemaVersion,
          'mealText': text,
        },
      );
    } on MealTextParseFailure {
      rethrow;
    } on Object {
      // Any transport failure (HTTP/relay/fetch/abort/network/auth) is not a
      // safe UI-facing detail. It always collapses to the same recoverable
      // reason so provider/status/response internals never escape.
      throw const MealTextParseFailure(MealTextParseFailureReason.unavailable);
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

    final rawMealName = response['mealName'];

    return MealLoggingDraft(
      mealName: rawMealName is String ? rawMealName : null,
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
      snapshot = NutritionSnapshot.fromJson(
        Map<String, Object?>.from(rawSnapshot),
      );
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
