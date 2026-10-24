# GitHub #250: Hosted Supabase 69/69 Canonical Doc Reconciliation

**Status:** Validated
**Archive date:** 2026-10-24
**Primary owner:** `im-tnyx`
**Affected platforms:** Documentation only; Supabase metadata verification is read-only.

## Owner Approval and Scope Boundary

**Trigger:** None, bounded documentation follow-up under #250.
**Approval status:** Approved by user request on 2026-10-24 for the bounded documentation correction through review gate; separate owner `Go merge with gate` then authorized the normal PR #670 squash merge on 2026-10-24.
**Approved boundaries:** Correct `docs/data/SUPABASE_SCHEMA.md`, `docs/data/SUPABASE_STRATEGY.md` and this focused handoff/index using current GitHub checked-in migration source and hosted read-only metadata.
**Explicit non-changes:** No SQL/migration/RLS/RPC/ACL mutation; no Auth, Flutter, Wear, source code, CI, lockfile or release flag change; no P9 work; no closure of parent GitHub #250 or Linear TNYX-193.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** `im-tnyx` (GitHub-connected branch, one bounded implementation slice)
**Review owner:** Distinct `im-tio` GitHub account formally `APPROVED` reviewed head `35f3ebed` on 2026-10-24. Review was assistant-operated and is **not independent human review**.
**Implementation ownership state:** Complete / validated; archive follows the verified GitHub merge.
**Ownership transition:** Not applicable.
**Repository state last verified:** Protected GitHub `main@76f693e757ebab2fe2e01b4dd3653582ba73d502` on 2026-10-24 after normal PR #670 squash merge.
**Branch:** `docs/issue-250-supabase-69-live-reconciliation`
**HEAD SHA:** PR #670 reviewed head `35f3ebed6d61b19fbf27cfe17a26166bc5d784a0`; squash merge `76f693e757ebab2fe2e01b4dd3653582ba73d502`.
**Observed working-tree state:** Local Windows working tree unavailable; do not claim clean local git.
**PR / tracker:** GitHub #250 Open; Linear TNYX-193 In Progress; #569 previous overlapping PR #662 already merged.
**Current implementation state:** Validated, merged docs-only correction; only the four approved Markdown paths were changed in verified squash commit.
**Validation completed:** Hosted read-only 69/69 migration name/version match, 19 RLS-enabled ordinary tables, 194 columns, 130 constraints, 55 indexes and protected RPC ACL inspection. Verified Flutter Move provider hard false. At exact PR #670 head `35f3ebed`: required App 5032971 Commit attribution guard SUCCESS; Attribution guard runner SUCCESS [run 40085156644](https://github.com/im-tnyx/tio-world/actions/runs/40085156644); Docs Hygiene SUCCESS [run 40085158255](https://github.com/im-tnyx/tio-world/actions/runs/40085158255) including hosted `git diff --check`; 0 unresolved review threads; `im-tio` GitHub `APPROVED` ([review 5637891879](https://github.com/im-tnyx/tio-world/pull/670#pullrequestreview-5637891879)); GitHub `mergeable_state=clean` pre-merge. The protected main squash SHA, merged status and four-file scope were verified post-merge.
**Validation remaining:** None for this completed docs-only slice; parent #250 whole-catalog contradiction acceptance and P9 remain separately gated, not validated.
**Current blocker:** None for this archived slice. Windows local checkout sync/clean status, feature-branch cleanup and post-merge-main CI were **not observed or performed**. This session used the verified hosted Docs Hygiene check, not a claimed local git run. Linear issue itself was readable; `get_agent_context` endpoint was unavailable.
**Open review finding IDs:** None at branch creation; reconcile live PR.
**Next exact action:** None for this slice. Parent #250/TNYX-193 remains Open/In Progress; audit remaining catalog contradictions and make separately authorized P9 routing-map decision. Do not infer closure from PR #670.

## Evidence

- Checked-in `supabase/migrations/` and linked hosted applied ledger: 69/69 exact version/name parity through `20261024090000_m5b_atomic_create_move_full_undo`.
- Hosted `pg_catalog`: 19 public ordinary tables, RLS 19/19, 194 columns, 130 constraints, 55 indexes.
- Program table has 3 new nullable UUID provenance columns and the coherent-provenance CHECK.
- `create_user_workout_program_and_move_routine`, `move_user_workout_routine`, and `undo_create_user_workout_program_and_move_routine` are present with `SECURITY DEFINER` and empty `search_path`, but EXECUTE=false for `PUBLIC`/`anon`/`authenticated`/`service_role`. The #568 first-Routine RPC is separately authenticated-executable.
- Flutter source `apps/app/lib/app/composition/workout_providers.dart` keeps `routineMoveReleaseEnabledProvider = false`.
- These observations do not prove production release, body-equivalence audit, real-write QA, or safety of issuing grants.

## Validation and Handoff

**Changed paths:** `docs/data/SUPABASE_SCHEMA.md`; `docs/data/SUPABASE_STRATEGY.md`; `.ai/tasks/README.md`; this task brief.
**Checks:** Exact-head GitHub Docs Hygiene, required Commit attribution guard and attribution runner SUCCESS; latest reviewed HEAD `35f3ebed`. Formal distinct-account assistant-operated APPROVED with 0 unresolved threads; squash merge verified at protected `main@76f693e7`. No local Windows git command or post-merge-main CI claimed.
**Final status:** **PASS for this docs-only slice**. Parent GitHub #250 remains Open, Linear TNYX-193 In Progress. The canonical public schema inventory and platform strategy were updated by PR #670; P9 and whole-catalog acceptance remain uncompleted. No SQL migration, RLS, RPC, ACL, UI, Flutter, feature-flag, device QA or production activation change in the slice.
**Canonical reference:** [Supabase public schema inventory](../../docs/data/SUPABASE_SCHEMA.md) and [Supabase strategy](../../docs/data/SUPABASE_STRATEGY.md). **Merge evidence:** [PR #670](https://github.com/im-tnyx/tio-world/pull/670) and [squash commit](https://github.com/im-tnyx/tio-world/commit/76f693e757ebab2fe2e01b4dd3653582ba73d502).
