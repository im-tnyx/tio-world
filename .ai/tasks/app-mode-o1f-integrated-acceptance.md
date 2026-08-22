# App Mode O1F — Integrated Acceptance

**Status:** Validated  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

The complete durable App Mode lifecycle is validated across onboarding completion, authenticated restore, Settings mode changes, compatibility recovery, routing visibility, and failure semantics. O1 is complete; Product Onboarding O2 common User Profile ownership is next.

## Authoritative O1F checkpoint

```text
Source: c7925b77e9ccdc1dcd0b6ac1d9554f05972d13a7
Flutter CI #1240 / run 32552460378
Bootstrap workspace        ✅
Analyze Flutter packages   ✅
Analyze Dart packages      ✅
Test Flutter packages      ✅
Test Dart packages         ✅
```

Earlier CI #1239 failed only an analyzer warning in the new acceptance-test helper because an optional `writeError` constructor parameter was never passed. Production code was unchanged. The helper was simplified and #1240 is the authoritative final O1 checkpoint.

## Integrated proof

`apps/app/test/app/app_mode_o1f_integrated_acceptance_test.dart` proves a shared canonical account lifecycle:

```text
first-device CompleteOnboardingUseCase
→ canonical app_mode + ordered active_tabs
→ remote completion
→ local cache

cleared / stale / second-device-equivalent bootstrap
→ canonical remote state wins before Ready
→ exact destinations reach shell + route policy

Ready Settings change
→ canonical-first write
→ runtime/local publication

another fresh device
→ restores the changed canonical state
```

Additional integrated/focused O1 tests cover mode-only rows, missing completed-legacy rows without Hybrid inference, malformed canonical failure, canonical Settings failure, authenticated fail-closed behavior, cache failure after remote success, pre-auth/account-switch isolation, and hidden-domain preservation.

## Acceptance matrix

- [x] first-device Product Onboarding completion writes canonical `app_mode` + ordered `active_tabs` before completion publication;
- [x] cleared local storage / fresh-install-equivalent restores canonical App Mode;
- [x] second-device-equivalent authenticated login restores canonical App Mode/navigation;
- [x] stale local App Mode loses to valid canonical remote state;
- [x] exact canonical `active_tabs` order reaches shell/routing policy unchanged;
- [x] `app_mode` + null `active_tabs` derives guided defaults without semantic inference;
- [x] completed legacy account with missing canonical row clears stale local semantic mode and keeps compatibility navigation;
- [x] malformed/invalid canonical state keeps bootstrap out of `Ready`;
- [x] Settings mode change writes canonical state first and survives a later fresh restore;
- [x] Settings canonical failure preserves the previous effective mode/cache and cannot become false success;
- [x] authenticated `Ready` mode change fails closed if canonical writer is unavailable;
- [x] pre-auth/onboarding/signed-out/account-switch state cannot overwrite another account preference;
- [x] App Mode changes do not mutate hidden Body/Nutrition/Workout owner data;
- [x] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on one exact source checkpoint.

## Guardrails retained

- `user_app_preferences` is the only authenticated App Mode/navigation owner;
- SharedPreferences is cache/pre-auth staging only;
- no silent Hybrid fallback;
- no local-vs-remote dual authority;
- no custom-tab/UI redesign was introduced;
- no hidden Body/Nutrition/Workout deletion;
- no schema/RLS/migration change was required by O1F.

## Exit

```text
O1 durable App Mode / active_tabs ✅ COMPLETE — CI #1240
→ O2 common User Profile owner + section activation NEXT
```
