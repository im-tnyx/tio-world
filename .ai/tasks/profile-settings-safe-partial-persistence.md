# Profile Settings Safe Partial Persistence

**Status:** In progress
**Primary owner:** `apps/features/profile` + `apps/features/settings` + `apps/app`
**Affected platforms:** Flutter phone app + Supabase
**Tracking:** GitHub issue #8, Slice 1
**Source branch:** `agent/profile-settings-safe-persistence`

## Global UI / Design-System Guardrail

This is persistence/data-integrity work, not a visual redesign. `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md` were reviewed before implementation.

Mandatory slice guardrail:

- preserve the current loaded Profile Settings layout, spacing, typography, colors, controls, assets, and interaction geometry;
- do not introduce new feature token bags or duplicate reusable core UI;
- loading/failure behavior may become safer only where required to prevent fabricated default profile values from being saved;
- no Supabase migration is approved or expected for this slice.

## 1. Discovery

### User Outcome

Editing Profile Settings updates only the fields owned by that screen, routes Username through the canonical account repository, and cannot overwrite unrelated persisted account/profile data.

### Success Criteria

- Profile Settings no longer reconstructs a broad `ProfileSetupData` record in app routing glue.
- Profile-owned edits update only Name, Gender, DOB, Height, and Current Weight.
- Username writes use `ProfileAccountRepository` and its canonical server policy.
- An unchanged Username does not trigger an availability/claim write.
- Mobile, mobile verification, goals, target weight, activity level, health conditions, avatar, plan, units, Account Setup completion, and onboarding completion are untouched by this save.
- Profile Settings cannot save fabricated fallback values while persisted profile data is still loading/unavailable.
- Persistence failure does not show success or pop the page.
- Current loaded-screen rendering remains unchanged.

### Scope

- add a narrow Profile Settings update contract/model under `apps/features/profile`;
- add Supabase partial-update implementation for only the screen-owned profile columns;
- add a domain use case to coordinate optional Username mutation with profile-owned fields;
- expose the narrow persistence boundary through app providers;
- update Profile Settings route wiring to wait for real profile data and call the use case;
- add focused domain/data/router/widget regressions as needed.

### Non-Goals

- Account Settings failure UX (Issue #8 later slice);
- changing Mobile semantics or Account Setup flow;
- Workout/Nutrition legacy fallback cleanup;
- deciding duplicated nutrition/body-metric canonical ownership;
- anonymous-auth cleanup owned by #5 unless this slice is directly blocked;
- any Profile Settings visual redesign;
- database migration/RLS change.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/app/lib/app/router.dart`
  - `apps/app/lib/app/network_providers.dart`
  - `apps/features/settings/lib/src/presentation/pages/profile_settings_page.dart`
  - `apps/features/profile/lib/src/domain/repositories/profile_setup_repository.dart`
  - `apps/features/profile/lib/src/domain/repositories/profile_account_repository.dart`
  - `apps/features/profile/lib/src/data/repositories/supabase_profile_setup_repository.dart`
  - `apps/features/profile/lib/src/data/repositories/supabase_profile_account_repository.dart`
  - `apps/core/lib/src/theme/README.md`
  - `apps/features/AGENTS.md`
- Existing pattern to follow:
  - `ProfileAccountRepository` already owns canonical Username mutation and skips unchanged Username in Account Settings;
  - `SupabaseAccountSetupRepository` uses authenticated narrow updates and verifies the affected current row;
  - existing Settings pages await `onSave` before success Snackbar/pop.
- Tests or validation already present:
  - `supabase_profile_account_repository_test.dart`
  - `supabase_profile_setup_repository_test.dart`
  - Settings widget tests
  - PR #36 CI #930 previously validated mobile-only Account Settings safety and related profile flow.
- Live read-only Supabase verification confirms `public.users` already contains the required columns and own-row authenticated SELECT/UPDATE RLS; no schema migration is required.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve current loaded Profile Settings pixels | Approved | #8 is persistence/integrity work | Product owner |
| Username remains editable but persists through `ProfileAccountRepository` | Approved | Prevent bypassing normalization/availability/claim/uniqueness policy | Profile domain |
| Use a narrow Profile Settings persistence contract rather than broad `saveProfileSetup()` | Approved | Screen must mutate only owned fields | Profile domain/data |
| Do not save fallback Profile values before hydration | Approved | Prevent silent data overwrite | App composition |
| No DB migration | Verified | Required live columns/RLS already exist | Supabase |

## 4. Architecture Design

### Chosen Approach

Introduce a narrow profile-settings update model/repository contract containing only screen-owned fields. The Supabase adapter performs an authenticated own-row `UPDATE` with those columns only and fails if the current profile row is missing.

Add a profile-domain save use case that compares the persisted Username with the requested Username. It calls `ProfileAccountRepository.updateUsername()` only when the normalized Username actually changes, then persists the profile-owned partial update through the narrow Profile Settings repository.

The app route remains composition glue: it supplies loaded data and delegates save behavior to the use case. It must not manufacture a complete profile record.

### Ownership and Data Flow

```text
ProfileSettingsPage
        ↓ onSave
SaveProfileSettingsUseCase
        ├─ changed Username → ProfileAccountRepository → canonical server policy
        └─ profile fields   → ProfileSettingsRepository → public.users partial UPDATE
```

### Alternative Rejected

- Continue constructing `ProfileSetupData` in `router.dart`: rejected because a partial screen should not own a full-record write.
- Directly update Username in the profile partial payload: rejected because it bypasses the existing canonical Username policy.
- Add a migration/RPC solely for this slice: rejected because the required own-row UPDATE surface already exists and the slice can remain narrowly client/repository scoped.

### Failure and Accessibility States

- While profile data is unresolved, do not expose an editable form seeded with fake defaults.
- Repository/use-case failure stays on Profile Settings and preserves the page's existing controlled error message.
- Normal loaded form remains visually unchanged.

## 5. Implementation Plan

- [ ] add narrow Profile Settings update model + repository contract/export
- [ ] implement authenticated Supabase partial update without upsert/anonymous fallback
- [ ] add `SaveProfileSettingsUseCase` with unchanged-Username skip
- [ ] wire app providers for the narrow repository/use case
- [ ] replace broad Profile Settings router save construction with use-case call
- [ ] guard route against unresolved/missing persisted profile data
- [ ] add focused tests for field ownership, Username behavior, missing-row/failure behavior, and loading guard
- [ ] run focused analyze/tests
- [ ] run full applicable CI before review-ready handoff

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Implementation not started yet.

## 7. Final Handoff

### Changed Files

Task brief only so far.

### Actual Behavior

Pending implementation.

### Known Limitations

Body-metric duplication between `public.users` and `public.user_nutrition_profiles` is intentionally deferred to the later canonical-owner consistency slice.

### Final Status

`PARTIAL`
