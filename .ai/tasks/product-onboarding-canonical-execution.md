# Product Onboarding — Canonical Execution Plan

**Status:** In progress — O1 App Mode durability; O1A/O1B/O1C validated, O1D bootstrap/restore is NEXT  
**Primary tracker:** GitHub Issue #40  
**Canonical ownership:** #44  
**App Mode:** #11  
**Account contact verification:** #8 (parallel account lane; not an onboarding blocker)  
**Settings parity:** #45 / #46 / #47  
**Canonical implementation PR:** #50  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Purpose

This file is the single current sequencing source for finishing post-signup Product Onboarding. It supersedes stale execution-order language in older onboarding planning tasks while preserving their validated implementation evidence and product/UI guardrails.

Only one Product Onboarding implementation slice is active at a time. Each slice must be validated and recorded here + #40 before the next begins.

## Current verified foundation

Validated / live:

```text
Section/step identity compatibility foundation      ✅ CI #945
Unified mode-aware Goal behavior                    ✅
Target Weight draft/eligibility semantics           ✅ CI #1079
Goal Pace ownership + skipped-intent cleanup         ✅ CI #1090
Integrated Goal/weight local acceptance + Review    ✅ CI #1095
Canonical Body onboarding writes                    ✅ CI #1135
Canonical Body read/history contract                 ✅ CI #1153
Canonical Body/Wellness/Nutrition/Workout tables    ✅ LIVE
user_profiles + user_app_preferences schema          ✅ LIVE
users.email_verified_at                              ✅ LIVE
P1 schema RLS/grants/hardening                       ✅ LIVE
O1A App Preferences domain/repository contract       ✅ CI #1183
O1B Supabase App Preferences adapter                 ✅ CI #1187
O1C onboarding completion canonical preference write ✅ CI #1194
```

O1C validated source:

```text
e9140705521f8af94675d785fb498180096bef55
Flutter CI #1194 / run 32548512802
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

Applied P1 migrations:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

PR #50 remains Draft/unmerged.

## Important sequencing correction

Account contact verification (#8) is important but is **not a technical prerequisite for Product Onboarding App Mode/Profile/domain persistence**.

Two tracks now exist:

```text
PRODUCT ONBOARDING LANE
O1 App Mode durability
→ O2 common Profile owner/section
→ O3 Body Goal section/canonical parity
→ O4 Wellness
→ O5 Nutrition
→ O6 Workout
→ O7 Health Connections
→ O8 Review + resume/edit-back
→ O9 Plan Building/finalization + Congratulations
→ O10 mode/device/persistence acceptance

ACCOUNT / SETTINGS LANE
A1 real email/mobile verification (#8)
→ later Settings parity consumes the same canonical owners
```

A1 may be implemented before or between onboarding slices when explicitly prioritized, but it must not block O1 solely for sequencing convenience.

## Final onboarding section target

```text
App Mode
→ User Profile
→ Body Goal
→ Wellness Goals                  if product-approved for onboarding
→ Nutrition Profile              Nutrition + Hybrid
→ Workout Intro                  Hybrid only
   ├─ Set up now → Workout Profile + Workout Targets
   └─ Later      → skip both for this run; preserve saved Workout data
→ Nutrition Targets              Nutrition + Hybrid
→ Workout Targets                Workout + configured Hybrid
→ Health Connections             optional, if approved
→ Review
→ Plan Building / Finalization
→ existing CongratulationsScreen
→ App
```

Exact Hybrid ordering between eligible Nutrition/Workout blocks remains controlled by the flow-plan tests. `Later` semantics are fixed: skip both Workout Profile and Workout Targets without deleting owner data.

## Canonical owners

```text
users                      → account/domain root + contacts/status
user_profiles              → common Profile
user_app_preferences       → App Mode + ordered active_tabs
body_weight_logs           → current/history weight
user_body_goals            → Body Goal + Target Weight + Goal Pace
user_wellness_targets      → steps/water/sleep
user_nutrition_profiles    → diet/allergy/food context
user_nutrition_targets     → calories/macros/fiber + recommendation/custom state
user_workout_profiles      → workout capability/context
user_workout_targets       → workout goals/schedule/plan constraints
onboarding_drafts          → draft/resume orchestration only
```

Onboarding is an orchestrator, never the durable owner.

## O1 — Durable App Mode / active navigation — IN PROGRESS

**Tracker:** #11  
**Focused task:** `.ai/tasks/app-mode-foundation.md`

Validated sub-slices:

```text
O1A backend-neutral App Preferences contract     ✅ #1183
O1B Supabase user_app_preferences adapter        ✅ #1187
O1C onboarding completion cutover                ✅ #1194
O1D authenticated bootstrap/restore              NEXT
O1E Settings mode-change parity
O1F integrated acceptance/full CI
```

Current behavior after O1C:

```text
Onboarding completion
→ owner writes
→ optional finalizer
→ canonical user_app_preferences(app_mode + guided active_tabs)
→ local App Mode cache
→ remote onboarding completion
→ local completion cache
→ best-effort draft clear
```

O1C failure semantics are locked: canonical App Preferences failure keeps onboarding incomplete/retryable, and a completed retry with a missing canonical preference repairs that preference instead of silently returning.

### O1D — NEXT

Authenticated bootstrap/restore must make canonical remote preference win for signed-in users:

```text
authenticated account
→ read user_app_preferences
→ valid active_tabs: restore exact order
→ app_mode + null active_tabs: derive guided defaults
→ completed legacy account with no canonical preference: controlled recovery
→ refresh local SharedPreferences cache
→ final navigation/shell resolution
```

O1D acceptance:
- [ ] wire backend-neutral `AppPreferencesRepository` into authenticated session/bootstrap;
- [ ] valid remote state wins over stale local cache;
- [ ] cleared local storage recovers from remote;
- [ ] second device recovers from remote;
- [ ] app_mode-only legacy row derives current guided defaults;
- [ ] malformed canonical row fails/recover safely rather than becoming local success;
- [ ] both canonical fields absent never silently invent Hybrid;
- [ ] pre-auth pending mode cannot overwrite another authenticated account;
- [ ] no Settings write cutover in O1D;
- [ ] focused tests + full relevant CI and exact checkpoint before O1E.

Remaining O1:
- [ ] O1D authenticated bootstrap/restore;
- [ ] O1E Settings mode change writes the same owner;
- [ ] O1F fresh-install/cleared-local/second-device/stale-cache integrated acceptance;
- [ ] SharedPreferences confirmed mode becomes cache/fast path rather than authenticated authority;
- [ ] no hidden Nutrition/Workout/Body data deletion on mode changes;
- [ ] full Flutter/Dart CI and exact final O1 checkpoint.

No custom-tab redesign in O1.

## O2 — Common User Profile owner + section activation

**Depends on:** O1 validated.

Canonical Profile fields:

```text
name
gender
date_of_birth
unit_preferences
height_cm
activity_level
health_conditions
other_health_condition
```

Current Weight is Body, not Profile.

Scope:
- [ ] cut onboarding common Profile persistence to `user_profiles`;
- [ ] activate/migrate the prepared `userProfile` section identity without breaking old drafts;
- [ ] preserve existing Name/Gender/DOB/Units/Height/Activity/Health UI and wheel contracts;
- [ ] remove Profile ownership of Goal/Target Weight/current weight from active canonical mapping;
- [ ] canonical Profile values win over stale `users` mirrors;
- [ ] no legacy-column drop yet;
- [ ] Settings common Profile parity can follow through the same repository contract;
- [ ] migration/resume tests + CI.

## O3 — Body Goal section + Body parity completion

**Depends on:** O2 validated.

Already validated foundations:
- unified Goal screen;
- Target Weight/Goal Pace flow semantics;
- Body canonical write/read repository.

Scope still required:
- [ ] activate/migrate prepared `bodyGoal` section identity while preserving existing Goal/Target Weight/Goal Pace UI;
- [ ] Current Weight stays in the user measurement flow but persists through Body owner;
- [ ] Profile models/mappers stop owning Body fields;
- [ ] no `users.current_weight_kg`, `users.target_weight_kg`, `users.goals`, `users.primary_goal` canonical writes;
- [ ] Profile Settings current-weight edits append `body_weight_logs` history rows;
- [ ] canonical Body values win over stale legacy mirrors;
- [ ] integrated onboarding/Settings read/write tests.

Final Body follow-up contract:

```text
Lose weight       → Target Weight + Goal Pace
Gain weight       → Target Weight + Goal Pace
Maintain weight   → skip both
Recomposition     → skip both
Workout/Hybrid Lose as primary/supporting → Target Weight + Goal Pace
training-only goals → skip both
```

Maintain/Recomposition do not auto-fill Target Weight with Current Weight. The maintenance/recomposition baseline is already represented by `starting_weight_kg` + weight history.

Remaining product gates, not permission to block unrelated persistence:
- measurement-picker/reference restoration if current active UI still lacks the approved reference;
- exact Target Weight recommendation numeric policy.

## O4 — Wellness placement + canonical owner

**Owner:** `user_wellness_targets`; Settings counterpart #45.

First action is a focused product/audit decision because #40 still leaves placement open.

Decide one of:
- required first-run onboarding;
- optional/skippable onboarding;
- Settings-only.

Candidate fields:
- steps;
- water;
- sleep duration;
- bedtime/wake time only if separately approved.

If onboarding-active:
- [ ] activate `wellnessGoals` identity;
- [ ] reuse existing target controls where valid;
- [ ] persist only to `user_wellness_targets`;
- [ ] remove Wellness ownership from mixed Nutrition targets repository;
- [ ] preserve mode independence.

## O5 — Nutrition Profile + Nutrition Targets split

**Eligible:** Nutrition + Hybrid  
**Settings counterpart:** #46

### Nutrition Profile
- diet type/style;
- allergies/restrictions;
- preferred/disliked foods where approved.

### Nutrition Targets
- calories;
- protein;
- carbs;
- fat;
- fiber;
- BMR/TDEE calculated context only.

Scope:
- [ ] activate `nutritionProfile` + `nutritionGoals` identities;
- [ ] cut persistence to `user_nutrition_profiles` + `user_nutrition_targets`;
- [ ] define and test recommended/custom/mixed state behavior;
- [ ] remove Body/Wellness/Profile mirrors from active Nutrition repository path only when true-owner reads are wired;
- [ ] mode changes hide but never delete Nutrition state;
- [ ] Review/resume parity + CI.

Open product decision before UI activation: exact Nutrition Profile requiredness and recommended-vs-custom behavior.

## O6 — Workout Intro + Workout Profile + Workout Targets split

**Eligible:** Workout + configured Hybrid  
**Settings counterpart:** #47

Fixed Hybrid rule:

```text
Workout Intro
├─ Set up now → Workout Profile + Workout Targets
└─ Later      → skip both, preserve existing data
```

Profile capability concepts:
- training location/environment;
- Home/Gym setup/facility type if approved;
- explicit Available Equipment for both Home and Gym;
- experience;
- focus areas;
- injuries/limitations.

Targets:
- Workout-specific Goal(s);
- training days;
- preferred duration;
- split;
- optional special event/date.

Before activation resolve:
- final Training Location options (`Both` decision);
- Home/Gym setup labels;
- equipment taxonomy/default suggestions;
- location/setup changes vs preserved equipment;
- split/event lifecycle.

Then:
- [ ] activate `workoutProfile` + `workoutTargets` identities;
- [ ] persist to `user_workout_profiles` + `user_workout_targets`;
- [ ] no Body Goal mirroring into Workout;
- [ ] Hybrid Later regression tests;
- [ ] Review/resume parity + CI.

## O7 — Health Connections

Health/device integration is separately owned; onboarding only offers optional consent-first entry.

Before implementation:
- [ ] create/identify focused health-integration tracker;
- [ ] audit Android Health Connect / Samsung Health availability and permission semantics;
- [ ] decide whether this section ships now or is deferred from first complete onboarding release;
- [ ] define connected/not-connected Review state;
- [ ] no fake connection success.

If approved, activate `healthConnections` identity and keep Skip/Not now available.

## O8 — Review + edit-back + draft/resume reconciliation

Scope:
- [ ] Review renders canonical section data, not legacy mixed mirrors;
- [ ] only eligible/configured sections appear;
- [ ] Hybrid Later never claims Workout configured;
- [ ] edit-back returns to correct owner section and preserves other answers;
- [ ] `onboarding_drafts` schema/version and prepared future step IDs migrate safely;
- [ ] mode/goal changes reconcile completed/current steps without deleting dormant values;
- [ ] process restart, corrupt draft, account switch, retry, and resume tests.

## O9 — Plan Building / truthful finalization

Scope:
- [ ] activate `planBuilding` identity;
- [ ] define real finalization operations that drive progress;
- [ ] idempotent cross-owner finalization;
- [ ] required writes succeed before 100%;
- [ ] failure stays in controlled retry and never shows Congratulations;
- [ ] publish canonical App Mode/completion only at the correct success boundary;
- [ ] clear only safely committed draft data;
- [ ] reuse existing `CongratulationsScreen` exactly as the final handoff surface.

Do not create a duplicate congratulations screen.

## O10 — Final acceptance

Table-driven acceptance across Workout/Nutrition/Hybrid:
- [ ] exact ordered flow;
- [ ] Hybrid Later/setup-now;
- [ ] Next/Back/system Back;
- [ ] progress denominators;
- [ ] draft resume and mode/goal changes;
- [ ] all canonical owner writes;
- [ ] fresh install / second device;
- [ ] failed partial writes/retry;
- [ ] Review correctness;
- [ ] Plan Building → Congratulations → App;
- [ ] no active legacy mirror writes;
- [ ] full Flutter/Dart CI;
- [ ] real-device acceptance.

Only after this should PR #50 become a candidate for Ready/merge. Legacy database columns are cleaned up later by a separate forward migration after proof they are unused.

## Independent A1 — Account contact verification (#8)

This remains required product work but is not a prerequisite for O1–O3 Product Onboarding persistence.

Scope:
- real phone-first → add/verify email;
- real email-first → add/verify mobile;
- remove false `isEmailVerified = true` default;
- reconcile provider-neutral `email_verified_at` / `mobile_verified_at` from trusted Auth evidence;
- no client-authoritative verified timestamps.

A1 must be completed before final account/settings acceptance, but it may be scheduled independently from the onboarding lane.

## UI guardrails

- preserve existing onboarding screen designs by default;
- preserve existing Height / Current Weight / Target Weight / DOB wheel/picker contracts;
- preserve existing Goal card visual language;
- no persistence/ownership slice authorizes a visual redesign;
- new visual contracts require separate explicit product approval;
- use `tio_core` reusable components/tokens before creating local equivalents.

## Handoff

**Current Product Onboarding next slice:** O1D authenticated App Preferences bootstrap/restore (#11).  
**Current parallel account slice:** A1 contact verification (#8), not blocking O1.  
**After O1F validation:** O2 common Profile owner + section activation.  
**Do not start O2 before O1 validation evidence is recorded.**
