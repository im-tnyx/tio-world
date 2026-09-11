# TNYX-198 — Meal Diary display preferences runtime foundation

**Status:** Validated — ready for final review; merge requires separate owner authorization
**Primary owner:** `apps/features/nutrition` with `apps/app` composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Approval status:** Approved
**Approval evidence:** Owner approved the bounded N14A slice and device-local persistence direction on 2026-09-11 after the fresh TNYX-66 readiness audit.

Approved runtime contract:

```text
showMealTimes = true
mealNotesEnabled = true
showMealNotePreview = false
```

Persistence is device-local `SharedPreferencesAsync`. `Show note preview` is visible but unavailable/inert while `Meal Notes` is OFF. Disabling Meal Notes must not rewrite `MealLogEntry`, clear stored note content, or erase the saved preview preference.

Explicit non-goals: no Diary cards/sections/aggregates, Quick Add save activation, MealLog create/edit/delete behavior, Meal Categories behavior, reminders, Supabase table/column/RLS/migration changes, cross-device preference sync, compact-card preference, or unrelated UI redesign.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** ChatGPT
**Implementation ownership state:** Implementation complete; review/validation handoff active
**Branch:** `tnyx/tnyx-198-n14a-meal-diary-display-preferences-runtime-foundation`
**Base:** `main` at `629cc1cda87423b2351551fb22b991be374c9e63`
**Validated source SHA:** `a0a04546e9fd569aaa432bfb0003a68963e57998`
**PR:** #257 — Draft at this handoff update
**Linear:** TNYX-198 — In Progress at this handoff update
**Repository state:** API-authored branch; fresh base comparison remained ahead-only with exact merge base at `629cc1cd...`; no unrelated local/user work was modified.
**Current blocker:** None in implementation. Final docs-only exact-head CI remains the last Ready gate after this handoff commit.
**Open review threads:** None at the source validation checkpoint.

## Discovery and Architecture

TNYX-68 implemented only the minimum Meal Diary Settings shell and intentionally omitted the three display preferences. TNYX-57 later Diary cards depend on these semantics, while TNYX-197 already provides durable selected-day MealLog reads. Calendar Preferences established the nearest device-local persistence/startup-hydration precedent.

Chosen ownership/data flow:

```text
MealDiarySettingsPage
  -> MealDiaryDisplayPreferencesController
  -> MealDiaryDisplayPreferencesRepository
  -> SharedPreferencesMealDiaryDisplayPreferencesRepository
  -> SharedPreferencesAsync

apps/app
  -> constructs the production persistent adapter/controller
  -> hydrates it before first frame
  -> overrides the feature controller provider with that same instance
```

The feature package default provider is intentionally platform-neutral/in-memory for package and router harnesses. Production persistence is explicit in `apps/app/main.dart`; the in-memory fallback is not used as production durability.

`MealDiaryDisplayPreferences` is presentation/capability state only. Durable timestamps and note text remain `MealLogEntry` truth. One versioned JSON snapshot key is used so one preference action writes one coherent local snapshot; malformed or unknown local payloads are removed and resolve safely to product defaults.

`MealDiaryDisplayPreferencesController` loads once, applies toggles optimistically, serializes writes, rolls a failed current write back to the last confirmed snapshot, and ignores superseded failures for rollback purposes. `setMealNotesEnabled(false)` preserves `showMealNotePreview`; preview mutation is inert while notes are disabled.

Core has no generic settings toggle row. The approved UI therefore uses a feature-owned one-off toggle composition inside `TioGroupCard`, consuming governed Core spacing, typography, colors and divider roles without introducing a speculative Core public component.

## Implemented Scope

- [x] immutable canonical preference model with defaults true / true / false;
- [x] Nutrition-owned repository contract;
- [x] versioned `SharedPreferencesAsync` production adapter;
- [x] Nutrition-owned controller with load, optimistic publish, serialized writes and rollback;
- [x] platform-neutral feature/provider fallback for harnesses;
- [x] app startup preload and ProviderScope override using the production persistent controller;
- [x] `Show meal times`, `Meal Notes`, `Show note preview` settings controls;
- [x] note-preview disabled/inert while Meal Notes is OFF, with its stored choice preserved;
- [x] save failure restores confirmed state and surfaces retry-oriented error copy;
- [x] repository/controller/widget/startup focused tests;
- [x] focused current-state documentation in `docs/screens/meal-diary-display-preferences.md`;
- [x] no Supabase/MealLog/Quick Add mutation-path change.

## Quality Review

### Validation

Flutter CI #2392 on source SHA `a0a04546e9fd569aaa432bfb0003a68963e57998`: **PASS**.

Validated gates:

```text
melos bootstrap                                  PASS
Flutter package analyze                         PASS
Dart package analyze                            PASS
Flutter package tests                           PASS
Dart package tests                              PASS
```

This handoff update is docs-only. The PR must be considered Ready only after CI is green again on the exact post-handoff head.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| R1 | P2 gate | Resolved | Initial focused tests used invalid semantics APIs and one unused fake parameter. | Test-only fixes landed; subsequent analyzers green. |
| R2 | P2 gate | Resolved | Feature default provider constructed `SharedPreferencesAsync`, causing router harnesses without plugin initialization to fail. | Default feature composition is platform-neutral/in-memory; production app still explicitly owns the persistent adapter. |
| R3 | P2 gate | Resolved | Default `ChangeNotifierProvider` registered manual `ref.onDispose` in addition to provider-owned notifier disposal, causing double-dispose in router teardown. | Removed duplicate disposal hook; Flutter suite passed on #2392. |
| R4 | P3 architecture | Resolved | Concrete persistence composition initially lived beside the presentation controller. | Moved composition to the Meal Diary feature-level provider seam. |
| R5 | P3 UI | Resolved | New toggle row rhythm initially differed from established Core settings row cadence. | Aligned vertical spacing to governed settings geometry without new Core API. |

Independent final source review found no remaining P1/P2 blocker at the validated source SHA. Review threads were empty.

## Changed Surface

Owned changes are limited to:

- this TNYX-198 task handoff;
- `apps/features/nutrition` Meal Diary preference model/repository/data/controller/provider/settings UI and focused tests;
- `apps/app` startup composition/hydration and focused startup test;
- Nutrition package dependency declaration required by the local adapter/tests;
- focused Meal Diary display-preferences documentation.

No `supabase/*`, MealLog repository mutation path, Quick Add save path, or unrelated product feature is changed.

## Known Limitations / Follow-up

- current Diary page still does not consume selected-day MealLog reads into cards/sections;
- Quick Add `Log Meal` remains disabled;
- preferences are intentionally device-local, not cross-device synced;
- reminders remain out of scope;
- the older broad `docs/screens/meal-diary.md` still contains historical wording that predates the TNYX-194→197 persistence/read foundation; the focused TNYX-198 doc records current truth and the broader document should be reconciled with the later Diary rendering slice rather than expanding this runtime-preference PR.

## Final Status

`VALIDATED / REVIEW` — approved bounded implementation is complete and source validation is green. Exact post-handoff CI + final PR/Linear reconciliation are required before marking PR #257 Ready. Merge remains a separate owner gate.
