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
**Review owner:** separate authenticated `im-tio` GitHub review account; formal COMMENTED at reviewed source SHA `1206e48aff29f32d178ae9f85fe41f5f3f10a0c5` with one P3 handoff-accuracy finding; not APPROVED. Review was assistant-operated, not separate human verification.
**Repository:** protected main `1352fa90d654606be42346906dc1bec6d96dd46e` verified via GitHub API. Branch `tnyx/issue-568-debug-only-first-routine-qa-20261022` forked at exact main; owner's Windows `git status` and local worktrees unavailable via connector, untouched.
**Supabase read-only:** Tio-tnyx hosted 68/68 migrations; first-Routine `authenticated EXECUTE=true`, Move RPCs `authenticated EXECUTE=false`; security advisor 10 authenticated-SECDEF WARNs, one password WARN and one private no-policy INFO.
**Tracker limitation:** Linear TNYX-78 and TNYX-81 are readable; `get_agent_context` API returned tool-not-found, so no unverified field-note claim.
**Prior test evidence:** owner-local 55 Workout plus 77 app-route tests passed at historical `main@ba611e7e` per #568 receipt. At PR source SHA `1206e48aff29f32d178ae9f85fe41f5f3f10a0c5`, GitHub Flutter CI 5/5 SUCCESS, Docs Hygiene and attribution SUCCESS. GitHub CI is not local Windows or physical hosted-write QA.

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

**Current review checkpoint (2026-10-22):** [GitHub PR #654](https://github.com/im-tnyx/tio-world/pull/654) is OPEN / NOT MERGED. Verified previous implementation HEAD `1206e48aff29f32d178ae9f85fe41f5f3f10a0c5` had **4 commits, 7 scoped files, 0 behind** `main@1352fa90`. Exact-source [Flutter CI 39729268310](https://github.com/im-tnyx/tio-world/actions/runs/39729268310) **5/5 SUCCESS**, [Docs Hygiene 39729268296](https://github.com/im-tnyx/tio-world/actions/runs/39729268296) SUCCESS (scoped Git diff hygiene), [attribution 39729266360](https://github.com/im-tnyx/tio-world/actions/runs/39729266360) SUCCESS. Cursor bot checks NEUTRAL, not security/independent approval.

**Review finding:** Separate authenticated GitHub reviewer `im-tio` submitted [COMMENTED review](https://github.com/im-tnyx/tio-world/pull/654) against that exact previous SHA: no P0/P1/P2 identified; P3 inline finding reports this task brief's formerly stale 2-commit/in-progress-CI prose. This bounded docs correction addresses P3. The PR HEAD after this correction is newer; **do not carry previous CI/review PASS forward as exact-current-HEAD validation**. Read the new HEAD, current checks, current thread status, and reviewer follow-up from GitHub before passing the gate.

**Validation not claimed:** Owner-local Windows `git status` / `git diff --check` on the updated PR HEAD, signed Android/iOS debug QA build, consented hosted real-write testing, two-device/UNKNOWN/account-isolation acceptance, or published release. Branch-protection API read returned 403, so current requiredness cannot be asserted from it. A QA build opt-in is not authorization. Production first-Routine provider remains hard `false`; #569 Move/Undo release remains OFF; no Supabase modification.

**Final status:** `REVIEW` pending new exact-head checks, P3 reviewer disposition and applicable owner-native/policy gate. **STOP before merge**; explicit owner `Go merge` is required. Keep GitHub #568 OPEN, Linear TNYX-78 In Progress and #569/TNYX-81 release-gated.
