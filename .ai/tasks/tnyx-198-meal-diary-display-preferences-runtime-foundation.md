# TNYX-198 — Meal Diary display preferences runtime foundation

**Status:** In progress
**Primary owner:** `apps/features/nutrition` with `apps/app` composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + approved product-visible Meal Diary Settings toggle behavior
**Approval status:** Approved
**Approval evidence:** Owner approved the exact N14A scope and device-local persistence direction on 2026-09-11 after a fresh TNYX-66 readiness audit.
**Approved product/UI/data-shape boundaries:** Add canonical runtime preferences `showMealTimes = true`, `mealNotesEnabled = true`, `showMealNotePreview = false`; persist them device-locally with `SharedPreferencesAsync`; expose the three already-defined N14 controls on Meal Diary Settings; make `Show note preview` unavailable/inert while Meal Notes is OFF.
**Explicit non-changes:** No Meal Diary log cards/sections/aggregates, Quick Add save activation, MealLog create/edit/delete behavior, Meal Category behavior, reminders/notification delivery, Supabase schema/RLS/migration, future compact-card preference, or unrelated visual redesign.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** None
**Implementation ownership state:** Active
**Ownership transition:** Not applicable — same approved slice; single implementation owner reconciled at the first durable implementation checkpoint.
**Repository state last verified:** 2026-09-11 on the task branch after fresh base/branch comparison.
**Branch:** `tnyx/tnyx-198-n14a-meal-diary-display-preferences-runtime-foundation`
**Base SHA:** `629cc1cda87423b2351551fb22b991be374c9e63`
**Current implementation checkpoint SHA:** `5051970e7aed8de892b028e8bb025be60501b631`
**Observed working-tree state:** Remote branch only; connector-authored commits. No unrelated local work is being modified.
**PR / tracker:** Linear `TNYX-198` is `In Progress`; no PR yet.
**Current implementation state:** Preference contract, local adapter, controller/provider, settings controls, startup composition, and focused repository/controller/widget/startup tests are implemented on the branch. Validation has not run yet.
**Relevant execution surface:** Meal Diary display preference domain/data/controller/UI plus app startup hydration/composition.
**Validation completed at SHA:** None yet for source implementation.
**Validation remaining:** Exact-scope diff review, Flutter/Dart analyze and tests on the current head, then Draft PR review.
**Current blocker:** None known.
**Open review finding IDs:** None yet.
**Next exact action:** Finish static/source audit, reconcile stale screen documentation, open Draft PR, and use exact-head CI as the validation gate.

## Global UI / Design-System Guardrail

Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/core/lib/src/theme/README.md` were read before UI implementation. The existing Meal Diary Settings visual system remains the baseline.

Core has no generic settings toggle row today. This slice therefore keeps one feature-owned toggle composition using governed Core spacing, typography, colors and `TioGroupCard`; it does not introduce a speculative new Core component/token contract.

## 1. Discovery

### User Outcome

Make the N14 Meal Diary display preferences real runtime state before actual Diary cards start consuming them.

### Success Criteria

- one canonical runtime preference state exists;
- defaults are `showMealTimes=true`, `mealNotesEnabled=true`, `showMealNotePreview=false`;
- values survive app restart on the device;
- Meal Notes OFF disables note-preview control without deleting or rewriting note data;
- later TNYX-57 rendering can consume this same state.

### Scope

- Nutrition-owned immutable preference model and repository contract;
- one versioned `SharedPreferencesAsync` adapter;
- Nutrition-owned controller/runtime provider;
- production startup preload + ProviderScope override in `apps/app`;
- exactly three approved controls on Meal Diary Settings;
- focused persistence/controller/widget/startup tests;
- small screen-doc reconciliation when implementation makes current-status text stale.

### Non-Goals

No actual MealLog rendering, section aggregation, Quick Add save, edit/delete, note editor, Meal Categories behavior, reminders, Supabase changes, cross-device sync, or unrelated UI redesign.

## 2. Codebase Exploration

### Verified Evidence

- TNYX-68 historical runtime contains the Meal Diary Settings shell and Meal Categories row only; its task explicitly excluded these three preferences.
- TNYX-57 requires the three preference semantics before compact Diary cards can be truthful.
- TNYX-197 already provides selected-day MealLog repository reads.
- Calendar Preferences provides the closest device-local `SharedPreferencesAsync` + startup hydration + queued optimistic-write precedent.
- `MealLogEntry.note` and `consumedAt` are durable actual-log data; these preferences must never mutate them.
- Core exposes `TioGroupCard` and governed visual roles, but no generic settings toggle row.
- Base-to-branch audit started at exact main `629cc1c...`, one planning commit ahead, zero behind, with no overlapping open PR/branch found during readiness.

### Existing Pattern Followed

```text
Nutrition preference contract/repository
        ↓
SharedPreferencesAsync adapter
        ↓
Nutrition controller/provider
        ↓
apps/app startup preload + ProviderScope override
        ↓
MealDiarySettingsPage renders state and emits actions
```

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Defaults true / true / false | Locked | N14 product contract | Owner / TNYX-68 |
| Persistence device-local | Locked | Display/capability preference, not account/MealLog truth | Owner / TNYX-198 |
| One versioned local snapshot key | Chosen | One toggle action writes one coherent preference snapshot | Implementation |
| Supabase | Excluded | No table/column/RLS/migration needed | Owner / audit |
| Meal Notes OFF | Locked | Hide capability only; preserve stored note and preview preference | TNYX-68 / TNYX-57 |
| Preview control when notes OFF | Locked | Visible but inert/disabled; stored preference remains unchanged | TNYX-68 |
| Controller ownership | Nutrition | App composes/hydrates but owns no preference business rules | Repo governance |

## 4. Architecture Design

### Chosen Approach

`MealDiaryDisplayPreferences` is immutable product state. `MealDiaryDisplayPreferencesRepository` is the persistence boundary. `SharedPreferencesMealDiaryDisplayPreferencesRepository` stores a strict version-1 JSON snapshot under one namespaced key. Unknown/malformed local payloads are removed and resolve to product defaults.

`MealDiaryDisplayPreferencesController` preloads at app startup, publishes user toggles immediately, serializes writes, and rolls a failed current write back to the last confirmed snapshot. A superseded failure never rolls back a newer choice.

### Ownership and Data Flow

```text
MealDiarySettingsPage
  -> MealDiaryDisplayPreferencesController
  -> MealDiaryDisplayPreferencesRepository
  -> SharedPreferencesAsync

apps/app
  -> constructs/preloads the production controller
  -> overrides the feature provider with that same instance
```

### Alternative Rejected

- Supabase columns: unnecessary schema/account-sync cost.
- Widget-local state: resets and creates no canonical consumer state.
- Hard-coded defaults in TNYX-57 cards: creates known rework and dishonest settings.
- Preference fields on `MealLogEntry`: corrupts durable history ownership.
- New Core toggle component: no current cross-context reuse evidence.

### Failure and Accessibility States

- local read failure falls back to defaults without blocking Diary;
- malformed local payload is removed rather than guessed;
- current write failure restores confirmed state and surfaces a compact error;
- rapid writes serialize in user-action order;
- note-preview row exposes no tap action while Meal Notes is disabled;
- existing theme/compact-width tests remain applicable.

## 5. Implementation Plan

- [x] Reconcile branch, Linear, agent/task instructions and single implementation ownership.
- [x] Add preference model and repository contract.
- [x] Add one-key versioned `SharedPreferencesAsync` adapter.
- [x] Add Nutrition-owned controller/provider with load, optimistic update, serialization and rollback.
- [x] Preload the production controller during app startup and publish the same instance.
- [x] Extend Meal Diary Settings with Show meal times, Meal Notes, Show note preview.
- [x] Preserve note-preview preference when Meal Notes is disabled.
- [x] Add repository/controller/widget/startup tests.
- [ ] Reconcile current Meal Diary screen documentation.
- [ ] Audit exact base-to-head scope and open Draft PR.
- [ ] Validate current exact head and complete independent review.

## 6. Quality Review

### Validation Run

```text
Not run yet on the implementation head.
```

Planned gate: repository CI for Flutter/Dart analyze + tests, plus exact changed-file/diff review and `git diff --check` equivalent scope inspection.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | No independent review completed yet | — | Pending Draft PR |

## 7. Final Handoff

### Changed Files

Pending final exact-head reconciliation.

### Actual Behavior

Pending validation. Implementation currently provides device-local canonical display preferences and the approved Meal Diary Settings controls; it does not render MealLog history or enable saving.

### Known Limitations

- no Meal Diary card/section consumer yet;
- no Quick Add save wiring;
- preferences are intentionally device-local, not cross-device synced;
- no reminder settings in this slice.

### Final Status

`REVIEW` — implementation is active; validation/review remain.
