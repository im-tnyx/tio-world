# Product Onboarding Structure, Ownership, Health Connections, and Finalization

**Status:** Needs decision
**Primary owner:** `apps/features/onboarding` for flow/orchestration; canonical data remains owned by Profile / Body-Wellness / Nutrition / Workout / integration boundaries
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Planning base:** `main` at `833fc625ea75a2b8f29f6338764ce977680bb897`

## Global UI / Design-System Guardrail

For any later Flutter UI work, read `.ai/tasks/design-system-token-consolidation.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` first. Reuse `package:tio_core/core.dart` components before rebuilding equivalents.

This task authorizes **planning/audit only**. No production UI, schema, migration, health integration, persistence mutation, PR merge, or runtime behavior change is authorized by this document.

---

## 1. Discovery

### User Outcome

Product Onboarding should have clean owner boundaries, mode-aware skips, optional health connection, truthful finalization, and reuse the existing celebration screen.

```text
Review
→ Plan Building 0…100
→ existing CongratulationsScreen
→ Let's go!
→ App
```

Mode direction:

```text
Workout
→ Common Profile / Body
→ Workout Profile
→ Workout Targets
→ Health Connections optional
→ Review
→ Plan Building
→ Congratulations
→ App

Nutrition
→ Common Profile / Body
→ Nutrition Profile
→ Nutrition Targets
→ Health Connections optional
→ Review
→ Plan Building
→ Congratulations
→ App

Hybrid
→ Common Profile / Body
→ Nutrition branch
→ Workout Intro
   ├─ Set up now
   │   → Workout Profile
   │   → Workout Targets
   └─ Later
       → skip Workout Profile
       → skip Workout Targets
→ remaining eligible sections
→ Health Connections optional
→ Review
→ Plan Building
→ Congratulations
→ App
```

### Success Criteria

- Body Goal is common and not duplicated as Nutrition Goal.
- Workout Goal is training-specific.
- Nutrition Targets are numeric/recommended/custom targets.
- Hybrid keeps Workout Intro.
- Hybrid `Later` skips **both** Workout Profile and Workout Targets for the current onboarding run.
- `Later` does not delete previously saved Workout owner data; later Settings edits/completes the same canonical owners.
- Workout Profile separates Training Location, environment setup/facility type, and explicit Available Equipment.
- **Home and Gym both have setup/facility classifications where useful.**
- **Available Equipment is collected for both Home and Gym active setup paths.**
- Setup/facility type may seed suggestions/defaults only; explicit Available Equipment remains authoritative.
- **Reuse the existing `EquipmentScreen` for the Home path where practical.**
- **Prefer evolving the same reusable Equipment screen/component for Gym context instead of creating duplicate Home/Gym equipment screens.**
- Context-specific title/copy/suggestions may differ while canonical equipment selection stays shared.
- Separate `HomeEquipmentScreen` / `GymEquipmentScreen` should exist only if a focused later UI audit proves materially different interaction needs.
- Health connection remains optional and separately owned.
- Plan Building reaches `100%` only after required finalization succeeds.
- Existing `apps/features/onboarding/lib/src/presentation/screens/congratulations_screen.dart` is reused as-is.
- Existing drafts/resume remain migration-safe.
- Every slice follows audit → finding → ownership review → explicit approval → implementation later.

### Non-Goals

- Workout tab, Routine, Program, Exercise Library, Active Workout implementation.
- Nutrition tab, Meal Diary, Diet Plan, Food Library implementation.
- Final equipment catalog/taxonomy in this update.
- Workout Runtime Settings (#48).
- App Mode durability (#11).
- Supabase schema changes before #44 approval.
- Health plugin/API choice before integration audit.
- Creating or redesigning Congratulations.
- Fake generated Workout Program/Diet Plan just to animate Plan Building.

---

## 2. Verified Current State

- `main` planning base: `833fc625ea75a2b8f29f6338764ce977680bb897`.
- #40 = Product Onboarding structure tracker.
- #44 = canonical owner tracker.
- #45/#46/#47 = Settings editing for Body-Wellness/Nutrition/Workout owners.
- #48 = separate Workout Runtime Settings.
- Current outer IDs are coarse (`profile`, `workout`, `nutrition`, `targets`, `review` style buckets).
- Current Workout flow uses one broad Workout Preferences section.
- Current Hybrid already has Workout Intro with `setupNow` / `later`.
- Current generic Profile Goal mixes body/workout/wellness intents.
- Current shared Targets mixes Wellness, Body Goal, common Profile mirrors and Nutrition recommendation values.
- Current `WorkoutPreferencesData` mixes Workout Profile and Workout Targets.
- Current `WorkoutGymAccess` has only `gym` and `home`.
- Current Equipment flow appears only for Home.
- Current Equipment validator requires selection only for Home.
- Current `WorkoutEquipment` has only six items: Dumbbells, Bench, Mat, Barbell, Bands, Kettlebell.
- Current Equipment screen copy is explicitly Home-only.
- Existing Home equipment implementation is `apps/features/onboarding/lib/src/presentation/screens/workout/equipment_screen.dart`.
- This is insufficient because both Home and Gym environments may have limited or extensive equipment, but the existing screen is a reusable-first starting point rather than something to replace automatically.
- Existing `CongratulationsScreen` already exists and current routing uses it after onboarding completion.

---

## 3. Product Decisions / Open Decisions

| Decision | Status |
|---|---|
| Common Body Goal separate from Nutrition Goal | Proposed / review |
| Workout Goal separate and training-specific | Proposed / review |
| Nutrition Targets numeric/recommended/custom | Proposed / review |
| Wellness placement | Needs decision |
| Hybrid keeps Workout Intro | Approved product direction |
| Hybrid `Later` skips Workout Profile + Workout Targets | Approved product direction |
| `Later` preserves saved Workout owner data | Approved guardrail |
| Training Location separate from setup/facility type | Approved planning direction |
| Home has Home Setup Type | Approved planning direction |
| Gym has Gym/Facility Type | Approved planning direction |
| Available Equipment shown for Home + Gym | Approved product direction |
| Setup/facility type only seeds suggestions | Approved product direction |
| Explicit Available Equipment is authoritative | Approved product direction |
| Existing `EquipmentScreen` reused for Home where practical | Approved reusable-first direction |
| Same reusable Equipment screen/component preferred for Gym context | Approved reusable-first direction |
| Separate Home/Gym equipment screens by default | Rejected unless focused audit proves different UX needs |
| `Both` Training Location option | Needs decision |
| Exact Home Setup labels | Needs focused audit |
| Exact Gym/Facility labels | Needs focused audit |
| Exact equipment taxonomy/categories | Needs focused audit |
| Health Connections optional | Proposed / review |
| Health placement before Review | Needs decision |
| Samsung Health vs Health Connect semantics | Needs technical audit |
| Plan Building after Review | Proposed / review |
| Existing Congratulations after successful Plan Building | Approved product direction |

---

## 4. Proposed Product Flow

```text
Account Setup completed
        ↓
User Profile                     common
        ↓
Body Goal                        common
        ↓
Wellness Goals                   placement open
        ↓
Nutrition Profile                Nutrition/Hybrid
        ↓
Workout Intro                    Hybrid only
        ├─ Set up now
        │    ↓
        │  Workout Profile
        │    ↓
        │  Workout Targets
        └─ Later
             ↓
           skip both Workout sections
        ↓
Nutrition Targets                Nutrition/Hybrid
        ↓
Health Connections               optional; placement open
        ↓
Review
        ↓
Plan Building 0 → 100
        ↓
existing CongratulationsScreen
        ↓
App
```

Workout-only can enter active Workout Profile directly unless a later product decision adds its own deferral step.

### Workout Profile — revised environment flow

```text
Training Location / Environment
├─ Home
├─ Gym
└─ Both                         decision candidate
```

If Home applies:

```text
Home Setup Type                 candidate labels, not final
├─ Bodyweight / No Equipment
├─ Basic Home Setup
├─ Dedicated Home Gym
└─ Not sure / choose equipment explicitly
```

If Gym applies:

```text
Gym / Facility Type             candidate labels, not final
├─ Apartment / Hotel Gym
├─ Small / Limited Gym
├─ Standard Commercial Gym
├─ Large / Full Gym
└─ Not sure / choose equipment explicitly
```

Then for either active environment:

```text
Available Equipment
→ Experience Level
→ Focus Areas
→ Injuries / Physical Limitations
```

### Environment / Equipment Rules

- `Training Location` answers where the user trains.
- `Home Setup Type` / `Gym Facility Type` describes the expected environment class.
- `Available Equipment` is the actual capability truth.
- Reuse the existing `equipment_screen.dart` Home experience where practical rather than rebuilding it.
- Prefer making that existing screen/component context-aware for Gym: title, description, suggestions/defaults and category visibility may vary by environment.
- Do not create incompatible HomeEquipment and GymEquipment identities for the same physical item.
- Do not create separate Home/Gym equipment screens merely because copy or recommendations differ.
- A separate screen is justified only if a focused Slice 5 UI audit proves the interaction itself must materially diverge.
- Home/Gym type may filter, recommend, or preselect likely items for convenience.
- A Dedicated Home Gym can have broad equipment.
- A Large/Full Gym can still miss specific machines.
- A Small/Limited Gym can still include any explicitly selected item.
- Location/setup changes must not silently delete existing selections.
- Future exercise/routine/program eligibility must ultimately consume explicit available-equipment capability, not facility labels alone.

### Conceptual Section IDs for Slice 1 Audit

```text
userProfile
bodyGoal
wellnessGoals
nutritionProfile
workoutIntro
workoutProfile
nutritionGoals
workoutTargets
healthConnections
review
planBuilding
```

Do not mechanically rename persisted IDs; migration/resume compatibility must be defined first.

---

## 5. Sliced Audit and Implementation Plan

**Global rule:** Audit first → finding → ownership review → explicit approval → implementation later.

### Slice 0 — Baseline and Characterization Audit

- [x] Verify current `main` and planning artifacts.
- [x] Inventory current Workout/Nutrition/Hybrid outer flows.
- [x] Confirm current Hybrid Workout Intro and `Later` behavior.
- [x] Confirm current Gym/Home model.
- [x] Confirm Equipment is currently Home-only.
- [x] Confirm persisted enum-name/resume compatibility is a major migration risk.
- [x] Confirm Review currently directly finalizes and routes to existing Congratulations.
- [x] Produce baseline report; no production mutation.

**Review gate:** baseline reviewed before Slice 1 code.

### Slice 1 — Section and Step Identity Contract

Goal: migration-safe future section identity with visible flow unchanged.

- [ ] Decide stable section IDs.
- [ ] Preserve Hybrid Workout Intro as a branch identity/decision where required.
- [ ] Ensure `Later` can make Workout Profile + Workout Targets ineligible without deleting owner data.
- [ ] Define old-ID → new-ID resume reconciliation.
- [ ] Remove direct dependence on enum `.name` only when a migration-safe codec/alias contract is approved.
- [ ] Define progress semantics across conditional sections.
- [ ] Decide stale App Mode/Mobile identity compatibility.
- [ ] Keep existing Congratulations external unless a real migration need proves otherwise.

**Expected visible behavior:** unchanged.

**Review gate:** approve identity map before code.

### Slice 2 — User Profile + Body Goal

```text
User Profile
Name
Gender
DOB / Age
Measurement Units
Height
Current Weight
Activity Level
General Health Conditions

Body Goal
Body Goal
Goal Weight       conditional
Weekly Goal       conditional
```

- [ ] Audit current Profile fields against #44.
- [ ] Decide Body Recomposition behavior.
- [ ] Move generic Goal/Target Weight conceptually out of Profile.
- [ ] Reuse existing screens/components where valid.

### Slice 3 — Wellness Goals Placement

```text
Daily Steps
Water Goal
Sleep Goal
Bedtime / Wake Time     optional future
```

- [ ] Decide mandatory vs optional vs Settings-only.
- [ ] Confirm common ownership.
- [ ] Define defaults/Skip behavior.

### Slice 4 — Nutrition Profile + Nutrition Targets

```text
Nutrition Profile
Diet Type
Allergies / Restrictions
Diet Style / Preference

Nutrition Targets
Calories
Protein
Carbs
Fat
Fiber

Use Recommended
or
Customize
```

- [ ] Audit #46/current Nutrition models/repos.
- [ ] Keep BMR/TDEE calculated context only.
- [ ] Define recommended-vs-custom provenance.
- [ ] Define mode conditional order.

### Slice 5 — Workout Intro + Workout Profile + Workout Targets

Hybrid branch:

```text
Workout Intro
├─ Set up now
│  → Workout Profile
│  → Workout Targets
└─ Later
   → skip Workout Profile
   → skip Workout Targets
```

Workout Profile:

```text
Training Location
→ Home Setup Type OR Gym/Facility Type
→ Available Equipment
→ Experience
→ Focus Areas
→ Injuries / Limitations
```

Workout Targets:

```text
Workout Goal
Training Days
Workout Duration
Workout Split / Preference
Special Event              optional
```

Audit/decisions:

- [ ] Audit `WorkoutPreferencesData`, `WorkoutGymAccess`, `WorkoutEquipment`, draft, mapper, repository against #44/#47.
- [ ] Lock `Later` skip semantics for both Workout sections.
- [ ] Verify saved Workout data preservation.
- [ ] Decide Training Location options (`Home`, `Gym`, possible `Both`).
- [ ] Finalize Home Setup Type labels.
- [ ] Finalize Gym/Facility Type labels.
- [ ] **Reuse the existing `apps/features/onboarding/lib/src/presentation/screens/workout/equipment_screen.dart` for Home where practical.**
- [ ] **Prefer evolving the same reusable Equipment screen/component for Gym context.**
- [ ] Support context-specific Home/Gym title, description, suggested/default selections and category visibility without duplicating canonical equipment state.
- [ ] Do not introduce separate `HomeEquipmentScreen` / `GymEquipmentScreen` unless a focused UI audit demonstrates materially different interaction requirements.
- [ ] Expand Equipment beyond current six-item Home-only model.
- [ ] Audit the provided categorized equipment reference (Weights/Bars, Benches/Racks, Machines, Cardio, Other) without copying blindly.
- [ ] Keep one canonical equipment vocabulary across Home/Gym.
- [ ] Define suggested/default selections separately for Bodyweight Home, Basic Home, Dedicated Home Gym, Apartment/Hotel Gym, Small Gym, Standard Gym, Large Gym.
- [ ] Ensure explicit Available Equipment is authoritative.
- [ ] Define behavior when location/setup changes after selections exist; no silent destructive reset.
- [ ] Decide Workout Goal, Split and Special Event behavior.
- [ ] Keep #48 runtime settings outside this slice.

**Review gate:** approve complete Workout branch and reusable Equipment-screen approach before implementation.

### Slice 6 — Health Connections

```text
Connect your health data
[ Connect Health Data ]
→ bottom sheet
   ├─ Samsung Health
   └─ Health Connect
[ Not now / Skip ]
```

- [ ] Audit provider semantics/platform support.
- [ ] Define integration owner/permissions/sync/revoke/privacy.
- [ ] Decide placement before Review vs later.
- [ ] Keep optional unless explicitly changed.

### Slice 7 — Review Restructure

```text
Profile
Body Goal
Wellness Goals          if collected
Nutrition Profile       if eligible
Nutrition Targets       if eligible
Workout Profile         if configured
Workout Targets         if configured
Health Connection       connected / not connected
```

- [ ] Owner-specific edit-back destinations.
- [ ] Preserve furthest valid checkpoint.
- [ ] Hybrid `Later` must not present Workout data as configured.
- [ ] Decide whether to show `Workout setup later` or simply omit.

### Slice 8 — Plan Building 0→100 + Existing Congratulations

```text
Review
→ Building your plan
→ 0 → 100%
→ existing CongratulationsScreen
→ Let's go!
→ App
```

- [ ] Map progress to real finalization checkpoints.
- [ ] No fake success at `100%`.
- [ ] Define retry/idempotency/back behavior.
- [ ] Failed finalization never exposes Congratulations.
- [ ] Existing Congratulations UI/assets/copy/animation remain unchanged.

### Slice 9 — Draft/Resume + Owner Persistence Reconciliation

- [ ] Map every field to one canonical owner.
- [ ] Define persisted-ID migration.
- [ ] Preserve Hybrid `Later` eligibility and inactive Workout data.
- [ ] Define environment/setup/equipment migration without destructive assumptions.
- [ ] Define owner-write ordering/partial failure recovery.
- [ ] Reconcile mirrored data only through approved #44/#8 plan.

### Slice 10 — Tests / Device Acceptance / Cleanup

- [ ] Exact Workout/Nutrition/Hybrid flow-order tests.
- [ ] Hybrid `Set up now` includes Workout Profile + Targets.
- [ ] Hybrid `Later` skips both and preserves saved data.
- [ ] Home/Gym setup type eligibility tests.
- [ ] Available Equipment always available for active Home/Gym setup.
- [ ] Existing Home `EquipmentScreen` behavior remains regression-protected while it is evolved.
- [ ] Home/Gym contexts share canonical selection state and do not duplicate owner models.
- [ ] Setup/facility suggestions never override explicit availability without user action.
- [ ] Draft/resume migration tests.
- [ ] Review/back/edit tests.
- [ ] Plan Building success/failure/retry/idempotency tests.
- [ ] Existing Congratulations handoff tests.
- [ ] #13 regression coverage.
- [ ] Focused analyze/tests, required CI, and real-device acceptance.

---

## 6. Current Planning Locks

```text
LOCK-WORKOUT-BRANCH
Hybrid Workout Intro = Later
→ skip Workout Profile
→ skip Workout Targets
→ preserve saved Workout data
```

```text
LOCK-ENVIRONMENT-DIRECTION
Training Location
→ Home Setup Type or Gym/Facility Type
→ explicit Available Equipment
```

```text
LOCK-EQUIPMENT-TRUTH
Setup/facility type = recommendation/default context
Available Equipment = authoritative capability
```

```text
LOCK-EQUIPMENT-REUSE
Home = reuse existing EquipmentScreen where practical
Gym = prefer same reusable screen/component with context-specific copy/suggestions
Separate Home/Gym equipment screens = only if focused UI audit proves necessary
Canonical equipment selection = shared
```

```text
LOCK-FINAL-HANDOFF
Review
→ truthful Plan Building
→ existing CongratulationsScreen
→ App
```

Exact Home/Gym labels and exact equipment catalog remain Slice 5 audit decisions.

---

## 7. Final Handoff

### Changed Planning Artifact

- `.ai/tasks/product-onboarding-structure-and-finalization.md`
- GitHub issue #40 is maintained with the same product-flow direction.

### Actual Runtime Behavior

No runtime behavior changed.

### Known Open Decisions

- #44 canonical owner decisions.
- Wellness placement.
- `Both` Training Location option.
- final Home Setup Type labels.
- final Gym/Facility Type labels.
- exact canonical equipment taxonomy/defaults.
- handling when setup type changes after equipment selection.
- Nutrition target provenance.
- Health provider semantics/placement.
- Plan Building real checkpoint mapping.
- exact Hybrid ordering around Nutrition vs Workout branches.
- existing Congratulations route vs persisted flow identity.

### Final Status

`REVIEW`