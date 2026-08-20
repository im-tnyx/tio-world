# Profile Settings Safe Partial Persistence

**Status:** Validated
**Primary owner:** `apps/features/profile` + `apps/features/settings` + `apps/app`
**Affected platforms:** Flutter phone app + Supabase
**Tracking:** GitHub issue #8, Slice 1
**Source branch:** `agent/profile-settings-safe-persistence`
**PR:** #42 (draft)

## Global UI / Design-System Guardrail

This is persistence/data-integrity work, not a visual redesign. `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md` were reviewed before implementation.

Mandatory slice guardrail:

- preserve the current loaded Profile Settings layout, spacing, typography, colors, controls, assets, and interaction geometry;
- do not introduce new feature token bags or duplicate reusable core UI;
- loading/failure behavior may become safer only where required to prevent fabricated default profile values from being saved;
- no Supabase migration is approved or required for this slice.

## 1. Discovery

### User Outcome

Editing Profile Settings updates only the fields owned by that screen, routes Username through the canonical account repository, and cannot overwrite unrelated persisted account/profile data.

### Success Criteria

- [x] Profile Settings no longer reconstructs a broad `ProfileSetupData` record in app routing glue.
- [x] Profile-owned edits update only Name, Gender, DOB, Height, and Current Weight.
- [x] Username writes use `ProfileAccountRepository` and its canonical server policy.
- [x] An unchanged Username does not trigger an account mutation.
- [x] Mobile, mobile verification, goals, target weight, activity level, health conditions, avatar, plan, units, Account Setup completion, and onboarding completion are excluded from the Profile Settings partial write.
- [x] Profile Settings cannot save fabricated fallback values while persisted profile data is unresolved/missing.
- [x] Persistence failure remains on Profile Settings and does not reach its success Snackbar/pop path.
- [x] Existing loaded `ProfileSettingsPage` visual implementation is unchanged.
- [x] Real-device persistence smoke accepted.

### Scope

- narrow Profile Settings update contract/model under `apps/features/profile`;
- authenticated Supabase partial-update implementation for screen-owned profile columns only;
- domain use case coordinating optional Username mutation with profile-owned fields;
- app provider/composition wiring;
- hydration guard before exposing the editable Profile Settings form;
- focused domain/data/app regressions.

### Non-Goals

- Account Settings failure UX (Issue #8 later slice);
- changing Mobile semantics or Account Setup flow;
- Workout/Nutrition legacy fallback cleanup;
- deciding duplicated nutrition/body-metric canonical ownership;
- anonymous-auth cleanup owned by #5 unless this slice is directly blocked;
- Profile Settings visual redesign;
- database migration/RLS change;
- Username-save latency optimization or transactional consolidation.

## 2. Codebase Exploration

### Verified Evidence

- The old route constructed a full `ProfileSetupData` using loaded values plus fallbacks before calling broad `saveProfileSetup()`.
- `ProfileAccountRepository` already owns canonical Username mutation/normalization/claim policy.
- `SupabaseAccountSetupRepository` established the authenticated narrow-update pattern used by this slice.
- Existing `ProfileSettingsPage` already awaits `onSave` before showing success and catches failure into its controlled error state.
- Live read-only Supabase verification confirmed `public.users` contains the required Profile Settings columns and authenticated own-row SELECT/UPDATE RLS; no migration is needed.
- Design-system and nested feature governance were reviewed before touching app UI composition.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve current loaded Profile Settings pixels | Approved | #8 is persistence/integrity work | Product owner |
| Username remains editable but persists through `ProfileAccountRepository` | Approved | Prevent bypassing server normalization/claim/uniqueness policy | Profile domain |
| Use a narrow Profile Settings repository instead of broad `saveProfileSetup()` | Approved | Partial screen must mutate only fields it owns | Profile domain/data |
| Do not expose/save fallback Profile values before hydration | Approved | Prevent silent overwrite with fabricated defaults | App composition |
| No DB migration | Verified | Required columns/RLS already exist live | Supabase |
| Username latency observation does not block Slice 1 acceptance | Accepted | Persistence is correct; changed Username uses an additional policy RPC/server write path | Product owner / engineering |

## 4. Architecture Design

### Chosen Approach

`ProfileSettingsUpdate` contains only screen-owned profile values. `SupabaseProfileSettingsRepository` performs an authenticated own-row `UPDATE` using an exact narrow mapper and fails if the current application-user row is missing; it never upserts or performs anonymous sign-in.

`SaveProfileSettingsUseCase` normalizes and compares the loaded/requested Username. It skips account mutation when unchanged. A changed Username is delegated to `ProfileAccountRepository.updateUsername()` before the profile partial write, so canonical server policy failures prevent the profile write from proceeding.

`ProfileSettingsRoute` owns app composition/hydration state and delegates loaded-screen rendering to the unchanged `ProfileSettingsPage`. `router.dart` now only registers that route component.

### Ownership and Data Flow

```text
ProfileSettingsPage
        ↓ onSave
SaveProfileSettingsUseCase
        ├─ changed Username → ProfileAccountRepository → claim_username RPC/server policy
        └─ profile fields   → ProfileSettingsRepository → public.users partial UPDATE
```

Exact profile partial payload:

```text
name
gender
date_of_birth
dob
height_cm
current_weight_kg
updated_at
```

### Alternative Rejected

- Continue reconstructing `ProfileSetupData` in `router.dart`: rejected because the screen does not own the full record.
- Put Username into the profile partial payload: rejected because that bypasses the canonical account policy.
- Add a migration/RPC solely for this slice: rejected because live own-row UPDATE capability already supports the bounded requirement.
- Collapse Username + profile fields into a new transactional RPC in this slice: rejected as a larger backend contract/performance change outside the accepted data-integrity scope.

### Failure and Accessibility States

- unresolved profile → themed loading state, no editable form/save;
- resolved missing profile → controlled unavailable state, no editable form/save;
- repository/use-case failure → existing Profile Settings error behavior, no success/pop;
- loaded profile → existing Profile Settings presentation/layout remains the same.

## 5. Implementation Plan

- [x] add narrow Profile Settings update model + repository contract/export
- [x] implement authenticated Supabase partial update without upsert/anonymous fallback
- [x] add `SaveProfileSettingsUseCase` with unchanged-Username skip
- [x] wire app providers for the narrow repository/use case
- [x] replace broad Profile Settings router save construction with use-case call
- [x] guard route against unresolved/missing persisted profile data
- [x] add focused field-ownership, Username, auth and hydration regressions
- [x] run repository-wide Flutter/Dart analyze/tests in CI
- [x] run real-device acceptance

## 6. Quality Review

### Validation Run

Authoritative runtime/test source head:

```text
73e469280773b700f452b1a61adc2eb053f7741c
```

GitHub Actions **Flutter CI #934** (run `32331376822`, job `96312549178`) completed successfully on that head:

```text
Bootstrap workspace       PASS
Analyze Flutter packages  PASS
Analyze Dart packages     PASS
Test Flutter packages     PASS
Test Dart packages        PASS
```

The later task-acceptance commits change documentation evidence only; they do not alter runtime/test source.

Focused regressions cover:

- unchanged normalized Username skips account mutation;
- changed Username uses the canonical account owner before profile partial persistence;
- Username failure prevents the profile partial write;
- blank changed Username is rejected before mutation;
- exact Profile Settings payload excludes unrelated account/profile fields;
- unauthenticated Profile Settings repository write fails;
- unresolved/missing profile state does not expose the editable form;
- loaded real profile renders the existing Profile Settings form.

### Real-Device Acceptance — 2026-08-20

Owner/device smoke accepted:

- Profile Settings values saved successfully and persisted;
- changed Username saved successfully through the server-owned Username path;
- remaining tested Profile Settings behavior was correct;
- Mobile was also changed through Account Settings and persisted successfully;
- Mobile save completed noticeably faster than changed-Username save;
- changed Username showed noticeable save latency, recorded as a non-blocking performance observation rather than a correctness failure.

Latency interpretation from the audited call path:

```text
changed Username from Profile Settings
→ claim_username RPC
→ canonical username checks/update
→ Profile Settings partial UPDATE

Mobile change with unchanged Username
→ simpler Account Settings read/update path
```

The Username RPC performs server normalization/policy/uniqueness checks. Taken/reserved failures may additionally generate suggestions. No correctness failure was observed in the accepted successful Username change.

### Review Findings and Resolution

- Broad Profile Settings write ownership in `router.dart` removed.
- Username policy bypass removed from this path.
- Fabricated fallback-value save path removed.
- No existing loaded-screen presentation widget or visual geometry was redesigned.
- Live schema was read-only verified; no SQL/migration was added.
- Device smoke confirms persistence works; Username latency is retained as a future performance concern rather than expanding this slice.

## 7. Final Handoff

### Changed Files

Core runtime changes are limited to:

```text
apps/app/lib/app/router.dart
apps/app/lib/app/profile/profile_settings_route.dart
apps/features/profile/lib/src/domain/models/profile_settings_update.dart
apps/features/profile/lib/src/domain/repositories/profile_settings_repository.dart
apps/features/profile/lib/src/domain/usecases/save_profile_settings_use_case.dart
apps/features/profile/lib/src/data/mappers/profile_settings_write_mapper.dart
apps/features/profile/lib/src/data/repositories/supabase_profile_settings_repository.dart
```

Plus barrels, focused tests, and this task brief.

### Actual Behavior

```text
Profile data unresolved/missing
→ no editable fallback form

Loaded Profile Settings
→ same existing screen
→ Save
   ├─ Username unchanged → no Username write
   ├─ Username changed → canonical ProfileAccountRepository policy
   └─ Name/Gender/DOB/Height/Current Weight → narrow public.users update
→ unrelated durable fields untouched by the Profile Settings payload
```

### Known Limitations

- Username and profile-owned fields are two client-side writes, not one database transaction. The ordering intentionally validates/claims a changed Username first; a later profile-write failure can therefore leave the Username changed while profile-owned values remain unchanged. A transactional server boundary would require a separately approved backend/RPC design and is not introduced in this slice.
- Changed Username has higher observed save latency than Mobile on the accepted device smoke. Current implementation performs the canonical Username RPC before the separate profile partial update; optimization/measurement is deferred rather than weakening Username integrity policy.
- Body-metric duplication between `public.users` and `public.user_nutrition_profiles` remains intentionally deferred to Issue #8 canonical-owner consistency work.
- Account Settings controlled repository-failure UX is a later #8 slice.
- Workout/Nutrition legacy fallback cleanup is a later #8 slice.

### Final Status

`VALIDATED — AUTOMATED + REAL-DEVICE ACCEPTANCE PASS`
