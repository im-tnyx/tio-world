# Issue #534 — Atomic Custom archive guard in Routine Save RPC

**Status:** In progress, unvalidated.
**Primary owner:** Supabase DB security implementation, this branch only.
**Platforms:** Supabase RPC; Flutter parity separately tracked.

## Approval and scope
Owner said "Go" on 2026-10-15 in response to explicit historical-preserving policy proposal. This is a security/correctness subtask, without table/column shape changes.
An existing archived Custom Exercise remains readable and may be retained unchanged (same original Routine entry UUID, Custom ref, Set UUIDs, values and Set order); user may edit other entries and remove an archived entry. New/replaced/modified archived refs are prohibited.
No Flutter UI/controller changes in this DB-only branch, no extra backend services, no production DDL, and no merge or cleanup of #551 or ancestor PRs.

## Verified source/runtime
- Read root AGENTS, Supabase strategy, canonical module ownership, issue #534 and W4 Linear context.
- GitHub main at 6a76011f10be1828b1dc661b2293de6ae41e775b contains migrations 20261013080000 (atomic Create) and 20261013120000 (nullable Set/RPC replacement).
- Live project has 55 migrations through 20261010061809; new source migrations are not hosted.
- Existing Save RPC is SECURITY DEFINER, owner scoped, checks user Custom owner/ref but does not lock/check active status.
- Existing Create RPC validates status='active' FOR SHARE; archive changes status using authenticated owner-scoped UPDATE.
- Save same-token replay comes before revision check, rich-field overwrite guard and full child snapshot replacement. Preserve that precedence.
- Owner tests 4–5 devices/emulators under multiple accounts; same-owner multi-session concurrency needs its own tests.

## Design
- New additive DB-only migration that replaces the existing narrow Save function, preserving signature, search_path, owner grants and replay.
- After replay + conflict gates and before destructive child DML: lock distinct incoming owner Custom refs FOR SHARE in stable UUID order. Reject foreign/missing with existing not-found code. Active refs allowed. Archived refs allowed only if original entry ID/ref and ordered normalized Set payload match persisted rows; reordered Routine entries allowed, reordered archived Sets forbidden.
- SQL matrix verifies active, archived unchanged, archived modified/new/replaced, foreign/missing, archived removal, other entry edit, replay after archive and no partial writes.
- Disposable two-session race script verifies archive vs Save serializes and cannot commit illegal archived entry.
- Add DB workflow steps; require full exact-head Supabase CI and independent security review before merging.
- Existing W4 Flutter Edit preflight rejects archived refs even when unchanged. That needs a separate bounded client correction before full UX acceptance; do not silently edit #551 here.

## Handoff
Implementation owner: Supabase security, single active branch.
Branch: security/issue-534-archive-routine-save (from exact main SHA above).
Worktree state: unavailable from GitHub connector; no local git status claimed.
Scope: this task file, new DB migration, new SQL/tests concurrency script, DB CI workflow.
Validation: not run yet; no production apply, merge, device QA, or review approval.
Next: implement and test, then open draft DB-only PR.