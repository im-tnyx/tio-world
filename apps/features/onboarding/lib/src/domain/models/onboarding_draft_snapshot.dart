import 'onboarding_draft.dart';

/// Immutable domain snapshot of an unfinished onboarding draft.
///
/// Encapsulates version metadata and the canonical [OnboardingDraft] state
/// for secure serialization and restore across lifecycles.
class OnboardingDraftSnapshot {
  const OnboardingDraftSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.draft,
    this.updatedAt,
  });

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final OnboardingDraft draft;
  final DateTime? updatedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingDraftSnapshot &&
            schemaVersion == other.schemaVersion &&
            draft == other.draft &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode => Object.hash(schemaVersion, draft, updatedAt);

  @override
  String toString() =>
      'OnboardingDraftSnapshot(version: $schemaVersion, mode: ${draft.selectedMode}, step: ${draft.currentStepId})';
}
