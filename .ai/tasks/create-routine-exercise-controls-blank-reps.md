# Create Routine Exercise controls + blank initial Reps

**Status:** Implementation and focused tests verified on synthetic CI source; [Draft PR #544](https://github.com/im-tnyx/tio-world/pull/544), independent Codex review pending; **no merge/deployment/device QA**.
**Implementation owner:** This connected GitHub session, exclusively on `tnyx/create-routine-long-press-blank-reps`; #537 and #541 parent owners' branches untouched.
**Scope:** Workout Create Routine page only, stacked child of Draft #541 (parent of #541 is Draft #537). Existing Edit Routine page outside this UI slice.

## Owner approval
- Remove Exercise Up/Down arrow buttons. Long-press the **Exercise header/title** (not an inline numeric field or menu) to pick up and drag the Exercise to a new position. Use the existing Workout `RoutineCreateController.moveExercise` and Flutter `SliverReorderableList` pattern already used in Nutrition; stable entry UUIDs. Keep scroll/a11y and existing layout spacing.
- Replace the right-side `X` Exercise action with a 3-dot overflow menu containing the existing **Remove Exercise** action. The menu must respect Save/Verify locked state. No new menu features. Set type, repetition mode, swipe-to-delete and haptics remain unchanged.
- Owner follow-up screenshot: when picking Exercise or tapping **Add Set**, the Reps field must be visibly **blank**, not a prefilled `1`. This applies to new Create draft Sets, including Set 1, not saved existing Edit Sets. Save MUST be disabled until all visible new Set Reps (or Rep Range Min+Max) are valid. Canonical persisted `SetPrescription` still requires positive reps; an internal `1` default is not a user input and must never be saved unless user explicitly enters a positive value. No DB table, RPC or domain shape change; track pending unentered Set UUIDs in owner Create page and pass blank-initial state to `RoutineSetInputRow`.
- On removal, clear pending/invalid states and keep last-Set→Exercise removal; reorder must preserve input state, Set identity, weight/reps values, and per-set pending Save guards.

## Source and ownership audit
- Read root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README and task template; live Linear TNYX-81 Backlog blocked by TNYX-78/80.
- Active Draft PR #533 Edit, #537 Create UI, #541 Set Type/Rep Range; new branch starts at PR #541 HEAD `238ee23363c8e3d23390ee73cadf6aaf862566e2` and owns only the delta. Parent branches MUST NOT be edited.
- Current Create uses `ListView` with static icons X/Up/Down in Exercise header; controller `moveExercise(old,new)` already exists; Nutrition shows `SliverReorderableList` + `ReorderableDelayedDragStartListener` header pattern.
- Current `RoutineSetInputRow` initializes Reps to `SetPrescription(reps:1).reps.toString()`; Create page `_invalidSetIds` only gates invalid editing, not untouched new rows. Existing Create regression tests assume automatic Save enabled with 1; update them to require actual user entry.
- No physical device, Flutter SDK or local source worktree available via this connected session; remote source/CI tests must be explicitly verified.

## Gates
- [x] Implement bounded Create-only interaction and initial blank field with pending Set UUID Save gate; source commit `6f10e866`.
- [x] Focused widget regressions authored and **executed on synthetic CI-only branch** for blank initial/added Reps, Rep Range Min/Max, invalid delete, long-press reorder with two Exercise IDs, 3-dot Remove, unchanged Set Type/swipe. Locked-state menu requires physical QA; not separately proven.
- [x] [Synthetic CI-only PR #545](https://github.com/im-tnyx/tio-world/pull/545) source `55d53ad` ran [Flutter CI #38400987188](https://github.com/im-tnyx/tio-world/actions/runs/38400987188): Flutter Analyze SUCCESS; Dart Analyze SUCCESS; Workout Flutter tests SUCCESS; Shared Dart tests SUCCESS. Synthetic branch includes scratch-only ancestor #537 lint fixes; this is **not original #544 exact-head PASS**. Full Flutter suite FAILED in unchanged #537 app route test at `workout_exercises_route_test.dart:661` (`Bad state: No element` on legacy `routine-name-field`). Workspace Dart tests skipped.
- [ ] [Codex independent review requested](https://github.com/im-tnyx/tio-world/pull/544#issuecomment-6146083732) for exact #544 source; bot review Running at last check. Resolve all confirmed findings first.
- [ ] Parent stack reconciling #537 route test and lint; no merge, Supabase migration, deployment or device acceptance until separate owner gates.

**Current implementation boundary:** one new Draft child PR only. Existing Edit UI controls preserved pending separate request. Reps persisted model and Supabase untouched.

## 2026-10-13 validated source handoff
- Owner request implemented in new *child* PR [#544](https://github.com/im-tnyx/tio-world/pull/544), base Draft #541, 6 commits ahead/0 behind; no parent source branch changes. Source SHA `6f10e86687d79c67a17b17c941a43ee0a6663da8`.
- `CreateRoutinePage`: Flutter `SliverReorderableList` + `ReorderableDelayedDragStartListener` wraps Exercise **title/header only**; popup `more_vert_rounded` offers existing Remove Exercise in place of X and Up/Down buttons; existing domain controller reorders immutable, identity-keyed entries. Reorder haptics. Set type/swipe/Rep Range interactions unaffected.
- Newly picked/additional Sets use temporary positive internal canonical `reps=1` because `SetPrescription` forbids missing reps, but *user-visible Reps is blank*. `_untouchedRepSetIds` IDs are added to `_invalidSetIds`; Save remains disabled until user explicitly enters valid fixed Reps or valid range Min+Max. Row `startWithBlankReps` only affects Create new draft rows, not persisted Edit. Removing Set/Exercise clears guards. Repetition mode can be selected before Reps without auto-populating blank Min/Max.
- Real GitHub Actions CI-only run [#38400987188](https://github.com/im-tnyx/tio-world/actions/runs/38400987188) **succeeded** in Flutter Analyze, Dart Analyze, targeted Workout Flutter tests and Shared Dart tests on synthetic source `55d53ad`, which adds scratch-only #537 null comparison removal, old test fixture const adjustments, and focused CI probes. Full workspace Flutter suite still fails **only observed known ancestor #537 stale route test** `apps/app/test/app/workout_exercises_route_test.dart:661`, Dart workspace tests skipped. **NO exact original PR #544 head CI PASS claim.**
- Security/deployment: no DB/SQL changes or production edits. Draft #533/#537/#541/#544 and DB Draft #536/#540 unmerged; physical device/large text/accessibility test not run; #537 parent fixes and stack reconciliation required for eventual exact-head full CI.
- **Next:** Codex review result, resolve supported findings, ensure CI-only PR #545 is closed unmerged after evidence, review stack ownership, refresh Linear W4 parent comment, do not merge or deploy without explicit authorization.
