# GitHub #569 / Linear TNYX-81: Debug-only REAL Move Routine QA gate

**Status:** REVIEW / P2 validation handoff. Independent `im-tio` review on `7961675b` requests changes solely for task evidence and owner-native `git diff --check`; source correctness was not rejected. This brief edit is a new commit and MUST receive fresh exact-head CI/re-review before merge.
**Ownership:** GitHub `im-tnyx` scoped implementation; separate independent review required.
**Base:** `main@becb33bb09c05e1470375bb616cdf62d9f3f2c3d` verified before branch creation (2026-10-22).
**Owner-approved behavior:** Existing #569 Move Routine selector, owner-scoped existing-Program and atomic New Program destinations; this is a bounded internal QA subtask, not a new product UX. No new tables or columns.

## Scope and source of truth
- Root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, ADR-0015, `docs/screens/routine-library.md`, current `apps/app` provider/shell, tests, GitHub #568/#569 and Linear TNYX-78/80/81 reconciled.
- Protected main already contains the Move repository, target controller, single confirmed dispatch, owner/login-cycle preflight, UNKNOWN reconciliation and Core 3-dot UI callbacks. Production `routineMoveReleaseEnabledProvider` is hard `false`.
- Hosted Tio-world has 68 migration versions (last `20261021130000`); both Move RPCs are SECDEF and `authenticated EXECUTE=false`. First-Routine RPC has different, independently scoped `authenticated EXECUTE=true`.
- Existing `TIO_MOVE_ROUTINE_UI_PREVIEW` is debug-only ZERO-write. Its preview Undo dismisses feedback, not a reverse Move.
- Local Windows checkout/status and physical Android/iOS devices are NOT accessible to this GitHub-connected implementation session.

## Decision and non-goals
- Introduce `TIO_MOVE_ROUTINE_QA=true` requiring both `kDebugMode` and explicit define; wire the existing two UI surfaces through the existing authenticated Move callback. The QA capability is presentation gating only, **not a server authorization control**.
- Preserve the production hard-false release provider. Existing preview remains ZERO-write and takes precedence whenever both QA and preview flags are present.
- Preserve all login-cycle, current SDK user, pending Create, destination checks, existing/New Program atomicity, unknown state handling, revision/CAS, and failure feedback; do not create a second Move composer or repositories.
- No SQL/migration/GRANT/hosted deployment, no production release, no client direct `UPDATE(program_id)`, no mobile UI redesign, no real post-commit 5-second Undo, no test users created, no actual hosted writes.
- Until a separately reviewed and owner-deployed grant exists, debug real Move attempts will be rejected at Supabase. **Do not distribute debug QA builds to ordinary users.**

## Validation requirements
- Predicate truth-table for debug/define combinations and default production OFF.
- App-route coverage with production release false + QA-only override from Program Detail and expanded Library: cancellation must dispatch zero writes, confirmed New Program Move must invoke the single existing owner-safe gateway, and failure must not be misreported as success. Added two explicit cancellation tests and two QA+preview priority tests for existing/new dispatch; assertions run in the exact-head Flutter CI, not through this remote connector.
- Preview-only behavior remains zero-write, even with QA opt-in. Same-owner re-login/auth-switch must revoke stale sheet write access; preserve existing regression coverage.
- `Flutter CI` exact-head including app-workout, `Docs Hygiene`, attribution and applicable branch gate checked on PR; independent reviewer must disposition findings. Owner-native `git diff --check` pending because connected GitHub API does not access `G:\\projects\\Tio-World`.

## Handoff / release plan
1. Submit this source-only PR and run independent review/CI. Do not merge without explicit `Go merge`.
2. Separately audit and stage exact-signature least-privilege EXECUTE grants for BOTH Move RPCs with SQL privilege and owner/guest/race regressions, including REVOKE rollback; new migration must be created using the repository Supabase CLI workflow.
3. Separately approve/deploy reviewed grants with `--skip-vault`, linked-project/migration preflight, backup/recovery decision and post-deploy ACL/Advisor verification. Flutter production Move stays OFF.
4. Authorized debug-device owners run authenticated real-write QA (A→B, B→A, New Program atomicity, idempotent retries, UNKNOWN, stale revision, second device race, owner switching, cancellation and 2 surfaced entry points) before production release approval.
5. Five-second post-commit Undo is a distinct owner-approval/implementation gate. Do not imply it exists.

## 2026-10-22 exact-head review and evidence reconciliation
- PR [#655](https://github.com/im-tnyx/tio-world/pull/655) is **READY FOR REVIEW, unmerged**. Base `main@becb33bb09c05e1470375bb616cdf62d9f3f2c3d`. On reviewed head `7961675b0461edde5c76affb6d7f9f88776ef6b7`, API compare showed 9 scoped commits, zero behind and exactly seven changed paths (the original allowlist in PR).
- **Verified checks on reviewed HEAD `7961675b`:**
  - [Flutter CI #39762892584](https://github.com/im-tnyx/tio-world/actions/runs/39762892584): **SUCCESS**, all 5 jobs (app-workout, nutrition-onboarding, core-wear, Analyze Flutter and Dart / test Dart, aggregate Analyze and test).
  - [Docs Hygiene #39762892613](https://github.com/im-tnyx/tio-world/actions/runs/39762892613): **SUCCESS**.
  - [Commit attribution #39762890250](https://github.com/im-tnyx/tio-world/actions/runs/39762890250): **SUCCESS**.
  - Neutral Cursor checks do not represent an approved code review. Codex/Cursor Bugbot usage limits were reported, not treated as passing reviewer verdicts.
- **Historical, NOT current:** Initial `e2416b51` exact-head Flutter/Docs/attribution passed; the test follow-up `b06fefcb` added QA cancellation (both entry surfaces) plus QA+preview zero-write (existing/New Program), and its Flutter run was **CANCELLED** when this task-brief commit advanced the branch. The later `7961675b` exact-head SUCCESS superseded these outcomes for review purposes.
- **Independent `im-tio` review [#5613145783](https://github.com/im-tnyx/tio-world/pull/655#pullrequestreview-5613145783)** at `7961675b`: **CHANGES_REQUESTED**, with two open P2 inline threads: (1) task-brief CI evidence stale, and (2) owner-native exact-head `git diff --check` receipt missing. Reviewer found no concrete source correctness defect. The first finding is addressed by this brief update; it is **NOT** considered resolved until reviewer disposition.
- **Required owner-native receipt still NOT obtained.** This connected GitHub session cannot run Windows `G:\\projects\\Tio-World` Git, so do NOT claim `git diff --check` was executed. The owner must inspect the refreshed final branch SHA, verify parent-to-head ancestry, exact seven-path allowlist and exit code `0`; post the receipt to PR #655. This new brief commit changes the HEAD again, so re-check the current SHA instead of using `7961675b` as the target.
- **Post-commit gates:** this documentation correction triggers a new HEAD; require applicable current-HEAD checks, owner-native diff receipt and independent re-review/re-disposition. Do not automatically resolve review threads, approve, merge, deploy or enable Move.
- **Hosted/release boundary remains unchanged:** No SQL/migration, GRANT, hosted test write, physical Android/iOS QA, real five-second Undo or production release. Both Move RPCs remain EXECUTE-denied to client roles and production flag hard false.

**Final status: REVIEW.** No completion, merge, deployment, production activation or owner-local verification claimed.
