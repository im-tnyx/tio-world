# Profile Screen

**Surface:** Phone full-screen account and fitness context
**Current route:** `/profile`
**Primary owner:** `apps/features/profile`
**Status:** A minimal Profile launcher is implemented with an actionable shared
avatar, Profile photo preview route, and Settings entry. Profile details and real
media persistence remain planned.

## Purpose

Give the user a single place to review and update personal and fitness context, while keeping each feature's calculations and settings with its own owner.

## Target Content

- Identity and account summary.
- Reusable `TioAvatar` with `TioAvatarSize.large` for the main Profile identity;
  its centralized semantic size is 80dp and it remains circular unless this
  screen explicitly adopts the shared rounded treatment.
- Personal and fitness profile details required by approved feature flows.
- Clear entry points to module-owned Nutrition Targets and Workout Settings.
- Links to Progress history or account controls only through their public navigation contracts.
- Settings launch entry; Home does not duplicate this action in its top bar.
- Tapping the 80dp avatar opens the owned [Profile Photo](profile-avatar.md)
  screen.

When avatar upload is approved, its file belongs in the private Supabase `profile` bucket through a Profile-owned repository. Profile fields remain structured data, not Storage files.

## Ownership Rules

- Profile is the source of approved personal and fitness context.
- Nutrition owns target calculations, overrides, and nutrition-specific settings.
- Workout owns routine/training defaults and workout-specific settings.
- Recovery, Progress, and Coach consume prepared, approved contracts. Profile does not host their business logic.
- `apps/core` owns the `TioAvatar` implementation; Profile chooses its semantic size and shape rather than duplicating avatar UI.

## States And Privacy

- Clearly distinguish unset data, user-entered data, inferred defaults, and data waiting to save/sync.
- Edits need validation, cancellation, save success, save failure, and offline handling before persistence is implemented.
- Sensitive data must have an explicit purpose and no accidental logging. Destructive account or data actions require their own confirmed flow and are not part of the first Profile slice.

## Acceptance Criteria

- Profile is reachable from the app chrome, not a primary tab.
- Updating a profile value never silently replaces explicit Nutrition or Workout overrides.
- Avatar behavior is consistent with the reusable `apps/core` component contract.
- Prepared entitlement may map Free to no frame, Plus to the shared ring, and Pro
  to the shared hexagon; Profile does not calculate or own the plan tier.
- Avatar tap opens the 1:1 preview without bypassing Profile ownership.
- Settings remains reachable through Profile without adding a separate Home top-bar action.
- Cross-feature links preserve module ownership.

## Related

- [Nutrition](nutrition.md)
- [Workout](workout.md)
- [Settings](settings.md)
- [Profile Photo](profile-avatar.md)
- [Architecture: reusable avatar](../ARCHITECTURE.md#reusable-profile-avatar)
