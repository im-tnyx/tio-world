# #568 / TNYX-78 — Debug-only first-Routine QA capability

**Status:** In progress; review/merge pending.
**Primary owner:** Flutter app-shell; scoped GitHub implementation owner `im-tnyx`.
**Affected platforms:** Flutter Android/iOS debug builds only. No Wear/watchOS, database or production-release changes.

## Owner Approval and Scope Boundary
**Trigger:** None: bounded engineering/QA subtask of owner-approved #568 direct Library first-Routine Create. Owner asked to begin the next audited task through merge gate on 2026-10-22.
**Approved boundary:** Add a separately opt-in debug-only capability to test the *existing* canonical first-Routine flow against the already-granted owner-scoped RPC. Reuse existing app-shell Auth/bootstrap/login-cycle/pending-state preflight and Workout repository. Add focused regression tests and accurate QA instructions.
**Explicit non-changes:** `myProgramRoutineCreateReleaseEnabledProvider` remains hard false; no new UI, production/profile release enablement, new composer, schema/RPC/migration/GRANT, hosted write, real device QA assertion, Move/Undo activation, key/credential, automated test-account creation or release distribution. Do not merge without separate owner Go merge.

## Active Handoff
**Planning:** GitHub #568 and Linear TNYX-78; #569/TNYX-81 separately dormant.
**Implementation owner:** `im-tnyx` GitHub isolated branch; no ownership transfer.
**Review owner:** independent `im-tio` GitHub PR review, pending.
**Repository:** protected main `1352fa90d654606be42346906dc1bec6d96dd46e` verified via GitHub API. Branch `tnyx/issue-568-debug-only-first-routine-qa-20261022` forked at exact main; owner's Windows `git status` and local worktrees unavailable via connector, untouched.
**Supabase read-only:** Tio-tnyx hosted 68/68 migrations; first-Routine `authenticated EXECUTE=true`, Move RPCs `authenticated EXECUTE=false`; security advisor 10 authenticated-SECDEF WARNs, one password WARN and one private no-policy INFO.
**Tracker limitation:** Linear TNYX-78 and TNYX-81 are readable; `get_agent_context` API returned tool-not-found, so no unverified field-note claim.
**Prior test evidence:** owner-local 55 Workout plus 77 app-route tests passed at historical `main@ba611e7e` per #568 receipt. Not rerun in this session; no physical hosted real-write receipt.

## Discovery and Architecture
- `apps/app/lib/app/composition/workout_providers.dart` currently has hard-false first-Routine production provider and an inaccurate pre-hosted-grant comment.
- `apps/app/lib/app/routing/shell/shell_route.dart` guards the Library entry and in-flight Save with bootstrap owner, current Auth login cycle, Supabase SDK user and pending-command identity; retain all checks.
- Existing `apps/app/test/app/workout_exercises_route_test.dart` uses fake repositories plus explicit ProviderScope overrides for ACK, fail, UNKNOWN and auth revocation. Reuse, do not clone persistence logic.
- Choose a separate `kDebugMode && bool.fromEnvironment('TIO_FIRST_ROUTINE_QA', defaultValue:false)` read-only capability provider and compose it with production gating inside the existing shell. This is a QA *presentation* opt-in, **not an authorization boundary**. The hosted API already authorizes eligible permanent users; only owner-approved test accounts/devices should exercise it.
- Reject production flag flips, runtime server switch, hardcoded tester IDs, another builder/RPC, and profile/release testing claims. Existing iOS CI builds unsigned profile IPA and cannot exercise a debug-only gate or prove installability.

## Acceptance and validation plan
1. Normal debug without define: first-Routine action OFF; production release provider stays false.
2. QA capability: only opt-in debug mode; rejected for profile/release even when define is provided.
3. QA-only override uses existing Library route/first-Routine composer without overriding production release capability. Cancel is zero-write; Auth/login-cycle and UNKNOWN regressions remain covered.
4. Exact-head Flutter CI and attribution, independent review, complete changed-file/ancestry diff, owner native `git diff --check` where required. **Do not claim local tool validation if unavailable.**
5. Device QA with owner-approved test accounts remains separate, including real Save, A/B isolation, UNKNOWN, races, and Android/iOS signing/install.

## Final handoff
**Current:** [GitHub PR #654](https://github.com/im-tnyx/tio-world/pull/654) OPEN / Ready for Review; source/test implementation is committed and independent `im-tio` review is requested, not approved. Exact-head Flutter CI is in progress at the first inspection; attribution and Docs Hygiene checks passed at `5f3bc4c9`. GitHub remote branch comparison 2 ahead/0 behind with 7 scoped files. Local `git diff --check` and actual hosted/device writes have NOT run here. Product release NO-GO; no Supabase changes. Dated check outcomes need refresh for the final HEAD before claiming merge readiness.
