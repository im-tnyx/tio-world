# Issue #534 — Atomic Custom archive guard in Routine Save RPC

**Status:** Implemented; disposable Supabase CI passed at 2026-10-15 checkpoint. Independent review, production rollout, and merge remain blocked.
**Primary owner:** Supabase DB security implementation, this branch only.
**Platforms:** Supabase RPC; Flutter parity separately tracked.


## Current verified gate — 2026-10-15 (supersedes initial draft checkpoints)

- **PR:** #561 Ready for Review, branch `security/issue-534-archive-routine-save`, base `main`; latest tested implementation head `d0c7a8416736a39fe862627c59b1dc23e33b5b06`.
- **Exact-head CI:** [Supabase Database CI #38718509800](https://github.com/im-tnyx/tio-world/actions/runs/38718509800) **SUCCESS**, and exact-head attribution guard + runner **SUCCESS**. Complete disposable migration replay, #534 SQL matrix, real two-session race and schema-lint regression checks succeeded.
- **Focused regression extension:** only `supabase/tests/database/tnyx_534_archived_custom_routine_save.test.sql` changed after previously green DB implementation head `664d830a`. The new SQL test protects #540 nullable `reps=NULL` Distance/Duration Sets during archived historical retention, same-token replay and unrelated edit; changed archived metric targets fail with zero partial writes.
- **Source diff security audit:** compared the replacement RPC to #540's immediate predecessor; differences were the scoped declarations and post-replay, pre-child-DML owner Custom `FOR SHARE`/archived historical Set-equality guard. No new role grants or table/column changes.
- **External truth:** Connected hosted Supabase remains **55 migrations** through `20261010061809`; #536/#540/#561 migration chain is not live. #551 consolidated Flutter latest tested head `a21c0e9c` is green but its 24 review threads include 18 unresolved; #559 requires owner-controlled 4–5-device APK/version inventory, old/new reader compatibility and same-owner device QA.
- **Outstanding gates:** independent security review/approval, branch-protection policy visibility (API 403), real-device/a11y QA, explicit hosted migration authorization, distinct app activation/merge approval. **No production DDL, merge, deployment, independent approval, or branch cleanup occurred.**
- **Review checkpoint:** https://github.com/im-tnyx/tio-world/pull/561#issuecomment-6189718074
- **Source environment:** GitHub connector; no local `git status` or local SQL command claimed. Latest CI was executed by GitHub Actions, not this agent's local machine.

### Historical notes below

Earlier unvalidated/pending-run descriptions document the original draft sequence and do not override the exact-head gate above.


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
Validation at initial draft: not yet run; current exact-head CI outcome is recorded above. No production apply, merge, device QA, or reviewer approval.
Next: implement and test, then open draft DB-only PR.

## Draft PR checkpoint
- [Draft PR #561](https://github.com/im-tnyx/tio-world/pull/561), based on main; this branch owns DB implementation only.
- Source head when draft opened: 49d5db715c6b696054b90038835fe130383700e6.
- Disposable Supabase DB CI: [run 38709360034](https://github.com/im-tnyx/tio-world/actions/runs/38709360034), pending; attribution pending at first check.
- Test files and workflow are committed; do not state validated until exact-head checks conclude.
- Live hosted migration ledger remains 55, through 20261010061809. New source #536/#540 and this #534 migration are **not hosted deployed**.
- Residual: Flutter #551 Edit preflight rejects legacy archived references; owner-approved UX needs a separate bounded Flutter parity correction, no UI redesign.
- Next exact action: check disposable CI logs, correct focused SQL/security findings, request independent PR review and then re-evaluate rollout/deployment gates. 
