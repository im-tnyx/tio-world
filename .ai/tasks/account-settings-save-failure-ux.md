# Account Settings Save Failure UX

**Status:** Validated
**Primary owner:** `apps/features/settings`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #8, Slice 2
**Source branch:** `agent/account-settings-save-failure-ux`
**PR:** #43

## Global UI / Design-System Guardrail

This slice is save-reliability/error-feedback work, not a visual redesign. `apps/core/lib/src/theme/README.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/features/AGENTS.md` were reviewed before implementation.

Mandatory guardrails:

- preserve the normal loaded Account Settings layout, spacing, typography, colors, controls, assets, and interaction geometry;
- reuse the existing `TioButton` loading state;
- generic save failure uses the existing transient Snackbar surface rather than adding layout-changing content;
- do not create new feature-local tokens or duplicate reusable core UI;
- no Supabase migration is required for this slice.

## 1. Discovery

### User Outcome

When Account Settings persistence fails, the user remains on the page with entered Username/Mobile intact, sees clear controlled feedback, and can retry without false success or navigation.

### Success Criteria

- [x] normal Account Settings rendering remains unchanged;
- [x] Save success preserves the existing success Snackbar + pop behavior;
- [x] repository/save failure is caught inside Account Settings presentation flow;
- [x] failure never shows success feedback and never pops the page;
- [x] `_isSaving` resets and duplicate save remains guarded;
- [x] entered Username and Mobile remain in their controllers after failure;
- [x] generic persistence/network failure is surfaced through transient error feedback without changing page geometry;
- [x] missing `onSave` cannot produce a false success/pop;
- [x] focused widget regressions cover failure recovery, preserved values, retry, and unavailable-save behavior;
- [x] full Flutter/Dart CI passed;
- [x] real-device acceptance passed;
- [x] no DB/schema/RLS change.

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

- Before this slice `AccountSettingsPage._handleSave()` had `try/finally` but no `catch`.
- Success Snackbar/pop already happened only after successful `await`, but repository failures had no controlled user-facing recovery feedback.
- A null `onSave` previously completed through the null-aware callback and could still produce success/pop.
- Existing `TioButton.primary` already owns loading presentation.
- `router.dart` already wires the real `ProfileAccountRepository.updateAccountSettings()` production save path.
- Audit also found the optional live Username availability callback is not wired by app composition. That adjacent UX/correctness concern remains explicitly deferred; final save remains server-authoritative.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve normal Account Settings pixels | Approved | Issue #8 excludes visual redesign | Product owner |
| Generic save failure uses transient feedback | Approved | Surfaces failure without layout shift | Settings presentation |
| Missing save callback fails visibly | Approved | Prevent false-success edge case | Settings presentation |
| Real live Username availability wiring | Deferred | Adjacent concern; not needed for save-failure recovery | App/Profile follow-up |
| No server-policy or migration change | Approved | Existing persistence contract is sufficient | Profile/data |

## 4. Architecture Design

### Chosen Approach

`AccountSettingsPage` keeps persistence/domain details outside the widget. The existing `onSave` callback remains the persistence boundary. A thrown callback failure is caught locally, shown as a generic retryable Snackbar, and leaves the route/controller state intact. A missing callback is treated as persistence unavailable instead of success.

Normal success behavior is unchanged.

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

- New inline error section: rejected because it would change page geometry.
- Let repository exceptions bubble: rejected because it gives no controlled recovery UX.
- Expand into live Username availability architecture: deferred to keep this slice bounded.
- Change Username RPC/server behavior: outside this slice.

### Failure and Accessibility States

- saving → existing button loading state;
- generic save failure → transient error feedback, page remains, values preserved;
- unavailable save callback → transient unavailable feedback, no success/pop;
- retry → same form values can be resubmitted;
- success → existing success feedback and pop.

## 5. Implementation Plan

- [x] add controlled `catch` path without layout redesign
- [x] prevent null `onSave` from producing false success/pop
- [x] preserve values/loading state and retry after failure
- [x] add generic failure regression for no pop/no success/value preservation/retry
- [x] add unavailable-save callback regression
- [x] keep existing success regression green
- [x] run full applicable CI
- [x] run real-device acceptance

## 6. Quality Review

### Validation Run

Authoritative runtime/test head before this acceptance-only task commit:

```text
6bbdfafe32db1f30c181542b80482935d66479f4
```

GitHub Actions **Flutter CI #942** (run `32348020543`, job `96360835170`) passed:

```text
Bootstrap workspace       PASS
Analyze Flutter packages  PASS
Analyze Dart packages     PASS
Test Flutter packages     PASS
Test Dart packages        PASS
```

Focused regressions cover save failure recovery, no false success/pop, value preservation, loading reset/retry, and missing-save callback behavior.

### Real-Device Acceptance — 2026-08-20

Owner/device smoke was accepted after checking the prescribed Account Settings failure/retry flow. No visual or persistence-recovery issue was reported.

### Review Findings and Resolution

- repository failures now receive controlled transient feedback;
- failure keeps Account Settings open and retryable;
- controller values are not cleared on failure;
- missing persistence callback can no longer present success;
- normal loaded screen geometry/style remains unchanged;
- no DB/schema/RLS change was introduced.

## 7. Final Handoff

### Changed Files

```text
apps/features/settings/lib/src/presentation/pages/account_settings_page.dart
apps/features/settings/test/presentation/account_settings_save_failure_test.dart
.ai/tasks/account-settings-save-failure-ux.md
```

### Actual Behavior

```text
Save
├─ success
│  → existing success Snackbar
│  → pop
└─ failure
   → controlled error Snackbar
   → stay on Account Settings
   → entered values preserved
   → loading reset
   → retry available
```

### Known Limitations

- Username-save latency remains a separate non-blocking performance observation from Slice 1.
- Real server-backed live Username availability wiring remains an explicit follow-up; final save continues to use canonical server repository policy.

### Final Status

`VALIDATED — AUTOMATED + REAL-DEVICE ACCEPTANCE PASS`
