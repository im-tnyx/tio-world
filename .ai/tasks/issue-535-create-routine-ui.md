# GitHub #535 — Create Routine reference UI and default Set 1

**Status:** In progress, approved bounded Create Routine UI slice; **stacked on Draft PR #533** and **blocked for deployment by Draft DB PR #536**. Not merged, deployed, released, or device-tested.
**Approval evidence:** 2026-10-13 user provided two Create Routine reference screenshots (empty state and populated Exercise) and explicitly directed reference-like Create UI plus **automatic first Set** for every chosen Exercise. After an explicit scope reply (existing fixed-Reps, optional kg/rest only; separate #535; no #533 Edit expansion; default minimal valid reps), user replied **Go**.
**Implementation owner:** Connected GitHub session on branch `tnyx/issue-535-create-routine-ui` exclusively for this bounded create slice; `tnyx/issue-532-w4b1-routine-editor` remains separate parent owner/review. No local Codex agent source takeover without recorded transfer.
**Planning owner:** Tio-world architecture. **Review owner:** Independent reviewer, not implementation session.
**Immediate stack parent:** `tnyx/issue-532-w4b1-routine-editor@58d8694cbbec3450a4beb7e6d9fa7c3469912181`; check parent and rebase policy before any further commits. Root `main` already implements *metadata-only* name sheet, not real Create composition.
**Related:** #535 issue Create UX; #533 Draft Edit/picker dependency; #536 Draft DB-only atomic nonempty Create dependency; #534 separate archival Custom write race; Linear TNYX-81 broad Backlog blocked by TNYX-78/TNYX-80.

## 1. Discovery
Goal: Tio-branded full Create Routine screen resembling the *interaction/structure* of user-supplied dark references, **not** an unlicensed/pixel-identical Hevy skin. Flow: existing Program Detail Add Routine → separate full Create screen → visible editable generated `Routine N`, top Cancel/Save, disabled Save with zero Exercises, empty-state hint/fitness icon, prominent Add Exercise. When a catalog/active owner Custom Exercise is chosen, insert a draft Exercise entry and automatically **Set 1**. Rows should visually group Exercises with their sets and allow removal and further editing. Cancel/Back before confirmed Create must not persist anything. Successful Create returns to Program and re-reads persisted canonical data.

**Default Set 1:** Existing `SetPrescription` requires positive fixed `reps`; approved minimal valid initial value is **reps=1**, optional loadKg/restSeconds **null**. UI must represent a real value, not falsely display “–” as though no Reps were persisted. This resolves the reference's empty Reps visual against current canonical schema without adding a new nullable-Rep type. User can edit this immediately. No restriction requiring user-entered reps beyond this initial valid default.

## 2. Runtime / Canonical Baseline
- Current `main@ee5ed4cc` `ProgramDetailPage._openCreate` opens `_RoutineNameSheet`; `ProgramRoutinesController.create` sends metadata-only INSERT, so it can persist a zero-Exercise Routine. Old clients remain compatible until separately approved rollout retires that access.
- Parent Draft #533 owns `RoutineExercisePickerPage`, `RoutineSetEditorSheet`, verified owner/session route patterns and separate Edit page. **Reuse**; do not copy a second Exercise catalog, picker, or session model.
- Draft #536 provides exactly one protected RPC `create_user_workout_routine_with_composition(p_routine_id,p_program_id,p_name,p_client_mutation_id,p_exercises)`, requiring non-empty Exercise entries; new Custom refs locked/validated active, same logical Routine metadata+composition transaction, stable UUID/mutation replay. No new tables/columns. It is **not merged or deployed**.
- Canonical existing `SetPrescription` is required fixed positive reps + optional loadKg/restSeconds; `RoutineCompositionEntry` and `RoutineCompositionSet` use immutable UUIDs. An Exercise with zero Sets is currently permitted, but approved UI calls for default Set 1 on selection.
- Root and feature `AGENTS.md`, Core theme README, .ai/FEATURE_DEVELOPMENT, ADR-0015, current Github/Linear status read. Use `package:tio_core/core.dart` and existing governed colors, sizing, typography and button/input components. No redesign of saved Routine Detail, card overflow Rename, or existing Edit Routine screen.

## 3. Bounded Approval / Decisions
- Approved: reference-inspired Create surface with visible editable Routine name, cancel/save, no-exercise empty state, Add Exercise, exercise selection, auto Set 1, Set manipulation via existing fixed-Reps/weight/rest editor; Save gated by valid Routine name, ≥1 allowed Exercise and auth/runtime capability.
- UI may include only currently backed fields; **no functioning Routine notes, per-Exercise Rest Timer, timed Set types, rep-range modes, supersets or image upload** without separate schema/product approval. Reference illustrations are UX direction, not proof those fields exist.
- Canonical Create writes must be one approved atomic RPC, never metadata-only INSERT then separate composition save; no local fake-success or privileged Flutter credential. The Create branch may be reviewed/tested while RPC undeployed but **must fail closed and must not merge/release or claim device E2E acceptance** until DB migration reviewed and approved for deployment.
- Preserve name-only Rename on existing Routines and readability of historical empty Routines. Preserve empty Programs and Program ownership.

## 4. Architecture and Security
Workout feature owns draft composition/controller, page and repository interface; Workout data adapter owns Supabase narrow RPC; `apps/app` supplies existing signed-in Supabase provider, scoped Program/session/cycle and navigator. Use owner A/B identity gate, exact login cycle at write, bounded Custom Exercise preflight as appropriate, cancellable read state and no double tap. Mutation and Routine UUIDs frozen for uncertain outcome; never silently replay a new token or create duplicate Routine. Confirm actual owner persisted state before “saved” when an ambiguous transport response occurs.

Rejected: invent second picker/Exercise definition model, two-step metadata Create + composition save (empty-orphan risk), fake “Save” with no backing RPC, adding advanced notes/rest schema, silently modifying existing Draft #533.

## 5. Planned Implementation / Quality Gates
- [x] Audit baseline code, root/feature/theme policy, GitHub #535, Draft #533/#536, Linear and live Supabase migration list.
- [x] Record owner approval, scope, dependencies and immutable Set 1 default.
- [ ] Implement bounded create draft state and atomic-RPC adapter tests in separate stacked branch.
- [ ] Implement Create screen with Core primitives and existing picker/Set modal, integrate Program Detail through account-keyed app shell.
- [ ] Tests: empty / one Exercise / remove-last Save gate; default Set 1; saved entry ordering and UUIDs; duplicate taps; cancel no write; authenticated owner switch; Custom archived during read; timeout / unknown Create and safe identical replay/read-only verification; kg/lb; compact/dark/text scaling/a11y.
- [ ] Exact-head Flutter/Dart Analyze+Tests, attribution and independent review. Independent current-head Codex review of #533 encountered usage limits; no substitute for exact-head review.
- [ ] Coordinate #536 merge and **separately explicit hosted deployment gate**, then real physical-device QA and owner acceptance before any Create UI merge.
- [ ] Reconcile narrow issue #535; broad Linear TNYX-81 remains Backlog/dependency blocked.

**Not validated:** GitHub CI on this branch, Android/iOS runtime, hosted RPC (not deployed), manual device UX, independent review, production merge. The connected session does not have the owner's Windows worktree/Flutter installation.
