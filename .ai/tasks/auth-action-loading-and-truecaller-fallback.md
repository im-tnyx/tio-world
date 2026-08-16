# Auth Action Loading and Truecaller Fallback

**Status:** Ready
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #9

## 1. Discovery

### User Outcome

Login auth actions behave independently and unavailable Truecaller never simulates a successful auth/navigation event.

### Success Criteria

- Only the tapped/in-flight auth action renders loading.
- Other auth actions may be disabled during a request but do not show another action's spinner.
- Truecaller is intentionally non-functional for now; tapping it keeps the user on Login and shows a short informational message.
- Truecaller unavailable never calls success navigation, `pop(true)`, `go('/')`, or starts a fake auth flow.
- Existing Login visual geometry/layout remains unchanged outside action-state behavior.

### Scope

- `LoginPage` per-action loading/interaction state.
- unavailable Truecaller informational feedback.
- focused Login widget tests.
- coordination with issue #7 where both touch `LoginPage`.

### Non-Goals

- Truecaller SDK/provider integration.
- Truecaller auth/network attempt of any kind in this slice.
- auth/session/bootstrap routing owned by #7.
- Login/EmailLogin consolidation.
- AuthLanding redesign or legal-copy changes.
- global `TioSocialButton` redesign without evidence of a shared component defect.

## 2. Codebase Exploration

### Verified Evidence

- `LoginPage` has one `_isLoading` boolean.
- Email and Google handlers both set `_isLoading = true`.
- Login, Google, and Truecaller buttons all receive `loading: _isLoading`.
- `LoginPage._handleTruecallerSignIn()` pops success when possible or routes to `/` otherwise despite no Truecaller integration check.
- `AuthLandingPage` is different: its missing Truecaller callback is currently a no-op and its `TioTermsDisclaimer` is intentional live UI.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Loading ownership | Made | Scope to initiating auth action | Auth |
| Other actions during request | Made | Disable/conflict-gate without showing spinner | Auth |
| Unavailable Truecaller | Made | Stay on Login and show informational feedback only | Auth |
| Truecaller integration | Deferred | Provider is not linked/configured yet; work will happen later | Product/Auth |
| Truecaller unavailable copy | Made | Use a concise neutral message such as `Truecaller sign-in is not available yet.` | Product/Auth |
| AuthLanding legal disclaimer | Made | Preserve exactly where currently rendered | Auth |

## 4. Architecture Design

### Chosen Approach

Use explicit action identity/state instead of one visual loading boolean.

```text
idle
emailLoading
googleLoading
```

Do not introduce `truecallerLoading` while there is no real Truecaller integration. The initiating Email/Google action owns its spinner. A shared `isBusy` derivation may gate conflicting taps without making all buttons appear loading.

Unavailable Truecaller uses the existing Login feedback/error surface as informational feedback and returns immediately without navigation or auth work.

### Ownership and Data Flow

```text
Login button tap
→ email-specific loading state
→ email auth use case
→ success/failure/cancel
→ reset action state

Google button tap
→ google-specific loading state
→ Google auth use case
→ success/failure/cancel
→ reset action state

Truecaller tap (current phase)
→ show `Truecaller sign-in is not available yet.`
→ remain on Login
→ no auth call
→ no loading spinner
→ no navigation
```

### Alternative Rejected

- one `_isLoading` for all actions: incorrect visual ownership.
- `pop(true)` / `go('/')` as Truecaller placeholder: falsely signals success.
- fake Truecaller success/auth request until SDK is integrated: unsafe product behavior.
- Truecaller spinner without a real request: misleading interaction feedback.

### Failure and Accessibility States

- Keep existing focus order, labels, sizes, colors, spacing, assets, and layout.
- Informational feedback must be readable and recoverable without navigation.
- Rapid repeated taps must not start duplicate auth requests.

## 5. Implementation Plan

- [ ] Rebase/sync after issue #7 LoginPage cleanup to avoid conflicting edits.
- [ ] Add tests proving Email loading affects only Login button.
- [ ] Add tests proving Google loading affects only Google button.
- [ ] Add tests proving other actions are gated without spinner duplication.
- [ ] Add test proving unavailable Truecaller stays on Login and emits no success navigation/auth call.
- [ ] Add test proving unavailable Truecaller shows the informational message and no spinner.
- [ ] Add unavailable Truecaller feedback using existing Login feedback surface.
- [ ] Replace global visual loading state with action-scoped Email/Google state.
- [ ] Run auth package tests/analyze and visual regression check.

## 6. Quality Review

### Validation Run

```text
Not run yet. Task is queued behind active issue #7 work.
```

### Review Findings and Resolution

- Root causes verified from current `codex/onboarding-mode-migration` source.
- Product decision clarified: Truecaller remains intentionally non-functional for now and only shows an informational message on tap.
- No production source changed while updating this task.

## 7. Final Handoff

### Changed Files

```text
.ai/tasks/auth-action-loading-and-truecaller-fallback.md
```

### Actual Behavior

No runtime behavior changed yet.

### Known Limitations

Truecaller provider/SDK remains unconfigured and is intentionally not implemented by this task.

### Final Status

`REVIEW`
