# Profile & Account Data Persistence

**Status:** In progress — Slice B Account Settings wiring awaiting local validation
**Primary owner:** `apps/features/profile` + `apps/features/settings` + `apps/features/onboarding` + `apps/app`
**Affected platforms:** Flutter phone app + Supabase
**Tracking:** GitHub issue #8
**Source branch:** `codex/onboarding-mode-migration`

## 1. User Outcome

Data entered during onboarding or edited later from Profile/Account Settings must persist to the canonical Supabase owner records without silently losing fields owned by other screens.

### Frozen visual guardrail

This is persistence/integrity work. Preserve current rendered Profile Settings and Account Settings layout, spacing, typography, colors, controls, assets, and interaction geometry unless a separate visual task is approved.

## 2. Verified findings

- `AccountSettingsPage` accepts `phoneNumber` and `onSave({username, phoneNumber})`.
- The old router omitted persisted mobile and did not wire a real Account Settings save.
- `ProfileSettingsPage` reconstructs `ProfileSetupData` and still risks dropping `mobile` / `isMobileVerified`.
- `ProfileOnboardingDraft` and profile mappers already carry mobile fields.
- Draft schema remains mismatched (`currentSchemaVersion == 3`, snapshot mapper support previously verified as `1`).
- Canonical live tables remain `users`, `user_nutrition_profiles`, `user_workout_profiles`, and `onboarding_drafts`.

### Live read-only verification

`public.users` exposes the Account Settings columns required by this work:

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

No SQL write or migration is required for Account Settings persistence.

## 3. Architecture decisions

- Account Settings uses a field-specific profile-account repository instead of full `saveProfileSetup()`.
- Account writes require an existing authenticated identity. No anonymous-auth fallback.
- Account update owns only `username`, `mobile`, `updated_at`, and mobile verification invalidation when mobile changes.
- Changing mobile clears `mobile_verified_at`; changing username only preserves mobile verification.
- Missing current `public.users` row is a controlled failure, not implicit insert/provisioning.
- DB-owned auth-user provisioning remains issue #5.

## 4. Slice A — Account repository boundary

Implemented and locally validated:

- [x] add `ProfileAccountRepository`
- [x] add `SupabaseProfileAccountRepository`
- [x] require authenticated current user
- [x] read current mobile before patching
- [x] update only Account Settings-owned columns
- [x] clear `mobile_verified_at` only when mobile changes
- [x] require the update to return the current row
- [x] export repository contract + Supabase implementation
- [x] unauthenticated writes fail without anonymous sign-in
- [x] `supabase_profile_account_repository_test.dart`: 1 passed
- [x] profile `flutter analyze`: No issues found
- [x] final reported worktree clean and synchronized

## 5. Slice B — Account Settings wiring

Implemented, awaiting local validation:

- [x] add app provider for `ProfileAccountRepository`
- [x] pass persisted `profileData.mobile` into Account Settings
- [x] pass persisted `profileData.isMobileVerified`
- [x] wire `onSave` to `ProfileAccountRepository.updateAccountSettings()`
- [x] invalidate `profileDataProvider` after successful save
- [x] move Account Settings route watch calls into a `Consumer` boundary
- [x] add widget coverage for persisted phone preload + Save callback values + success pop
- [ ] settings focused test passes
- [ ] settings analyzer passes
- [ ] app analyzer passes

### Slice B changed files

```text
apps/app/lib/app/network_providers.dart
apps/app/lib/app/router.dart
apps/features/settings/test/presentation/account_settings_page_test.dart
.ai/tasks/profile-account-data-persistence.md
```

### Slice B follow-up after wiring validation

Repository exceptions already prevent the existing success Snackbar/pop because the page awaits `onSave` before success handling. A focused follow-up will add explicit user-facing failure feedback instead of allowing the async error to surface only through the error boundary.

## 6. Remaining slices

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

## 7. Current handoff

### Slice A local evidence

```text
apps/features/profile
supabase_profile_account_repository_test.dart: 1 passed
flutter analyze: No issues found
final git status: clean
```

### Slice B validation gate

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git pull --ff-only

Set-Location "G:\projects\Tio-World\apps\features\settings"
& "G:\dev\flutter-sdk\bin\flutter.bat" test "test/presentation/account_settings_page_test.dart"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" analyze

Set-Location "G:\projects\Tio-World"
git status --short --branch
```

### Final status

`PARTIAL — SLICE B LOCAL VALIDATION PENDING`
