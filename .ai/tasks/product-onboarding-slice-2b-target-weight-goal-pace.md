# Product Onboarding Slice 2B — Target Weight and Goal Pace

**Status:** In progress — core Goal/Target/Pace behavior + Body owner foundation validated; remaining picker/recommendation gates tracked  
**Primary owner:** `apps/features/onboarding`  
**GitHub tracker:** #40  
**Canonical ownership:** #44  
**Canonical implementation PR:** #50  
**Current onboarding sequence:** `.ai/tasks/product-onboarding-canonical-execution.md`

PR #50 remains Draft/unmerged.

## Validated checkpoints

```text
Target Weight draft/direction semantics       CI #1079 ✅
Goal Pace ownership/skipped-intent cleanup    CI #1090 ✅
Integrated mode/goal local acceptance         CI #1095 ✅
Canonical Body onboarding writes              CI #1135 ✅
Canonical Body read/history contract          CI #1153 ✅
P1 Profile/App Preferences schema             LIVE ✅
```

Latest validated Flutter Body source checkpoint before schema-only P1 work:

```text
e3822b81d2c8793191cfb8a208257fd2bc8bc7dd
Flutter CI #1153 / run 32508150413
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

## Approved Goal contract

`GoalIntentSelection` is semantic authority.

Nutrition:

```text
Lose weight      → Target Weight + Goal Pace
Gain weight      → Target Weight + Goal Pace
Maintain weight  → skip both
Recomposition    → skip both
```

Workout / Hybrid:

```text
Lose weight primary/supporting → Target Weight + Goal Pace
training-only goals            → skip both
```

Rules:
- Nutrition single-select;
- Workout/Hybrid max two compatible intents;
- `Build muscle != Gain weight`;
- no Goal inference from BMI/current-target delta;
- no fake GoalIntent → legacy ProfileGoal mappings.

## Maintain/Recomposition semantic rule

Do not auto-fill Target Weight with Current Weight.

Canonical representation:

```text
body_weight_logs
→ current/history weight

user_body_goals.starting_weight_kg
→ goal-start baseline

Maintain / Recomposition
→ target_weight_kg = null
→ weekly_weight_change_kg = null
```

A fake `target_weight=current_weight` would duplicate state and can later misrepresent normal weight fluctuation as a desired destination.

## Target Weight draft behavior — validated

- local draft schema v4 stores Target Weight plus loss/gain direction association;
- eligibility comes only from explicit Goal intent;
- eligible → temporarily ineligible preserves dormant Target Weight in draft state;
- returning to the same direction restores the exact user value;
- explicit loss ↔ gain switch clears incompatible old scalar target;
- recommendation seeding never overwrites an existing user target;
- dormant/ineligible Target Weight is not consumed as canonical Body intent.

## Goal Pace behavior — validated

- Goal Pace owns weekly body-weight change only;
- BMR/TDEE/calorie deficit/surplus logic was removed from Goal Pace ownership;
- ineligible default pace is not consumed/persisted as user-selected intent;
- Review shows pace/target only when explicit current Goal eligibility allows it.

## Canonical Body persistence — validated foundation

```text
Current Weight
→ body_weight_logs

Body Goal / Target Weight / Goal Pace
→ user_body_goals
```

Maintain/Recomposition follow-ups are rejected by both repository semantics and DB constraints.

Training-only Goal intents never create fake Body Goal semantics.

## Current remaining Slice 2B product gates

These remain tracked but do **not** block unrelated onboarding persistence work such as O1 App Mode or O2 Profile owner cutover.

### Measurement picker/reference

Current task history found a mismatch/absence risk around the approved Height/Current Weight/Target Weight input reference. Guardrail remains:

```text
visible value == selected wheel position == canonical draft value
```

Do not invent a replacement picker or redesign. Preserve the approved wheel/picker UI if/when the reference is restored/confirmed.

### Exact Target Weight recommendation numeric policy

Concept is approved; exact numeric policy is not yet final.

Rules:
- explicit Goal intent is semantic authority;
- recommendation is deterministic;
- BMI/current measurements may be safety inputs, not Goal inference;
- recommendation never overwrites a user-selected target;
- no arbitrary fallback target becomes persisted intent.

## Relationship to current onboarding execution

This focused slice is **not the global next-step sequencer anymore**.

Use:

`.ai/tasks/product-onboarding-canonical-execution.md`

Current Product Onboarding order:

```text
O1 durable App Mode / active_tabs        NEXT
→ O2 common Profile owner/section
→ O3 Body Goal section + Body/Profile parity
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7–O10 final onboarding sections/acceptance
```

O3 will complete structural Body/Profile parity and activate the prepared Body Goal section identity while preserving this task's validated Goal/Target/Pace behavior.

## UI preservation

- keep existing Goal card visual language;
- keep Height/Current Weight/Target Weight/DOB wheel/picker contracts;
- preserve Goal Pace slider/projection UI;
- persistence/ownership changes do not authorize redesign;
- user-visible option changes require focused product approval.

## Exit criteria for this focused task

- [x] Goal-aware Target Weight/Goal Pace eligibility
- [x] reversible Target Weight draft semantics
- [x] Goal Pace ownership cleanup
- [x] Review uses unified Goal source
- [x] integrated local mode/goal acceptance
- [x] canonical Body write foundation
- [x] canonical Body read/history foundation
- [ ] approved/confirmed measurement picker/reference or explicit deferral
- [ ] exact Target Weight recommendation numeric policy approved or explicitly deferred
- [ ] O3 proves no active legacy Profile Body ownership remains
- [ ] final O10 acceptance covers all active Goal/weight flows

## Handoff

**Global next onboarding slice:** O1 App Mode (#11), not account verification.  
**This task resumes directly during O3 for final Body/Profile structural parity and during final acceptance for picker/recommendation gates.**