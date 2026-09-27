# Profile Screen

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: `apps/features/profile`
Truth Boundary: Authoritative for the Profile screen product contract, ownership, and documented current/target behavior; runtime source wins for actual shipped behavior and trackers own delivery status.

**Surface:** Phone full-screen account and fitness context
**Current route:** `/profile`
**Primary owner:** `apps/features/profile`
**Status:** The Profile route loads canonical profile/account/body data, renders personal and health context, exposes persisted Profile Settings editing, opens Settings, and supports Profile avatar upload/deletion through the Profile-owned Supabase repository. Additional cross-feature content remains governed by its owning modules.

## Purpose

Give the user a single place to review and update personal and fitness context, while keeping each feature's calculations and settings with its own owner.

## Target Content

- Identity and account summary.
- Reusable `TioAvatar` with `TioAvatarSize.large` for the main Profile identity;
  its centralized semantic size is 100dp and it remains circular unless this
  screen explicitly adopts the shared rounded treatment.
- Personal and fitness profile details required by approved feature flows.
- Clear entry points to module-owned Nutrition Targets and Workout Settings.
- Links to Progress history or account controls only through their public navigation contracts.
- Settings launch entry; Home does not duplicate this action in its top bar.
- Tapping the 100dp avatar opens the owned [Profile Photo](profile-avatar.md)
  screen.

Current avatar media uses the Profile-owned Supabase avatar repository and the existing public `avatars` bucket with user-folder ownership checks; `public.users.avatar_url` stores the pointer. This is a documented current exception, not the default model for sensitive health/fitness media. Profile fields remain structured data, not Storage files.

## Ownership Rules

- Profile is the source of approved personal and fitness context.
- Nutrition owns target calculations, overrides, and nutrition-specific settings.
- Workout owns routine/training defaults and workout-specific settings.
- Recovery, Progress, and Coach consume prepared, approved contracts. Profile does not host their business logic.
- `apps/core` owns the `TioAvatar` implementation; Profile chooses its semantic size and shape rather than duplicating avatar UI.

## States And Privacy

- Clearly distinguish unset data, user-entered data, inferred defaults, and data waiting to save/sync.
- Persisted edits require validation, cancellation, truthful save success/failure handling, and safe retry behavior; do not present unsaved local state as canonical data.
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
- [Architecture: reusable avatar](../architecture/ARCHITECTURE.md#reusable-profile-avatar)
