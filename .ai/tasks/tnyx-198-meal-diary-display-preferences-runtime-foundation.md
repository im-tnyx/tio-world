# TNYX-198 — Meal Diary display preferences runtime foundation

**Status:** Ready
**Primary owner:** `apps/features/nutrition` with `apps/app` composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice + approved product-visible Meal Diary Settings toggle behavior
**Approval status:** Approved
**Approval evidence:** Owner approved the exact N14A scope and device-local persistence direction on 2026-09-11 after a fresh TNYX-66 readiness audit.
**Approved product/UI/data-shape boundaries:** Add the missing canonical runtime preferences `showMealTimes = true`, `mealNotesEnabled = true`, `showMealNotePreview = false`; persist them device-locally with `SharedPreferencesAsync`; expose the three already-defined N14 controls on the existing Meal Diary Settings surface; make `Show note preview` unavailable/inert while Meal Notes is OFF.
**Explicit non-changes:** No Meal Diary log cards/sections/aggregates, Quick Add save activation, MealLog create/edit/delete behavior, Meal Category behavior, reminders/notification delivery, Supabase schema/RLS/migration, future compact-card preference, or unrelated visual redesign.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** Not assigned yet
**Review owner:** None
**Implementation ownership state:** Not started
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-11 after owner-completed post-merge sync and fresh GitHub read
**Branch:** `tnyx/tnyx-198-n14a-meal-diary-display-preferences-runtime-foundation`
**HEAD SHA:** branch created from `629cc1cda87423b2351551fb22b991be374c9e63`
**Observed working-tree state:** Agent has not modified a local worktree; remote branch contains this planning brief only after branch creation.
**Observed uncommitted/dirty files:** None reported by owner before branch creation; local `main` was clean and aligned with `origin/main`.
**PR / tracker:** Linear `TNYX-198` Backlog/Ready-to-start; no PR yet.
**Current implementation state:** Planning/readiness only. Production source not changed.
**Relevant execution surface:** Nutrition Meal Diary Settings preferences + app composition/startup hydration pattern.
**Validation completed at SHA:** Read-only source/tracker audit only; no source validation required yet.
**Validation remaining:** Applicable Flutter/Dart analyze/tests after implementation; focused repository/controller/widget/composition tests; `git diff --check` before PR.
**Current blocker:** None. Owner approval resolved the previous readiness decision.
**Open review finding IDs:** None.
**Next exact action:** On explicit owner `Go`, move TNYX-198 to In Progress, reconstruct branch/source state, assign one Implementation owner, then implement this bounded slice only.

## Global UI / Design-System Guardrail

This slice touches Flutter production UI. Before implementation, follow root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/tasks/design-system-token-consolidation.md`, and `apps/core/lib/src/theme/README.md`.

The existing Meal Diary Settings visual system must be preserved. Reuse governed Core settings components; do not create feature-local token/color/layout catalogs or redesign unrelated settings geometry.

## 1. Discovery

### User Outcome

Make the already-defined Meal Diary display preferences real runtime state before actual Diary cards start consuming them.

### Success Criteria

- one canonical runtime preference state exists for Meal Diary display behavior;
- defaults are `showMealTimes=true`, `mealNotesEnabled=true`, `showMealNotePreview=false`;
- settings survive app restart on the device;
- Meal Notes OFF disables/hides the ability to change note preview without deleting stored meal notes;
- later TNYX-57 rendering can consume this state without inventing another store.

### Scope

- Nutrition-owned preference model/repository/controller or equivalent current-pattern boundary;
- `SharedPreferencesAsync` device-local adapter;
- app composition/startup hydration only as needed to expose one canonical owner;
- existing Meal Diary Settings surface gains exactly the three approved controls;
- focused persistence/state/widget/composition tests.

### Non-Goals

- rendering actual MealLog history;
- section/card aggregate logic;
- Quick Add `Log Meal` enablement;
- manual MealLog edit/delete;
- note editing UI in Meal Editor;
- reminders;
- Supabase changes;
- cross-device preference sync.

## 2. Codebase Exploration

### Verified Evidence

- `TNYX-68` is Done for the historical minimum settings shell, but current `MealDiarySettingsPage` intentionally contains only the Meal Categories navigation row and explicitly omits later Diary preferences.
- `TNYX-57` requires `showMealTimes`, `mealNotesEnabled`, and `showMealNotePreview` for compact Diary presentation.
- `TNYX-197` completed selected-day MealLog repository reads, so the next visible Diary work should not hard-code temporary preference semantics.
- Settings already has a device-local `SharedPreferencesAsync` precedent for Calendar Preferences; app composition owns construction/hydration, while the preference domain/repository stays outside widgets.
- `MealLogEntry.note` and `consumedAt` are durable actual-log data. Visibility preferences must never mutate them.
- Core exposes governed Settings components; feature UI must reuse them rather than invent local visual contracts.
- No overlapping open PR/branch for TNYX-57, TNYX-68, TNYX-115, or this new slice was found during readiness audit.
- Current authoritative `main` at branch creation: `629cc1cda87423b2351551fb22b991be374c9e63`.

### Existing Pattern to Follow

```text
feature preference contract/repository
        ↓
device-local SharedPreferencesAsync adapter
        ↓
app construction / hydration / provider composition
        ↓
feature controller/state
        ↓
MealDiarySettingsPage renders state + emits actions
```

Calendar Preferences is the closest existing persistence/composition precedent. Do not copy its ownership blindly if Nutrition package boundaries require an equivalent Nutrition-local contract; preserve the same separation of storage, controller and presentation responsibilities.

### Tests or Validation Already Present

- Meal Diary settings route/widget tests;
- app startup hydration and Calendar Preferences controller/repository tests as pattern references;
- Core settings component coverage;
- Nutrition package analyze/test CI baseline.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preference defaults | Locked | N14 contract: true / true / false | Owner / TNYX-68 |
| Persistence | Locked | Device-local `SharedPreferencesAsync`; presentation convenience is not MealLog/account truth | Owner / TNYX-198 |
| Supabase | Excluded | No table/column/RLS/migration needed | Owner / audit |
| Meal Notes OFF behavior | Locked | Hide/disable note presentation capability only; never clear persisted `MealLogEntry.note` | TNYX-68 / TNYX-57 |
| Note preview dependency | Locked | Meaningful only when Meal Notes is ON | TNYX-68 |
| App ownership | Composition only | App may construct/hydrate/provide; Nutrition owns the preference semantics | `AGENTS.md` / module ownership |
| Visual scope | Locked | Add only the approved preference controls using current Core settings system; no unrelated redesign | Owner |

## 4. Architecture Design

### Chosen Approach

Use one immutable Meal Diary display-preferences value plus a repository contract and local adapter. A controller/notifier owns optimistic or serialized updates and rollback/failure state as appropriate to the existing repository patterns. App composition provides/hydrates that owner; `MealDiarySettingsPage` receives state/actions rather than calling storage directly.

### Ownership and Data Flow

```text
MealDiarySettingsPage
  -> Meal Diary preferences controller/notifier
  -> Meal Diary preferences repository
  -> SharedPreferencesAsync

later TNYX-57
  -> reads the same canonical preference state
  -> controls timestamp/note presentation only
  -> never mutates MealLogEntry data
```

### Alternative Rejected

- **Supabase/account-synced columns:** unnecessary data-model cost for V1 display preferences and would create a schema/approval burden without product need.
- **Local widget state only:** would reset on restart and create no canonical state for Diary rendering.
- **Hard-code defaults directly in TNYX-57 cards:** would force later rework and make N14 toggles dishonest.
- **Store settings on each MealLogEntry:** violates the N14 contract and would couple presentation preferences to durable history.

### Failure and Accessibility States

- persisted read failure must resolve through an explicit safe/default state rather than crash the settings route;
- write failure must not silently claim a saved preference; rollback/error handling must follow the closest established settings-controller pattern;
- disabled/inert note-preview control must expose correct semantics while Meal Notes is OFF;
- toggles need standard tap targets, labels and keyboard/focus behavior through governed Core components;
- existing light/dark/OLED/compact-width behavior must not regress.

## 5. Implementation Plan

- [ ] Reconstruct current branch/source/Linear state and assign one Implementation owner.
- [ ] Inspect exact current Calendar Preferences + Settings toggle precedents before source edits.
- [ ] Add Nutrition-owned Meal Diary display-preferences contract with locked defaults.
- [ ] Add device-local `SharedPreferencesAsync` repository adapter with stable namespaced keys.
- [ ] Add controller/notifier/provider boundary with explicit load/update/failure behavior.
- [ ] Compose/hydrate the canonical owner from `apps/app` only where required.
- [ ] Extend `MealDiarySettingsPage` with Show meal times, Meal Notes and Show note preview using existing Core settings components.
- [ ] Enforce note-preview dependency without mutating stored note data.
- [ ] Add focused repository/controller/widget/app-composition tests.
- [ ] Update `docs/screens/meal-diary.md` / task handoff only where observed runtime status becomes stale because of this slice.
- [ ] Audit exact base-to-head scope before Draft PR.

## 6. Quality Review

### Validation Run

```text
Not run yet — implementation has not started.

Planned minimum:
melos bootstrap
melos analyze
melos test
git diff --check
```

Focused package/app checks may be run earlier while iterating, but final PR evidence must describe what actually ran.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | — | No implementation review yet | — | — |

## 7. Final Handoff

### Changed Files

Planning only at this checkpoint:

- `.ai/tasks/tnyx-198-meal-diary-display-preferences-runtime-foundation.md`

### Actual Behavior

No runtime behavior changed yet.

### Known Limitations

- `TNYX-57` Diary cards remain unimplemented;
- Quick Add remains unable to save;
- N14 reminder behavior remains separate;
- no cross-device sync for these V1 presentation preferences.

### Final Status

`REVIEW` — task is approved and READY for implementation, but source work has not started.
