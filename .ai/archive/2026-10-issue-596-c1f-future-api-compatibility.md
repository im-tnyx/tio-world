# GitHub #596 C1F — Future Protected-API Compatibility Review

**Status:** Validated
**Completed / archived:** 2026-10-25
**Owner:** Repository AI Governance (docs-only C1F implementation)
**Affected platforms:** Engineering testing and change-review process only; Flutter, Wear, Supabase and future services runtime unchanged
**Primary tracker:** [GitHub #596](https://github.com/im-tnyx/tio-world/issues/596) — remains OPEN; its D1 quality measurement is still active

## Validated outcome (supersedes pre-merge handoff)

[PR #679](https://github.com/im-tnyx/tio-world/pull/679) was normal squash-merged into protected `main` on **2026-10-25T05:54:28Z**, without admin override.

- **Exact reviewed source HEAD:** `ad65e43157c250c6edd0dddc3dd67a598938d9cd`.
- **Verified squash/main commit:** [`90aed04fcbcbcc7e46f643bd390510a5e213562f`](https://github.com/im-tnyx/tio-world/commit/90aed04fcbcbcc7e46f643bd390510a5e213562f). Its only parent was `37f738c4a6788e3e997f1ab3938a2f6541f3644c`.
- **Exact merged paths:** `docs/development/TESTING_GUIDE.md`, `.ai/tasks/issue-596-c1f-future-api-compatibility.md`, and `.ai/tasks/README.md`; no app, SQL, RPC, CI, ruleset or service code changed.
- **Final-head CI:** required `Commit attribution guard` SUCCESS, `Attribution guard runner` SUCCESS, [Docs Hygiene job #121086491006](https://github.com/im-tnyx/tio-world/actions/runs/40165811198/job/121086491006) SUCCESS and actual `git diff --check` PASS on exact source HEAD.
- **Review evidence:** separate connected GitHub account `im-tio` submitted `APPROVED`, explicitly naming exact reviewed HEAD; 0 unresolved inline threads. This was assistant-operated technical review, **not** independent human security/compliance attestation. Copilot/Cursor quota/neutral outputs must not be counted as clean human reviews.
- **Post-merge state:** remote GitHub `main` verified at the merge commit. No owner Windows local checkout status, local sync or device validation was established.
- **Post-merge tracker:** PR #679's merge automatically closed #596, but #596 was promptly reopened and verified OPEN because D1 seven-day regression observations were not complete. See [post-merge receipt](https://github.com/im-tnyx/tio-world/issues/596#issuecomment-6394135235).

## Approved boundary and canonical result

**Owner instruction:** "Start work follow agent.md @Linear @Supabase @GitHub" on 2026-10-25 approved the bounded C1F docs-only implementation. A later explicit "Go merge" authorized the separate PR #679 merge.

Canonical rule owner: [`docs/development/TESTING_GUIDE.md` — Change-Time Future Protected-API Compatibility Review](../../docs/development/TESTING_GUIDE.md#change-time-future-protected-api-compatibility-review-affected-contracts-only). The check applies **only** to changed persisted identity/ownership, repository/DTO contracts, Supabase migrations/RLS/RPC, Auth/protected integrations and phone/watch sync; unrelated purely visual UI, docs and mechanical changes are exempt.

At change time, cite canonical domain owner, current Supabase adapter, stable business contract, authorization and impacted old-client/retry/failure behavior. Record one evidence-backed outcome: `N/A`, `Compatible + evidence`, or `Migration/follow-up required + issue`. **Do not promise future service portability without evidence.**

Source-backed examples in the canonical guide: [PR #674](https://github.com/im-tnyx/tio-world/pull/674) for privileged Move RPC grant/contract, where disposable Database CI passed but hosted wrong-owner/guest/JWT negative tests remain NOT RUN; and [PR #671](https://github.com/im-tnyx/tio-world/pull/671) for an exempt mechanical handoff/docs change with scoped hygiene evidence.

**Preserved architecture:** Supabase is current Auth/data/RLS/RPC owner; `supabase/migrations/` alone owns DB schema changes; ADR-0007 keeps `services/api` future-only and separately approval-gated; intentionally retained dormant `Remote*/HTTP` adapters are not removed or replaced. This review does not implement future services, migrations, native watch or mobile functionality.

## Remaining dependencies and evidence limits

- **D1 measurement:** 10 substantive cohort entries were recorded in [GitHub #596's evidence ledger](https://github.com/im-tnyx/tio-world/issues/596#issuecomment-6393903470); seven-day post-merge observation windows were still OPEN on 2026-10-25 (last matures 2026-10-31T17:31:09Z). Regression-rate conclusions and parent #596 completion are **not** C1F acceptance.
- **Hosted negative QA / privileged RPCs:** #569 retains the real hosted wrong-owner/guest/JWT authorization validation; #675 retains consolidated independent human security/privacy/compliance review before public launch. Neither was performed in C1F.
- **Linear:** targeted searches identified no dedicated #596 mirror. [TNYX-193](https://linear.app/tnyx/issue/TNYX-193) tracks #250 documentation governance, not C1F; no Linear issue mutation was performed.
- **Supabase:** C1F is documentation-only; no database query mutation, migration, grant, deployment or hosted QA was performed.
- **Audit boundary:** GitHub remote PR/main/review/CI and canonical docs establish the source result; the owner's Windows worktree was not accessible, so local `git status` / `git pull` were not performed by this assistant.

**C1F source-implementation outcome:** `PASS` / Validated and merged. This archive move is a separate docs-only handoff follow-up and requires its own GitHub PR exact-HEAD Docs Hygiene/review gates and owner-authorized merge. The original pre-merge "In review / PR OPEN" snapshot is historical and superseded.
