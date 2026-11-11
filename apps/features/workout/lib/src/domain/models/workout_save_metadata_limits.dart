import 'dart:convert';

/// Client-side caps aligned with `rpc_save_workout_session_v1` payload checks.
/// Keep drafts editable when validation fails; never freeze an oversize Save.
abstract final class WorkoutSaveMetadataLimits {
  static const maxTitleLength = 2000;
  static const maxDescriptionUtf8Bytes = 65536;
  static const maxGymNameLength = 200;
  static const maxActivityTypeLength = 100;

  static bool isValidTitle(String? title) {
    final trimmed = title?.trim() ?? '';
    return trimmed.isNotEmpty && trimmed.length <= maxTitleLength;
  }

  static bool isValidDescription(String? description) {
    if (description == null || description.isEmpty) return true;
    return utf8.encode(description).length <= maxDescriptionUtf8Bytes;
  }

  static bool isValidGymName(String? gymName) {
    final trimmed = gymName?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    return trimmed.length <= maxGymNameLength;
  }

  static bool isValidActivityType(String? activityType) {
    final trimmed = activityType?.trim() ?? '';
    if (trimmed.isEmpty) return true;
    return trimmed.length <= maxActivityTypeLength;
  }
}
