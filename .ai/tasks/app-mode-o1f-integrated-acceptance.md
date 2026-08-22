# App Mode O1F — Integrated Acceptance

**Status:** In progress  
**Tracker:** GitHub Issue #11  
**Parent task:** `.ai/tasks/app-mode-foundation.md`  
**Canonical onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`  
**Implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Outcome

Prove the complete durable App Mode lifecycle across onboarding completion, authenticated restore, Settings mode changes, compatibility recovery, routing visibility, and failure semantics before O1 is declared complete.

This slice is acceptance-first. Production behavior should change only if the integrated matrix exposes a real contract gap.

## Starting checkpoint

Latest validated implementation checkpoint before O1F:

```text
O1E source: 7210fe7409af9f41f7478096e19d56853e8060d4
Flutter CI #1231 / run 32551614514
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O1F starts from current branch head after handoff/documentation sync:

```text
45b07f1f1abc07dc2c13d9bc77d01a061105eec5
```

## Acceptance matrix

- [ ] first-device Product Onboarding completion writes canonical `app_mode` + ordered `active_tabs` before local completion publication;
- [ ] cleared local storage / fresh-install-equivalent restores canonical App Mode;
- [ ] second-device-equivalent authenticated login restores the same canonical App Mode/navigation;
- [ ] stale local App Mode loses to valid canonical remote state;
- [ ] exact canonical `active_tabs` order reaches shell/routing policy unchanged;
- [ ] `app_mode` + null `active_tabs` derives current guided defaults without semantic inference;
- [ ] completed legacy account with missing canonical row clears stale local semantic mode and keeps controlled compatibility navigation;
- [ ] malformed/invalid canonical state keeps bootstrap out of `Ready`;
- [ ] Settings mode change writes canonical state first and survives a later fresh restore;
- [ ] Settings canonical write failure preserves the previously effective mode/cache and cannot become false success navigation;
- [ ] authenticated `Ready` mode change fails closed if canonical writer is unavailable;
- [ ] App Mode changes do not delete or mutate hidden Body/Nutrition/Workout owner data;
- [ ] full Flutter analyze + Dart analyze + Flutter tests + Dart tests are green on one exact final O1 checkpoint.

## Integrated proof strategy

Add a focused app-level lifecycle acceptance test using one fake canonical account store shared across boundaries:

```text
CompleteOnboardingUseCase
→ canonical AppPreferences + remote completion
→ device-local cache

new / cleared / stale device controller
→ AppSessionBootstrapController
→ canonical restore before Ready
→ shell/route destinations

Ready Settings change
→ canonical-first AppModeController.select
→ new canonical state

another fresh device
→ bootstrap restores changed canonical state
```

Separate scenarios cover missing legacy rows, mode-only rows, malformed canonical reads, Settings write failure, fail-closed authenticated writes, and hidden-domain preservation.

Existing focused O1A–O1E tests remain authoritative for low-level edge cases; O1F adds cross-boundary proof rather than duplicating every unit test.

## Guardrails

- no UI redesign;
- no schema/RLS/migration change unless a real acceptance failure proves it is required;
- `user_app_preferences` remains the only authenticated App Mode/navigation owner;
- SharedPreferences remains cache/pre-auth staging only;
- no silent Hybrid fallback;
- no local-vs-remote dual authority;
- no hidden Body/Nutrition/Workout owner deletion on mode change;
- do not start O2 common Profile until O1F is validated and final evidence is recorded in #11, #40, #44, PR #50, `.ai/CURRENT.md`, and canonical task docs.

## Validation

Not run yet. Do not mark O1 complete until the integrated matrix and full CI are green on the exact final O1 source checkpoint.

## Exit

When validated:

```text
O1 durable App Mode / active_tabs ✅ COMPLETE
→ O2 common User Profile owner + section activation NEXT
```
