# #569 M3D2B1 — Dormant app-shell Move integration

**Status:** In Review — Draft PR #604 with exact source/test HEAD `57f77d2ab565eb460170adfad6486833b87bbaea` Flutter CI #39139696738 **5/5 PASS** + attribution **2/2 PASS**. Later task/index-only HEAD CI and independent review pending. No user-facing Move activation.
**Primary owner:** apps/app app-shell composition and routing
**Issue:** GitHub #569 / Linear TNYX-81
**Approval:** Owner requested "Next audit ke sath work start kare with agent.md" inside the approved Move #569 scope. This is NOT authorization for hosting/grants, activation or merge.
**Implementation branch:** `tnyx/issue-569-m3d2b1-dormant-shell-move`
**Verified base:** protected `main@11d5324fd44ff1c690417bfacf3005b02a865032`; merged PR #603 / post-merge Flutter CI #39138469849 5/5 PASS, no open PRs when branch was created. Current PR [#604](https://github.com/im-tnyx/tio-world/pull/604) Draft before review-ready gate.
**Local Windows checkout:** NOT observed from remote connector. Last user-provided local git status was pre-#603. No reset/stash/force-delete/local sync performed.

## Scope / truths

Root AGENTS, .ai/workflow, MODULE_OWNERSHIP, ADR-0015, Core theme README, canonical Routine Library, shell route, Workout Move flow/controller/repository, provider tests and GitHub/Linear reviewed fresh. Host read-only has **64 migrations**, atomic Create+Move RPC **absent**, existing Move authenticated EXECUTE **revoked**. Owner broader TNYX-81 Backlog (TNYX-78/80 dependencies). `.ai/tasks` M3D2A historical pre-merge snapshot is stale; live PR #603 merged.

Approved M3D2B1: compose the existing feature-owned `RoutineMoveFlow` and same-instance existing/atomic adapter in the app shell, with app-owned live Auth+login cycle+SDK owner and pending source-Create checks, including dialog/sheet revocation. Hook into both optional Move presentation callbacks **only behind a default-OFF app-owned release capability**. Reuse the existing `promptCreateProgramName` via `RoutineMoveFlow` (no new Create Program sheet or separate INSERT path).

No new UI geometry, screen, Create Program sheet, database/RLS, provider privileged grant, broad callback enabling or device release. No global Create/Edit/Delete mutation lock, destination/new-Program reconciliation or uncertain-result verification claims in this slice; M3D3 owns them. The true callback still means source reread request, not Move success.

## Architecture & controls

- Single app-shell callback shared by Program Detail and expanded Library. Feature stays unaware of Supabase/Auth.
- Opening owner/login cycle, Supabase SDK user and bootstrap owner must agree. Verify again before and during flow, after awaited dialogs and at RPC boundary; revoke stale sheets using existing `_guardRoutineOptionsSheet`.
- Existing `routineMoveRepositoryProvider` and `routineCreateMoveRepositoryProvider` MUST be the same instance and share the process-lifetime gate. Never fall back to ProgramRepository.create or two RPCs.
- A single default-OFF app-owned capability in production ensures Move remains hidden while hosted atomic RPC, RLS/grant, complete refresh, concurrent mutations and device QA are incomplete. Do not enable it as part of this PR.
- Both surfaces already have optional `onMoveRoutine` from merged PR #603.

## Quality gate

- [x] Implement guarded dormant app-shell coordinator and default-OFF capability, with mid-dialog release withdrawal recheck.
- [x] Add valid-auth release-OFF provider regression (existing tests retain owner/login-cycle and stale-adapter protection). Dedicated release-enabled end-to-end device/refresh tests are M3D3/release gates.
- [x] Source+tests `57f77d2a` Flutter CI #39139696738 5/5 PASS, attribution 2/2 PASS (7/7).
- [ ] Final docs-only HEAD CI and independent review.
- [ ] Independent inline review (P1/P2 disposition), separate explicit owner Go merge. GitHub branch protection enforced, no bypass.
- [ ] M3D3 full source/destination/new Program refresh and Create/Edit/Delete arbitration.
- [ ] Separate hosted atomic RPC/least privilege security rollout and Android QA.

**Handoff:** Implementation owner apps/app only; do not merge, activate Move, or mutate hosted Supabase in this slice.

## Latest verified quality checkpoint

Exact source+test HEAD `57f77d2a` CI **7/7 PASS**. Changed scope before handoff: `apps/app/lib/app/composition/workout_providers.dart`, `apps/app/lib/app/routing/shell/shell_route.dart`, `apps/app/test/app/network_providers_test.dart` and two `.ai/tasks` files. Review flag is default-OFF and checked during `sameSession`; UI callback remains null in production. No independent GitHub approval, no local Windows checkout verification, no actual Move RPC rollout.
