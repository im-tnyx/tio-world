# GitHub #569 / Linear TNYX-81: Debug-only REAL Move Routine QA gate

**Status:** In Review, unmerged; `im-tio` independent review has CHANGES_REQUESTED pending reviewer disposition. This brief is a dated **immutable verification snapshot**; [PR #655 live checks](https://github.com/im-tnyx/tio-world/pull/655/checks), [PR review threads](https://github.com/im-tnyx/tio-world/pull/655/files), and owner-native console receipts in PR discussion determine the **latest** exact HEAD gates. Do not interpret snapshot results as proof for a later HEAD.
**Implementation owner:** `im-tnyx`, scoped to #569 debug-only QA. Independent `im-tio` owns review, not source edits in this slice.
**Base:** `main@becb33bb09c05e1470375bb616cdf62d9f3f2c3d` (verified 2026-10-22).
**Approved scope:** Existing Program/Library Routine Move selector, confirmation, existing/new Program target, same-owner readback; debug-only real-write testing capability, no new UX/schema.

## Verified implementation scope and boundaries
- Read root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.github/PUSH_TEMPLATE.md`, ADR-0015 and relevant Workout docs/Linear/GitHub trackers.
- Production `routineMoveReleaseEnabledProvider` is hard `false`; `TIO_MOVE_ROUTINE_QA=true` requires `kDebugMode` as well as explicit opt-in. It only enables existing UI dispatch, not backend authorization.
- `TIO_MOVE_ROUTINE_UI_PREVIEW` still takes precedence if BOTH QA and preview flags are present, with **ZERO** database writes. Its Undo only dismisses a preview pill, not a real reverse Move.
- Existing Program Detail and Library share the authenticated owner/login-cycle-bound flow, pending Create arbitration, target revisions, protected existing/New Program adapters, UNKNOWN outcome handling and refresh.
- Hosted Tio-world last independently verified 68 migrations (latest `20261021130000`); **both Move RPCs remain EXECUTE-denied** to `authenticated`. Existing first-Routine #568 authenticated RPC has a separate grant; never borrow it or use a service-role client.
- No SQL, migrations, table/column changes, GRANT, production flags, real post-commit Undo, hosted writes, Android/iOS physical-device tests, test-user creation or UI redesign in this PR.

## Source and test acceptance
- Predicate truth table enforces debug AND explicit define; ordinary debug/profile/release builds remain OFF by default.
- Both Library and Program Detail test confirmed existing Program and atomic New Program Move via rejected fake gateway: no write before confirmation, exactly one attempted write after confirmation, no fabricated success.
- Separate cancellation tests for both entry surfaces assert zero writes; simultaneous QA+preview tests cover both Move paths and assert ZERO writes even after confirmation.
- Existing session revocation/owner switch and preview tests remain in the Flutter test suite. GitHub green CI does not prove hosted real writes or physical device behavior.

## Verified exact-head evidence snapshot (2026-10-22)

### Previously reviewed source HEAD `ec0203ddc02e6384d17d8fb6f5913a814bf3466e`
- Flutter CI [#39768006816](https://github.com/im-tnyx/tio-world/actions/runs/39768006816): **SUCCESS (5/5)**.
- Docs Hygiene [#39768006489](https://github.com/im-tnyx/tio-world/actions/runs/39768006489): **SUCCESS**.
- Attribution [#39768004084](https://github.com/im-tnyx/tio-world/actions/runs/39768004084): **SUCCESS**.
- Owner-native Windows `git diff --check`, base/HEAD ancestry and seven-file allowlist: **PASS**, [receipt #6339409338](https://github.com/im-tnyx/tio-world/pull/655#issuecomment-6339409338).

### Subsequently reviewed source HEAD `da66d1e0711c1ca361d53b004fa2b7f76cc8bffd`
- GitHub compare with base `becb33bb`: **11 ahead, 0 behind, 7 expected files**.
- Flutter CI [#39770507831](https://github.com/im-tnyx/tio-world/actions/runs/39770507831): **SUCCESS (5/5)**, including app-workout.
- Docs Hygiene [#39770507885](https://github.com/im-tnyx/tio-world/actions/runs/39770507885): **SUCCESS**.
- Attribution [#39770505425](https://github.com/im-tnyx/tio-world/actions/runs/39770505425): **SUCCESS**.
- Owner-native Windows base/HEAD check, ancestry, **exact seven-path allowlist** and `git diff --check`: **PASS**, [new receipt #6339712185](https://github.com/im-tnyx/tio-world/pull/655#issuecomment-6339712185). Owner provided actual PowerShell console transcript. GitHub connector did not execute local Git.

### Earlier source heads (historical only)
- `e2416b51`: earlier CI/Docs/attribution passed.
- `b06fefcb`: four additional QA Cancel/Preview tests; its Flutter CI run was **CANCELLED** when a later commit advanced the head.
- `7961675b`: Flutter [#39762892584](https://github.com/im-tnyx/tio-world/actions/runs/39762892584) 5/5 SUCCESS, Docs [#39762892613](https://github.com/im-tnyx/tio-world/actions/runs/39762892613) SUCCESS and attribution [#39762890250](https://github.com/im-tnyx/tio-world/actions/runs/39762890250) SUCCESS; superseded by later heads.

## Independent review and final merge conditions
- `im-tio` [review #5613145783](https://github.com/im-tnyx/tio-world/pull/655#pullrequestreview-5613145783) on `7961675b`, [review #5613350969](https://github.com/im-tnyx/tio-world/pull/655#pullrequestreview-5613350969) on `ec0203dd`, and its subsequent `da66d1e` review all have **CHANGES_REQUESTED** solely for stale handoff/owner receipt. No concrete implementation correctness defect was identified. Do **not** claim APPROVED or independently resolve the P2 threads.
- This **brief-only reconciliation is itself a new HEAD**. The latest SHA, required exact-HEAD CI and *matching* new owner-native `git diff --check` receipt must be read from [PR #655](https://github.com/im-tnyx/tio-world/pull/655) at final review time. An earlier SHA's PASS **never** establishes a later SHA's PASS. Keep future CI/receipt updates in the live PR evidence rather than repeatedly editing this immutable evidence snapshot and invalidating the validated head.
- Before a merge: exact-current-head CI/Docs/attribution PASS, base/HEAD seven-path allowlist and owner-native `git diff --check` PASS, independent reviewer re-dispositions blocking P2 threads with GitHub APPROVED as applicable, and **explicit owner `Go merge`**.
- The latest native receipt may be recorded in a PR comment; **no need to edit this historic snapshot again merely because CI finishes**. Any future *source correctness* or scope change needs normal updated validation and review.

## Downstream separate gates (not part of PR #655)
1. Review/audit both existing Move RPCs; separately stage least-privilege EXECUTE migration with owner/guest/replay/concurrency SQL regressions and REVOKE rollback, **without broad table grants**.
2. Separate owner-approved hosted deployment with migration ledger/security re-check and rollback readiness; production Move still OFF.
3. Approved authenticated physical Android/iOS debug QA on consenting isolated test accounts, including A→B/B→A, New Program atomicity, cancel, UNKNOWN, stale rev, cross-device races and auth switching. Debug opt-in is **not** a server-side test-user allowlist.
4. Separate approval/implementation for real five-second server-authoritative post-commit Undo and later production Move release.
5. #567 Program Delete → atomic reparent to canonical default My Program remains an independently reviewed and approved backend/confirmation slice.

**Final status: REVIEW.** PR #655 is not merged; neither source/handoff snapshots nor neutral bot statuses substitute for independent current-HEAD review or release authorization.
