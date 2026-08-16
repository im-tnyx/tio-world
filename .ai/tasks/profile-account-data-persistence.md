# Profile & Account Data Persistence

**Status:** Ready
**Primary owner:** `apps/features/profile` + `apps/features/settings` + `apps/features/onboarding` + `apps/app`
**Affected platforms:** Flutter phone app + Supabase
**Tracking:** GitHub issue #8

## 1. Discovery

### User Outcome

User data entered during onboarding or edited later from Profile/Account Settings must reliably persist to Supabase and reload correctly.

### Success Criteria

- Onboarding persists required profile, workout, nutrition/targets, and mobile data.
- Account Settings loads current mobile and Save actually persists supported account fields.
- Profile Settings updates height/weight/name/etc. without losing mobile verification or fields outside that screen's ownership.
- Failed writes do not show a false success state.
- Onboarding drafts round-trip across app restarts without silent version-loss.
- Current phone UI remains visually unchanged.

### Scope

- Account Settings mobile/username read-write wiring.
- Profile Settings safe partial-update semantics.
- Onboarding profile/mobile end-to-end persistence validation.
- Onboarding draft schema-version compatibility.
- Canonical Supabase owner-table write/read consistency.
- Focused persistence tests and live-schema verification.

### Non-Goals

- Auth/bootstrap routing from issue #7.
- UI redesign or token migration.
- Broad schema redesign unrelated to proven persistence gaps.
- Legacy table resurrection when canonical tables are healthy.

## 2. Codebase Exploration

### Verified Evidence

- `AccountSettingsPage` exposes `phoneNumber` and `onSave({username, phoneNumber})`.
- `apps/app/lib/app/router.dart` currently does not pass `phoneNumber` or wire `onSave` for Account Settings.
- `ProfileSettingsPage` save path reconstructs `ProfileSetupData` but currently omits `mobile` and `isMobileVerified` preservation.
- `ProfileOnboardingDraft`, draft JSON serialization, and `ProfileSetupMapper` all carry `mobile` and `isMobileVerified`.
- `OnboardingDraft.currentSchemaVersion == 3`, while `OnboardingDraftSnapshotDtoMapper.supportedSchemaVersion == 1`; repository load currently converts mapper failures to `null`.
- Live read-only Supabase inspection confirms canonical tables `users`, `user_nutrition_profiles`, `user_workout_profiles`, and `onboarding_drafts` exist.
- Live aggregate inspection found the current `users` row has mobile missing while height/current weight/target weight are populated. No personal values were inspected or recorded.

### Existing Pattern to Follow

- Data ownership stays in feature repositories.
- App shell wires feature pages to repositories/providers but should not duplicate persistence logic.
- Prefer explicit field-specific update methods or safe merge semantics for partial settings screens.
- Supabase tables remain RLS-protected and user-owned.

### Tests or Validation Already Present

Inspect/update tests around:

- profile repository persistence;
- settings page callbacks;
- onboarding profile mapper;
- onboarding draft DTO round-trip;
- owner repository writes.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep issue separate from #7 | Made | Data persistence is independently testable and should not expand auth-routing scope | App |
| Account Settings Save must persist | Made | Current UI can report success without a write | Settings/Profile |
| Partial settings updates preserve unrelated fields | Made | Screens should not accidentally erase data they do not own | Profile |
| Canonical tables are primary | Made | Live project uses current canonical owner tables | Profile/Nutrition/Workout |
| No visual redesign | Made | This is a data-integrity task | All |
| Schema changes only after live verification | Made | Do not edit applied migrations in place | Supabase |

## 4. Architecture Design

### Chosen Approach

Use repository-owned field updates/merge semantics rather than rebuilding and overwriting whole user records from partial settings screens.

### Ownership and Data Flow

```text
Onboarding UI
→ Onboarding draft/controller
→ Profile/Workout/Targets mappers
→ owner repositories
→ Supabase canonical tables

Profile Settings
→ profile update command
→ ProfileSetupRepository
→ public.users

Account Settings
→ account update command
→ profile/account repository boundary
→ public.users
```

Account and Profile Settings must load the latest persisted values before editing and preserve fields outside the active form.

### Alternative Rejected

- Keep optional `onSave` unwired and rely on local UI: false-success behavior.
- Reconstruct a full profile with defaults from a partial screen: risks data loss.
- Catch-and-ignore persistence failures: hides corruption and makes debugging impossible.
- Reintroduce anonymous sign-in as a write fallback: changes account identity unexpectedly.

### Failure and Accessibility States

- Save failure stays on the current screen and exposes the existing error/snackbar pattern rather than popping as success.
- Saving state remains accessible and prevents duplicate writes.
- No spacing, typography, colors, control sizes, field order, or layout changes.

## 5. Implementation Plan

- [ ] Add tests that prove Account Settings currently does not persist mobile and define expected fixed behavior.
- [ ] Wire persisted `phoneNumber` and real `onSave` into Account Settings.
- [ ] Introduce safe profile/account update API(s) so settings screens update only owned fields.
- [ ] Preserve `mobile`/`isMobileVerified` and other non-owned profile fields during Profile Settings edits.
- [ ] Add onboarding mobile end-to-end persistence regression test.
- [ ] Reconcile onboarding draft schema version and add v3 round-trip/load tests.
- [ ] Verify canonical Profile/Workout/Nutrition writes against the live schema without exposing personal data.
- [ ] Remove/limit legacy fallback behavior only where tests prove it masks canonical failures.
- [ ] Run focused Flutter tests/analyze and Supabase security/RLS checks if SQL changes are required.

## 6. Quality Review

### Validation Run

```text
Not run yet. Task is queued behind active issue #7 work.
```

### Review Findings and Resolution

- UI visual baseline must remain unchanged.
- No production DB write or migration has been performed during discovery.

## 7. Final Handoff

### Changed Files

Task brief only at creation time.

### Actual Behavior

Not implemented yet.

### Known Limitations

Exact onboarding controller event path for mobile and any required repository API split must be reverified when this task becomes active.

### Final Status

`REVIEW`
