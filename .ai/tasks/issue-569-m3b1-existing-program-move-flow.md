# #569 M3B1 — Feature-Owned Existing-Program Move Selection and Confirmation

**Status:** In progress — feature-owned presentation slice, no app activation.
**Primary owner:** Workout feature implementation on `tnyx/issue-569-m3b1-existing-program-move-flow`.
**Affected platforms:** Flutter Workout feature presentation/tests and compact execution handoff only.

## Owner Approval and Scope Boundary

**Trigger:** None. Normal bounded subtask of existing owner-approved #569 Routine Move UI.
**Approval status:** Existing #569 approval (2026-10-15) covers destination selector and explicit confirmation.
**Approval evidence:** GitHub #569, ADR-0015, `docs/screens/routine-library.md`, user's Continue following verified PR #595 merge.
**In scope:** Reusable feature-owned Move flow for an already-persisted owned Routine into a *different existing* owned Program; owner-scoped ProgramRepository list, M3A revision-frozen Move adapter, Core selector/confirmation, cancel, failure/unknown states and tests.
**Explicit non-changes:** No app shell callback/provider wiring, live Move button, SQL/GRANT/RLS/migration, direct Routine Program UPDATE, fake canonical My Program, + New Program/Create & Move, Program Delete, phone visual redesign, release or device QA.
**Gate:** Leave Move dormant in runtime. Add app-shell integration and cross-operation Create/Edit/Delete coordination only in later M3B2, with owned Program refresh and appropriate activation gate.

## Active Handoff

- **Planning owner:** GitHub #569 / Linear TNYX-81 W4 (broad Backlog, dependencies TNYX-78/80 unchanged).
- **Implementation owner:** This new remote M3B1 branch exclusively; M3A PR #595 is merged and no competing M3B PR was open when branch created.
- **Review owner:** Separate GitHub review/CI gate (not same as source author).
- **Implementation ownership state:** Active; review will follow code and CI.
- **Ownership transition:** M3A completed → new M3B1 owner; no overlapping source modifications.
- **Repository state:** Fresh remote protected `main@59a21ba305b3265aa8d903dc3f46ee397b39219f` after squash PR #595. GitHub had zero open PRs after merge. No local Windows checkout/dirty-state claims; source edits performed on remote new branch only.
- **M3A verification:** Pre-merge Flutter CI #39054363779 5/5 PASS plus attribution 2/2; post-merge main Flutter CI #39055475888 5/5 PASS, verified.
- **Supabase read-only state:** Hosted 64 migrations M1+M2C, Move RPC present but authenticated EXECUTE revoked, direct `UPDATE(name/program_id)` denied. No deployment or write planned.
- **Validated at current SHA:** No M3B1 source validation yet.
- **Blocking dependency:** #568 canonical My Program stable identity is not implemented; never use name matching or invent default. This slice limits destination selection to persisted owner Programs. Activation remains NO-GO.
- **Next action:** Implement feature-owned selector, explicit confirmation and mock/widget tests; verify PR CI at exact head, review, no merge until owner gate.

## Discovery → Exploration → Design

- Source: `ProgramRepository.list()` owner-filtered under `SupabaseProgramRepository`; `RoutineMoveRepository.inspect/move` is M3A server-CAS adapter with one-use, owner/cycle-validated target and unknown-outcome guard. Existing `RoutineDeleteFlow` is the closest ownership boundary for modal confirmation/status handling.
- Canonical `RoutineMetadataCard` exposes an optional `onMove` callback, currently unwired on both Program Detail and expanded Library. Existing sheets are `showTioEditorSheet` / `TioEditorSheet`, `TioCard`, `TioButton` and Core tokens.
- New feature-owned flow handles owner-visible destination list, independent selection, confirmation with Routine+destination name, same-Program avoidance, one RPC, safe unknown/rejection feedback and a boolean list-refresh signal (the boolean is **not** proof of a successful mutation).
- Reject a stale source Routine, owner/session change at awaits, invalid or duplicate Program IDs, nonexistent chosen destination or empty/failed owner Program list. Final RPC guards owner/source/revision/destination atomically.
- Do not promise synchronizing source/destination pages without later app-shell wiring; M3B2 must invalidate both after confirmation or uncertainty and guard Create/Edit/Delete pending sessions. Selection of canonical default depends on #568 only when its stable ID is real.

## Quality Review

**Pending.** GitHub CI and widget tests on exact M3B1 HEAD are required. No physical-device test/hosted Move execution can be claimed while EXECUTE remains revoked.

## Final Handoff

**Status:** PARTIAL until exact-head CI and review.
