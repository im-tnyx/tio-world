# GitHub #596 — C1 risk-based regression and review policy

**Status:** In progress (docs-only; PR review and exact-head validation pending)
**Primary owner:** Repository AI governance / developer experience documentation
**Affected platforms:** Documentation guidance only for Flutter phone, Wear OS, future Apple Watch, Supabase and future approved protected service

## Owner Approval and Scope Boundary

**Trigger:** None — process/testing documentation clarification, not a new product feature, visible UI/UX change or Supabase table/column change.
**Approval status:** Approved for this bounded docs-only C1 slice.
**Approval evidence:** Owner's `Go C1` in the conversation on 2026-10-20, following [#596 C0 tracker handoff](https://github.com/im-tnyx/tio-world/issues/596).
**Scope:** Add a concise risk-based validation/review matrix to the existing canonical `docs/development/TESTING_GUIDE.md`; add only a small link from the existing `.ai/FEATURE_DEVELOPMENT.md` process rule and an active-task index row if useful.
**Non-goals:** No runtime app/watch/backend, Supabase SQL/RLS/functions, Auth/health behavior, test implementations, test inventing, new CI/checks, branch protection, UI/UX, #250/#571/#580 policy ownership, wholesale agent-rule rewrite, automatic merge.

## Active Handoff

**Planning owner:** [GitHub #596](https://github.com/im-tnyx/tio-world/issues/596), completed C0 policy-level audit.
**Implementation owner:** This C1 GitHub connector docs-edit session only; no known competing C1 branch/PR writer observed.
**Review owner:** Not assigned; independent PR review to be requested if available.
**Implementation ownership state:** Active for C1 docs-only files; handoff at open PR.
**Ownership transition:** Not applicable — new C1 branch at verified main.
**Repository state last verified:** 2026-10-20, remote `main@b327a63a19b5f500cb8683880cb5b0f69ffabd01`.
**Branch:** `docs/issue-596-c1-risk-regression-policy`.
**HEAD SHA:** Initial branch `b327a63a19b5f500cb8683880cb5b0f69ffabd01`; consult live GitHub before claiming current-head checks.
**Observed working-tree state:** Remote GitHub API source and branch only.
**Observed uncommitted/dirty files:** Owner's Windows/local worktree is inaccessible; unknown, not claimed clean.
**PR / tracker:** Parent [#596](https://github.com/im-tnyx/tio-world/issues/596), C1 PR pending.
**Validation completed at SHA:** None for this new branch.
**Validation remaining:** Owner/runner exact-head `git diff --check origin/main...origin/docs/issue-596-c1-risk-regression-policy`, live PR changed-file and patch audit, required GitHub checks, review and findings dispositions.
**Current blocker:** No documented policy blocker; exact-head validation/review not yet done.
**Open review findings:** None observed yet; update on PR review.
**Next exact action:** Add smallest canonical risk matrix, narrow process pointer, inspect diff, open PR for independent review. No merge.

## Discovery and verified evidence

- `docs/development/TESTING_GUIDE.md` on `main@b327a63a19b5f500cb8683880cb5b0f69ffabd01` already defines test pyramid, Flutter/Dart/Wear commands, a generic area table and docs-only `git diff --check`.
- `AGENTS.md` security-sensitive validation and `.github/PUSH_TEMPLATE.md` already define required-vs-supplemental scanner and infrastructure-vs-concrete finding axes. Reuse, do not duplicate or weaken.
- `.ai/FEATURE_DEVELOPMENT.md` already defines evidence-based final status and case-specific negative/offline/accessibility tests.
- `.github/workflows/flutter-ci.yml` already contains analyze/test jobs plus aggregate `Analyze and test`; docs guidance cannot claim a named check is branch-required without live ruleset evidence.
- `docs/README.md` owns documentation authority; `docs/architecture/MODULE_OWNERSHIP.md` and `docs/data/SUPABASE_STRATEGY.md` own relevant scope boundaries.
- Linear search did not positively find a dedicated #596 mirror; TNYX-193 mirrors #250, not this issue.

## Acceptance criteria and scope-to-evidence map

| Criterion | Planned change | Required evidence |
|---|---|---|
| C1-AC01 | Risk matrix for docs, domain, UI/routing, phone↔watch, Auth/health/privacy, Supabase, future service | Read changed-file diff against main and verify class/negative-path specificity |
| C1-AC02 | No blanket costly tests; unknown/manual checks explain residual risk | Review conditional wording and DoD for required-vs-optional distinction |
| C1-AC03 | UI visual-scope, security tenant/fail-closed, scanner distinction preserved | Cross-check root AGENTS.md, PUSH_TEMPLATE.md and canonical scope |
| C1-AC04 | No runtime/CI/data files and no duplicated agent governance | Compare exact PR file list, targeted docs-only check |

## Review and final handoff checkpoint

**Review provenance:** Pending; no independent review is claimed.
**Validation:** Pending for final branch SHA. GitHub API diff inspection is not the owner's local `git diff --check`.
**Final status:** `REVIEW` while review/checks are pending; a known failed or un-runnable required check escalates the completion/merge gate to `BLOCKED` under `.ai/FEATURE_DEVELOPMENT.md`.
