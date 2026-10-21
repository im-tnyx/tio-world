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

**Verified baseline** (2026-10-21, `f4c07a1483339405e9b11e611c2888e2cdb35966`): exact-HEAD GitHub Flutter CI run [#39567096629](https://github.com/im-tnyx/tio-world/actions/runs/39567096629) **5/5 SUCCESS**; exact-HEAD commit attribution run [#39567093527](https://github.com/im-tnyx/tio-world/actions/runs/39567093527) **SUCCESS**; bounded 8-file compare 12 ahead/0 behind; owner-provided clean-local-main, exact-HEAD ancestry and native `git diff --check origin/main...FETCH_HEAD` **PASS**. Owner-local terminal evidence was provided in chat and documented in the PR and Linear. This connector did **not** execute Windows tooling.

**Review remediation in progress:** `im-tio` [COMMENTED review](https://github.com/im-tnyx/tio-world/pull/645) on original exact HEAD (not APPROVED). One P3 inline finding identified that the test fake modeled the atomic first-Routine transaction as independently failing Program/Routine writes, without a definite server rollback regression. The implementation owner is correcting the test-only fake to make both rows visible in one synchronous in-memory commit, with a typed pre-commit rejection test asserting no default Program or Routine remains and a subsequent explicit Save succeeds. No production code or grant is changed in this remediation.

**Current PR-head gate:** Following P3 and handoff corrections, revalidate the **new exact HEAD** (Flutter CI jobs, attribution, eight-file scope, native owner `git diff --check`, independent review and P3 disposition). Old-head PASS receipts must **not** be claimed for the new HEAD. The current task stays **In progress / NO MERGE** until revalidation and an independent APPROVED review. GitHub cannot inspect `G:\\projects\\Tio-World`; production SQL/write QA and release remain deferred.

## Handoff

Stop at pre-merge gate; keep PR open. `#568` and TNYX-78 remain incomplete until separately authorized RPC activation and physical-device QA.