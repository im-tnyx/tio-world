# Account Settings Save Failure UX

**Status:** In progress
**Primary owner:** `apps/features/settings` + `apps/app`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #8, Slice 2
**Source branch:** `agent/account-settings-save-failure-ux`

## Global UI / Design-System Guardrail

This slice is save-reliability/error-feedback work, not a visual redesign. `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md` were reviewed before implementation.

Mandatory guardrails:

- preserve the normal loaded Account Settings layout, spacing, typography, colors, controls, assets, and interaction geometry;
- reuse the existing Username feedback surface and existing `TioButton` loading state;
- generic save failure must use an existing transient feedback surface rather than inserting new layout-changing content;
- do not create new feature-local tokens or duplicate reusable core UI;
- no Supabase migration is approved or required for this slice.

## 1. Discovery

### User Outcome

When Account Settings persistence fails, the user remains on the page with their entered Username/Mobile intact, sees clear controlled feedback, and can retry without any false success or navigation. Username availability feedback should use the real server policy rather than the page's simulated fallback when the app repository is available.

### Success Criteria

- normal Account Settings rendering remains unchanged;
- Save success preserves the current success Snackbar + pop behavior;
- repository/save failure is caught inside Account Settings presentation flow;
- failure never shows the success Snackbar and never pops the page;
- `_isSaving` always resets and double-save remains prevented;
- entered Username and Mobile values remain in their controllers after failure;
- a generic persistence/network failure is surfaced through transient error feedback without changing page geometry;
- username policy failures can reuse the existing username feedback area where the error is field-specific;
- app routing wires `ProfileAccountRepository.checkUsernameAvailability()` into the existing `onCheckUsernameAvailability` callback;
- the simulated local username-availability fallback is not used in production app routing when the real repository is available;
- focused widget/app tests cover success, failure, preserved values, retry, and real availability mapping;
- no DB/schema/RLS change.

### Scope

- `AccountSettingsPage` save-error handling and feedback behavior;
- small presentation-safe error classification contract if needed;
- app route wiring for real Username availability checks;
- focused settings/app tests;
- task/PR validation evidence.

### Non-Goals

- Account Settings redesign or layout changes;
- changing Username server policy/RPC behavior;
- Username save-latency optimization;
- Mobile verification redesign;
- Profile Settings behavior;
- duplicated body-metric canonical ownership;
- Workout/Nutrition legacy fallback cleanup;
- auth/provider hardening outside Account Settings save feedback;
- database migration.

## 2. Codebase Exploration

### Verified Evidence

- `AccountSettingsPage._handleSave()` currently has `try/finally` but no `catch`.
- Success Snackbar/pop occur only after successful `await`, so false-success is already avoided, but repository errors bubble without controlled user-facing feedback.
- Existing `TioButton.primary` already owns the loading state and prevents duplicate user interaction while `_isSaving` is true.
- Existing Username UI already owns unavailable/available feedback and suggestion rendering.
- `ProfileSettingsPage` has a controlled save-failure pattern, but its inline layout-changing error text is not copied here because this slice explicitly preserves Account Settings geometry.
- `router.dart` wires the real `ProfileAccountRepository.updateAccountSettings()` save path but does not currently pass `onCheckUsernameAvailability`; therefore the page falls back to its simulated local availability check during live typing.
- `ProfileAccountRepository` already exposes server-backed username availability and typed `UsernameUnavailableException` data.
- Existing tests cover successful persisted Account Settings save/pop but not save failure/retry.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve normal Account Settings pixels | Approved | Issue #8 explicitly excludes visual redesign | Product owner |
| Generic save failure uses transient feedback | Approved | Avoid layout shift while surfacing failure | Settings presentation |
| Username-specific failure reuses existing username feedback | Approved | Existing field feedback is already the correct surface | Settings presentation |
| Wire real username availability in app route | Approved | Prevent simulated availability/server-save mismatch | App composition |
| No server-policy or migration change | Approved | Existing repository/RPC contract is sufficient | Profile/data |

## 4. Architecture Design

### Chosen Approach

Keep persistence/domain details out of the Settings widget. `AccountSettingsPage` owns only presentation behavior: save/loading state, preserving controller values, and rendering a presentation-safe failure supplied or classified through a narrow callback/result boundary.

App composition continues to own the concrete `ProfileAccountRepository`. It maps server-backed username availability into `UsernameAvailabilityResult` for the existing field UI and maps expected save exceptions into presentation-safe failure categories/messages where needed.

Normal success path remains unchanged.

### Ownership and Data Flow

```text
AccountSettingsPage
  ├─ username typing
  │    → onCheckUsernameAvailability
  │    → app composition
  │    → ProfileAccountRepository.checkUsernameAvailability
  │    → existing username feedback UI
  │
  └─ Save
       → onSave
       → ProfileAccountRepository.updateAccountSettings
       ├─ success → existing Snackbar + pop
       └─ failure → stay + preserve values + controlled feedback
```

### Alternative Rejected

- Add new inline error section under the form: rejected because it changes normal layout geometry and is unnecessary.
- Let repository exceptions bubble to Flutter: rejected because the user gets no controlled recovery path.
- Keep simulated username availability in production routing: rejected because it can disagree with the canonical server policy.
- Change username RPC/server behavior in this slice: rejected as unrelated backend/performance expansion.

### Failure and Accessibility States

- saving → existing button loading state;
- generic save failure → transient error feedback, page remains, values preserved;
- username-specific save failure → existing Username unavailable/error feedback surface where possible;
- retry → same form values can be resubmitted after correcting input or transient failure;
- success → existing success feedback and pop.

## 5. Implementation Plan

- [ ] add controlled `catch` path to Account Settings save flow without layout redesign
- [ ] preserve values/loading state and retry after failure
- [ ] reuse existing Username feedback for field-specific server rejection
- [ ] wire real server-backed username availability in `router.dart`
- [ ] add tests for generic failure: no pop/no success/values preserved/loading reset/retry
- [ ] add tests for username-specific failure feedback
- [ ] add app/composition test for real availability callback mapping where practical
- [ ] run focused analyze/tests
- [ ] run full applicable CI before review-ready handoff
- [ ] run narrow real-device acceptance

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

Username-save latency is a separate non-blocking performance observation from Slice 1 and is not optimized here.

### Final Status

`PARTIAL`
