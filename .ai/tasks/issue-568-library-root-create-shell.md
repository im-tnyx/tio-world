# GitHub #568-B — Dormant direct Library Create Routine app-shell integration

**Status:** Source MERGED (PR #645, 2026-10-21); first-Routine production release OFF / #568 open
**Primary owner:** Workout Flutter app-shell / feature integration
**Affected platforms:** Android/iOS Flutter, no production enablement

## Post-merge reconciliation (2026-10-21; current source status)

- **Merge verified:** [PR #645](https://github.com/im-tnyx/tio-world/pull/645) normally squash-merged into protected `main@598c0602c50002e0b6f9724883565e0c77229cc5` on 2026-10-21. Reviewed source HEAD `c97dd8d75d738926f0ca4497170261ec320322b8`, parent `e213fa5710e9372f3326f6866ad5e2c36f0ae362`; eight owned files. Earlier branch, in-progress review and NO MERGE language below is **historical pre-merge evidence**, not a current PR gate.
- **Exact-head pre-merge gates:** `im-tio` submitted independent formal **APPROVED** at reviewed source HEAD after P3 test-double rollback finding was corrected; its one inline thread was resolved. [Flutter CI #39574161558](https://github.com/im-tnyx/tio-world/actions/runs/39574161558) **5/5 SUCCESS** and [attribution #39574157794](https://github.com/im-tnyx/tio-world/actions/runs/39574157794) **SUCCESS**. Owner-provided guarded Windows native `git diff --check` **PASS** is documented in PR #645 and Linear TNYX-78; the connected GitHub tool did **not** execute that command.
- **Post-merge evidence:** [Flutter CI #39579199708](https://github.com/im-tnyx/tio-world/actions/runs/39579199708) **5/5 SUCCESS** at merge SHA.
- **Release boundary:** `myProgramRoutineCreateReleaseEnabledProvider` remains hard `false` in `apps/app/lib/app/composition/workout_providers.dart`. Hosted Supabase already has 66/66 migrations, including W1 `is_default` and the first-Routine RPC, but its `authenticated EXECUTE` permission is still denied. Merged source is **not** a live Create Routine release, actual-write Android/iOS QA, or release authorization. Move #569 stays OFF, and real 5-second reverse Undo remains unimplemented.
- **Tracking / next gate:** [GitHub #568](https://github.com/im-tnyx/tio-world/issues/568) stays OPEN, Linear [TNYX-78](https://linear.app/tnyx/issue/TNYX-78) remains In Progress, W4/TNYX-81 remains Backlog. Next is a separate minimal-grant/security and rollback preflight, followed by authorized Android/iOS real-write QA. No competing Routine model, UI expansion, new SQL/table/column, grant activation or new migration deployment is implied. See latest read-only #568 security preflight in GitHub #568 / TNYX-78.

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

## Historical pre-merge validation and review (superseded checkpoint)

**Verified baseline** (2026-10-21, `f4c07a1483339405e9b11e611c2888e2cdb35966`): exact-HEAD GitHub Flutter CI run [#39567096629](https://github.com/im-tnyx/tio-world/actions/runs/39567096629) **5/5 SUCCESS**; exact-HEAD commit attribution run [#39567093527](https://github.com/im-tnyx/tio-world/actions/runs/39567093527) **SUCCESS**; bounded 8-file compare 12 ahead/0 behind; owner-provided clean-local-main, exact-HEAD ancestry and native `git diff --check origin/main...FETCH_HEAD` **PASS**. Owner-local terminal evidence was provided in chat and documented in the PR and Linear. This connector did **not** execute Windows tooling.

**Historical review remediation (resolved before merge):** `im-tio` [COMMENTED review](https://github.com/im-tnyx/tio-world/pull/645) on original exact HEAD (not APPROVED). One P3 inline finding identified that the test fake modeled the atomic first-Routine transaction as independently failing Program/Routine writes, without a definite server rollback regression. The implementation owner is correcting the test-only fake to make both rows visible in one synchronous in-memory commit, with a typed pre-commit rejection test asserting no default Program or Routine remains and a subsequent explicit Save succeeds. No production code or grant is changed in this remediation.

**Historical PR-head gate (superseded by merged state):** Following P3 and handoff corrections, revalidate the **new exact HEAD** (Flutter CI jobs, attribution, eight-file scope, native owner `git diff --check`, independent review and P3 disposition). Old-head PASS receipts must **not** be claimed for the new HEAD. The current task stays **In progress / NO MERGE** until revalidation and an independent APPROVED review. GitHub cannot inspect `G:\\projects\\Tio-World`; production SQL/write QA and release remain deferred.

## Current handoff

The #568-B Flutter source slice has merged, but first-Routine production Create remains OFF and protected RPC `EXECUTE` remains denied. Keep GitHub #568 OPEN and TNYX-78 In Progress until independently reviewed minimal-grant activation, rollback and Android/iOS real-write QA are separately authorized and verified. GitHub #569 / W4 remains separately gated. This documentation correction does not authorize runtime changes.
