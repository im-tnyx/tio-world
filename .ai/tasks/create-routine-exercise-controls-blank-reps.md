# Create Routine Exercise controls + blank initial Reps

**Status:** In progress; owner-approved UI refinements in this conversation.
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
- [ ] Implement bounded Create-only interaction and initial blank field (no persistence of untouched canonical placeholder).
- [ ] Unit/widget tests: Add Exercise blank Reps and Save disabled, Add Set blank & Save blocked until both entered, range mode remains blank for unentered Set, invalid deletion restores guard, long-press reorder with two Exercise IDs, 3-dot removal, menu disabled while locked, unchanged Set Type/swipe.
- [ ] Exact-head Flutter Analyze+Workout tests via main-targeted validation if needed; do not claim pass from authored tests.
- [ ] Independent review and follow-up from Codex.
- [ ] Parent stack reconciling #537 route test and lint; no merge, Supabase migration, deployment or device acceptance until separate owner gates.

**Current implementation boundary:** one new Draft child PR only. Existing Edit UI controls preserved pending separate request. Reps persisted model and Supabase untouched.
