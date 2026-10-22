# GitHub #569 / Linear TNYX-81: Debug-only REAL Move Routine QA gate

**Status:** REVIEW. Independent `im-tio` re-review at `ec0203dd` verified owner-native diff receipt and 5/5 Flutter CI plus Docs/attribution; the remaining P2 was this task brief's stale pending-evidence wording. This brief-only correction advances HEAD and requires new-head CI, native diff receipt and independent re-disposition. Production Move is OFF; no merge approval.
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

## 2026-10-22 verified QA and independent-review reconciliation

- **Current implementation base, before this brief-only fix:** `main@becb33bb09c05e1470375bb616cdf62d9f3f2c3d`; [PR #655](https://github.com/im-tnyx/tio-world/pull/655) remains Ready for Review and **unmerged**. The prior/current-at-audit head `ec0203ddc02e6384d17d8fb6f5913a814bf3466e` is 10 commits ahead, zero behind, with exactly seven allowed changed files. **This documentation correction advances HEAD**: re-read the PR's actual new SHA and run checks there; no earlier SHA receipt can be relabeled as that new head's validation.
- **Verified predecessor-head `ec0203dd` CI results**, independently retrieved from GitHub (all **SUCCESS**):
  - [Flutter CI #39768006816](https://github.com/im-tnyx/tio-world/actions/runs/39768006816): **5/5 SUCCESS** (app-workout, nutrition-onboarding, core-wear, Analyze Flutter/Dart + Dart tests, aggregate Analyze and test).
  - [Docs Hygiene #39768006489](https://github.com/im-tnyx/tio-world/actions/runs/39768006489): **SUCCESS**.
  - [Commit attribution #39768004084](https://github.com/im-tnyx/tio-world/actions/runs/39768004084): **SUCCESS**.
  - Cursor neutral checks are NOT code-review approvals. Codex/Cursor Bugbot usage limitations are not passes.
- **Owner-run exact-predecessor-head native Git receipt has been obtained**, not pending. The owner supplied the actual Windows PowerShell transcript and [recorded it in PR comment #6339409338](https://github.com/im-tnyx/tio-world/pull/655#issuecomment-6339409338): `PASS: SHA, ancestry, 7-file scope and diff check`. Verified base `becb33bb09c05e1470375bb616cdf62d9f3f2c3d`, head `ec0203ddc02e6384d17d8fb6f5913a814bf3466e`, exact seven-file allowlist, `git diff --check` exit `0`. This was **owner-executed**, not a GitHub-connector shell command; a new native receipt is required after this brief-only HEAD change under repository policy.
- **Historical (superseded, not current):** `e2416b51` Flutter/Docs/attribution SUCCESS; `b06fefcb` added four QA-specific Cancel/Preview regression tests but its Flutter run was **CANCELLED** on subsequent head advancement; `7961675b` had Flutter CI [39762892584](https://github.com/im-tnyx/tio-world/actions/runs/39762892584) 5/5 SUCCESS plus [Docs Hygiene 39762892613](https://github.com/im-tnyx/tio-world/actions/runs/39762892613) and [attribution 39762890250](https://github.com/im-tnyx/tio-world/actions/runs/39762890250) SUCCESS.
- **Independent `im-tio` review [#5613145783](https://github.com/im-tnyx/tio-world/pull/655#pullrequestreview-5613145783)** on `7961675b`: `CHANGES_REQUESTED` for stale brief + missing owner native proof. Follow-up **independent `im-tio` review [#5613350969](https://github.com/im-tnyx/tio-world/pull/655#pullrequestreview-5613350969)** on `ec0203dd`: verified owner native proof, all CI, source correctness; **still `CHANGES_REQUESTED`, solely because this handoff document wrongly reported those proofs as pending**. Two older unresolved threads plus one new P2 documentation thread require independent disposition. Do not auto-resolve or pretend review approved.
- **Next actions, and ONLY pending review gates:** exact-new-HEAD GitHub CI (Flutter, Docs Hygiene, attribution), owner-native exact-new-HEAD `git diff --check` against the same base and seven-file allowlist, and `im-tio` independent re-review/threads disposition. Production release/device/backend grants are NOT part of this source-only PR and are separate downstream approvals; PR merge itself additionally requires explicit owner `Go merge`.
- **Hosted/security boundary remains unchanged:** both Move RPCs client `EXECUTE`-denied, production Move flag OFF, no schema/migrations/GRANT, no hosted writes, no actual Android/iOS device QA, no real five-second Undo.

**Final status: REVIEW** (open independent review gate). This brief truthfully records the predecessor-head validations; a fresh head is never declared CI-passed or owner-diff-checked until those checks actually run.
