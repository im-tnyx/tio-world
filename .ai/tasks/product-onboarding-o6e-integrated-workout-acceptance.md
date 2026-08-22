# Product Onboarding O6E — Integrated Canonical Workout Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #74  
**Parent O6:** #69  
**O6D persistence cutover:** #73 ✅ / CI #1552  
**O6C runtime/targets:** #72 ✅ / CI #1537  
**O6B runtime/profile:** #71 ✅ / CI #1511  
**O6A contracts:** #70 ✅ / CI #1509  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting validated checkpoint

```text
01b3c36a13e2a40cdc55e25c544f66af8c39d7bb
Flutter CI #1552 / run 32590392127
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

This is the frozen O6D source checkpoint. Tracker/task commits after it do not replace exact source validation.

## Objective

Validate Workout end-to-end after the canonical runtime and persistence split. This slice is acceptance-focused: add focused integrated tests and fix only proven implementation bugs. Do not introduce a new architecture, UI, flow, formula, schema version, or semantic default without evidence from a failing acceptance case.

## Canonical runtime contract

Workout/Hybrid setupNow:

```text
workoutProfile
  gymAccess
  equipment (home only)
  experienceLevel
  focusAreas
  healthConcerns
→ workoutTargets
  trainingDays
  workoutDuration
  workoutSplit
  specialEvent
```

Nutrition and Hybrid later contain neither Workout section for the active run.

## Canonical completion contract

```text
Profile
→ Body
→ Wellness
→ Nutrition Profile (when active)
→ Workout Profile (when active)
→ Workout Targets (when active)
→ Nutrition Targets
→ confirmed App Mode / active_tabs
→ completion publication
```

No Product Onboarding call to `WorkoutPreferencesRepository.saveWorkoutPreferences` is allowed.

## Acceptance matrix

### 1. Workout first run

Validate:
- runtime order crosses `workoutProfile → workoutTargets` continuously;
- canonical Profile fields round-trip with explicit/null semantics;
- canonical Targets fields round-trip losslessly;
- only training intents map to Workout goals;
- original unified goal rank 1/2 is preserved;
- Body-direction intents are omitted;
- Auto duration maps null preferred minutes;
- trimmed empty event and missing event date remain null;
- completion writes Workout Profile before Workout Targets.

### 2. Hybrid setupNow

Validate:

```text
Nutrition Profile
→ Workout Profile
→ Workout Targets
→ Nutrition Targets
```

and only then App Mode / completion publication.

### 3. Hybrid later

Validate:
- both Workout runtime sections are skipped;
- neither canonical Workout owner is written;
- pre-existing Workout Profile + Targets data remains unchanged.

### 4. Nutrition

Validate neither canonical Workout owner is written.

### 5. Resume / compatibility

Validate:
- schema v6 canonical `workoutProfile` / `workoutTargets` resumes at exact owner/child cursor;
- pre-v6 broad `workoutPreferences` / `workoutProfile` snapshots migrate owner-aware;
- historical `workoutPreferences` stays decode-only;
- new saves stay canonical;
- back/edit across Profile/Targets boundary invalidates only the correct completed owner subsection;
- no reclassification of Profile-owned child state into Targets-owned state.

### 6. Failure / retry / idempotency

Validate:
- Workout Profile failure blocks Workout Targets + all later publication;
- Workout Targets failure blocks Nutrition Targets + App Mode + completion;
- retry succeeds through canonical owners only;
- completed retry is idempotent;
- no fallback/dual write to the broad Workout repository.

## Implementation slices

1. Audit current O6B/O6C/O6D test coverage and avoid duplicate low-value tests.
2. Add one focused integrated O6E acceptance test file for gaps across runtime + persistence boundaries.
3. Reuse deterministic in-memory canonical repositories/recorders.
4. Test Workout, Nutrition, Hybrid setupNow, Hybrid later eligibility in one coherent matrix.
5. Test canonical owner data/rank/null semantics at completion.
6. Test fail-closed Profile/Targets ordering and retry/idempotency.
7. Test schema-v6 resume plus representative pre-v6 broad migration boundary.
8. Prove Product Onboarding broad Workout writer remains untouched.
9. Run exact full four-gate CI.

## Guardrails

- no visual redesign/copy/field/value change;
- no navigation/eligibility/formula change;
- no schema-version change unless a failing compatibility test proves a real bug;
- no DB schema/migration/applied migration edit;
- no legacy column/table drop;
- no dual write;
- no fabricated Workout goal/location/equipment/experience/focus/schedule/event default;
- O11/#54 remains blocked until O10;
- PR #50 stays Draft/open/unmerged.

## Acceptance

- [ ] Workout first-run runtime order is continuous across `workoutProfile → workoutTargets`;
- [ ] Workout completion writes both canonical owners in order;
- [ ] Workout Profile explicit/null semantics round-trip;
- [ ] Workout Targets ordered goals/ranks and target fields round-trip without fabrication;
- [ ] Hybrid setupNow writes Nutrition + both Workout owners in fail-closed order;
- [ ] Hybrid later writes neither Workout owner and preserves stored Workout data;
- [ ] Nutrition writes neither Workout owner;
- [ ] schema v6 resume + pre-v6 migration remain continuous/lossless;
- [ ] Workout Profile failure blocks all later publication;
- [ ] Workout Targets failure blocks all later publication;
- [ ] retry/idempotency remain correct;
- [ ] Product Onboarding never calls broad `saveWorkoutPreferences`;
- [ ] no UI/navigation/formula/DB change;
- [ ] four CI gates green on one exact source SHA.

## Exit

Freeze exact O6E source SHA + CI evidence, close #74 and parent O6 #69, update #40/#44/#50, then activate O7 Health Connections.