# Product Onboarding O4 — Canonical Wellness

**Status:** In progress — O4A validated; O4B ACTIVE  
**Tracker:** GitHub Issue #58  
**O4A:** #59 ✅ closed / CI #1365  
**O4B:** #60 ACTIVE  
**Parent:** #40  
**Canonical ownership:** #44  
**Predecessor:** #55 O3 ✅ CI #1354  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Validated foundation

O3 final:
```text
75237e6c31222f4b08f3cdd41353121aa1ca3afc
Flutter CI #1354 / run 32562632629 ✅
```

O4A canonical Wellness repository contract:
```text
f244b4913143ba8f76439a8b2554fd095d7e1973
Flutter CI #1365 / run 32563623833
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Canonical durable owner

```text
user_wellness_targets
→ steps_target
→ water_target_ml
→ sleep_target_minutes
→ bed_time
→ wake_up_time
```

O4A established the backend-neutral repository boundary in `tio_feature_progress`. O4B now aligns runtime semantics only.

## Execution

```text
O4A canonical Wellness domain/repository contract             ✅ #59 / CI #1365
→ O4B wellnessGoals runtime section/navigation/progress/resume ACTIVE #60
→ O4C canonical Wellness persistence + Nutrition mirror cutoff
→ O4D integrated Wellness read/write/resume/failure acceptance
```

Only one O4 sub-slice is active at a time.

## O4B target runtime

```text
wellnessGoals
  Bridge
  → Step Target
  → Sleep Target
  → Water Target

targets
  Nutrition Target
```

Existing `TargetsOnboardingDraft` / `TargetStepId` remain serialized compatibility containers. O4B reuses existing screens without redesign and moves semantic ownership/navigation/progress only.

Legacy actual `targets + bridge/stepTarget/sleepTarget/waterTarget` cursors must resume under `wellnessGoals` with values preserved. Later top-level checkpoints stay later when Wellness values are merely dormant.

## Guardrails

- no persistence wiring in O4B;
- no Nutrition Wellness mirror cutoff until O4C;
- no serialized schema-version bump unless unavoidable;
- no UI redesign;
- no applied migration edits or legacy-column drops;
- no O4C until O4B exact full CI green;
- no O5 until O4D.

## Current work

**Execute O4B runtime Wellness ownership on #60 only.**
