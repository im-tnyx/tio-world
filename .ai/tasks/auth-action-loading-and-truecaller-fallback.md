# Auth Action Loading and Truecaller Fallback

**Status:** In progress
**Primary owner:** `apps/features/auth`
**Affected platforms:** Flutter phone app
**Tracking:** GitHub issue #9

## 1. Discovery

### User Outcome

Login auth actions behave independently and unavailable Truecaller never simulates a successful auth/navigation event.

### Success Criteria

- Only the tapped/in-flight auth action renders loading.
- Other auth actions are conflict-gated during a request without showing another action's spinner.
- Truecaller is intentionally non-functional for now; tapping it keeps the user on Login and shows `Truecaller sign-in is not available yet.`
- Truecaller unavailable never calls success navigation, `pop(true)`, `go('/')`, or starts fake auth/network work.
- Rapid repeated taps do not start duplicate auth requests.
- Failure/cancel returns the initiating action to idle.
- Existing Login geometry, spacing, colors, typography, assets, and button layout remain unchanged.

### Non-Goals

- Truecaller SDK/provider integration.
- auth/session/bootstrap routing (completed under #7).
- Login/AuthLanding redesign or consolidation.
- legal-copy changes.
- global `TioSocialButton` redesign.

## 2. Verified Evidence

After #7 cleanup, `LoginPage` is destination-neutral but still has one `_isLoading` boolean:

- Email and Google both mutate `_isLoading`.
- Login, Google, and Truecaller all render `loading: _isLoading`.
- back/forgot/signup interactions use the same busy guard.
- unavailable Truecaller still performs `pop(true)` or `go('/')`.

Core `TioSocialButton` already exposes independent `enabled` and `loading` inputs, so this can be fixed locally without changing the shared component.

## 3. Frozen Decisions

```text
idle
emailLoading
googleLoading
```

No `truecallerLoading` exists until a real Truecaller integration exists.

```text
Email tap
→ only Login spinner
→ Google/Truecaller disabled, no spinner

Google tap
→ only Google spinner
→ Login/Truecaller disabled, no spinner

Truecaller tap
→ no spinner
→ no auth/network
→ no navigation
→ existing Login feedback surface shows:
  “Truecaller sign-in is not available yet.”
```

## 4. Implementation Plan

- [x] #7 Login destination cleanup completed and locally validated
- [ ] replace global visual loading bool with action identity
- [ ] gate conflicting actions without spinner duplication
- [ ] replace Truecaller navigation placeholder with informational feedback only
- [ ] add Email loading ownership widget test
- [ ] add Google loading ownership widget test
- [ ] add conflict-gating/no-spinner widget assertions
- [ ] add Truecaller no-navigation + feedback test
- [ ] add cancellation/idle regression coverage
- [ ] run focused Login tests and auth analyzer
- [ ] confirm no visual composition/layout code changed

## 5. Quality Review

Implementation must remain local to `LoginPage` + focused tests unless evidence requires otherwise.

## 6. Final Handoff

Pending implementation and local validation.
