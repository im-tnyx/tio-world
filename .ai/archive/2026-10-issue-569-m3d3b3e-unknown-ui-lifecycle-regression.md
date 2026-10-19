# GitHub #569 — M3D3B3e UNKNOWN feedback lifecycle regression

**Status:** Validated — 2026-10-19; [PR #616](https://github.com/im-tnyx/tio-world/pull/616) squash-merged.
**Implementation owner:** Workout presentation/widget tests — completed; no active source implementation in this slice.
**Planning / review:** GitHub #569 remains OPEN; Linear TNYX-81 remains Backlog with W1/TNYX-78 and W3/TNYX-80 blockers.
**Reviewed PR HEAD:** `45f7fa712ed6ab36252ab2dfd7eb7b61ebae4abc`.
**Protected main merge commit:** `8d25bde88f3de0d8b896b4a30d3312b1e92f7ee0`.
**Original branch:** `tnyx/issue-569-m3d3b3e-unknown-ui-lifecycle-regression` (historical, not the current branch).

## Discovery, owner approval and scope

GitHub #569 owner-approved Move UNKNOWN reconciliation includes accurate feedback, no blind retry, widget disposal and auth-cycle safety. The owner separately authorized PR #616 squash merge after its review gate. No new independently scoped product feature, product-visible UI, backend or schema change was authorized.

The merged slice was **test plus execution handoff only** (four paths): focused Workout widget tests, the prior B3d task handoff, this B3e brief and `.ai/tasks/README.md`. No production Flutter source, UI geometry, Supabase migration/RPC/grants/RLS, release toggle or real Undo code was changed.

## Verified behavior and coverage

- Atomic `Create & Move` UNKNOWN with no authoritative original mutation receipt remains unconfirmed, requests owner-guarded refresh, performs one atomic command and one verifier read, and never runs standalone Program creation or a second Move.
- Existing Move UNKNOWN readback resolving after originating-route disposal cannot surface a stale success/error snackbar. The final P2-corrected test preserves the root `MaterialApp` and live `ScaffoldMessenger` while replacing only the original route with a destination `Scaffold`; a positive-control snackbar proves the messenger survives. One original write, one readback and the attempted refresh signal remain.
- These are automated regression test results, not evidence of device QA or live permissioned Move writes.

## Quality gate — completed at the exact reviewed SHA

- [x] [Flutter CI #39248566192](https://github.com/im-tnyx/tio-world/actions/runs/39248566192): **SUCCESS 5/5** at PR HEAD `45f7fa71` (analyzer/Dart, app-workout, core-wear, nutrition-onboarding, aggregate).
- [x] [Commit attribution #39248385873](https://github.com/im-tnyx/tio-world/actions/runs/39248385873): **SUCCESS** at the same PR HEAD.
- [x] Codex **code review completed**, no findings, at `45f7fa71`; all **3/3 inline threads replied to and resolved**. Manual author-side review was COMMENTED, **not** an independent formal APPROVED; a separate automated security review was not claimed.
- [x] Owner `Go merge with merge gate` authorization, followed by standard GitHub squash merge (no branch-protection bypass).
- [x] [Protected-main post-merge Flutter CI #39249303687](https://github.com/im-tnyx/tio-world/actions/runs/39249303687): **SUCCESS 5/5** at the merge commit `8d25bde8`.

### Resolved review findings

| ID | Severity | Disposition and evidence |
| --- | --- | --- |
| [Route disposal / live messenger](https://github.com/im-tnyx/tio-world/pull/616) | P2 | Resolved: corrected source test `e3aa08cc`, final PR-head Flutter 5/5 PASS and thread resolved. Replaced vacuous whole-app unmount with real route replacement while a root messenger is alive. |
| [Task status drift](https://github.com/im-tnyx/tio-world/pull/616) | P3 | Resolved: status and exact-head gate evidence reconciled during PR, reviewer reply/thread resolved; this post-merge handoff records final actual outcome. |
| [Task index drift](https://github.com/im-tnyx/tio-world/pull/616) | P3 | Resolved: reviewer reply/thread resolved; final index row is reconciled in the separate docs-only post-merge handoff PR. |

## Final handoff and release boundaries

**Actual outcome:** B3e test-only regression slice **VALIDATED / MERGED**, not the entire Move Routine feature. GitHub #569 is still OPEN and parent Linear TNYX-81 Backlog. Current `apps/app/lib/app/composition/workout_providers.dart` still sets `routineMoveReleaseEnabledProvider=false`. The implementation-period live read-only Supabase audit showed authenticated Move EXECUTE revoked and atomic Create+Move RPC absent; no fresh hosted DB write/deploy or grant is part of this handoff. Real five-second reverse Undo is **planning acceptance only** and needs a separately approved bounded implementation.

**Verification environment:** GitHub connector and hosted GitHub Actions. No local Windows `git status`, worktree sync/cleanup, physical-device QA or production write performed or claimed. Follow `.github/POST_MERGE_SYNC.md` before local changes.

**Archive disposition (2026-10-19):** Validated child task archived at `.ai/archive/2026-10-issue-569-m3d3b3e-unknown-ui-lifecycle-regression.md` under the mandatory `.ai/archive/README.md` procedure. The active task index no longer treats B3e as active; the archive registry links to GitHub #569, PR #616 and the canonical Workout development setup. Parent GitHub #569 stays OPEN and Linear TNYX-81 stays Backlog; do not infer full Move Routine implementation or release.
