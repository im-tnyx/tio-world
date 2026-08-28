# Product Onboarding O4 — Canonical Wellness

**Status:** Validated  
**Tracker:** GitHub Issue #58 ✅ closed  
**Parent:** #40  
**Canonical ownership:** #44  
**Predecessor:** #55 O3 ✅ CI #1354  
**Successor:** O5 Nutrition Profile + Targets  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final O4 checkpoint

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Completed sequence

```text
O4A canonical Wellness repository contract             ✅ #59 / CI #1365
O4B wellnessGoals runtime/navigation/progress/resume   ✅ #60 / CI #1405
O4C canonical persistence + Nutrition mirror cutoff   ✅ #61 / CI #1428
O4D integrated read/write/resume/failure acceptance   ✅ #62 / CI #1441
```

## Final runtime

```text
wellnessGoals
  Bridge
  → Step Target
  → Sleep Target
  → Water Target

targets
  Nutrition Target
```

## Final durable ownership

```text
public.user_wellness_targets
  steps_target
  water_target_ml
  sleep_target_minutes
  bed_time
  wake_up_time
```

Product Onboarding owner persistence order is:

```text
Profile
→ Body
→ Wellness
→ Workout (when active)
→ Nutrition Targets
→ completion publication
```

Nutrition may consume Wellness values for calculations/recommendations but active Nutrition persistence no longer durably owns them.

## Compatibility result

`TargetsOnboardingDraft` / `TargetStepId` remain serialized compatibility containers. O4D added narrow presence provenance so historical snapshots with missing Wellness fields do not turn current UI defaults into fabricated canonical values. Legacy cursors still normalize losslessly to `wellnessGoals`.

Legacy database mirrors remain read-compatible where needed until later owner cutovers/O11. No destructive schema cleanup occurred.

## Guardrails preserved

- no UI redesign or picker contract change;
- no permanent dual-write synchronization;
- no applied migration edit or legacy-column drop;
- no anonymous-auth side effect for canonical Wellness writes;
- no fabricated canonical defaults;
- O11/#54 remains blocked until O10;
- PR #50 remains Draft/open/unmerged.

## Handoff

**O4 is complete. O5 Nutrition Profile + Targets starts from exact validated source checkpoint `d70de933dc0cc01f1c6544d37f625fb01937b309` / CI #1441.**
