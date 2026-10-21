# GitHub #568-B — Dormant direct Library Create Routine app-shell integration

**Status:** In progress, stop before merge
**Primary owner:** Workout Flutter app-shell / feature integration
**Affected platforms:** Android/iOS Flutter, no production enablement

## Owner Approval and Scope Boundary

**Trigger:** None, a bounded implementation subtask of owner-approved GitHub #568 and ADR-0015. User explicitly authorized work through the merge gate on 2026-10-21, but prohibited merge.
**Base:** protected `main@e213fa5710e9372f3326f6866ad5e2c36f0ae362`
**Branch:** `tnyx/issue-568-library-root-create-shell-20261021`
**Tracking:** GitHub #568; Linear TNYX-78 (In Progress), #569 / TNYX-81 remains blocked and release OFF.
**Implementation owner:** This scoped GitHub-connected session; no other source implementation ownership assumed.

## Discovery and Architecture

Read root `AGENTS.md`, feature AGENTS, workflow, PR/push templates, Core theme usage, ADR-0015, Workout library docs, #568/#569, active #568 composer/pending handoffs, current Flutter provider/shell/Library/page/controller/gate code and route tests.

Existing `CreateRoutinePage.forMyProgram` and `RoutinePendingCreateGate` already protect one frozen first-Routine transaction and uncertain outcomes. New Library-root entry must reuse them; no fake Program, client INSERT, duplicate composer or broad grants.

## Scope

- Add a separate hard-OFF first-Routine release capability and a session-bound nullable atomic adapter.
- Wire a dormant Library-root Create Routine action to the existing composer; fail closed without owner/bootstrap/Auth/SDK match or required repositories.
- Bind the pending mutation BEFORE dispatch; preserve uncertain state across account/login-cycle changes; support explicit owner-safe verification.
- Refresh owner-scoped Program and Routine lists after confirmed receipt or unknown exit, never equate a read refresh with RPC success.
- Add focused widget/app-route tests without changing existing Program-scoped Create behavior.

**Non-goals:** No `GRANT EXECUTE`, production exposure, hosted database write/deploy, SQL/table shape, Move/Undo, redesign, real-device QA, or merge/auto-merge.

## Validation and review

Pending exact-head GitHub Flutter CI, attribution guard, source/diff scope checks, independent `im-tio` review and owner-local native `git diff --check` receipt. GitHub connector cannot run Windows Flutter/Dart or inspect `G:\\projects\\Tio-World`. Never label these PASS before verification.

## Handoff

Stop at pre-merge gate; keep PR open. `#568` and TNYX-78 remain incomplete until separately authorized RPC activation and physical-device QA.