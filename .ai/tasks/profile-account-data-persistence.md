# Profile & Account Data Persistence

**Status:** In progress — Slice A repository boundary awaiting local validation
**Primary owner:** `apps/features/profile` + `apps/features/settings` + `apps/features/onboarding` + `apps/app`
**Affected platforms:** Flutter phone app + Supabase
**Tracking:** GitHub issue #8
**Source branch:** `codex/onboarding-mode-migration`

## 1. User Outcome

Data entered during onboarding or edited later from Profile/Account Settings must persist to the canonical Supabase owner records without silently losing fields owned by other screens.

### Frozen visual guardrail

This is persistence/integrity work. Preserve current rendered Profile Settings and Account Settings layout, spacing, typography, colors, controls, assets, and interaction geometry unless a separate visual task is approved.

## 2. Verified findings

- `AccountSettingsPage` already accepts `phoneNumber` and `onSave({username, phoneNumber})`.
- `router.dart` does not currently pass persisted mobile or wire a real Account Settings save.
- The page currently shows `Account settings saved!` and pops after an absent/no-op `onSave`, creating false-success behavior.
- `ProfileSettingsPage` reconstructs `ProfileSetupData` and currently risks dropping `mobile` / `isMobileVerified`.
- `ProfileOnboardingDraft` and profile mappers already carry mobile fields.
- Draft schema remains mismatched (`currentSchemaVersion == 3`, snapshot mapper support previously verified as `1`).
- Canonical live tables remain `users`, `user_nutrition_profiles`, `user_workout_profiles`, and `onboarding_drafts`.

### Live read-only verification for Slice A

`public.users` currently exposes the Account Settings columns required by this slice:

```text
id uuid NOT NULL
username text NULL
mobile varchar NULL
mobile_verified_at timestamptz NULL
updated_at timestamptz NOT NULL
```

RLS policies verified read-only:

```text
users_select_own  SELECT  TO authenticated  USING auth.uid() = id
users_update_own  UPDATE  TO authenticated  USING auth.uid() = id
                                      WITH CHECK auth.uid() = id
```

No SQL write or migration is required for Slice A.

## 3. Architecture decisions

- Account Settings gets a field-specific profile-account repository boundary rather than reusing full `saveProfileSetup()`.
- Account writes require an existing authenticated identity. No anonymous-auth fallback.
- Account update owns only `username`, `mobile`, `updated_at`, and mobile verification invalidation when the mobile value changes.
- Changing the mobile number clears `mobile_verified_at`; changing only username preserves existing mobile verification.
- Missing current `public.users` row is a controlled failure, not an implicit insert/provisioning action.
- DB-owned auth-user provisioning remains issue #5.

## 4. Slice A — Account repository boundary

Implemented:

- [x] add `ProfileAccountRepository`
- [x] add `SupabaseProfileAccountRepository`
- [x] require authenticated current user
- [x] read current mobile before patching
- [x] update only Account Settings-owned columns
- [x] clear `mobile_verified_at` only when mobile changes
- [x] require the update to return the current row
- [x] export repository contract + Supabase implementation
- [x] add regression guard that unauthenticated writes fail without anonymous sign-in
- [ ] local focused test passes
- [ ] profile analyzer passes

### Slice A changed files

```text
apps/features/profile/lib/src/domain/repositories/profile_account_repository.dart
apps/features/profile/lib/src/domain/repositories/repositories.dart
apps/features/profile/lib/src/data/repositories/supabase_profile_account_repository.dart
apps/features/profile/lib/src/data/data.dart
apps/features/profile/test/data/supabase_profile_account_repository_test.dart
.ai/tasks/profile-account-data-persistence.md
```

## 5. Next slices after Slice A is green

### Slice B — Account Settings wiring

- load persisted `profileData.mobile` and verification state into Account Settings
- wire real `onSave` through `ProfileAccountRepository`
- surface failed writes without success Snackbar/pop
- invalidate/reload profile data after success
- add widget/router regression coverage

### Slice C — Profile Settings safe merge

- preserve `mobile`, `isMobileVerified`, and other non-owned fields
- prefer safe partial-update/merge semantics
- add field-loss regression tests

### Slice D — Onboarding mobile persistence

- prove mobile draft/controller → mapper → profile owner repository end to end
- confirm persisted mobile/verification semantics

### Slice E — Draft compatibility

- reconcile schema version 3 serialization/loading
- prevent recoverable draft progress from becoming silent `null`

### Slice F — Canonical owner consistency

- verify Profile/Workout/Nutrition canonical writes
- remove/limit legacy fallbacks only where tests prove they mask canonical failures

## 6. Local validation required for Slice A

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\profile"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/data/supabase_profile_account_repository_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

## 7. Current handoff

### Actual behavior

The field-specific Account Settings persistence boundary exists, but router/UI wiring is intentionally not started until Slice A validates locally.

### Final status

`PARTIAL — SLICE A LOCAL VALIDATION PENDING`
