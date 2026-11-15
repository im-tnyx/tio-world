# W10-D — Warm-up Calculator

**Status:** In progress  
**Primary owner:** `apps/features/workout`  
**Affected platforms:** Flutter phone Android/iOS

## Owner Approval and Scope Boundary

**Trigger:** New product-visible Workout Settings and Log Workout slice.  
**Approval status:** Approved.  
**Approval evidence:** Owner's 2026-11-15 chat instruction to build the calculator in Workout Settings and Log Workout (`GO`), followed by screenshot-based approval for named warm-up methods, the Percent/Fixed/Bar editor, and the Routine Create/Edit method picker. The owner confirmed that Routine picker `Done` generates warm-up Set rows from the Exercise's working weight.  
**Approved scope:** Device-local named warm-up method library; built-in Classic, Strength and Barbell Ramp methods; custom method creation with Percent/Fixed/Bar set rules; method selection in Workout Settings, Log Workout and Routine Create/Edit; calculator preview/insertion; generated routine `warm_up` Set prescriptions using the existing composition contract; plate/dumbbell rounding. Use Tio-World Core tokens/components.  
**Explicit non-changes:** No Supabase schema/RPC/hosted change, Workout Profile data, workout-statistics recalculation, watch, or unrelated Workout Settings rows. Preserve unrelated Log Workout and Routine rendering.

## Active Handoff

**Planning owner:** Codex  
**Implementation owner:** Codex  
**Previous agent:** Not applicable  
**Last commit agent:** Codex  
**Last commit SHA:** `2692ff8e` (implementation commit; task-brief checkpoint follows)  
**Review owner:** Independent reviewer pending  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** `main@7127c22d11f93bd5ebe0576a4dda95e24e8013cf`; clean before branch creation.  
**Branch:** `tnyx/w10d-warmup-calculator`  
**HEAD SHA:** `2692ff8e` at this handoff checkpoint.  
**Observed working-tree state:** Implementation committed; this task brief remains untracked until its handoff commit.  
**Observed uncommitted/dirty files:** `.ai/tasks/w10d-warmup-calculator.md` only.  
**PR / tracker:** GitHub Issue #48; Linear TNYX-87 (broader W10 remains Backlog).  
**Tracker reconciliation (2026-11-15):** GitHub Issue #48 is open and still records the broader runtime-settings slice as pending audit/approval; Linear TNYX-87 is `Backlog` and blocked by TNYX-78. The owner explicitly authorized this bounded W10-D child slice in chat. No W10-D PR was found; parent tracker states were not changed.  
**Current implementation state:** The initial W10-D calculator/settings slice and approved named-method extension are committed on the task branch, including Settings, Log Workout and Routine Create/Edit. Workout analysis and full package tests passed; visual device acceptance remains open.  
**Relevant execution surface:** Workout settings repository/controller/page, warm-up domain/calculator sheets, Save-only Log Workout draft/controller/page, Routine Create/Edit composition controllers/pages, canonical screen docs and focused tests.  
**Validation completed at implementation commit `2692ff8e` (base `7127c22d11f93bd5ebe0576a4dda95e24e8013cf`):** The extension passed Workout `flutter analyze --no-pub`, focused warm-up/Routine tests, focused Routine Create picker test, the full Workout `flutter test --no-pub` suite (1570 tests), a later focused 320dp/light/dark method-sheet test, and `git diff --check` on the same source tree before commit. Earlier Core `flutter analyze`/full `flutter test` and the focused app Log Workout route test passed before the method extension; their affected contracts did not change in this extension.  
**Validation remaining:** Emulator visual acceptance of compact/light/dark Settings, method editor, Log Workout and Routine Create/Edit flows.  
**Current blocker:** None for implementation. Device visual acceptance has not yet been performed.  
**Open review finding IDs:** None yet.  
**Next exact action:** Push this branch, then inspect the four warm-up surfaces on an emulator before requesting PR review.

## 1. Discovery

### User Outcome

Configure reusable named warm-up methods in Workout Settings, apply them to Log Workout and Routine Create/Edit, and keep calculations and generated warm-up Sets consistent with the Tio-World Workout model.

### Success Criteria

- Built-in methods match the approved examples: Classic (40% × 5, 60% × 5, 80% × 3), Strength (40% × 5, 60% × 3, 80% × 2, 90% × 1), and Barbell Ramp (Bar × 5, 40% × 5, 60% × 3, 80% × 2).
- Users can create named methods with Percent, Fixed and Bar set rules, select one method, and retain the existing rounding settings.
- Settings/method library remains owner-scoped and device-local; old formula-only settings migrate without dropping a custom formula.
- Log Workout previews calculated loads/reps for the selected method and inserts accepted warm-up sets explicitly, preserving the current draft and set order/identities.
- Routine Create/Edit method picker applies the selected method by generating existing `warm_up` Set prescriptions from the Exercise's first working Set load; it respects the existing eight-Set cap and leading warm-up order without adding a DB field.
- Disabled, invalid/missing-weight, failed-read, over-limit, and compact-layout states are truthful and recoverable.

### Scope

`apps/features/workout` runtime settings, method library/calculation, Save-only Log Workout UI/draft, Routine Create/Edit composition, focused tests; canonical Workout, Active Workout and Routine screen docs.

### Non-Goals

Workout-statistics inclusion/recalculation, cross-device sync, automatic Log Workout modification, legacy online Workout path, new database shape, and Watch/Wear parity.

## 2. Codebase Exploration

### Verified Evidence

- The previous Tio-World implementation contains only a percentage/reps formula and device-local rounding, not named methods; the screenshot set supplies the newly approved method-library UI.
- Tio's Log Workout Exercise menu action is `Add warm-up sets`. Its calculator sheet uses Plate rounding, exposes a settings gear to open the separate Calculator Settings screen, and opens an individual Set Formula picker from each preview row. Tio's separate `Warm-up Sets` screen exposes the stats switch. `active_workout_editor.dart` calls the default calculator independently. Keep the approved Calculator screen and Log Workout action scoped to their actual reference surfaces.
- Tio-World `WorkoutRuntimeSettingsRepository` is owner-scoped/device-local; Save-only draft owns set identity, local persistence, and warm-up ordering. `RoutineCompositionLimits.maxSetsPerExercise` is 8.
- `SetPrescription` already represents `RoutineSetType.warmUp` (`warm_up` wire value); Routine Create/Edit controllers insert those Sets before non-warm-up Sets and validate the existing eight-Set cap. This supports the approved Routine behavior without changing the persistence schema.
- Tio-World `RoutineSetType.warmUp` serializes as `warm_up`; Tio's dynamic map uses `warmup`.
- Owner's latest clarification: `Add warm-up sets` is the first Exercise option. Reuse the same Tio-style value wheel for percentage and repetitions; render one Formula/Warm-up preview table and keep the established Tio-World card, divider, color, radius, and typography tokens.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse Tio's 40/60/80 method and editable formula | Approved | Explicit copy instruction | Owner |
| Store calculator settings owner-scoped on device | Implementation choice | Reuses current W10 settings repository; no new schema | Codex |
| Include warm-up sets in stats | Out of scope | Tio places this on a separate `Warm-up Sets` screen; W10-D approval covers the Calculator screen and Log Workout | Codex |
| Routine picker `Done` behavior | Approved: generate `warm_up` Set rows from the Exercise's working load | Owner selected this behavior on 2026-11-15; reuse the existing Set contract | Owner |
| Bar rule load | Use the standard 20 kg bar for Bar method calculations | Screenshot has a Bar rule without a separate bar-weight setting | Codex |

## 4. Architecture Design

Workout Settings UI -> `WorkoutRuntimeSettingsController` -> owner-scoped repository -> local preferences. The named method model owns built-ins and user-created methods; decoding the old formula-only JSON preserves non-default formulas as a legacy Custom method. Settings, Log Workout and Routine Create/Edit use the same method selector/editor. Log Workout calculates a preview and performs one draft insertion. Routine Create/Edit calculates from the first positive non-warm-up load and atomically replaces generated leading warm-up prescriptions in the existing composition draft; normal Set identities/order remain intact. Use Core's existing editor sheets, inputs, buttons, cards and theme tokens.

## 5. Implementation Plan

- [x] Add validated pure-Dart warm-up formula/calculation model and tests.
- [x] Persist and expose calculator settings with independent failure/retry behavior.
- [x] Add Workout Settings entry/editor using Core components and Tio's UI composition.
- [x] Add Log Workout calculator entry, preview, and atomic draft insertion.
- [x] Refine the Exercise action ordering, single Formula/Warm-up preview table, pinned action footer, and Tio-matched wheel styling.
- [x] Update canonical screen docs.
- [x] Add named methods, legacy settings migration, Percent/Fixed/Bar editor, and selector.
- [x] Use selected method in Log Workout calculator and Routine Create/Edit warm-up generation.
- [x] Update canonical Workout, Active Workout and Routine screen docs.
- [x] Rerun focused Flutter analysis and tests.
- [ ] Perform emulator visual acceptance.

## 6. Quality Review

### Validation Run

The current uncommitted W10-D tree passed Workout `flutter analyze --no-pub`, the focused warm-up/Routine tests, the focused Routine Create method-picker test, the full Workout `flutter test --no-pub` suite (1570 tests), and `git diff --check`. A focused widget test after the full suite passed at 320dp with 1.3× text scale in light and dark themes; Flutter analysis passed again afterward. Earlier Core analysis/full tests and a focused app Log Workout route test passed before the method extension. Flutter used the owner-provided SDK. Physical device visual acceptance remains NOT RUN.

### Change-Time Future Protected-API Compatibility Review

**Compatible + evidence (limited to the current local contract):** `apps/features/workout` owns the calculator and owner-scoped local settings. The new settings repository methods add a separate local preference key; they do not change existing server DTOs, Supabase adapters or durable Workout identities. Inserted Sets use the existing `SetPrescription` (`warm_up`, reps, kg) and new draft UUIDs, preserving existing IDs. A future protected service can receive the existing saved Set shape without re-keying this change. Actual future adapter parity, hosted authorization, mixed-version clients and retries remain untested; no new service or migration is implied.

### Acceptance Evidence

| Criterion | Changed behavior / file | Evidence and result | Environment | Remaining risk |
|---|---|---|---|---|
| Classic/Strength/Barbell Ramp and Percent/Fixed/Bar calculation | `workout_warmup_calculator.dart` | Domain test PASS; full Workout suite PASS | Local uncommitted branch, Flutter SDK 3.44.6 | Standard 20 kg Bar assumption remains a product decision |
| Owner-scoped methods, legacy formula migration, malformed storage | Settings model/repository and tests | Repository/domain tests PASS | Same | Cross-device sync intentionally absent |
| Log Workout explicit insertion, IDs and cap | Calculator sheet/draft controller and tests | Widget/controller tests and full suite PASS | Same | Device flow unverified |
| Routine Create/Edit generated `warm_up` Sets, ID preservation and cap | Routine controllers/pages and tests | Create/Edit widget and controller tests PASS | Same | Device flow and hosted Save/Update not exercised |
| Method UI adapted to Core tokens | Settings page and selector/editor/calculator sheets | Widget tests, 320dp/1.3× light/dark selector/editor test and Workout analysis PASS | Same | Physical rendering unverified |

### Review Provenance

Self-review of source and Core component APIs completed on the local working tree. Independent review not requested in this task; no GitHub approval or PR exists for this slice.

## 7. Final Handoff

**Actual behavior:** Workout Settings offers the nested calculator and named method picker/editor. Classic, Strength, Barbell Ramp and saved custom Percent/Fixed/Bar methods are available per owner on the device. Log Workout previews and inserts Sets from the selected method. Routine Create/Edit generate leading `warm_up` prescriptions from the first working load after method selection; existing warm-up rows require replacement confirmation, and working Set IDs/values remain unchanged.

**Known limitations:** Emulator visual acceptance and hosted Routine Save/Update were not run. Bar uses a standard 20 kg value; another bar size is not configurable in this slice. Implementation commit `2692ff8e` exists locally; push is pending at this checkpoint. No PR, tracker write or hosted change was made.

**Final status:** `PARTIAL` pending physical device visual acceptance and independent review.
