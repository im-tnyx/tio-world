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

A new user should complete one clear Product Onboarding flow where every screen appears for a reason, goals are not duplicated across domains, optional health connections are consent-first, Review reflects the actual selected setup, and Review is followed by a truthful `0 → 100%` Plan Building/finalization screen before entering the app.

The flow must remain mode-aware:

```text
Workout
→ common Profile / Body
→ Workout Profile
→ Workout Targets
→ optional Health Connections
→ Review
→ Plan Building
→ App

Nutrition
→ common Profile / Body
→ Nutrition Profile
→ Nutrition Targets
→ optional Health Connections
→ Review
→ Plan Building
→ App

Hybrid
→ common Profile / Body
→ Nutrition + Workout owner sections
→ optional Health Connections
→ Review
→ Plan Building
→ App
```

Common Wellness screens (Steps / Water / Sleep) remain a review decision: mandatory onboarding, optional onboarding, or Settings-only.

### Success Criteria

- Product Onboarding has explicit section boundaries for common Profile, Body Goal, optional/common Wellness, Nutrition Profile, Nutrition Goals, Workout Profile, Workout Targets, Health Connections, Review, and Plan Building where approved.
- `Lose/Gain/Maintain/Recomposition` is asked once as common Body Goal, not repeated as a Nutrition Goal.
- Workout Goal remains training-specific.
- Nutrition Targets remain numeric/recommendation-specific.
- Settings #45/#46/#47 later edit the same canonical owners used by onboarding.
- Health connection is optional and does not make Onboarding the owner of permissions, provider state, health records, sync, retention, or revocation.
- Review is followed by a real finalization state with a visible `0 → 100%` ring; `100%` cannot be shown before required finalization succeeds.
- Existing #13 App Mode/Auth/Account Setup behavior remains regression-protected.
- Existing drafts/resume checkpoints are migrated/reconciled safely when step/section identity changes.
- No implementation slice starts before its audit findings and ownership decisions are reviewed and explicitly approved.

### Scope

- Product Onboarding screen order and mode matrices.
- Section/step identity refactor planning.
- Canonical ownership mapping against #44 and Settings trackers.
- Body Goal vs Nutrition Targets vs Workout Targets separation.
- Health Connections onboarding UX and integration-boundary audit.
- Review grouping and safe edit-back/resume behavior.
- Plan Building/finalization progress and failure contract.
- Draft/resume compatibility planning.
- Sliced implementation plan and validation gates.

### Non-Goals

- Workout tab, Routine, Program, Exercise Library or Active Workout implementation.
- Nutrition tab, Meal Diary, Diet Plan or Food Library implementation.
- Workout Runtime Settings (#48).
- App Mode durability (#11).
- Supabase schema changes before #44 ownership approval.
- Choosing or adding a health plugin/API before provider/integration audit.
- Inventing a generated Workout Program or Diet Plan merely to animate the final Plan Building screen.
- Calculation formula changes.
- Visual redesign outside separately approved screen designs.

---

## 2. Codebase Exploration

### Verified Evidence

- `main` verified at `833fc625ea75a2b8f29f6338764ce977680bb897` before this planning branch.
- GitHub issue #40 is the Product Onboarding structure tracker and has been updated with the expanded flow proposal.
- #44 is the canonical owner tracker.
- #45 owns post-onboarding Body/Weight/Wellness Settings planning.
- #46 owns post-onboarding Nutrition Profile/Goals Settings planning.
- #47 owns post-onboarding Workout Profile/Targets Settings planning.
- #48 is separate Workout Runtime Settings.
- Current `OnboardingSectionId` is coarse:

```text
appMode
profile
mobile
workoutIntro
workout
nutritionIntro
nutrition
targets
review
```

- Current `OnboardingStepId` is similarly coarse:

```text
mode
profileBasics
mobile
workoutIntro
workoutPreferences
nutritionIntro
nutritionPreferences
targets
review
```

- Completed #13 already moved active App Mode before signup and Mobile into Account Setup; stale/compatibility Product Onboarding identities must be audited instead of blindly reused.
- Current generic `ProfileGoal` mixes body, workout and broader-wellness intents.
- Current Nutrition `TargetsSetupData` mixes Wellness, Body Goal, common Profile mirrors and Nutrition recommendation values.
- Current `WorkoutPreferencesData` mixes Workout Profile and Workout Target/schedule fields.
- No existing dedicated Health Connect/Samsung Health integration owner/tracker was found during this planning audit.

### Existing Pattern to Follow

- One `/onboarding` parent route and stable step identity.
- `OnboardingController` owns navigation/orchestration; child screens render state and emit typed actions.
- Feature/domain owners retain calculations, validation and durable data.
- `package:tio_core/core.dart` reusable-first UI boundary.
- Draft/resume uses stable IDs and migration/reconciliation rather than screen index.

### Tests or Validation Already Present

Existing onboarding flow, draft/resume, owner persistence, Profile, Workout, Targets and Review tests provide a characterization baseline. Exact affected tests must be inventoried in Slice 0 before source changes.

---

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Common Body Goal separate from Nutrition Goal | Proposed / review | Avoid duplicate goal semantics across modes | Product + #44 |
| `Lose/Gain/Maintain/Recomposition` asked only once | Proposed / review | One canonical Body Goal | Product + #44 |
| Workout Goal separate and training-specific | Proposed / review | Workout target feeds training planning, not body-weight ownership | Workout + #47 |
| Nutrition Targets numeric/recommended/custom | Proposed / review | Calories/macros are not body-goal identity | Nutrition + #46 |
| Steps/Water/Sleep common Wellness | Proposed / review | Must not be Nutrition-owned by storage accident | #44/#45 |
| Wellness screens mandatory vs optional vs Settings-only | Needs decision | Keep onboarding useful without unnecessary length | Product |
| Health Connections is optional | Proposed / review | Connection should not block basic account setup | Product + integration owner |
| Health Connections placed before Review | Needs decision | Allows Review/finalization to know truthful connection status if relevant | Product |
| Provider choices show Samsung Health + Health Connect | Needs technical audit | UI labels must not imply incorrect independent APIs | Product + Android/integration owner |
| Plan Building follows Review | Proposed / review | Matches intended final user flow | Product + Onboarding |
| Progress `100%` only after required finalization succeeds | Proposed / review | Prevent false success | Onboarding + owner repositories |
| Exact operations driving Plan Building progress | Needs decision | Must reflect real finalization work | Architecture + owners |
| New section/step IDs | Needs decision | Required for correct ownership but must preserve draft compatibility | Onboarding |
| Stale App Mode/Mobile onboarding identities removal | Needs audit | #13 moved their active ownership elsewhere | Onboarding + Account Setup |

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
Workout Profile                  Workout/Hybrid
        ↓
Nutrition Goals / Targets        Nutrition/Hybrid
        ↓
Workout Goals / Targets          Workout/Hybrid
        ↓
Health Connections               common optional; placement open
        ↓
Review
        ↓
Plan Building / Finalization
        0 → 100
        ↓
App
```

Exact Hybrid ordering between Nutrition and Workout sections is a product-flow decision, not a data-ownership decision.

### Proposed Section Identity

Names are conceptual until Slice 1 approves migration-safe identifiers:

```text
userProfile
bodyGoal
wellnessGoals
nutritionProfile
workoutProfile
nutritionGoals
workoutTargets
healthConnections
review
planBuilding
```

Do not create empty presentation folders solely to mirror this list. Section identity is a domain/flow concept; physical folders should be created only when a real approved slice needs them.

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

Health connection is separate:

```text
Health Connections onboarding screen
        ↓ explicit user selection
Health integration contract / adapter
        ↓
provider availability / permission / connection state
```

Onboarding does not own imported health data.

Finalization:

```text
Review confirmed
        ↓
Plan Building screen starts
        ↓
required owner persistence/finalization
        ↓
mode-relevant setup/recommendation work that actually exists
        ↓
success -> 100% -> mark onboarding completed -> App
failure -> controlled retry state, no false completion
```

### Alternative Rejected

- Keep one generic `Targets` section permanently.
- Put Body Goal inside Nutrition only.
- Put Workout Goal into generic Profile Goal.
- Treat Settings as a separate owner of the same targets.
- Put Health Connect/Samsung provider code inside onboarding screens.
- Animate a fake 0→100 timer independent of actual finalization and route Home regardless of write failures.
- Add speculative folders/tables for every future capability before an approved slice needs them.

### Failure and Accessibility States

Later implementation must cover:

- optional provider unavailable / permission denied / connection failed / retry / Skip;
- Review edit-back without losing furthest valid resume checkpoint;
- Plan Building finalization failure and retry;
- duplicate Continue/Finish protection;
- offline/pending state where applicable;
- screen-reader progress semantics for the 0→100 ring;
- reduced-motion alternative that communicates progress without requiring ring animation;
- high contrast / large text / compact phone layouts through governed core components.

---

## 5. Sliced Audit and Implementation Plan

**Global rule for every slice:** Audit first. Record findings. Review ownership. Obtain explicit approval. Only then mutate production source/schema/UI for that slice.

### Slice 0 — Baseline and Characterization Audit

Goal: make current flow behavior measurable before restructuring.

- [ ] Fresh-fetch current main and active issue/task state.
- [ ] Inventory `OnboardingSectionId`, `OnboardingStepId`, step definitions, `BuildOnboardingFlowUseCase`, renderer dispatch, controller transitions and progress plan.
- [ ] Inventory existing mode matrices for Workout/Nutrition/Hybrid.
- [ ] Inventory draft schema, furthest-reached/resume semantics and persisted stable IDs.
- [ ] Inventory tests that characterize Back, resume, mode changes, Review and completion.
- [ ] Identify whether `appMode` / `mobile` section/step identities have any active Product Onboarding consumers after #13.
- [ ] Produce before-flow map; no production mutation.

**Review gate:** approve the characterization baseline before Slice 1.

### Slice 1 — Section and Step Identity Contract

Goal: replace the conceptual one-bucket Targets model without breaking resume compatibility.

- [ ] Decide final stable section identities.
- [ ] Decide whether one outer step may dispatch multiple owner-specific child steps or whether stable child IDs are needed.
- [ ] Define old-ID → new-ID resume reconciliation.
- [ ] Preserve old drafts safely; do not rewrite applied/persisted identity blindly.
- [ ] Decide safe retirement/compatibility handling for stale App Mode/Mobile Product Onboarding IDs.
- [ ] Define progress semantics across mode-conditional sections.

**Review gate:** user approves section tree and stable identity mapping before code.

### Slice 2 — User Profile + Body Goal

Goal: separate shared profile baseline from body-goal planning.

Proposed user screens:

```text
User Profile
1 Name
2 Gender
3 DOB / Age
4 Measurement Units
5 Height
6 Current Weight
7 Activity Level
8 General Health Conditions

Body Goal
9 Body Goal
10 Goal Weight       conditional
11 Weekly Goal       conditional
```

- [ ] Audit every current Profile field against #44.
- [ ] Decide Body Recomposition behavior.
- [ ] Decide whether current weight stays shared/profile input while durable ownership evolves toward Body Metrics.
- [ ] Define migration from current generic Profile Goal / Target Weight placement.
- [ ] Reuse existing screens/components where behavior remains valid.

**Review gate:** approve exact common flow and owner mapping before implementation.

### Slice 3 — Wellness Goals Placement Decision

Goal: decide whether onboarding should collect Steps/Water/Sleep at all.

Candidate:

```text
Daily Steps
Water Goal
Sleep Goal
Bedtime / Wake Time     optional future
```

- [ ] Confirm common Wellness ownership with #44/#45.
- [ ] Compare three product options: mandatory onboarding, optional `Set daily goals`, Settings-only/defaults.
- [ ] Decide Skip/default behavior.
- [ ] Remove Nutrition-only assumptions from current generic Targets classification.

**Review gate:** explicit product decision before any screen/order change.

### Slice 4 — Nutrition Profile + Nutrition Targets

Goal: create a clean Nutrition branch without repeating Body Goal.

Proposed Nutrition Profile:

```text
Diet Type
Allergies / Restrictions
Diet Style / Preference
```

Proposed Nutrition Target summary:

```text
Calories
Protein
Carbs
Fat
Fiber

Use Recommended
or
Customize
```

- [ ] Audit #46 owner model direction and current Nutrition draft/models/repositories.
- [ ] Confirm BMR/TDEE display-only calculated context.
- [ ] Define recommended-vs-custom provenance.
- [ ] Decide which custom target edits belong in onboarding vs later Settings.
- [ ] Define mode-conditional skip/order behavior.

**Review gate:** approve Nutrition flow before implementation.

### Slice 5 — Workout Profile + Workout Targets

Goal: separate training context from training objective/schedule.

Proposed Workout Profile:

```text
Training Environment
Equipment
Experience Level
Focus Areas
Injuries / Limitations
```

Proposed Workout Targets:

```text
Workout Goal
Training Days
Workout Duration
Workout Split / Preference
Special Event           optional
```

- [ ] Audit current `WorkoutPreferencesData` against #44/#47.
- [ ] Decide final Workout Goal options.
- [ ] Decide Special Event lifecycle/requiredness.
- [ ] Decide Workout Split user-selected vs recommended behavior.
- [ ] Keep #48 runtime settings entirely outside this slice.

**Review gate:** approve Workout Profile/Targets split before implementation.

### Slice 6 — Health Connections Ownership and UX Audit

Goal: add an optional onboarding connection surface without prematurely choosing the wrong integration architecture.

Proposed screen:

```text
Connect your health data

[ Connect Health Data ]
        ↓
Bottom sheet
├─ Samsung Health
└─ Health Connect

[ Not now / Skip ]
```

Audit before implementation:

- [ ] Confirm Android/platform support and actual provider semantics.
- [ ] Determine whether Samsung Health is a separate supported connector or routes through Health Connect for the approved data types/devices.
- [ ] Decide package/adapter ownership for provider availability, permission request, connection state, sync and revoke.
- [ ] Inventory health data types Tio actually needs before asking permissions; request minimum necessary access only.
- [ ] Define permission education, denial, retry, unavailable-device and revocation behavior.
- [ ] Define privacy/retention/storage ownership before importing any health records.
- [ ] Decide final placement: before Review vs post-onboarding if connection does not affect setup.
- [ ] Ensure connection remains optional unless a later explicit decision changes it.
- [ ] Reuse a governed bottom-sheet/action pattern from `tio_core` rather than building a local parallel component.

**Review gate:** approve ownership, provider semantics, requested data and placement before adding a plugin or UI.

### Slice 7 — Review Restructure

Goal: Review mirrors canonical owners rather than old section buckets.

Proposed grouping:

```text
Profile
Body Goal
Wellness Goals          if collected
Nutrition Profile       if eligible
Nutrition Targets       if eligible
Workout Profile         if eligible
Workout Targets         if eligible
Health Connection       connected / not connected
```

- [ ] Audit current Review model and edit actions.
- [ ] Define owner-specific edit-back destinations.
- [ ] Preserve furthest-reached/resume checkpoint when reviewing earlier answers.
- [ ] Ensure hidden/ineligible domain data is not displayed but also not destroyed.
- [ ] Review must not claim unsaved/incomplete connection or target state as committed.

**Review gate:** approve final Review content/order before implementation.

### Slice 8 — Plan Building 0→100 Finalization Contract

Goal: after Review, visibly prepare/finalize the user's setup and enter the app only on real success.

Proposed user flow:

```text
Review
  ↓ confirm
Building your plan

      0 → 100%
   circular progress

Preparing your Tio experience…
  ↓
App
```

Audit/decisions:

- [ ] Inventory current `CompleteOnboardingUseCase` / owner-persistence ordering.
- [ ] Define which real operations exist for Workout, Nutrition and Hybrid.
- [ ] Define progress mapping to real checkpoints; no fake successful 100% independent of finalization.
- [ ] Do not create a Workout Program or Diet Plan just because this screen is named Plan Building.
- [ ] Decide whether progress may animate between real checkpoints while completion remains gated by actual success.
- [ ] Define failure/retry state without losing Review answers.
- [ ] Define Back/cancel behavior once finalization starts.
- [ ] Define idempotency and duplicate-tap protection.
- [ ] Define accessible progress semantics and reduced-motion behavior.
- [ ] Route to App only after required owner writes + completion marker succeed in approved order.

**Review gate:** approve progress/finalization truth contract and visual concept before implementation.

### Slice 9 — Draft Schema, Resume, and Owner Persistence Reconciliation

Goal: make the restructured flow durable without data loss or duplicate ownership.

- [ ] Map every approved screen field to exactly one canonical owner from #44.
- [ ] Update onboarding draft shape only for orchestration/edit state, not as a second canonical owner.
- [ ] Define forward-compatible schema migration from existing drafts and stable IDs.
- [ ] Define owner write ordering and partial-failure recovery.
- [ ] Reconcile current Profile/Nutrition/Workout mirrored fields only through approved #44/#8 plan.
- [ ] Verify inactive mode/domain data preservation.
- [ ] Keep App Mode durability changes in #11.

**Review gate:** approve persistence/migration plan before schema/repository mutations.

### Slice 10 — Mode Matrices, Validation, Device Acceptance, and Cleanup

- [ ] Unit tests for exact Workout/Nutrition/Hybrid step order and conditional skips.
- [ ] Draft/resume migration tests.
- [ ] Back/edit/review/furthest-checkpoint tests.
- [ ] Health connection skip/unavailable/denied/success/failure tests for the approved integration boundary.
- [ ] Plan Building progress/success/failure/retry/idempotency tests.
- [ ] Ensure completed #13 Account Setup/App Mode behavior remains green.
- [ ] Analyze affected Flutter/Dart packages.
- [ ] Full required CI.
- [ ] Real-device fresh Workout, Nutrition and Hybrid onboarding acceptance.
- [ ] Real-device health connection acceptance only on supported devices/providers after integration approval.
- [ ] Remove obsolete compatibility paths only after zero-reference and migration verification.

---

## 6. Quality Review

### Validation Run

```text
Planning-only task creation.
No production analyze/test run required yet.
```

### Review Findings and Resolution

Current structural finding:

```text
Existing
Profile + Workout + Nutrition + Targets + Review

Desired conceptual direction
User Profile
Body Goal
Wellness (decision)
Nutrition Profile / Goals
Workout Profile / Targets
Health Connections
Review
Plan Building
```

The task intentionally does not lock physical folder trees yet. Folder changes follow approved owner boundaries and real implementation slices; no speculative empty structure.

---

## 7. Final Handoff

### Changed Files

Planning branch only:

- `.ai/tasks/product-onboarding-structure-and-finalization.md`

GitHub planning tracker:

- #40 updated separately with the expanded Product Onboarding flow contract.

### Actual Behavior

No runtime behavior changed.

### Known Limitations

- #44 canonical owner decisions are not complete.
- Wellness first-run placement is undecided.
- Health integration/provider semantics and package ownership are undecided.
- Plan Building's real operation/progress mapping is undecided.
- Exact Hybrid section order remains reviewable.

### Final Status

`REVIEW`
