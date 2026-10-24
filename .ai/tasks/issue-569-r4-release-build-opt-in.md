# GitHub #569 R4 — Opt-in Move release-candidate build gate

**Status:** R4 source fix prepared; exact-current-head CI and draft review gate pending. No public release.
**Owner:** `im-tnyx` app composition; single active implementation slice
**Affected surface:** Flutter Android/iOS build configuration + existing Workout Move UI wiring; test-only CI
**Tracking:** [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569), [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81/w4-programs-and-routines-canonical-content-composition-and-builders), [#675 deferred human review](https://github.com/im-tnyx/tio-world/issues/675)

## Owner Approval and Scope Boundary

**Trigger:** Continuation of owner-approved #569 Routine Move release activation. Owner said `go start kare work` after reviewing R3 hosted deployment and discussion of R4 controlled QA/activation. The existing Move/Save & Move/Undo UX contract (2026-10-23) is owner-approved. This is **not** a request or permission to redesign UI.
**Approved bounded slice:** Replace hard OFF Flutter release gate with a **compile-time explicit opt-in** using `TIO_MOVE_ROUTINE_RELEASE`. Default remains `false`. This permits an **intentionally opted-in internal QA/release-candidate build** to exercise the already implemented Move/Undo paths and existing UI without requiring the debug-only QA define. No existing production/default build is silently enabled.
**Non-goals:** Do not publish a store binary, distribute a public build, flip default to ON, migrate/modify hosted Supabase, alter RPC/RLS/Auth/table schema, add UI controls, change Move behavior or Delete Program #567, create remote feature-flag infrastructure, or claim hosted JWT negative-path QA passes without credentials and actual result.
**Approval:** Existing #569 UX and user's latest explicit R4 start direction; later **public release/store rollout remains separately owner-gated**, including final UI acceptance.

## Discovery / Source Truth

- Base `main@9e883c690fc5ca84f2f00e32c0b1489664dd1d1c`; source PR #674 MERGED. Root `AGENTS.md`, feature workflow, app composition, Flutter CI and app Workout route tests inspected.
- Hosted Supabase read-only ledger: **70 applied**, latest `20261024120000`. All three protected Move/Create+Move/Full Undo RPCs `authenticated EXECUTE=true`, `anon=false`. Database client ACL is **live** despite Flutter OFF.
- At verified base, `apps/app/lib/app/composition/workout_providers.dart` hard-coded `routineMoveReleaseEnabledProvider = false`. The R4 branch replaces only this app-shell release gate with a default-false build-time opt-in, retaining separate `kDebugMode && TIO_MOVE_ROUTINE_QA` and debug preview that prevents writes.
- Existing app-level `workout_exercises_route_test.dart` has two entry-surface default OFF tests, enabled test override, auth-session revocation, zero-write preview and debug-QA guards. Preserve them.
- Current canonical `docs/development/DEVELOPMENT_SETUP.md` documents **debug-only** QA and an earlier Option A isolated-hosted-denial checkpoint; that is historical after the explicitly user-applied R3 hosted grant. Do not mistake its stale prose for live ACL.
- Linear TNYX-81 and GitHub #569 retain historically stale statements that direct Move/Undo not implemented or hosted grants denied; merged source, hosted ledger and current owner-approved contract win.

## Architecture Decision

**Chosen:** Keep the **same existing** `routineMoveReleaseEnabledProvider` and consumers; read `const bool.fromEnvironment('TIO_MOVE_ROUTINE_RELEASE', defaultValue: false)` for build-time opt-in only. Ordinary app-workout tests assert **isFalse**; the opt-in CI test additionally passes an independent test-only `TIO_TEST_EXPECT_MOVE_ON=true` marker and explicitly asserts **isTrue**. Dropping only the production ON define cannot silently pass the ON test. Preserve existing route-level default-OFF regression.
**Rejected:** turning the provider permanently `true` before QA; adding remote config/feature service; widening the debug-only QA gate to release builds; duplicating feature provider state. These expand exposure/architecture prematurely.

## Quality and Release Acceptance

1. Default `flutter test` / ordinary debug/profile/release builds: production Move remains OFF unless **explicitly** opted in.
2. `flutter test --no-pub --dart-define=TIO_MOVE_ROUTINE_RELEASE=true --dart-define=TIO_TEST_EXPECT_MOVE_ON=true test/app/routine_move_release_gate_test.dart` asserts the **actual** app provider **ON independently of the release flag expectation**. CI runs in the app-workout shard as a separate bounded step; ordinary app-workout shard tests assert OFF. No JWT/remote writes.
3. Existing route tests (no build define) must still hide Move in both Routine entry surfaces and cover non-release auth/preview/QA.
4. GitHub `Flutter CI` all analysis/test shards + Docs Hygiene + required Attribution pass **on exact PR HEAD**. No local Windows Flutter commands were run from this connector.
5. Before any **public** ON build: authorized isolated/consenting QA users; hosted authenticated negative owner/guest/cross-account checks, expected Save&Move and full Undo, timeout/UNKNOWN, owner switch, device Android/iOS UI approval, and staged rollout/rollback; evidence and residual human review on #675/TNYX-40/TNYX-126.

## Handoff / validation

**Branch:** `tnyx/569-r4-release-build-opt-in` — created from pinned main SHA above.
**Scope paths:** `apps/app/lib/app/composition/workout_providers.dart`, `apps/app/test/app/routine_move_release_gate_test.dart`, `.github/workflows/flutter-ci.yml`, `docs/development/DEVELOPMENT_SETUP.md`, this brief, `.ai/tasks/README.md`.
**Validation checkpoint (2026-10-24):** Draft [PR #676](https://github.com/im-tnyx/tio-world/pull/676) created. Before review-finding fixes, exact HEAD `087ba14307a0c44e631fcf9c8eedcde982328085` passed [Flutter CI #40107734500](https://github.com/im-tnyx/tio-world/actions/runs/40107734500), including all app-workout/other shards, analysis, and ON-mode step; Docs Hygiene #40107734348 and attribution #40107733628 also passed. That initial ON test used the same define for its expected value and could falsely pass if the CLI flag disappeared. Manual GitHub inline [P2](https://github.com/im-tnyx/tio-world/pull/676#discussion_r4367666694) requested independent ON assertion; [P3](https://github.com/im-tnyx/tio-world/pull/676#discussion_r4367666696) requested current handoff/index reconciliation. **Both findings have a proposed source/documentation fix in this branch; exact post-fix HEAD checks are NOT YET VERIFIED as of this handoff edit.** Confirm live PR #676 exact-head checks, changed-file scope and review dispositions before declaring merge readiness. No local Windows Flutter or physical-device tests were run by this connected agent.
**Known limitations:** The CLI flag is a **build-time gate, not authorization or emergency remote kill switch**. Hosted API surface is already exposed; production usage cannot be made safe purely by hiding Move UI. Existing negative SQL/disposable PostgREST CI did not constitute new hosted JWT QA. A paid independent human review is **deferred to prelaunch** under #675 but real severe findings/required CI still actionable.
**Next:** Check the latest PR HEAD, confirm Flutter/Docs/attribution CI and separate ON assertion success, review inline P2/P3 fixes, reconcile thread dispositions and scope with GitHub main. Preserve draft/default-OFF and obtain explicit owner `Go merge` before merging. After code merge, controlled Android/iOS and hosted HTTP QA remain separate; normal public ON/store rollout requires final owner UI/release acceptance.
