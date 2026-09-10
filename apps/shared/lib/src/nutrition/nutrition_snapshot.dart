import 'nutrient_id.dart';

/// Immutable, provider-independent nutrition amounts in canonical units.
///
/// An absent nutrient is unknown. A present nutrient with an amount of zero is
/// explicitly known to be zero. Source and capture provenance belongs to the
/// entity that owns this value object, not to the snapshot itself.
final class NutritionSnapshot {
  NutritionSnapshot({
    required this.schemaVersion,
    required Map<NutrientId, num> nutrients,
  }) : nutrients = Map<NutrientId, num>.unmodifiable(
          _validateAndCopy(nutrients),
        );

  /// Registry version against which these canonical amounts were normalized.
  final int schemaVersion;

  /// Canonical nutrient amounts keyed by Tio-owned identities.
  final Map<NutrientId, num> nutrients;

  /// Returns the canonical amount, or `null` when the nutrient is unknown.
  num? amountFor(NutrientId nutrient) => nutrients[nutrient];

  /// Whether this snapshot explicitly contains the nutrient, including zero.
  bool containsNutrient(NutrientId nutrient) => nutrients.containsKey(nutrient);

  /// Decodes the canonical JSON-compatible snapshot shape.
  ///
  /// Unknown future nutrient identities are ignored without remapping so known
  /// current data remains usable. Malformed known values are rejected.
  factory NutritionSnapshot.fromJson(Map<String, Object?> json) {
    final rawSchemaVersion = json['schemaVersion'];
    if (rawSchemaVersion is! int) {
      throw const FormatException('schemaVersion must be an integer.');
    }

    final rawNutrients = json['nutrients'];
    if (rawNutrients is! Map<Object?, Object?>) {
      throw const FormatException('nutrients must be a map.');
    }

    final nutrients = <NutrientId, num>{};
    for (final entry in rawNutrients.entries) {
      final storageValue = entry.key;
      if (storageValue is! String) {
        throw const FormatException('nutrient keys must be strings.');
      }

      final nutrient = NutrientId.fromStorageValue(storageValue);
      if (nutrient == null) continue;

      final amount = entry.value;
      if (amount is! num) {
        throw FormatException('$storageValue must contain a numeric amount.');
      }
      nutrients[nutrient] = amount;
    }

    return NutritionSnapshot(
      schemaVersion: rawSchemaVersion,
      nutrients: nutrients,
    );
  }

  /// Encodes only nutrients explicitly present in this snapshot.
  Map<String, Object> toJson() {
    final encodedNutrients = <String, num>{};
    for (final nutrient in NutrientId.values) {
      final amount = nutrients[nutrient];
      if (amount != null) {
        encodedNutrients[nutrient.storageValue] = amount;
      }
    }

    return <String, Object>{
      'schemaVersion': schemaVersion,
      'nutrients': encodedNutrients,
    };
  }

  static Map<NutrientId, num> _validateAndCopy(
    Map<NutrientId, num> nutrients,
  ) {
    final copy = <NutrientId, num>{};
    for (final entry in nutrients.entries) {
      final nutrient = entry.key;
      final amount = entry.value;

      if (nutrient.derivedOnly) {
        throw ArgumentError.value(
          nutrient,
          'nutrients',
          'derived-only nutrients cannot be stored in a NutritionSnapshot',
        );
      }
      if (!amount.isFinite || amount < 0) {
        throw ArgumentError.value(
          amount,
          nutrient.storageValue,
          'must be finite and non-negative',
        );
      }

      copy[nutrient] = amount;
    }
    return copy;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NutritionSnapshot ||
        other.schemaVersion != schemaVersion ||
        other.nutrients.length != nutrients.length) {
      return false;
    }

    for (final entry in nutrients.entries) {
      if (!other.nutrients.containsKey(entry.key) ||
          other.nutrients[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        Object.hashAllUnordered(
          nutrients.entries.map(
            (entry) => Object.hash(entry.key, entry.value),
          ),
        ),
      );
}
