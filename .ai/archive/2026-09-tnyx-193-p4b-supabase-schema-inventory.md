# TNYX-193 P4B — Supabase Public Schema Inventory

**Status:** Validated
**Primary owner:** repository documentation governance + Supabase data ownership
**Affected platforms:** documentation only
**Completed:** 2026-09-27
**Tracker:** GitHub #250 / Linear TNYX-193

## Outcome

P4B created the canonical human-readable inventory of the current Tio-world Supabase `public` schema at `docs/data/SUPABASE_SCHEMA.md`.

The inventory is explicitly non-executable documentation. Current database truth remains:

1. checked-in `supabase/migrations/`; and
2. verified live Supabase schema metadata.

The document must be refreshed when an applied schema migration changes the documented structure.

## Scope Boundary

Owner authorized P4B after a read-only audit.

P4B changed documentation/governance surfaces only. It did not mutate Supabase schema, migrations, RLS/policies, grants, Storage, Auth, Edge Functions, runtime/UI, CI workflows, lockfiles, P5/P6 governance headers, or P7 `.ai/CURRENT.md`.

The inventory intentionally excludes row counts, production/user data, secrets, sample personal records, and policy-by-policy RLS bodies.

## Final Evidence

- source base: `main@5faa41472be7fc2ad1fda88b637e566fb3ef7465`
- final reviewed source head: `ff60835a60c1f83735446a58cd5497e1d3aa4f13`
- source PR: #414
- squash merge: `fdb946e8aa3589e718c77e3004f94ed10ec41306`
- source net paths: 4
- live/repository migration parity: 49 / 49 by version + name
- active ordinary `public` tables: 14
- columns: 147
- catalog constraint records: 88
  - primary key: 14
  - foreign key: 14
  - unique: 4
  - check: 54
  - constraint-trigger: 2
- indexes: 39
- RLS enabled: 14 / 14 tables
- partitioned tables: 0
- views: 0
- materialized views: 0
- live metadata coverage against inventory: 14/14 tables, 147/147 columns, 88/88 catalog constraint records, 39/39 indexes
- local Markdown references checked: 65
- missing local Markdown references: 0
- row-count payload: absent
- exact patch scan: trailing whitespace 0; conflict markers 0; missing-final-newline markers 0
- net `apps/**`: 0
- net `services/**`: 0
- net `supabase/**`: 0
- net `.github/workflows/**`: 0
- lockfiles: 0
- Codex exact-head review: no major issues
- unresolved review threads before merge: 0
- Commit attribution guard: PASS
- Attribution guard runner: PASS
- supplemental `github-advanced-security`: FAILURE before meaningful analysis with `400 The requested model is not supported`; tracked separately under TNYX-256 and not represented as a security pass or concrete repository finding
- remote `main` verified at `fdb946e8aa3589e718c77e3004f94ed10ec41306` after source merge

## Tracker Reconciliation

After source merge automation temporarily completed the umbrella Linear issue:

- GitHub #250 remains open because P5/P6/P7/P9 remain separately gated;
- Linear TNYX-193 was restored to `In Progress`;
- P4B is marked completed in both trackers;
- no later phase is authorized by the P4B merge.

## Deferred Follow-up

P4B confirmed adjacent factual drift that was intentionally not bundled:

- `docs/data/DATABASE_BACKUP_RECOVERY.md` still states 24 applied migrations while the verified current count is 49.
- `docs/data/SUPABASE_STRATEGY.md` status prose still carries older owner-table wording that is not the current 14-table schema.

These remain separately bounded documentation-drift follow-ups.

## Final Status

`VALIDATED — MERGED VIA PR #414 (fdb946e8)`

No P5/P6/P7/P9 implementation is authorized by this archived handoff.
