# W7B/W7C Pending Migration Timezone Remediation

**Status:** In progress — source validation complete; PR review pending
**Primary owner:** Codex
**Affected platforms:** Supabase Postgres; no Flutter changes

## Owner Approval and Scope Boundary

**Trigger:** None — correctness fix within the already approved W7 persistence slice.
**Approval evidence:** Owner's 2026-11-10 source-only timezone remediation request.
**In scope:** Correct timestamp instants and fixed 24-hour future windows in the three pending W7 migrations; extend existing W7 SQL tests; publish one reviewable PR.
**Out of scope:** Hosted migration execution, real authenticated hosted writes, schema shape or RPC signature changes, UI, W8, merge.

**Testing-only backup decision (2026-11-10):** Owner confirms no real Tio-World end users, approximately 4–5 test accounts, and disposable workout testing data. For this bounded W7 testing-only migration, owner defers backup as a deployment prerequisite. This does not change production backup/recovery policy in `docs/data/DATABASE_BACKUP_RECOVERY.md`, disable controls, or authorize database reset or deployment.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable — dedicated new remediation slice
**Last commit agent:** Pending
**Last commit SHA:** Pending
**Review owner:** Independent `im-tio` after PR publication
**Implementation ownership state:** Active
**Repository state last verified:** `G:\projects\Tio-World`; clean `main@0b4adfc4c2a7e4a456764294b1ee83f8d81e23f9` before branch creation; GitHub main matched.
**Branch:** `fix/w7b-w7c-timestamptz-timezone`
**PR / tracker:** TNYX-84 In Progress; no pre-existing open timezone PR found.
**Hosted state:** `tio-world` `oykupyiitspujzpwwvuj` ACTIVE_HEALTHY; no project branches; hosted migration ledger stops at `20261031142025`, before all three W7 migrations.
**Other applied history:** The existing persistent local Supabase database reports W7B version `20261106073920` applied. This PR does not attempt to replay the edited historical SQL there. Any use of that already-migrated local database requires a separately scoped forward-only corrective migration or an explicitly authorized disposable rebuild; do not assume source edits retrofit it.
**Current implementation state:** W7B/W7C `timestamptz` defaults, trigger/RPC updates use `now()`; Start lower bound is explicit UTC; Start and Save-only future windows use 24 elapsed hours. Existing local-date conversion unchanged.
**Validation completed:** Isolated local Docker Postgres 17.6.1 full migration replay PASS; W7B pgTAP 115/115, W7C metadata 28/28, Save-only 41/41; existing W7B six-race concurrency harness PASS. Exact-head CI and review pending.
**Next exact action:** Commit and publish focused PR, then verify exact-head CI and independent review. Stop before merge.
