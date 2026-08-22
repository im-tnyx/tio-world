# Product Onboarding O4 — Canonical Wellness

**Status:** In progress — audit active  
**Tracker:** GitHub Issue #58  
**Parent:** #40  
**Canonical ownership:** #44  
**Predecessor:** #55 O3 ✅ CI #1354  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

```text
75237e6c31222f4b08f3cdd41353121aa1ca3afc
Flutter CI #1354 / run 32562632629
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Outcome

Give Wellness one canonical Product Onboarding semantic/persistence owner and remove ongoing Wellness durable mirrors from Nutrition without destructive cleanup.

Canonical durable owner:

```text
user_wellness_targets
→ steps_target
→ water_target_ml
→ sleep_target_minutes
→ bed_time
→ wake_up_time
```

## Audit before source changes

Determine current reality for:
- active `TargetStepId` / `TargetsFlowPlan` Wellness children;
- `TargetsOnboardingDraft` Wellness value/cursor serialization;
- existing Step/Sleep/Water screens and validators;
- any typed Wellness flow/section identity already present;
- canonical `user_wellness_targets` domain/repository adapter availability;
- `SupabaseTargetsSetupRepository` Wellness mirror writes;
- Nutrition recommendation dependencies on steps/sleep/water/bed/wake;
- resume/progress behavior for current Targets cursors.

The audit must create one focused O4A task/issue before source edits.

## Expected execution shape

Exact slices are decided by audit, but likely sequence is:

```text
O4A typed Wellness contract/owner boundary
→ O4B runtime Wellness section + navigation/progress/resume
→ O4C canonical Wellness persistence + stop Nutrition Wellness mirrors
→ O4D integrated read/write/resume/failure acceptance
```

Only one O4 sub-slice may be active at a time.

## Guardrails

- preserve existing Wellness screens and picker behavior unless wiring requires movement;
- do not invent Wellness defaults to satisfy persistence;
- Nutrition may consume Wellness values for calculation but must not own them durably;
- no permanent dual-write synchronization;
- no anonymous-auth side effects on canonical owner writes;
- no applied migration edits;
- no legacy-column drops; O11/#54 remains blocked until O10;
- no O5 source work until O4 integrated acceptance is green.

## Validation

Each focused sub-slice requires tests with exact CI evidence before the next begins. Final O4 acceptance requires:

```text
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

on one exact O4 source checkpoint.

## Current work

**Audit current Wellness runtime/draft/persistence ownership and open the smallest safe O4A slice.**
