# GitHub #521 — W4A Program-owned Routine metadata UI (validated)

**Status:** Validated / archived on 2026-10-11
**Owner:** `apps/features/workout` (presentation/controller), `apps/app` (navigation/provider composition)
**Source baseline:** protected `main@12999565d72915e0653116d6060d93e1e9cb10f5`
**Tracking:** [GitHub #521](https://github.com/im-tnyx/tio-world/issues/521) CLOSED; [PR #522](https://github.com/im-tnyx/tio-world/pull/522) squash-merged; [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) stays Backlog, blocked by W1/TNYX-78 and W3/TNYX-80.

## Owner approval and delivered scope

- **Approval:** 2026-10-11 owner "Go" in response to the bounded W4A Program Detail + Program-owned Routine List/Create/Rename proposal. Approval applied to this visible UI slice only.
- **Implemented:** Library persisted Program-name selection opens `ProgramDetailPage` with selected canonical Program identity; feature-owned `ProgramRoutinesController` lists/creates/renames only that Program's Routines via `RoutineRepository`; generated editable creation name; loading/empty/error/retry; safe unknown-result read reconciliation and stable UUID on one create attempt; app provider injects nullable `SupabaseRoutineRepository` and fails closed when unavailable.
- **Preserved:** Library Program chevron, overflow Program rename, Exercises entry and existing geometry. No competing Library Routine identity, no privileged client key.
- **Out of scope and still gated:** Routine Exercise/Set composition editor, Exercise picker, direct Library Routine quick-create/default `My Program`, Favorites/Folders, TrainingPlan, Workout Start, Program archive/delete/media/source adoption, new Supabase migrations/RPC and app release.

## Verification and review evidence

- PR source head: `e5bad053ef13fba3d4fb6620cdfc64b84140d307`.
- **Flutter/Dart Analyze and test:** [run 38155502675](https://github.com/im-tnyx/tio-world/actions/runs/38155502675) completed **SUCCESS** at that source head.
- **Required commit attribution:** [run 38155499922](https://github.com/im-tnyx/tio-world/actions/runs/38155499922) completed **SUCCESS** at that same head.
- Six original Codex P2 findings were corrected (input state, Program tap target, title ellipsis, abandoned-create UUID, authoritative rename reconciliation, screen catalog drift), replied to, and resolved (0 unresolved threads). The previously failing compact-width/2× text-scale overflow regression was fixed and verified by the passing exact-head Flutter run.
- **Review limitation:** an exact-final-head Codex bot review was unavailable due to usage limits; do not describe the result as Codex APPROVED/PASS. The explicit owner `Go merge with gate` followed a documented final read-only source/CI review and clean GitHub merge gate. No separate independent human approval was claimed.
- GitHub reports PR #522 merged, GitHub #521 closed, and `main` at exact squash SHA `12999565d72915e0653116d6060d93e1e9cb10f5`; owner subsequently verified local `main` matched `origin/main` and `git status -sb` was clean.

## Durable architecture and follow-up

- Program owns user Routine metadata and Composition; `apps/features/workout/lib/src/presentation/library/programs/` owns Program Detail while `presentation/library/routines/` owns the Routine controller. `apps/app` only composes providers/navigation. [Programs](../../docs/screens/programs.md), [Program-owned Routines](../../docs/screens/routine-library.md), [Library](../../docs/screens/library.md), and [ADR-0015](../../docs/adr/0015-program-owned-routine-and-program-source-boundary.md) are canonical.
- This archive closes only W4A. W4B Routine composition editor/picker requires a new separately owner-approved bounded slice. W1 default `My Program` identity still gates direct Library Routine create, but not editing a saved Routine selected inside its owning Program.
- No source/runtime/schema change or production write was performed by this historical archive reconciliation.
