# GitHub #250 — pre-P9 M5B canonical-current documentation correction

**Status:** In progress — PR review / merge gate pending (not merged)
**Primary owner:** repository documentation governance (`im-tnyx`)
**Affected platforms:** canonical Workout/Development docs and .ai execution handoff only

## Authorization and ownership
- **Explicit authorization:** owner “Go merge gate tak lekar jaye” on 2026-10-24 after read-only next-task audit.
- **Implementation owner:** `im-tnyx`; review is separate from implementation; no simultaneous source owner.
- **Owner approval trigger:** None for this documentation-only correction; does not start P9.
- **Base:** protected `main@04bf644bc026256f9a5a3537c4fdb66689e3c31d` (GitHub API; Windows checkout not accessed).
- **Branch:** `docs/issue-250-pre-p9-m5b-current-drift`; exact head/CI/review must be refreshed from live GitHub.
- **Tracking:** [GitHub #250](https://github.com/im-tnyx/tio-world/issues/250) Open; [Linear TNYX-193](https://linear.app/tnyx/issue/TNYX-193) In Progress; [GitHub #569](https://github.com/im-tnyx/tio-world/issues/569) Open.

## Discovery / source of truth
- PRs [#664](https://github.com/im-tnyx/tio-world/pull/664) and [#665](https://github.com/im-tnyx/tio-world/pull/665) merged M5B protected database and Flutter full Undo source.
- 2026-10-24 connected Supabase read-only recheck: 69 applied migrations, latest `20261024090000_m5b_atomic_create_move_full_undo`. Three Move/Create+Move/Undo `SECURITY DEFINER` RPCs exist with empty search paths; `PUBLIC`, `anon`, `authenticated` and `service_role` have `EXECUTE=false` for all three.
- GitHub `main` app source `apps/app/lib/app/composition/workout_providers.dart` has `routineMoveReleaseEnabledProvider = Provider<bool>((ref) => false)` and debug-only QA/preview opt-ins.
- [#569](https://github.com/im-tnyx/tio-world/issues/569) records owner-reported 5/5 isolated Android QA, not independently verified per-write/iOS/hosted release acceptance. R2 permission/grant and all-signed-in exposure decision remain open, as does separate #567 Program Delete.
- `docs/data/SUPABASE_SCHEMA.md` and `docs/data/SUPABASE_STRATEGY.md` already describe 69/69 hosted state accurately; do not edit those documents again.
- `.ai/tasks/issue-569-slice-1-post-merge-reconciliation.md` is an old in-review handoff from PR #662 (now merged); do not silently take over or bulk-refresh that separate ownership history. No active overlapping docs PR found at audit.
- Linear agent field notes endpoint returned “Tool get_agent_context not found”; live Linear issue was read separately.

## Bounded changes / non-goals
1. `docs/screens/routine-library.md`: change only the erroneous **current** 68/68/absent Undo statement and dependent current delivery gate; preserve explicitly historical checkpoints.
2. `docs/development/DEVELOPMENT_SETUP.md`: correct “M5B pending implementation” wording; keep debug isolated real-write QA vs preview vs hosted permissions distinct; flag that two-RPC isolated grant sample does **not** grant full Undo.
3. `.ai/tasks/README.md`: one compact active-task pointer, no historical rewrite.
4. This focused task brief. No runtime Flutter, SQL/migration, RPC, RLS, grant, CI/config, lockfile, P9 map, user data, or production-release changes. **No third-RPC grant instructions or privileged hosted mutation.**

## Quality / exact-head merge gate
- Review exact GitHub compare: branch starts at authorized protected main; ancestor, ahead/behind, full paths, no unrelated changes.
- Check docs semantic replacements, references, conflicts and whitespace; GitHub-hosted Docs Hygiene CI `git diff --check` is required as observed verification when available.
- Required App-pinned `Commit attribution guard` (App 5032971) must pass; review all additional actual check results and any concrete security findings without treating neutral statuses as approvals.
- Inspect formal GitHub review, unresolved inline threads and PR mergeability for the **exact head**.
- **Stop before merge.** Merge requires separate user “Go merge”; parent #250 and Linear TNYX-193 stay open/in progress until independent whole-catalog contradiction acceptance and P9 decision.
- No local Windows `git status`, Flutter tests or device QA claimed from connected GitHub API.
