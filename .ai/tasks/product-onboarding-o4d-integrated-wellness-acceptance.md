# Product Onboarding O4D — Integrated Canonical Wellness Acceptance

**Status:** Validated  
**Tracker:** GitHub Issue #62 ✅ closed  
**Parent O4:** #58 ✅ complete  
**Predecessor O4C:** #61 ✅ CI #1428  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**Successor:** O5 Nutrition Profile + Targets  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Final validated checkpoint

```text
d70de933dc0cc01f1c6544d37f625fb01937b309
Flutter CI #1441 / run 32570394147
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This exact SHA is the frozen O4D/O4 runtime baseline. Later task/tracker-only commits do not replace it unless runtime source changes and full CI is rerun.

## Validated canonical Wellness path

```text
Product Onboarding Wellness compatibility state
        ↓
WellnessTargetsMapper
        ↓
WellnessTargetsRepository
        ↓
SupabaseWellnessTargetsRepository
        ↓
public.user_wellness_targets
```

Canonical owner fields remain:

```text
steps_target
water_target_ml
sleep_target_minutes
bed_time
wake_up_time
```

## Integrated acceptance proved

- fresh Steps/Water/Sleep/Bed/Wake values map and round-trip through the canonical owner;
- canonical readback remains authoritative and Nutrition mirrors are not restored as durable truth;
- legacy `targets + bridge/stepTarget/sleepTarget/waterTarget` cursors resume under `wellnessGoals` without value loss;
- later top-level resume checkpoints remain later when nested Wellness state is dormant;
- legacy snapshots missing Wellness fields no longer promote current UI defaults into canonical truth;
- narrow provenance flags preserve whether each compatibility value was historically present;
- `WellnessTargetsMapper` maps absent historical values to canonical `null` while preserving explicit current values;
- canonical nullable unknown/clear semantics remain meaning-preserving;
- Wellness owner failure blocks Workout, Nutrition Targets, confirmed App Mode, and completion publication in the same call;
- signed-out canonical Wellness writes remain fail-closed with no anonymous-auth side effect;
- retry paths do not recreate Nutrition-owned Wellness mirrors;
- Nutrition calculation inputs remain available without restoring durable Wellness ownership;
- production app composition selects `SupabaseWellnessTargetsRepository` when Supabase is available and delegates the Body/Wellness bridge to the canonical provider;
- no UI redesign, runtime section reorder, applied migration edit, schema drop, or permanent dual-write was introduced.

## Source changes made by O4D

O4D exposed one semantic gap and fixed it narrowly:

```text
TargetsOnboardingDraft
  concrete values for UI compatibility
  + provenance booleans for historical presence

OnboardingDraftSnapshotDtoMapper
  preserves missing/present provenance

WellnessTargetsMapper
  present value → canonical value
  historically absent value → null
```

No onboarding schema-version bump was required.

## O4 final outcome

```text
wellnessGoals
  Bridge → Step Target → Sleep Target → Water Target

Owner persistence
  Profile → Body → Wellness → Workout(if active) → Nutrition Targets → completion

Wellness durable owner
  public.user_wellness_targets
```

Active Nutrition persistence no longer owns Steps/Water/Sleep/Bed/Wake values. Legacy stored mirrors/read compatibility remain until later cutovers/O11.

## Exit

**O4D validated. O4 Wellness complete. O5 Nutrition Profile + Targets may start from exact validated source checkpoint `d70de933dc0cc01f1c6544d37f625fb01937b309` / Flutter CI #1441.**
