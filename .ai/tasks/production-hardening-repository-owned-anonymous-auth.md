# Production Hardening — Repository-owned Anonymous Auth

## Status

**COMPLETE / FROZEN — NO LONGER REPRODUCIBLE. NO SOURCE CHANGE REQUIRED.**

Fresh audit head:

```text
a757816f73e40c19371b0dd604a7d5d0edd70140
```

Current source/test checkpoint already validated by:

```text
38949e8d25aeed6c5387f3b825deac224717f12d
Flutter CI #1914 / run 32819604848 ✅
Android Native CI #326 / run 32819604927 ✅
```

Owner tracker: #5 P1 item 10.

## Goal

Verify whether any current Profile/Nutrition/Workout persistence repository still mutates authentication state by calling anonymous sign-in when no authenticated user exists. If reproducible, remove that side effect and require an authenticated user instead.

## Fresh current-head findings

### Historical implementations are gone

Repository-wide search surfaced historical/default-branch references to anonymous sign-in in legacy setup/preferences adapters, including:

```text
supabase_profile_setup_repository.dart
supabase_targets_setup_repository.dart
supabase_workout_preferences_repository.dart
```

Fresh current-branch directory inspection confirms those legacy files are no longer present after the canonical O11 cutover.

### Canonical Profile owner is fail-closed

`SupabaseUserProfileRepository` resolves only `client.auth.currentUser?.id`. Its `_requireUserId()` throws when no authenticated user exists; it never invokes any auth mutation.

Existing regression:

```text
apps/features/profile/test/data/supabase_user_profile_repository_test.dart
```

proves signed-out canonical read/write require authentication and never reach the table gateway.

### Canonical Nutrition owners are fail-closed

Current repositories are:

```text
SupabaseNutritionProfileRepository
SupabaseNutritionTargetsRepository
```

Both resolve only the current user ID. Signed-out writes throw `StateError`; neither repository mutates authentication state.

Existing regression:

```text
apps/features/nutrition/test/data/supabase_canonical_nutrition_repositories_test.dart
```

proves signed-out writes fail before gateway access for both Profile and Targets.

### Canonical Workout owners are fail-closed

Current repositories are:

```text
SupabaseWorkoutProfileRepository
SupabaseWorkoutTargetsRepository
```

Both resolve only the current user ID. Signed-out writes throw `StateError`; neither repository mutates authentication state.

Existing regression:

```text
apps/features/workout/test/data/supabase_canonical_workout_repositories_test.dart
```

proves signed-out writes fail before gateway access.

## Acceptance

- [x] No current canonical Profile persistence path signs in anonymously.
- [x] No current canonical Nutrition persistence path signs in anonymously.
- [x] No current canonical Workout persistence path signs in anonymously.
- [x] Signed-out canonical writes fail closed with an authenticated-user requirement.
- [x] Persistence repositories do not own auth-session creation.
- [x] Legacy anonymous-auth adapters are absent from the current branch.
- [x] Existing focused tests already guard the required behavior.
- [x] No production source change required.
- [x] No DB migration.

## Classification

The historical item 10 finding is **no longer reproducible** on the current canonical architecture. Reintroducing an anonymous sign-in side effect would violate the accepted repository boundary.

## Guardrails

- Do not add anonymous sign-in as a persistence fallback.
- Read paths may return `null` where their existing domain contract defines signed-out/no-row as absent state; write paths must never create auth identity implicitly.
- Auth creation remains owned by explicit Auth flows.
- PR #50 remains Draft/open/unmerged unless separately authorized.
