# #569 M3B1 — Feature-Owned Existing-Program Move Selection and Confirmation

**Status:** Draft stacked PR #598 against #597 controller branch. Initial isolated UI source `62900703` passed CI, but refactored controller-integrated UI source/test/docs is NOT yet validated together. No merge or activation.
**Primary owner:** Workout UI/confirmation on `tnyx/issue-569-m3b1-existing-program-move-flow`, stacked after controller implementation owner PR #597. One canonical dispatch owner: `RoutineMoveDestinationController` on #597; this UI MUST NOT implement a second independent Move dispatch.
**Affected platforms:** Flutter Workout feature presentation/tests and compact execution handoff only.

## Owner Approval and Scope Boundary

**Trigger:** None. Normal bounded subtask of existing owner-approved #569 Routine Move UI.
**Approval status:** Existing #569 approval (2026-10-15) covers destination selector and explicit confirmation.
**Approval evidence:** GitHub #569, ADR-0015, `docs/screens/routine-library.md`, user's Continue following verified PR #595 merge.
**In scope:** Reusable feature-owned Move selector/confirmation for a saved Routine going to a different existing Program; delegate inspection, destination recheck, one-use dispatch and cancellation generation guards to PR #597's `RoutineMoveDestinationController`; Core UI, cancel/unknown feedback and widget tests.
**Explicit non-changes:** No app shell callback/provider wiring, live Move button, SQL/GRANT/RLS/migration, direct Routine Program UPDATE, fake canonical My Program, + New Program/Create & Move, Program Delete, phone visual redesign, release or device QA.
**Gate:** Leave Move dormant in runtime. Add app-shell integration and cross-operation Create/Edit/Delete coordination only in later M3B2, with owned Program refresh and appropriate activation gate.

## Active Handoff

- **Planning owner:** GitHub #569 / Linear TNYX-81 W4 (broad Backlog, dependencies TNYX-78/80 unchanged).
- **Implementation owner:** Stacked UI-only scope on PR #598 after controller PR #597. Both branches had claimed M3B1 ownership at initial audit; now #597 owns destination verification/dispatch and #598 owns selector/confirmation. They must not merge independently or expose duplicated authorities.
- **Review owner:** Separate GitHub review/CI gate (not same as source author).
- **Implementation ownership state:** Active; review will follow code and CI.
- **Ownership transition:** M3A merged; #597 controls M3B1 destination validation and dispatch; #598 is now Draft, targets #597 as a stacked UI dependency and removes its duplicate dispatch. Integrated validation/merge requires the parent gate first.
- **Repository state:** Fresh remote protected `main@59a21ba305b3265aa8d903dc3f46ee397b39219f` after squash PR #595. GitHub had zero open PRs after merge. No local Windows checkout/dirty-state claims; source edits performed on remote new branch only.
- **M3A verification:** Pre-merge Flutter CI #39054363779 5/5 PASS plus attribution 2/2; post-merge main Flutter CI #39055475888 5/5 PASS, verified.
- **Supabase read-only state:** Hosted 64 migrations M1+M2C, Move RPC present but authenticated EXECUTE revoked, direct `UPDATE(name/program_id)` denied. No deployment or write planned.
- **Validation baseline:** Isolated pre-integration selector source `62900703` passed GitHub Flutter CI #39057336768 (5/5 Flutter jobs and both attribution checks), 9 initial widget cases. Current stacked source now imports PR #597 controller, delegates dispatch and adds a destination-deleted-before-confirmation widget test; this combination is NOT Flutter CI-validated because Flutter workflow triggers only for PRs targeting `main`. Do not attribute pre-integration green checks to it.
- **Blocking dependency:** #568 canonical My Program stable identity is not implemented; never use name matching or invent default. This slice limits destination selection to persisted owner Programs. Activation remains NO-GO.
- **Next action:** Resolve #597 controller merge gate first under explicit owner instruction, then retarget/reconcile stacked #598 against fresh protected `main`, run exact combined-head Flutter CI and close remaining P2 review threads only with validated evidence. M3B2 app-shell callback/refresh and Move EXECUTE remain OFF.

## Discovery → Exploration → Design

- Source: `ProgramRepository.list()` owner-filtered under `SupabaseProgramRepository`; `RoutineMoveRepository.inspect/move` is M3A server-CAS adapter with one-use, owner/cycle-validated target and unknown-outcome guard. Existing `RoutineDeleteFlow` is the closest ownership boundary for modal confirmation/status handling.
- Canonical `RoutineMetadataCard` exposes an optional `onMove` callback, currently unwired on both Program Detail and expanded Library. Existing sheets are `showTioEditorSheet` / `TioEditorSheet`, `TioCard`, `TioButton` and Core tokens.
- UI presents controller-verified destinations and explicit confirmation, delegates a one-use confirmed Move via #597 controller, preserves safe unknown/rejection feedback and a boolean list-refresh signal (not proof of commit). Tests include destination disappearing during confirmation (zero Move RPC expected).
- Reject a stale source Routine, owner/session change at awaits, invalid or duplicate Program IDs, nonexistent chosen destination or empty/failed owner Program list. Final RPC guards owner/source/revision/destination atomically.
- Do not promise synchronizing source/destination pages without later app-shell wiring; M3B2 must invalidate both after confirmation or uncertainty and guard Create/Edit/Delete pending sessions. Selection of canonical default depends on #568 only when its stable ID is real.

## Quality Review

**Pre-integration isolated source CI PASS** at `62900703`: five Flutter jobs and two attribution checks. **Stacked integrated source not CI-validated**; Flutter CI currently accepts PR target `main` only. Parent #597 exact source fix `056b0b56` passed CI #39058582339 with Workout 727 tests. Keep #598 Draft and its cross-PR P2 open until combined source on `main` base is tested. No deployed client Move or physical-device QA.

## Final Handoff

**Status:** PARTIAL — merged-parent+UI Git tree assembled at `38c180f`, with controller and selector in one executable source tree. Temporarily target `main` for an exact combined CI run, then restore the Draft stacked target #597; changing the base alone does not prove CI. No app activation, merge, client GRANT or deployment.
