# TNYX-232 / GitHub #283 — AI Co-Authored-By Attribution Guard

**Status:** In progress
**Primary owner:** repository governance / `.github/workflows`, `scripts/`
**Affected platforms:** None (governance/CI tooling only; no Flutter/Supabase/product runtime change)

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Governance/CI-guard implementation matches none of `AGENTS.md`'s three Owner Approval triggers (new independently scoped product/feature slice; unapproved product-visible UI/UX change; Supabase table/column shape change). Confirmed against the current `AGENTS.md` text during the prior read-only readiness audit.
**Approved product/UI/data-shape boundaries:** Not applicable.
**Explicit non-changes:** No `main` history rewrite, no force-push, no edit/recreation of PR #282, no removal of the existing historical Claude contributor attribution, no runtime/product/Flutter/Supabase behavior change, no unrelated branch-protection settings change, no merge of the resulting PR.

## Active Handoff

**Planning owner:** prior read-only audit pass (same session)
**Implementation owner:** current session
**Review owner:** Not applicable (pending PR review)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-22, fresh `git status -sb` / `git fetch` / `git pull --ff-only` before mutation
**Branch:** `tnyx/tnyx-232-ai-attribution-guard`
**HEAD SHA:** starting from `main` @ `b86bd3db4b3274c3ed6da02d5a6ea8f2afbd3b0c` (fresh-verified equal to `origin/main`)
**Observed working-tree state:** clean before branch creation
**Observed uncommitted/dirty files:** none
**PR / tracker:** GitHub #283 (open, unchanged), Linear TNYX-232 (`Backlog` → `In Progress` at implementation start)
**Current implementation state:** guard script, fixture tests, workflow, CONTRIBUTING.md remediation section, and this task brief created; local validation run; PR not yet opened at time of writing this section (updated below once opened)
**Relevant execution surface:** `.github/workflows/commit-attribution-guard.yml`, `scripts/check_commit_attribution.sh`, `scripts/check_commit_attribution_test.sh`, `CONTRIBUTING.md`
**Validation completed at SHA:** see Quality Review section below
**Validation remaining:** GitHub Actions execution of the new workflow itself (only observable once the PR is open); admin follow-up to make the check required
**Current blocker:** none for the code slice; the required-check/admin follow-up is a separate, explicitly out-of-scope step for this pass
**Open review finding IDs:** none yet (PR not yet reviewed)
**Next exact action:** open Draft PR, report status, stop before merge

## 1. Discovery

### User Outcome

A pull request targeting `main` that contains a prohibited AI `Co-Authored-By` trailer (Claude/Anthropic/Codex/OpenAI, or equivalent) in any of its commits is automatically flagged by a repository-wide CI check, without requiring any human reviewer to notice it manually, and without blocking ordinary human co-author trailers.

### Success Criteria

- A `pull_request` workflow runs on every PR targeting `main`, no product path filters.
- It inspects every commit in the PR's `base...head` range for prohibited AI `Co-Authored-By` trailers.
- It fails (non-zero) when a prohibited trailer is found, passes otherwise.
- Ordinary human co-authors, including a human literally named "Claude", are never blocked.
- A narrow, owner-controlled, PR-diff-external exception path exists.
- The detection logic is independently unit-testable (fixture-based), not only observable via a full CI run.
- The real historical PR #282 regression is proven detected by the new checker against real repository history, without mutating that history.

### Scope

- `scripts/check_commit_attribution.sh` — trailer-parsing detection logic.
- `scripts/check_commit_attribution_test.sh` — fixture-based regression test runner.
- `.github/workflows/commit-attribution-guard.yml` — thin PR-triggered workflow wrapper.
- `CONTRIBUTING.md` — remediation guidance appended to the existing "Commit attribution" section.
- This task brief.

### Non-Goals

- No `main` history rewrite, no force-push, no edit/recreation of PR #282.
- No attempt to remove the existing historical Claude contributor attribution.
- No runtime/product/Flutter/Supabase behavior change.
- No branch-protection/ruleset configuration change (owner/admin follow-up, separate step).
- No merge of the resulting PR in this pass.
- No `AGENTS.md` edits in this slice (the audit's Source-Of-Truth-list gap is a separate, optional, tiny governance cleanup — not bundled here).
- No PR title/body scanning in v1 (see Detection Scope rationale below).

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `CONTRIBUTING.md` (existing "Commit attribution" policy, lines 277-280 pre-change), `.claude/settings.json` (`attribution.commit`/`attribution.pr` both `""`), all 4 existing `.github/workflows/*.yml` (all path-filtered product checks, none inspect commit messages), `.github/CODEOWNERS` (fully commented out, no real owners), repository root (no `scripts/`, `tool/`, `tools/`, `Makefile`, `package.json` existed before this change), `melos.yaml` (Flutter/Dart scripts only).
- Fresh GitHub evidence: `gh api repos/im-tnyx/tio-world/rulesets` → `[]`; `gh api repos/im-tnyx/tio-world/branches/main/protection` → `404 Branch not protected`; `gh api repos/im-tnyx/tio-world/collaborators` → sole collaborator `im-tnyx`.
- Real regression evidence (fresh-verified via `gh pr view 282 --json commits,mergeCommit` and `gh api repos/im-tnyx/tio-world/commits/<sha>`):
  - PR #282 source commit `9b54488c3cfcabef29db059f6e1c801f8db9762f` — body ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
  - PR #282 source commit `3ad489fbe1b58b62df12d2daf8ed7f458c06bd7f` — body ends with `Co-Authored-By: Claude <noreply@anthropic.com>`.
  - Squash/main commit `13da1de59ad4980dc36ce6a9fbc3c206d1463224` message contains three trailer-shaped lines; `git interpret-trailers --parse` (git's own trailer-block semantics — a trailer block must be the message's true final paragraph) recognizes only the last one (`Co-authored-by: Claude <noreply@anthropic.com>`, appended by GitHub's squash-merge UI) as an actual trailer of the aggregate squash commit; the two embedded inside the squashed sub-commit bodies are mid-message text from git's parser's point of view, not trailers of the squash commit itself. This is exactly why detection must run pre-merge, against the real `base...head` commit range, not only against the final squash message.
  - Git author/committer of the two source commits is the repository owner account, not a distinct "Claude" git identity — the causal fact this slice relies on is only: prohibited AI `Co-Authored-By` trailers existed in PR commit messages before merge, and no automated guard existed to reject them, so the merge was allowed.

### Existing Pattern To Follow

- `.github/workflows/*.yml`: `permissions: contents: read`, `concurrency` group per workflow, `timeout-minutes`, `actions/checkout@v7`. Followed here.
- No existing `scripts/` convention in this repo (directory did not exist); introduced as portable POSIX-ish Bash, no new package-manager dependency, matching `AGENTS.md`'s "prefer existing patterns" together with the explicit "no Node/npm/pnpm dependency" instruction for this slice.

### Tests Or Validation Already Present

None prior to this change (no commit-message tooling existed in the repository).

## 3. Clarification

### Decisions Required Or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Detection scope = commit messages only (`base..head`), not PR title/body | Made | Regression is a commit-trailer regression; PR bodies may legitimately document literal prohibited example strings (this task brief and `CONTRIBUTING.md` do exactly that); scanning PR prose would create avoidable false positives. Tracked as a possible separate hardening follow-up if future evidence shows squash can independently synthesize attribution from PR-body trailer text. | This slice |
| Trailer parsing = `git interpret-trailers --parse`, not generic grep | Made | Matches real git trailer semantics (only the message's true trailing trailer block is recognized), naturally satisfies the boundary requirement that ordinary prose mentioning AI vendor names must not fail. | This slice |
| AI-name matching = exact known display-name list, not "contains claude" | Made | A bare human first name "Claude" must not be rejected; only exact known AI display identities (`anthropic`, `codex`, `openai`, `openai codex`, `claude code`, `claude sonnet`, `claude opus`, `claude haiku`) or a provider-domain email (`*@anthropic.com`, `*@openai.com`, including subdomains) are rejected. | This slice |
| Owner exception mechanism = repository Actions variable `AI_ATTRIBUTION_EXCEPTION_PR`, PR-diff-external | Made | Rejects the unsafe `ALLOW_AI_ATTRIBUTION=true`-in-PR pattern explicitly called out as unacceptable; a repo variable is only settable by an account with write/admin access to repository settings, external to the PR diff, and its change is visible in GitHub's own audit trail. | This slice |
| Required-check / branch-protection configuration | Deferred | Explicitly out of scope for this slice per the authorization; `main` currently has no branch protection or ruleset at all (fresh-verified), so this workflow cannot yet be a hard merge gate until an owner/admin follow-up configures it as required. | Owner/admin follow-up |

## 4. Architecture Design

### Chosen Approach

Option B from the prior audit: a small, dependency-light, testable detection script (`scripts/check_commit_attribution.sh`) invoked by a thin PR-triggered workflow (`.github/workflows/commit-attribution-guard.yml`), with a separate fixture-based test script (`scripts/check_commit_attribution_test.sh`) that the workflow runs before the real check and that a developer can also run locally with no network/GitHub dependency.

### Ownership And Data Flow

```text
pull_request (opened/synchronize/reopened, branches: [main])
  -> actions/checkout@v7 (fetch-depth: 0, ref: head.sha)
  -> bash scripts/check_commit_attribution_test.sh   (fixture regression suite)
  -> bash scripts/check_commit_attribution.sh <base.sha> <head.sha>
       -> git rev-list --reverse base..head
       -> per commit: git show -s --format=%B | git interpret-trailers --parse
       -> per Co-Authored-By trailer: match email domain / exact AI display name
  -> exit 0 (clean) | exit 1 (violation, no exception) | exit 0 (violation, exception PR matches)
```

### Alternative Rejected

- Generic substring grep for vendor names across the whole commit message: rejected — would false-positive on prose/docs mentioning the vendor names outside a real trailer (explicit boundary requirement).
- GitHub-native ruleset commit-message rule: rejected as the sole mechanism — fresh-verified zero rulesets exist, and native rulesets do not offer the nuanced trailer-key + domain/name matching this contract needs; still a useful supplementary Phase-9 admin step for making the check required, not a replacement for the script.
- Node/Python-based commitlint-style tooling: rejected per explicit instruction and repository pattern — no `package.json`/Node toolchain exists at the repo root; Bash + Git already present on the runner is sufficient.

### Failure And Accessibility States

Not applicable (no UI surface). CI failure state: the workflow step prints the exact offending commit short-SHA and the sanitized trailer name/email that triggered the failure, without dumping unrelated commit content.

## 5. Implementation Plan

- [x] `scripts/check_commit_attribution.sh` — trailer parser + AI-identity matcher, exits 0/1/2.
- [x] `scripts/check_commit_attribution_test.sh` — fixture-based PASS/FAIL/BOUNDARY suite, runs in a disposable temp repo.
- [x] `.github/workflows/commit-attribution-guard.yml` — repository-wide `pull_request` trigger on `main`, no path filters, minimum `contents: read` permission, runs the test suite then the real check, honors `vars.AI_ATTRIBUTION_EXCEPTION_PR`.
- [x] `CONTRIBUTING.md` — remediation steps and owner-exception documentation appended to the existing "Commit attribution" section.
- [x] Local validation (syntax check, fixture suite, real historical regression range, known-clean control range, `git diff --check`).
- [ ] Open Draft PR linking GitHub #283 / Linear TNYX-232.
- [ ] Report final handoff; stop before merge and before any branch-protection/ruleset mutation.

## 6. Quality Review

### Validation Run

```text
bash -n scripts/check_commit_attribution.sh               -> syntax OK
bash -n scripts/check_commit_attribution_test.sh           -> syntax OK
bash scripts/check_commit_attribution_test.sh               -> 12 passed, 0 failed
  (5 PASS fixtures: no trailer; single human co-author; multiple human co-authors;
   human literally named "Claude" with a personal email; AI vendor names in prose
   outside any trailer)
  (7 FAIL fixtures: Claude/anthropic.com; case-variant trailer key + Claude Sonnet;
   Anthropic; Codex; OpenAI; OpenAI Codex; AI trailer mixed among human co-authors)

Real historical PR #282 regression range (read-only, no history mutation):
  bash scripts/check_commit_attribution.sh 0111e23eea150bc24d6634a07887c1ef9fe43974 3ad489fbe1b58b62df12d2daf8ed7f458c06bd7f
  -> exit 1, both offending commits (9b54488c, 3ad489fb) individually identified

Squash commit itself (13da1de), as an additional cross-check:
  bash scripts/check_commit_attribution.sh 0111e23eea150bc24d6634a07887c1ef9fe43974 13da1de59ad4980dc36ce6a9fbc3c206d1463224
  -> exit 1, the GitHub-appended trailer at the true end of the squash message is detected

Known-clean control range (real main history, no trailers):
  bash scripts/check_commit_attribution.sh f3f78074ba69d46877cbd43bd193d1fde8d54581 b86bd3db4b3274c3ed6da02d5a6ea8f2afbd3b0c
  -> exit 0

git diff --check   -> clean (no whitespace errors) [recorded once run against the final diff before push]
```

### Review Findings And Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | (none recorded yet; PR not yet reviewed) | | |

## 7. Final Handoff

### Changed Files

`scripts/check_commit_attribution.sh` (new), `scripts/check_commit_attribution_test.sh` (new), `.github/workflows/commit-attribution-guard.yml` (new), `CONTRIBUTING.md` (remediation section appended), `.ai/tasks/tnyx-232-ai-attribution-guard.md` (new, this file).

### Actual Behavior

Repository-wide PR guard exists and is locally proven correct against fixtures and real repository history, but is not yet a required check on `main` (no branch protection/ruleset configured — confirmed absent, out of scope for this pass).

### Known Limitations

- Not yet a hard merge gate; requires a separate owner/admin action to configure `Commit attribution guard` as a required status check on `main`.
- v1 does not scan PR title/body (deliberate, see Clarification table).
- Direct pushes to `main` (bypassing PRs entirely) are not covered by a `pull_request`-only trigger; this was flagged as a known, accepted limitation in the prior audit and not expanded in this slice to avoid speculative scope growth.

### Final Status

`REVIEW` — implementation complete and locally validated; PR open and awaiting review/merge decision; required-check/admin follow-up outstanding.
