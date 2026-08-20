# Product Onboarding Structure, Ownership, Health Connections, and Finalization

**Status:** Needs decision
**Primary owner:** `apps/features/onboarding` for flow/orchestration; canonical data remains owned by Profile / Body-Wellness / Nutrition / Workout / integration boundaries
**Affected platforms:** Flutter phone app
**GitHub tracker:** #40
**Planning base:** `main` at `833fc625ea75a2b8f29f6338764ce977680bb897`

## Global UI / Design-System Guardrail

For any later Flutter UI work, read `.ai/tasks/design-system-token-consolidation.md`, `apps/features/AGENTS.md`, and `apps/core/lib/src/theme/README.md` before changing visual implementation. Inspect the existing reusable core UI/component surface and prefer the public `package:tio_core/core.dart` boundary before rebuilding an equivalent pattern locally.

This task currently authorizes **planning/audit only**. It does not authorize production UI, schema, migration, health integration, or persistence mutations.

---

## 1. Discovery

### User Outcome

A new user should complete one clear Product Onboarding flow where every screen appears for a reason, goals are not duplicated across domains, optional health connections are consent-first, Review reflects the actual selected setup, Review is followed by a truthful `0 → 100%` Plan Building/finalization screen, and successful finalization then reuses the **existing** `CongratulationsScreen` before the user enters the app.

Final handoff:

```text
Review
→ Plan Building 0…100
→ existing CongratulationsScreen
→ Let's go!
→ App
```

Mode-aware product direction:

```text
Workout
→ common Profile / Body
→ Workout Profile
→ Workout Targets
→ optional Health Connections
→ Review
→ Plan Building
→ existing CongratulationsScreen
→ App

Nutrition
→ common Profile / Body
→ Nutrition Profile
→ Nutrition Targets
→ optional Health Connections
→ Review
→ Plan Building
→ existing CongratulationsScreen
→ App

Hybrid
→ common Profile / Body
→ Nutrition branch
→ Workout Intro
   ├─ Set up now
   │   → Workout Profile
   │   → Workout Targets
   └─ Later
       → skip Workout Profile
       → skip Workout Targets
→ remaining eligible sections
→ optional Health Connections
→ Review
→ Plan Building
→ existing CongratulationsScreen
→ App
```

Common Wellness screens (Steps / Water / Sleep) remain a review decision: mandatory onboarding, optional onboarding, or Settings-only.

### Success Criteria

- Product Onboarding has explicit boundaries for common Profile, Body Goal, optional/common Wellness, Nutrition Profile, Nutrition Goals, Workout Profile, Workout Targets, Health Connections, Review, and Plan Building where approved.
- `Lose/Gain/Maintain/Recomposition` is asked once as common Body Goal, not repeated as a Nutrition Goal.
- Workout Goal remains training-specific.
- Nutrition Targets remain numeric/recommendation-specific.
- Hybrid retains Workout Intro.
- Hybrid `Workout Intro → Later` skips **both** Workout Profile and Workout Targets for the current onboarding run.
- `Later` never deletes previously saved Workout Profile/Target data; Settings can complete/edit the same canonical Workout owners later.
- Workout Profile distinguishes Training Location, conditional Gym/Facility Type, and explicit Available Equipment.
- Available Equipment works for both Home and Gym paths; gym type may seed suggestions but must not imply complete equipment availability.
- Settings #45/#46/#47 later edit the same canonical owners used by onboarding.
- Health connection is optional and does not make Onboarding the owner of permissions, provider state, health records, sync, retention, or revocation.
- Review is followed by a real finalization state with a visible `0 → 100%` ring; `100%` cannot be shown before required finalization succeeds.
- Successful finalization reuses `apps/features/onboarding/lib/src/presentation/screens/congratulations_screen.dart`.
- Failed/incomplete finalization never shows Congratulations.
- No duplicate or redesigned Congratulations screen is introduced by this task.
- Existing #13 App Mode/Auth/Account Setup behavior remains regression-protected.
- Existing drafts/resume checkpoints are migrated/reconciled safely when step/section identity changes.
- No implementation slice starts before its audit findings and ownership decisions are reviewed and explicitly approved.

### Scope

- Product Onboarding screen order and mode matrices.
- Section/step identity refactor planning.
- Canonical ownership mapping against #44 and Settings trackers.
- Body Goal vs Nutrition Targets vs Workout Targets separation.
- Hybrid Workout Intro branching and skip semantics.
- Workout Profile facility/equipment planning for Home and Gym users.
- Health Connections onboarding UX and integration-boundary audit.
- Review grouping and safe edit-back/resume behavior.
- Plan Building/finalization progress and failure contract.
- Handoff from Plan Building to the existing Congratulations screen.
- Draft/resume compatibility planning.
- Sliced implementation plan and validation gates.

### Non-Goals

- Workout tab, Routine, Program, Exercise Library or Active Workout implementation.
- Nutrition tab, Meal Diary, Diet Plan or Food Library implementation.
- Final expanded 30–40 item equipment taxonomy in this update; exact equipment catalog belongs to the Workout Profile slice audit.
- Workout Runtime Settings (#48).
- App Mode durability (#11).
- Supabase schema changes before #44 ownership approval.
- Choosing or adding a health plugin/API before provider/integration audit.
- Inventing a generated Workout Program or Diet Plan merely to animate the final Plan Building screen.
- Creating a second Congratulations screen.
- Redesigning the existing Congratulations screen.
- Calculation formula changes.
- Visual redesign outside separately approved screen designs.

---

## 2. Codebase Exploration

### Verified Evidence

- `main` verified at `833fc625ea75a2b8f29f6338764ce977680bb897` before this planning branch.
- #40 is the Product Onboarding structure tracker.
- #44 is the canonical owner tracker.
- #45 owns post-onboarding Body/Weight/Wellness Settings planning.
- #46 owns post-onboarding Nutrition Profile/Goals Settings planning.
- #47 owns post-onboarding Workout Profile/Targets Settings planning.
- #48 is separate Workout Runtime Settings.
- Current `OnboardingSectionId` is coarse: `appMode`, `profile`, `mobile`, `workoutIntro`, `workout`, `nutritionIntro`, `nutrition`, `targets`, `review`.
- Current `OnboardingStepId` is similarly coarse: `mode`, `profileBasics`, `mobile`, `workoutIntro`, `workoutPreferences`, `nutritionIntro`, `nutritionPreferences`, `targets`, `review`.
- Current Workout mode flow is `Profile → Workout Preferences → Targets → Review`.
- Current Nutrition mode flow is `Profile → Targets → Review`.
- Current Hybrid flow already contains `Workout Intro`; `Later` currently removes the broad Workout Preferences step.
- Current generic `ProfileGoal` mixes body, workout and broader-wellness intents.
- Current Nutrition `TargetsSetupData` mixes Wellness, Body Goal, common Profile mirrors and Nutrition recommendation values.
- Current `WorkoutPreferencesData` mixes Workout Profile and Workout Target/schedule fields.
- Current `WorkoutGymAccess` only contains `gym` and `home`.
- Current `BuildWorkoutFlowPlanUseCase` shows Equipment only when `gymAccess == home`.
- Current `WorkoutStepValidator` requires Equipment only for Home.
- Current `WorkoutEquipment` has only six items: Dumbbells, Bench, Mat, Barbell, Bands, Kettlebell.
- Current Equipment screen copy is explicitly Home-only.
- Therefore current Gym path assumes standard equipment too strongly for future planning; gym users can also have limited equipment.
- No existing dedicated Health Connect/Samsung Health integration owner/tracker was found during this planning audit.
- Existing celebration screen is already implemented at `apps/features/onboarding/lib/src/presentation/screens/congratulations_screen.dart`.
- Current app routing already uses the Congratulations route after successful onboarding completion.

### Existing Pattern to Follow

- One `/onboarding` parent route and stable step identity.
- `OnboardingController` owns navigation/orchestration; child screens render state and emit typed actions.
- Feature/domain owners retain calculations, validation and durable data.
- `package:tio_core/core.dart` reusable-first UI boundary.
- Draft/resume uses stable IDs and migration/reconciliation rather than screen index.
- Existing Congratulations screen remains the celebration/handoff surface unless a separately approved product decision changes it.
- Workout environment metadata can guide defaults, but explicit equipment selection must remain the capability truth used by future exercise/routine/program eligibility.

---

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Common Body Goal separate from Nutrition Goal | Proposed / review | Avoid duplicate goal semantics | Product + #44 |
| `Lose/Gain/Maintain/Recomposition` asked only once | Proposed / review | One canonical Body Goal | Product + #44 |
| Workout Goal separate and training-specific | Proposed / review | Training objective is not Body Goal | Workout + #47 |
| Nutrition Targets numeric/recommended/custom | Proposed / review | Calories/macros are not body-goal identity | Nutrition + #46 |
| Steps/Water/Sleep common Wellness | Proposed / review | Must not be Nutrition-owned by storage accident | #44/#45 |
| Wellness screens mandatory vs optional vs Settings-only | Needs decision | Avoid unnecessary first-run length | Product |
| Hybrid keeps Workout Intro | Approved product direction | User can defer Workout setup | Product + Onboarding |
| Hybrid `Later` skips Workout Profile + Workout Targets | Approved product direction | Deferring Workout must skip the full Workout branch | Product + Onboarding |
| Hybrid `Later` preserves saved Workout owner data | Approved guardrail | Hide/skip must not delete owner data | Workout + Onboarding |
| Training Location separate from Gym/Facility Type | Proposed / review | Location and facility capability are different concepts | Workout + #47 |
| Equipment appears for Home and Gym | Approved product direction | Both environments may have limited equipment | Workout + #47 |
| Gym type can seed suggestions, not canonical availability | Approved product direction | Avoid false equipment assumptions | Workout + #47 |
| `Both` as Training Location option | Needs decision | Useful but not yet locked | Product + Workout |
| Exact Gym/Facility labels | Needs decision | Small/Large/Not sure are current planning candidates | Product + Workout |
| Exact expanded equipment taxonomy | Needs focused audit | Screenshot/reference list is not yet canonical | Workout + #47 |
| Health Connections optional | Proposed / review | Connection should not block basic setup | Product + integration owner |
| Health Connections before Review | Needs decision | Placement depends on finalization usefulness | Product |
| Provider choices Samsung Health + Health Connect | Needs technical audit | UI must match real provider semantics | Integration owner |
| Plan Building follows Review | Proposed / review | Intended finalization UX | Product + Onboarding |
| Progress `100%` only after finalization succeeds | Proposed / review | Prevent false success | Onboarding + owners |
| Existing Congratulations follows successful Plan Building | Approved product direction | Existing screen must be reused | Product + Onboarding |
| No new/redesigned Congratulations screen | Approved guardrail | Preserve validated surface | Product + Onboarding |
| New section/step IDs | Needs decision | Must preserve draft compatibility | Onboarding |

---

## 4. Architecture Design

### Chosen Direction for Review

```text
Account Setup completed
        ↓
Product Onboarding
        ↓
User Profile                     common
        ↓
Body Goal                        common
        ↓
Wellness Goals                   common; placement/requiredness open
        ↓
Nutrition Profile                Nutrition/Hybrid
        ↓
Workout Intro                    Hybrid only
        ├─ Set up now
        │    ↓
        │  Workout Profile        Workout/Hybrid active branch
        │    ↓
        │  Workout Targets
        └─ Later
             ↓
           skip Workout Profile + Workout Targets
        ↓
Nutrition Goals / Targets        Nutrition/Hybrid
        ↓
Health Connections               common optional; placement open
        ↓
Review
        ↓
Plan Building / Finalization
        0 → 100
        ↓
existing CongratulationsScreen
        ↓ Let's go!
App
```

Workout-only does not need Hybrid's deferral intro unless separately approved; it can enter active Workout Profile directly.

Exact Hybrid ordering between Nutrition and Workout sections remains a product-flow decision, but `Workout Intro → Later` must exclude both Workout Profile and Workout Targets.

### Workout Profile Capability Direction

```text
Training Location / Environment
├─ Home
├─ Gym
└─ Both                         decision candidate
        ↓
Gym / Facility Type            conditional when Gym applies
├─ Small / Limited Gym
├─ Large / Full Gym
└─ Not sure
        ↓
Available Equipment            Home + Gym
        ↓
Experience Level
        ↓
Focus Areas
        ↓
Injuries / Physical Limitations
```

Rules:

- Location, facility type, and equipment are separate concepts.
- One canonical equipment vocabulary should be reused across Home/Gym contexts.
- Facility type may filter, recommend, or preselect equipment for convenience.
- Explicit Available Equipment is authoritative.
- `Large Gym` does not imply all equipment.
- A location/facility change must not silently erase previously selected/saved equipment; exact reconciliation behavior is audited in Slice 5/9.

### Proposed Section Identity

Conceptual names only until Slice 1 approves migration-safe identifiers:

```text
userProfile
bodyGoal
wellnessGoals
nutritionProfile
workoutIntro              existing concept retained for Hybrid branching
workoutProfile
nutritionGoals
workoutTargets
healthConnections
review
planBuilding
```

The existing Congratulations route/screen does not automatically need a persisted `OnboardingStepId`.

### Ownership and Data Flow

```text
Onboarding child UI
        ↓ typed action
Onboarding Controller / Flow Planner
        ↓
Onboarding Draft / Review orchestration
        ↓
canonical owner mapper/use case
        ↓
Profile / Body-Wellness / Nutrition / Workout repository
```

Workout setup branch:

```text
Workout Intro choice
        ↓ flow eligibility only
Set up now → Workout Profile + Workout Targets active
Later      → both inactive for this run
              saved owner data preserved
```

Health connection remains a separate integration boundary.

Finalization remains:

```text
Review confirmed
→ Plan Building starts
→ required owner persistence/finalization
→ success = 100%
→ existing CongratulationsScreen
→ Let's go!
→ App

failure
→ controlled retry
→ no false 100%
→ no Congratulations
```

### Alternatives Rejected

- Keep one generic Targets section permanently.
- Put Body Goal inside Nutrition only.
- Put Workout Goal into generic Profile Goal.
- Treat Settings as a separate target owner.
- Treat Hybrid `Later` as skipping only Gym/Equipment while still forcing Workout Targets.
- Put `Later` inside Gym Access instead of keeping it as a Workout Intro branch decision.
- Assume every Gym has standard/full equipment and skip explicit equipment collection.
- Create separate incompatible HomeEquipment and GymEquipment identities for the same physical equipment.
- Put health-provider implementation inside onboarding screens.
- Fake Plan Building completion independent of real finalization.
- Create or redesign Congratulations in this task.

---

## 5. Sliced Audit and Implementation Plan

**Global rule:** Audit first → record findings → ownership review → explicit approval → implementation later.

### Slice 0 — Baseline and Characterization Audit

Goal: measure the current flow before restructuring.

- [ ] Fresh-fetch current main and active issue/task state.
- [ ] Inventory `OnboardingSectionId`, `OnboardingStepId`, flow definitions, renderer dispatch, controller transitions and progress plan.
- [ ] Inventory exact Workout/Nutrition/Hybrid matrices, including Hybrid `Workout Intro → Later` behavior.
- [ ] Inventory current Workout Gym/Home and Home-only Equipment conditional behavior.
- [ ] Inventory draft schema, resume semantics and persisted IDs.
- [ ] Inventory Back, resume, mode, Review, completion and Congratulations tests.
- [ ] Characterize current completion → Congratulations → App behavior.
- [ ] Produce before-flow map; no production mutation.

**Review gate:** approve characterization before Slice 1.

### Slice 1 — Section and Step Identity Contract

Goal: create migration-safe identities without breaking current drafts.

- [ ] Decide final stable section identities.
- [ ] Preserve Hybrid Workout Intro as an explicit branch identity/decision where needed.
- [ ] Ensure `Later` can mark Workout Profile + Workout Targets ineligible without deleting owner data.
- [ ] Define old-ID → new-ID resume reconciliation.
- [ ] Preserve old drafts safely; do not rename persisted enum names blindly.
- [ ] Define progress semantics across mode/branch-conditional sections.
- [ ] Decide safe handling for stale App Mode/Mobile Product Onboarding IDs.
- [ ] Keep existing Congratulations external unless a real migration requirement proves otherwise.

**Review gate:** approve section tree + identity mapping before code.

### Slice 2 — User Profile + Body Goal

Proposed screens:

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
- [ ] Define migration from generic Profile Goal/Target Weight placement.
- [ ] Reuse existing screens/components where valid.

**Review gate:** approve common flow + ownership.

### Slice 3 — Wellness Goals Placement Decision

```text
Daily Steps
Water Goal
Sleep Goal
Bedtime / Wake Time     optional future
```

- [ ] Confirm common Wellness ownership.
- [ ] Choose mandatory vs optional vs Settings-only.
- [ ] Define Skip/default behavior.
- [ ] Remove Nutrition-only assumptions from current generic Targets classification.

**Review gate:** explicit product decision.

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

- [ ] Audit #46/current Nutrition contracts.
- [ ] Confirm BMR/TDEE calculated-context-only behavior.
- [ ] Define recommended-vs-custom provenance.
- [ ] Define mode-conditional ordering/skips.

**Review gate:** approve Nutrition flow.

### Slice 5 — Workout Intro + Workout Profile + Workout Targets

Goal: make Workout setup context-aware and let Hybrid safely defer the whole Workout branch.

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

Workout Profile direction:

```text
Training Location
→ Gym / Facility Type       conditional
→ Available Equipment       Home + Gym
→ Experience Level
→ Focus Areas
→ Injuries / Limitations
```

Workout Targets direction:

```text
Workout Goal
Training Days
Workout Duration
Workout Split / Preference
Special Event              optional
```

Audit/decisions:

- [ ] Audit current `WorkoutPreferencesData`, `WorkoutGymAccess`, `WorkoutEquipment`, draft, mapper and repository against #44/#47.
- [ ] Lock Hybrid `Later` skip behavior for both Profile and Targets.
- [ ] Confirm `Later` preserves existing saved Workout owner data.
- [ ] Decide Training Location final options (`Home`, `Gym`, possible `Both`).
- [ ] Decide Gym/Facility Type final options/labels.
- [ ] Expand Equipment beyond the current six-item Home-only model.
- [ ] Perform focused equipment taxonomy audit using the provided categorized reference (Weights/Bars, Benches/Racks, Machines, Cardio, Other) without copying it blindly.
- [ ] Keep one canonical equipment vocabulary across Home/Gym.
- [ ] Define Home vs Small Gym vs Large Gym suggested/default equipment behavior.
- [ ] Ensure explicit Available Equipment remains authoritative.
- [ ] Decide behavior when location/facility changes after selections exist; no silent destructive reset.
- [ ] Decide Workout Goal options.
- [ ] Decide Workout Split selected vs recommended behavior.
- [ ] Decide Special Event lifecycle.
- [ ] Keep #48 runtime settings outside this slice.

**Review gate:** approve complete Workout branch before implementation.

### Slice 6 — Health Connections Ownership and UX Audit

```text
Connect your health data

[ Connect Health Data ]
        ↓
Bottom sheet
├─ Samsung Health
└─ Health Connect

[ Not now / Skip ]
```

- [ ] Confirm provider semantics/platform support.
- [ ] Decide integration owner for availability, permissions, connection, sync and revoke.
- [ ] Define minimum requested data types and privacy/retention behavior.
- [ ] Define denial/retry/unavailable/revoke behavior.
- [ ] Decide placement before Review vs post-onboarding.
- [ ] Keep connection optional unless explicitly changed.

**Review gate:** approve integration boundary before plugin/UI work.

### Slice 7 — Review Restructure

Review should mirror canonical owners:

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

- [ ] Define owner-specific edit-back destinations.
- [ ] Preserve furthest valid checkpoint.
- [ ] Hybrid `Later` must not present Workout Profile/Targets as configured.
- [ ] Decide whether Review shows a truthful `Workout setup later` state or simply omits the branch.
- [ ] Hide ineligible data without deleting it.

**Review gate:** approve Review content/order.

### Slice 8 — Plan Building 0→100 + Existing Congratulations Handoff

```text
Review
→ Building your plan
→ 0 → 100% circular progress
→ existing CongratulationsScreen
→ Let's go!
→ App
```

- [ ] Inventory current completion/owner-write ordering.
- [ ] Map progress to real checkpoints.
- [ ] No fake successful `100%`.
- [ ] Define failure/retry/idempotency/back behavior.
- [ ] Reach `100%` only after required writes/completion marker succeed.
- [ ] Reuse existing Congratulations UI/assets/copy/animation.
- [ ] Failed finalization must never expose Congratulations.

**Review gate:** approve finalization truth contract.

### Slice 9 — Draft Schema, Resume, and Owner Persistence Reconciliation

- [ ] Map every approved field to one canonical owner from #44.
- [ ] Update onboarding draft for orchestration/edit state only.
- [ ] Define migration from existing persisted IDs.
- [ ] Preserve Hybrid `Later` branch eligibility and saved inactive Workout data.
- [ ] Define location/facility/equipment migration without destructive assumptions.
- [ ] Define owner-write ordering and partial-failure recovery.
- [ ] Reconcile mirrored Profile/Nutrition/Workout fields only through approved #44/#8 plan.
- [ ] Keep App Mode durability changes in #11.

**Review gate:** approve persistence/migration plan.

### Slice 10 — Mode Matrices, Validation, Device Acceptance, and Cleanup

- [ ] Exact Workout/Nutrition/Hybrid flow-order tests.
- [ ] Hybrid `Set up now` includes Workout Profile + Workout Targets.
- [ ] Hybrid `Later` skips both Workout sections.
- [ ] Hybrid `Later` does not delete saved Workout data.
- [ ] Home/Gym Equipment eligibility tests.
- [ ] Facility-type suggestion vs explicit-equipment-authority tests.
- [ ] Draft/resume migration tests.
- [ ] Back/edit/review/furthest-checkpoint tests.
- [ ] Health connection tests after integration approval.
- [ ] Plan Building success/failure/retry/idempotency tests.
- [ ] Failed finalization never shows Congratulations.
- [ ] Successful finalization reaches existing Congratulations and `Let's go!` enters App.
- [ ] #13 behavior remains green.
- [ ] Focused analyze/tests + full required CI.
- [ ] Real-device Workout, Nutrition and Hybrid acceptance.

---

## 6. Quality Review

### Current Structural Findings

```text
Current broad onboarding
Profile + Workout Preferences + shared Targets + Review

Desired direction
User Profile
Body Goal
Wellness (decision)
Nutrition Profile / Goals
Workout Intro (Hybrid branch)
Workout Profile / Targets when active
Health Connections
Review
Plan Building
existing CongratulationsScreen
App
```

Workout correction now recorded:

```text
Current
Gym/Home
Equipment only for Home

Future direction
Training Location
→ conditional Gym/Facility Type
→ explicit Available Equipment for Home + Gym
```

Hybrid correction now recorded:

```text
Workout Intro = Later
→ skip Workout Profile
→ skip Workout Targets
→ preserve any previously saved Workout owner data
```

Plan Building correction remains:

```text
Plan Building = NEW finalization surface
CongratulationsScreen = ALREADY EXISTS; REUSE AS-IS
```

The task intentionally does not lock physical folder trees yet. Folder changes follow approved owner boundaries and real implementation slices.

---

## 7. Final Handoff

### Changed Planning Artifact

- `.ai/tasks/product-onboarding-structure-and-finalization.md`
- GitHub issue #40 carries the same product-flow contract.

### Actual Runtime Behavior

No runtime behavior changed.

### Known Open Decisions

- #44 canonical owner decisions are not complete.
- Wellness first-run placement is undecided.
- Training Location `Both` option is not locked.
- Gym/Facility Type labels/default behavior are not locked.
- Exact equipment taxonomy/categories/default selections require focused Slice 5 audit.
- Nutrition target provenance is not locked.
- Health provider semantics/package ownership are undecided.
- Plan Building real progress mapping is undecided.
- Exact Hybrid ordering around Nutrition/Workout sections remains reviewable, while `Workout Intro → Later` skip semantics are now fixed as a product requirement.
- Existing Congratulations route vs flow identity remains an implementation audit item; the screen itself is not to be recreated or redesigned.

### Final Status

`REVIEW`
