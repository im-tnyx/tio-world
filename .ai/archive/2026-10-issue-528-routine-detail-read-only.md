# GitHub #528 — owner-scoped read-only Routine Detail (validated)

**Status:** Validated / merged on 2026-10-12; post-merge canonical status reconciliation is in a separate docs-only PR.
**Owner:** `apps/features/workout` (read controller/presentation), `apps/app` (provider/navigation composition)
**Tracking:** [GitHub #528](https://github.com/im-tnyx/tio-world/issues/528), [PR #530](https://github.com/im-tnyx/tio-world/pull/530); parent [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) still Backlog/dependency-blocked.
**Source:** PR #530 reviewed/tested HEAD `1c23bf1eba9a684912ebdeda8da8b9bf3a518b96`; squash-merged to protected `main@0c2a6cd07fea8b6426c8c7bf9b800bb8bf97479b` on 2026-10-12.

## Approval, scope and verified behavior

- Owner approved the bounded Routine-card **primary tap → selected Program/Routine read-only Detail** (2026-10-11), plus the subsequent bounded long-Set internal scroll treatment (2026-10-12). Existing anchored overflow **Edit → Rename** remains separate.
- App composition injects nullable persisted repositories. The Workout read controller checks the selected Program/Routine association, resolves revision-validated composition and canonical Exercise refs, and fails closed on missing capability, wrong owner, stale async reads, and repository errors. Auth/account transitions dispose prior-owner Detail data; unresolved Profile preference never reuses the previous account's kg/lb preference.
- Read-only ordered Exercises/Sets retain persisted Set/Entry identity. Ordinary cards remain inline through 40 Sets; larger Sets render with a 200dp bounded lazy inner viewport, without truncation. Existing Core `TioCard`, theme and normal visuals are reused.
- **Not included:** Routine composition builder/editor/picker, Workout Start, default `My Program` identity, app-store/mobile release, Supabase schema/RLS/RPC, new backend, watch integration, media/Storage or WorkoutSession execution.

## Exact-head validation and review

- [Flutter CI #38214540559](https://github.com/im-tnyx/tio-world/actions/runs/38214540559) **SUCCESS at `1c23bf1e`**: Flutter/Dart Analyze and Tests, including 1,007 Sets reached through lazy scrolling, long Exercise-list virtualization, compact dark baseline, owner/session transitions, stale weight units and failure/retry behavior. Trusted Tio attribution App guard and runner **SUCCESS**.
- Eight PR review threads were technically resolved, including source security/performance findings and canonical doc-status coordination. [Exact-head manual COMMENT review #5487743892](https://github.com/im-tnyx/tio-world/pull/530#pullrequestreview-5487743892) records evidence; latest-head Codex review was unavailable due quota. No independent human/Codex `APPROVED` review, physical-device visual QA, local Flutter execution or local `git diff --check` was claimed.
- PR #530 was merged only after explicit owner `Go merge with gate`, live exact-head CI/attribution/threads and GitHub clean mergeability were rechecked, and GitHub accepted the expected-head-SHA guarded squash merge. Branch-protection REST returned 403, so the exact configuration was not independently read; GitHub server enforced the merge operation.
- The earlier canonical screen mismatch was fixed through separate merged PR #523 (`main@c76e9e6a`). This post-merge docs slice corrects later stale 'PR #530 under review' statements without claiming a published mobile app release.

## Remaining boundaries

- W1/TNYX-78 and W3/TNYX-80 still gate broader W4/TNYX-81 acceptance; do not mark the parent epic complete because this read-only child slice merged.
- The owner must separately review/merge the post-#530 docs-only reconciliation and follow `.github/POST_MERGE_SYNC.md` to fast-forward the clean local Windows `main`. Do not infer remote branch deletion, local sync, production deployment or app release from the PR merge.
- Canonical current intent: [Program-owned Routines](../../docs/screens/routine-library.md), [Workout Library](../../docs/screens/library.md), [Supabase strategy](../../docs/data/SUPABASE_STRATEGY.md).
