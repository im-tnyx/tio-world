# GitHub #526 — Owner-scoped permanent Delete Routine DB-only slice

**Status:** In progress — SQL source and disposable CI pending; **not deployed**.
**Primary owner:** Workout persistence / Supabase security.
**Affected platforms:** Supabase Postgres only; Flutter/UI/Watch code unchanged.

## Owner Approval & Boundary

**Trigger:** New independent destructive persistence/feature task; **approved by owner** on 2026-10-16 via “Next to go” immediately following the exact Routine-only permanent Delete proposal. This authorizes a backend-only implementation/review, **not PR merge, production deployment or client UI release**.

**Approved lifecycle:** Delete exactly one user-owned persisted Routine and its owned Routine Exercise entries and Sets permanently after a separate Flutter confirmation. Preserve the owning Program, global/custom Exercise definitions, any actual prior WorkoutSession history and unrelated Routines. No Undo in the approved initial flow. Do **not** implement Delete Program #567 (which must reparent children), Move Routine #569 (same RoutineId between owned Programs), Change Picture, Play or new client permission.

**Owner clarification (interruption, 2026-10-16):** Saved Routine 3-dot targets **Edit Routine, Move Routine, Delete Routine** together. #569 separately owns Move; backend-only Delete cannot show a misleading Move/Delete UI. Current runtime uses TioAnchoredPopup for Routine, not the Program TioSheet; preserve without silent visual migration.

## Active Handoff

- **Planning:** GitHub #526 + #564; Move explicitly #569; Linear TNYX-81 (Backlog/blocked by TNYX-78 and TNYX-80). Source-of-truth ADR-0015; canonical `docs/screens/routine-library.md` is partly stale (calls merged/deployed #577 Draft and atomic #576 pending).
- **Implementation owner:** Receiving GitHub-connected implementation session for the same owner-approved #526 DB-only scope, 2026-10-16. Previous GitHub-connected implementation session → receiving session; remote branch `security/issue-526-owner-scoped-routine-delete-db` at `11d4a6a2a98c93d414f0cfa6696d50c38cb4c20a` verified before takeover. No observed new source commits after Codex P1 at this checkpoint. Source remains single-owner; do not run concurrent agents against this branch.
- **Takeover caveat:** The remote branch contains committed work only, but the Windows `G:\projects\Tio-World` worktree and its local dirty/untracked state are inaccessible here; no local checkout, sync or cleanup is claimed. Remote branch/current PR review/source was re-audited. The latest P1 about effective libpq host override is OPEN; all subsequent edits are confined to the already approved destructive *test harness / CI safety* remediation. Merge and hosted deployment still forbidden.
- **Parent:** `main@2fad164981ff4ab41cd3d493a5f3f2213d0c6af7`; zero open PRs verified at task start.
- **Observed working tree:** GitHub remote branch. Windows `G:\projects\Tio-World` checkout **not inspected**, so cannot claim local clean or synced after #577.
- **Review owner:** Independent review requested at exact source head after CI; Codex quota may be a blocker.
- **Approval caveat:** No new table/column shape. No authorized production DDL or data change.

## Runtime & Hosted Metadata Audited (read-only)

- Authenticated `DELETE` on `user_workout_routines`, `user_workout_routine_exercises`, `user_workout_routine_sets` all **false**, owner SELECT true; no current public/private delete Routine RPC, owner Routine RLS enabled.
- Composite owner FKs: Routine Exercise `(routine_id,user_id)` → Routine `(id,user_id)` ON DELETE CASCADE; Routine Set `(routine_exercise_id,user_id)` → Exercise `(id,user_id)` ON DELETE CASCADE. Program parent owns Routine through composite `(program_id,user_id)` FK. Only these existing live FKs reference Routine or child Entries. Future WorkoutSession/TrainingPlan retention must independently audit their physical relationship before adding those sources.
- Existing `composition_revision` is aggregate Name/Set version following merged+deployed #576. New Delete must acquire parent `FOR UPDATE` lock, require original revision, and serialize concurrent Name/Set edits. On stale source revision, fail; after completed delete, old Save/Edit cannot resurrect parent. Keep existing authenticated direct UPDATE(name) legacy path and old versioned RPC signatures untouched.
- `RoutineRepository` has list/create/rename, no Delete. Current 3-dot option is `TioAnchoredPopup` and contains only Edit Routine. Core already exposes destructive `showTioConfirmationBottomSheet`. Flutter UI will be a separate reviewed slice after this RPC deploy.

## Minimum Server Contract

- `public.delete_user_workout_routine(p_routine_id uuid,p_program_id uuid,p_expected_revision bigint) returns boolean`.
- Authenticated-only EXECUTE; SECDEF `set search_path=''`, `auth.uid()` required. Guard nonnull Routine/Program and nonnegative revision; select `WHERE id,user_id,program_id` FOR UPDATE to ensure owner and target, then compare exact aggregate revision and issue one protected parent `DELETE`. Return true iff exactly one targeted owner row was removed. Delete triggers existing FK cascades in same SQL transaction.
- Unowned, cross-Program, missing or already removed Routine → same not-found error. Stale revision → explicit conflict. Do not expose routine existence across owners. No client table DELETE grant, no global cascade/RLS changes, no storage/media delete and no new history delete.
- Unknown outcome client semantics (later Flutter): original RPC may commit despite network failure. Recheck signed-in same owner/login-cycle and the **Routine UUID across all owner Programs** to distinguish true deletion from a concurrent Move to another Program. Treat confirmed absence only with trustworthy owner read; if network/auth uncertainty persists do not claim success. Do not automatically issue a second destructive call after an ambiguous first response. Duplicate retry after completed delete returns not-found, never touches other Routines. No durable mutation log or new column for deletion replay.

## Proposed Checks

- [ ] Disposable full migration replay + existing Supabase regression matrices.
- [ ] Authenticated-only execute, anon/PUBLIC rejection and no direct authenticated table DELETE.
- [ ] Wrong owner, cross-Program, wrong ID/not-found, missing auth, malformed args.
- [ ] Revision CAS stale Name/Set edit and live concurrent lock race.
- [ ] Parent/Exercise/Set cascade and unrelated Routines, Programs, Exercise definitions preserved.
- [ ] Earlier 4-arg and 7-arg Edit RPC cannot resurrect deleted parent.
- [ ] Two-session in-flight Edit vs Delete; owner/auth switch reviewed for Flutter later.
- [ ] Post-merge hosted rollout as a separate explicitly authorized step; no live destructive test writes in production.
- [ ] Independent exact-head security review / all CI / no branch cleanup or merge without owner command.

## Source Ownership / Non-Goals

Only `supabase/migrations/*`, `supabase/tests/database/*`, additive `.github/workflows/supabase-db-ci.yml` test invocation and this short handoff. No `apps/**` UI, `docs/screens/**` visual design, new columns/tables, direct DELETE permissions or generalized Program/Move lifecycle. Future source/docs status reconciliation (#577 stale canonical brief) is separate governance work.

**Validation at start:** Hosted read-only schema/grants/FKs/ledger and GitHub tests inspected; no newly implemented Delete SQL run, no CI, no Codex verdict yet. **Status IN PROGRESS.**
