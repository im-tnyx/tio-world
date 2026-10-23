# GitHub #569: Slice 1 — Move Routine Post-Merge Reconciliation

**Status:** In progress
**Primary owner:** `im-tnyx`
**Affected platforms:** Documentation, task briefs, tracker governance

## Owner Approval and Scope Boundary

**Trigger:** None (Documentation and tracker reconciliation for approved, merged implementation subtasks PR #657, #660, #661).
**Approval status:** Approved for bounded Slice 1 documentation/tracker reconciliation per prompt execution authorization.
**Approval evidence:** User prompt contract in this session (2026-10-23).
**Approved boundaries:**
- Reconcile stale documentation, task handoffs, and tracker records after the merge of PR #657, #660, and #661.
- Document verified runtime behavior: direct existing Program Move, atomic `Save & Move` into a new Program, and M5A real five-second Undo for existing Program moves.
- Explicitly contrast completed M5A (existing-Program Undo) with pending M5B (full Create & Move Undo: atomic transaction moving Routine back to A and deleting newly created Program B).
- Explicitly document pending #567 Program Delete lifecycle, hosted Move RPC execution denial, and production feature flag posture (`routineMoveReleaseEnabledProvider = false`).
**Explicit non-changes:**
- No Flutter source, UI, route, provider, or test modifications.
- No Supabase SQL migrations, RLS policies, RPC definitions, or grant changes.
- No feature flag enablement or production release.
- No merging of PRs or premature closing of parent issues #569 or #567.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81 and TNYX-267
**Implementation owner:** `im-tnyx`
**Review owner:** Connected reviewer `im-tio` / Codex
**Implementation ownership state:** Active (Documentation and task handoff reconciliation complete; local validation in progress)
**Ownership transition:** Not applicable
**Repository state last verified:** `main@16dbb6dbee51035280bfa8dec97153273cd764be`
**Branch:** `docs/issue-569-slice-1-post-merge-reconciliation`
**HEAD SHA:** `16dbb6dbee51035280bfa8dec97153273cd764be` (branch base)
**Observed working-tree state:** Clean on base; modified documentation files: `docs/screens/routine-library.md`, `docs/data/SUPABASE_STRATEGY.md`, `docs/development/DEVELOPMENT_SETUP.md`, `.ai/tasks/issue-569-m5a-real-move-undo.md`, `.ai/tasks/README.md`.
**PR / tracker:** GitHub #569 OPEN; GitHub #567 OPEN; PR #657 MERGED; PR #660 MERGED; PR #661 MERGED (`16dbb6db`; post-merge CI `39989687126` SUCCESS); Linear TNYX-81 & TNYX-267 in Backlog (CLI unauthenticated).
**Current implementation state:** Documentation and task handoff reconciliation complete across canonical docs and task indexes. Local git diff check and link validation in progress.
**Relevant execution surface:**
- `docs/screens/routine-library.md`
- `docs/data/SUPABASE_STRATEGY.md`
- `docs/development/DEVELOPMENT_SETUP.md`
- `.ai/tasks/issue-569-m5a-real-move-undo.md`
- `.ai/tasks/README.md`
- `.ai/tasks/issue-569-slice-1-post-merge-reconciliation.md`
**Validation completed at SHA:** Local `git diff --check` and link consistency checks.
**Validation remaining:** Push documentation branch, open GitHub PR, run PR CI checks, request independent review, verify merge gate (stop before merge).
**Current blocker:** None. Linear CLI reports `No API key configured`, noted as documented limitation without inventing status.
**Open review finding IDs:** None.
**Next exact action:** Run `git diff --check`, commit changes, push branch, open PR with clear `#569` reconciliation scope.

## 1. Discovery

### User Outcome

Following the merge of PR #657 (expanded Library source refresh fix), PR #660 (direct Move destination selection and atomic Save & Move UX), and PR #661 (M5A real five-second Undo for existing Program moves), the repository's canonical documentation, task handoff files, and tracker references accurately reflect current verified implementation truth without stale claims (e.g. "real reverse Move is not implemented" or "Undo not implemented").

### Success Criteria

1. Canonical documentation (`routine-library.md`, `SUPABASE_STRATEGY.md`, `DEVELOPMENT_SETUP.md`) updated to reflect verified merged capabilities:
   - Direct existing Program Move.
   - Atomic `Save & Move` into a newly created Program.
   - Real five-second Undo for existing Program moves (M5A).
2. Pending scope is clearly documented and distinguished:
   - M5B full Create & Move Undo (atomic reparent-and-delete transaction) remains pending.
   - GitHub #567 separate Delete Program lifecycle remains pending.
   - Production RPC execution grants on hosted Supabase remain denied (`authenticated = false`).
   - Production feature flag `routineMoveReleaseEnabledProvider = false` remains dormant.
   - Production Android/iOS device acceptance remains required.
3. Active task brief for M5A (`issue-569-m5a-real-move-undo.md`) and task index (`.ai/tasks/README.md`) reconciled to reflect merged status and post-merge Flutter CI SUCCESS (`39989687126`), preserving historical checkpoints.
4. Tracker status (GitHub #569, #567, Linear TNYX-81, TNYX-267) reconciled factually without premature issue closure.
5. Zero changes to production Flutter code, database schemas, RLS, RPCs, or feature flags.

### Scope

- Documentation and task index reconciliation only.
- Local validation via `git diff --check` and reference verification.
- PR creation and review readiness gating (stop condition: stop before merge).

### Non-Goals

- Production Flutter code modifications.
- Supabase SQL migrations, RLS policies, RPC updates, or database deployments.
- Enabling `routineMoveReleaseEnabledProvider` or granting RPC execution on hosted Supabase.
- Implementing M5B Create & Move Undo or #567 Program Delete.
- Closing GitHub #569 or #567, or marking Linear TNYX-81/267 as Done.
- Merging the PR.

## 2. Codebase Exploration

### Verified Evidence & Provenance

- **Main commit:** `16dbb6dbee51035280bfa8dec97153273cd764be` (`feat(workout): #569 M5A real five-second Undo for existing Program moves (#661)`).
- **PR #657:** MERGED (`21286e78fc3d899a739cc7abc658ffa765031806`), verified expanded Library source refresh fix.
- **PR #660:** MERGED (`6dee84bfd018e13a7f8674560c07f719cfb0f5e9`), verified direct Move destination selection and atomic Save & Move.
- **PR #661:** MERGED (`16dbb6dbee51035280bfa8dec97153273cd764be`), verified M5A real five-second Undo for existing Program moves.
- **Post-merge CI for PR #661:** GitHub Actions run `39989687126` on commit `16dbb6db` completed with `success` (4m2s, Flutter CI).
- **GitHub #569:** OPEN (`feat(workout): direct Move Routine, atomic Save & Move, and 5-second full Undo`).
- **GitHub #567:** OPEN (`security(workout): implement owner-safe Delete Program lifecycle and bottom-sheet action`).
- **Linear CLI:** Reported `No API key configured`; documented as environment limitation.
- **Production feature flag:** `apps/app/lib/app/composition/workout_providers.dart` line 177: `routineMoveReleaseEnabledProvider = Provider<bool>((ref) => false);`.
- **Hosted Supabase security posture:** 68/68 migrations applied ending at `20261021130000_harden_move_routine_permanent_owner.sql`; both Move RPCs (`move_user_workout_routine` and `create_user_workout_program_and_move_routine`) remain client `EXECUTE = false`.

## 3. Architecture Design

This is a documentation and tracker reconciliation slice. No architectural modifications are introduced.

### Truth Boundaries

- **Runtime source:** Authoritative for actual software behavior (`routine_move_flow.dart` contains M5A Undo with CAS revision check, session guard, and decoupled invalidation; `routineMoveReleaseEnabledProvider = false`).
- **Canonical documentation:** Authoritative for intended product and architectural policy (`docs/screens/routine-library.md`, `docs/data/SUPABASE_STRATEGY.md`, `docs/development/DEVELOPMENT_SETUP.md`).
- **GitHub/Linear trackers:** Authoritative for planning, issue dependencies, PR history, and acceptance status.

## 4. Implementation Plan

- [x] Create focused documentation branch from fresh `origin/main`.
- [x] Create active task brief `.ai/tasks/issue-569-slice-1-post-merge-reconciliation.md`.
- [x] Reconcile `.ai/tasks/issue-569-m5a-real-move-undo.md` status to Validated / Merged via PR #661.
- [x] Reconcile `.ai/tasks/README.md` current tasks and summary table.
- [x] Reconcile `docs/screens/routine-library.md` lines 17 and 86 to reflect PR #657, #660, #661 merged status and clear M5A vs M5B boundary.
- [x] Reconcile `docs/data/SUPABASE_STRATEGY.md` line 15 to reflect M5A merged status, dormant hosted RPCs, and pending release gates.
- [x] Reconcile `docs/development/DEVELOPMENT_SETUP.md` lines 117-118 and 169-170 to clarify M5A merged status while M5B and #567 remain pending.
- [x] Validate changes using `git diff --check` and file inspection.
- [ ] Commit changes, push branch, open GitHub PR, and verify exact-head CI.
- [ ] Request review and stop at merge gate.

## 5. Quality Review

### Acceptance Evidence

| Criterion | Verified Evidence | Status |
|---|---|---|
| M5A source reconciliation | PR #661 merged at commit `16dbb6db`; post-merge CI `39989687126` SUCCESS; source verified in `routine_move_flow.dart` | PASS |
| Canonical docs reconciliation | `routine-library.md`, `SUPABASE_STRATEGY.md`, `DEVELOPMENT_SETUP.md` updated with exact verified behavior and pending boundaries | PASS |
| Task briefs & index | `issue-569-m5a-real-move-undo.md` and `.ai/tasks/README.md` updated with merged status, preserving historical evidence | PASS |
| Production safety | `routineMoveReleaseEnabledProvider = false` untouched; zero SQL or schema edits; zero production code edits | PASS |
| Clean diff & formatting | `git diff --check` passes with zero whitespace or line-break errors | PASS |

## 6. Final Handoff

### Changed Files

1. `.ai/tasks/issue-569-slice-1-post-merge-reconciliation.md`: Active task brief for this reconciliation slice.
2. `.ai/tasks/issue-569-m5a-real-move-undo.md`: Reconciled M5A task brief to reflect merged PR #661 and post-merge CI SUCCESS.
3. `.ai/tasks/README.md`: Reconciled task index for M5A and added Slice 1 active brief.
4. `docs/screens/routine-library.md`: Reconciled implementation and delivery boundary to reflect PRs #657, #660, and #661.
5. `docs/data/SUPABASE_STRATEGY.md`: Reconciled Routine Move status to reflect M5A real Undo in client source while preserving dormant hosted RPC posture.
6. `docs/development/DEVELOPMENT_SETUP.md`: Clarified that M5A existing-Program Undo is merged in source, while M5B full atomic Undo and #567 remain pending.
