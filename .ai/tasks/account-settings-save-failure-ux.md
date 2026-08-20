# Account Settings Save Failure UX

**Status:** In progress
**Primary owner:** `apps/features/settings`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #8, Slice 2
**Source branch:** `agent/account-settings-save-failure-ux`

## Global UI / Design-System Guardrail

This slice is save-reliability/error-feedback work, not a visual redesign. `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md` were reviewed before implementation.

Mandatory guardrails:

- preserve the normal loaded Account Settings layout, spacing, typography, colors, controls, assets, and interaction geometry;
- reuse the existing `TioButton` loading state;
- generic save failure must use an existing transient feedback surface rather than inserting new layout-changing content;
- do not create new feature-local tokens or duplicate reusable core UI;
- no Supabase migration is approved or required for this slice.

## 1. Discovery

### User Outcome

When Account Settings persistence fails, the user remains on the page with their entered Username/Mobile intact, sees clear controlled feedback, and can retry without any false success or navigation.

### Success Criteria

- normal Account Settings rendering remains unchanged;
- Save success preserves the current success Snackbar + pop behavior;
- repository/save failure is caught inside Account Settings presentation flow;
- failure never shows the success Snackbar and never pops the page;
- `_isSaving` always resets and double-save remains prevented;
- entered Username and Mobile values remain in their controllers after failure;
- a generic persistence/network failure is surfaced through transient error feedback without changing page geometry;
- missing `onSave` cannot produce a false success/pop;
- focused widget tests cover success, failure, preserved values, retry, and unavailable-save behavior;
- no DB/schema/RLS change.

### Scope

- `AccountSettingsPage` save-error handling and feedback behavior;
- focused Settings widget tests;
- task/PR validation evidence.

### Non-Goals

- Account Settings redesign or layout changes;
- changing Username server policy/RPC behavior;
- wiring/reworking live Username availability in app composition;
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
- Success Snackbar/pop occur only after successful `await`, so repository failures do not currently false-pop, but errors bubble without controlled user-facing feedback.
- If `onSave` is null, the current null-aware callback call completes immediately and the page still shows success/pop; this is a presentation-level false-success edge case worth eliminating.
- Existing `TioButton.primary` already owns the loading state and prevents duplicate user interaction while `_isSaving` is true.
- `ProfileSettingsPage` has a controlled save-failure pattern, but its inline layout-changing error text is not copied here because this slice explicitly preserves Account Settings geometry.
- `router.dart` already wires the real `ProfileAccountRepository.updateAccountSettings()` production save path.
- Existing tests cover successful persisted Account Settings save/pop but not save failure/retry.
- Audit also found that the page's optional live Username availability callback is not wired by the app route, so the page can use its simulated fallback while typing. That is a real adjacent UX/correctness concern, but it is explicitly deferred so this slice stays focused on persistence failure recovery. Final server save policy remains authoritative.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve normal Account Settings pixels | Approved | Issue #8 explicitly excludes visual redesign | Product owner |
| Generic save failure uses transient feedback | Approved | Avoid layout shift while surfacing failure | Settings presentation |
| Missing save callback must fail visibly, not succeed | Approved | Prevent presentation false-success edge case | Settings presentation |
| Real live Username availability wiring | Deferred | Adjacent correctness/UX work; not required to fix save-failure recovery | App/Profile follow-up |
| No server-policy or migration change | Approved | Existing repository/RPC contract is sufficient | Profile/data |

## 4. Architecture Design

### Chosen Approach

Keep persistence/domain details out of the Settings widget. `AccountSettingsPage` owns only presentation behavior: save/loading state, preserving controller values, and transient generic failure feedback.

The page continues to delegate persistence through its existing `onSave` callback. A thrown callback failure is caught locally, shown as a generic retryable error Snackbar, and does not pop the page. A missing callback is treated as persistence unavailable rather than success.

Normal success path remains unchanged.

### Ownership and Data Flow

```text
AccountSettingsPage
  → Save
  → onSave
  → app composition / ProfileAccountRepository
     ├─ success → existing success Snackbar + pop
     └─ failure → catch in page
                  → error Snackbar
                  → stay on page
                  → values preserved
                  → loading reset
                  → retry possible
```

### Alternative Rejected

- Add new inline error section under the form: rejected because it changes normal layout geometry and is unnecessary.
- Let repository exceptions bubble to Flutter: rejected because the user gets no controlled recovery path.
- Expand this slice into live Username availability architecture: deferred to keep the persistence-failure slice bounded and reviewable.
- Change username RPC/server behavior in this slice: rejected as unrelated backend/performance expansion.

### Failure and Accessibility States

- saving → existing button loading state;
- generic save failure → transient error feedback, page remains, values preserved;
- unavailable save callback → transient unavailable feedback, no success/pop;
- retry → same form values can be resubmitted after transient failure;
- success → existing success feedback and pop.

## 5. Implementation Plan

- [ ] add controlled `catch` path to Account Settings save flow without layout redesign
- [ ] prevent null `onSave` from producing false success/pop
- [ ] preserve values/loading state and retry after failure
- [ ] add tests for generic failure: no pop/no success/values preserved/loading reset/retry
- [ ] add test for unavailable save callback
- [ ] keep existing success regression green
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

- Username-save latency is a separate non-blocking performance observation from Slice 1 and is not optimized here.
- Real server-backed live Username availability wiring remains an explicit follow-up; final save continues to use the canonical server repository policy.

### Final Status

`PARTIAL`
