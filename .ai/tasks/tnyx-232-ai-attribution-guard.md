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

**Planning owner:** prior read-only audit pass + manual review passes (same session)
**Implementation owner:** current session (implementation complete as of this pass; this pass is docs-only handoff cleanup, not further behavior change)
**Review owner:** current session (manual review found G1/G2/G3, then G4; all resolved; this pass only corrects stale task-brief wording, no new finding)
**Implementation ownership state:** Handoff pending (implementation complete; awaiting owner review of PR #310)
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-22, fresh `git status -sb` / `git fetch` / `git switch` reconstruction before this pass
**Branch:** `tnyx/tnyx-232-ai-attribution-guard` (existing branch throughout, no new branch created)
**HEAD SHA:** current final implementation head (last code-changing commit) is `574ff1d06afd137f601f484ab921d08b6f262566` (fresh-verified as the current PR #310 head before this pass; base `main` still `b86bd3db4b3274c3ed6da02d5a6ea8f2afbd3b0c`, unmoved). This pass adds one additive docs-only commit on top of it that touches only this task-brief file; see the PR for that commit's exact SHA once pushed.
**Observed working-tree state:** clean before this pass's edits
**Observed uncommitted/dirty files:** none
**PR / tracker:** existing PR [#310](https://github.com/im-tnyx/tio-world/pull/310) (Draft, not merged), GitHub #283 (open, unchanged), Linear TNYX-232 (`In Review`, unchanged)
**Current implementation state:** Guard implementation, trust-boundary hardening (G1/G2/G3), and output-wiring correction (G4) are all complete and pushed to PR #310 as of commit `574ff1d0`. This pass is durable-handoff cleanup only: it corrects task-brief wording that still described the original (superseded) `pull_request` trigger design instead of the implemented `pull_request_target` trusted-base design, and refreshes the "Next exact action" line, which still described already-completed push/reconcile/report steps from the previous pass. No guard behavior, scripts, or workflow file are touched in this pass.
**Relevant execution surface:** `.ai/tasks/tnyx-232-ai-attribution-guard.md` only for this pass (guard files unchanged: `.github/workflows/commit-attribution-guard.yml`, `scripts/check_commit_attribution.sh`, `scripts/check_commit_attribution_test.sh`, `CONTRIBUTING.md`)
**Validation completed at SHA:** see Quality Review section below (unchanged by this docs-only pass; last re-run at `574ff1d0`)
**Validation remaining:** the corrected `pull_request_target` workflow still cannot bootstrap-run against PR #310 itself (base branch doesn't contain it yet); a post-merge validation PR remains required to observe the fixed output-wiring running live end-to-end; hard required-check configuration remains an owner/admin follow-up.
**Current blocker:** none; remaining steps are owner review, owner-authorized merge, and post-merge follow-ups, all explicitly out of scope for this session to perform unilaterally
**Open review finding IDs:** G1, G2, G3, G4 — all Resolved (see Review Findings And Resolution); no new finding in this pass
**Next exact action:** owner review of PR #310 → fresh exact-head merge-readiness verification → owner-authorized squash merge only if the gate remains clean

## 1. Discovery

### User Outcome

A pull request targeting `main` that contains a prohibited AI `Co-Authored-By` trailer (Claude/Anthropic/Codex/OpenAI, or equivalent) in any of its commits is automatically flagged by a repository-wide CI check, without requiring any human reviewer to notice it manually, and without blocking ordinary human co-author trailers.

### Success Criteria

- A `pull_request_target` workflow, trusted-base-controlled, runs on every PR targeting `main`, no product path filters.
- It inspects every commit in the PR's `base...head` range for prohibited AI `Co-Authored-By` trailers, reading the PR head only as Git object data, never checking it out or executing anything from it.
- It fails (non-zero) when a prohibited trailer is found, passes otherwise.
- Ordinary human co-authors, including a human literally named "Claude", are never blocked.
- A narrow, owner-controlled, PR-diff-external exception path exists, implemented inside the tested checker script (not in untested workflow YAML), and it can never bypass a technical/invocation failure.
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
pull_request_target (opened/synchronize/reopened, branches: [main])
  -> actions/checkout@v7 (ref: base.sha, fetch-depth: 0)        [TRUSTED BASE ONLY]
  -> bash scripts/check_commit_attribution_test.sh              [trusted base code]
  -> git fetch --no-tags origin refs/pull/<n>/head:refs/remotes/pull/<n>/head
       -> verify fetched sha == event head.sha                  [PR head as DATA only]
  -> bash scripts/check_commit_attribution.sh <base.sha> <fetched-head-sha> <pr-number> <exception-pr>
       -> validate base/head refs                                (exit 2 on invalid ref)
       -> git rev-list --reverse base..head
       -> per commit: git show -s --format=%B | git interpret-trailers --parse
            (parser failure -> exit 2, fail closed; empty result is a normal non-match)
       -> per Co-Authored-By trailer: match email domain / exact AI display name
       -> if violation found: only an exact pr-number == exception-pr match forgives it
  -> exit 0 (clean, or violation exempted) | exit 1 (violation, no exception) | exit 2 (technical failure, never bypassed)
```

PR-controlled code is never checked out and never executed at any point in this flow; the PR's own commits are read only through `git rev-list`/`git show` against fetched object data.

### Alternative Rejected

- Generic substring grep for vendor names across the whole commit message: rejected — would false-positive on prose/docs mentioning the vendor names outside a real trailer (explicit boundary requirement).
- GitHub-native ruleset commit-message rule: rejected as the sole mechanism — fresh-verified zero rulesets exist, and native rulesets do not offer the nuanced trailer-key + domain/name matching this contract needs; still a useful supplementary Phase-9 admin step for making the check required, not a replacement for the script.
- Node/Python-based commitlint-style tooling: rejected per explicit instruction and repository pattern — no `package.json`/Node toolchain exists at the repo root; Bash + Git already present on the runner is sufficient.
- Original `pull_request` + `ref: head.sha` checkout design: rejected after manual review (G1) — it executed PR-controlled workflow/script code in a context that could, in a future PR, modify the very checker it is being judged by. Replaced by the `pull_request_target` trusted-base design in this correction.
- Exception decision implemented as an `if`/`fi` block in workflow YAML: rejected after manual review (G2) — untested, and risked silently upgrading a technical/invocation failure (exit 2) into a pass. Moved into the tested checker script itself with a strict validate-refs-then-detect-then-exception ordering.

### Failure And Accessibility States

Not applicable (no UI surface). CI failure state: the workflow step prints the exact offending commit short-SHA and the sanitized trailer name/email that triggered the failure, without dumping unrelated commit content.

## 5. Implementation Plan

- [x] `scripts/check_commit_attribution.sh` — trailer parser + AI-identity matcher, exits 0/1/2.
- [x] `scripts/check_commit_attribution_test.sh` — fixture-based PASS/FAIL/BOUNDARY suite, runs in a disposable temp repo.
- [x] `.github/workflows/commit-attribution-guard.yml` — repository-wide `pull_request_target` trigger on `main`, trusted-base-controlled (workflow definition and every script it runs are loaded from `main`, never from the PR), no product path filters, minimum `contents: read` permission. The PR head is fetched and sha-verified as Git object data only (`refs/pull/<n>/head`) and is never checked out or executed. Runs the test suite then the real check, honors `vars.AI_ATTRIBUTION_EXCEPTION_PR` via the checker's fail-closed 4-argument exception contract. (Original `pull_request` + head-checkout design superseded by G1's correction.)
- [x] `CONTRIBUTING.md` — remediation steps and owner-exception documentation appended to the existing "Commit attribution" section.
- [x] Local validation (syntax check, fixture suite, real historical regression range, known-clean control range, `git diff --check`).
- [x] Open Draft PR linking GitHub #283 / Linear TNYX-232 (PR #310).
- [x] Manual review pass (G1 P1, G2 P1/P2, G3 P2 found).
- [x] `scripts/check_commit_attribution.sh` — add 4-argument form; exception decision moved into the script; fail-closed on trailer-parse errors (rc=2, never bypassed by exception).
- [x] `scripts/check_commit_attribution_test.sh` — add exception-contract and fail-closed technical-error fixtures.
- [x] `.github/workflows/commit-attribution-guard.yml` — converted to `pull_request_target`, trusted-base checkout only, PR head fetched as data only (`refs/pull/<n>/head`), never checked out/executed.
- [x] `CONTRIBUTING.md` — small truthful update describing the trusted-base execution model.
- [x] `.ai/tasks/tnyx-232-ai-attribution-guard.md` — Active Handoff and findings refreshed to current truth.
- [x] Re-run local validation for the correction (fixtures, real regression range, clean range, invalid-ref + exception, `git diff --check`).
- [x] Push correction commit to existing branch/PR #310; reconcile PR body.
- [x] `.github/workflows/commit-attribution-guard.yml` — G4: fetch step given `id: fetch_pr_head`, switched from `GITHUB_ENV`/`${{ env.* }}` to `GITHUB_OUTPUT`/`${{ steps.fetch_pr_head.outputs.head_sha }}` for the runtime-computed PR head SHA.
- [x] Corrected task-brief wording that overstated fixture coverage for the `git interpret-trailers` parser-failure branch specifically (G3 row).
- [ ] Report final handoff; stop before merge and before any branch-protection/ruleset/Actions-policy mutation.

## 6. Quality Review

### Validation Run

Original implementation pass (PR #310 first commit, `e332432`):

```text
bash -n scripts/check_commit_attribution.sh               -> syntax OK
bash -n scripts/check_commit_attribution_test.sh           -> syntax OK
bash scripts/check_commit_attribution_test.sh               -> 12 passed, 0 failed

Real historical PR #282 regression range: exit 1, both offending commits identified
Known-clean control range: exit 0
git diff --check: clean
```

Correction pass (this commit — G1/G2/G3 hardening):

```text
bash -n scripts/check_commit_attribution.sh                -> syntax OK
bash -n scripts/check_commit_attribution_test.sh            -> syntax OK
bash scripts/check_commit_attribution_test.sh                -> 18 passed, 0 failed
  (12 identity fixtures unchanged from the original pass — 5 PASS, 7 FAIL, see below)
  (+4 exception-contract fixtures, 4-argument form:
     clean range + no exception               -> PASS rc=0
     violation + no exception                 -> FAIL rc=1
     violation + non-matching PR exception     -> FAIL rc=1
     violation + exact matching PR exception   -> PASS rc=0)
  (+2 fail-closed technical-error fixtures, exception present but MUST NOT bypass:
     invalid base ref + matching exception     -> rc=2
     invalid head ref + matching exception     -> rc=2)

Identity fixtures (unchanged):
  PASS: no trailer; single human co-author; multiple human co-authors;
        human literally named "Claude" with a personal email;
        AI vendor names in prose outside any trailer
  FAIL: Claude/anthropic.com; case-variant trailer key + Claude Sonnet;
        Anthropic; Codex; OpenAI; OpenAI Codex; AI trailer mixed among human co-authors

Real historical PR #282 regression range (read-only, no history mutation), re-run against corrected script:
  bash scripts/check_commit_attribution.sh 0111e23eea150bc24d6634a07887c1ef9fe43974 3ad489fbe1b58b62df12d2daf8ed7f458c06bd7f
  -> exit 1, both offending commits (9b54488c, 3ad489fb) individually identified

Known-clean control range (real main history, no trailers), re-run:
  bash scripts/check_commit_attribution.sh f3f78074ba69d46877cbd43bd193d1fde8d54581 b86bd3db4b3274c3ed6da02d5a6ea8f2afbd3b0c
  -> exit 0

Invalid ref + exact matching exception, against real repo (must stay fail-closed):
  bash scripts/check_commit_attribution.sh totally-invalid-ref b86bd3db4b3274c3ed6da02d5a6ea8f2afbd3b0c 42 42
  -> exit 2, NOT bypassed by the matching exception

git diff --check origin/main...HEAD   -> clean (no whitespace errors)
```

Bootstrap limitation (expected, not a defect): the corrected `pull_request_target` workflow cannot execute against PR #310 itself, because `pull_request_target` always loads the workflow definition from the base branch (`main`), which does not yet contain this workflow version. The original `pull_request`-triggered run on PR #310's first commit did complete successfully on GitHub Actions, but per the manual review that run is historical functional evidence only, not tamper-resistance evidence, since it used the design G1 replaces. This correction pass therefore relies on manual review plus the deterministic local validation above; a separate post-merge validation PR is required to prove the trusted workflow live before any required-check configuration.

Separately, the external "Code scanning AI findings" GitHub check (run `35707161694`) failed with `400 The requested model is not supported` for `claude-opus-5[ReasoningEffort=medium]` — an external scanner infrastructure/model-availability failure, not a finding about this repository's code. No repository code was changed in response to it.

### Review Findings And Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| G1 | P1 | Resolved | Guard used `pull_request` + `ref: github.event.pull_request.head.sha` checkout, executing PR-controlled workflow/script code in the context that judges it — a future PR could modify the checker it is being checked against. | Found against `e33243226b48b1491f6d7a9c38dce35e12b5f682` | Fixed by converting to `pull_request_target` with `ref: github.event.pull_request.base.sha` checkout; PR head is fetched only as `refs/pull/<n>/head` object data (verified to match the event's reported head sha) and is never checked out or executed. See `.github/workflows/commit-attribution-guard.yml`. |
| G2 | P1/P2 | Resolved | The owner-exception logic lived in untested workflow YAML and did not distinguish rc=1 (real violation) from rc=2 (technical/invocation failure), risking a technical failure being silently treated as an approved exception. | Found against `e33243226b48b1491f6d7a9c38dce35e12b5f682` | Moved into the tested `scripts/check_commit_attribution.sh` itself (new 4-argument form `<base> <head> <pr-number> <exception-pr>`), with strict ordering: validate args -> validate refs -> detect -> only then evaluate the exact-PR exception. Proven with 4 new fixtures (clean+no-exception, violation+no-exception, violation+wrong-PR-exception, violation+matching-exception) and 2 fail-closed fixtures (invalid base/head ref + matching exception -> still rc=2). All 6 pass. |
| G3 | P2 | Resolved | `git interpret-trailers --parse` failures were effectively fail-open (a parser error could be indistinguishable from "no trailers"), which is unacceptable for a governance guard. | Found against `e33243226b48b1491f6d7a9c38dce35e12b5f682` | `set +e` / capture `trailer_rc` / `set -e` around the parse call; a non-zero `trailer_rc` now prints a concise error and exits 2 immediately, distinct from the normal "empty output, exit 0" no-trailers case. **Precise validation status:** the two automated `rc=2` fixtures (`invalid base ref` / `invalid head ref` with matching exception) exercise the shared exit-2 contract and prove the exception can never bypass it, but they do so via invalid refs, not by forcing `git interpret-trailers` itself to return non-zero — no fixture actually drives that specific command to fail (it is a very robust parser; there is no clean, non-script-complicating way to make it error deterministically). The `git interpret-trailers` fail-closed branch is implemented and code-reviewed, not fixture-proven in isolation. Human co-author and AI-identity boundaries remain unchanged (18/18 fixtures pass). |
| G4 | P1/P2 | Resolved | The fetch step wrote the resolved PR head SHA with `echo "fetched_head_sha=..." >> "$GITHUB_ENV"` and the next step read it via `${{ env.fetched_head_sha }}` in the workflow-expression context. A `GITHUB_ENV` write is a runtime shell-environment value for later steps' shells, not a workflow-expression `env.*` value; the `${{ }}` expression evaluates before the runtime write is guaranteed visible to it, so `HEAD_SHA` could resolve empty on a live run even on an otherwise clean PR, making the checker fail closed with `rc=2` for the wrong reason. | Found against `d73d70431b4b0ffde87f83dc828aef55878004de` | Fetch step given `id: fetch_pr_head`; it now writes `echo "head_sha=${fetched_head_sha}" >> "$GITHUB_OUTPUT"` instead of `GITHUB_ENV`. The checker step now reads `HEAD_SHA: ${{ steps.fetch_pr_head.outputs.head_sha }}` — a proper step-output expression reference, evaluated after the fetch step completes. No `GITHUB_ENV`/`env.*` ambiguity remains anywhere in the workflow. Trust model unchanged: `pull_request_target` -> trusted base checkout -> trusted scripts only -> PR head fetched as data -> sha-verified against event head -> never checked out -> never executed. |

## 7. Final Handoff

### Changed Files

Original implementation commit: `scripts/check_commit_attribution.sh` (new), `scripts/check_commit_attribution_test.sh` (new), `.github/workflows/commit-attribution-guard.yml` (new), `CONTRIBUTING.md` (remediation section appended), `.ai/tasks/tnyx-232-ai-attribution-guard.md` (new).

Correction commit 1 (G1/G2/G3, same PR #310, same branch): `scripts/check_commit_attribution.sh` (rewritten — 4-argument form, fail-closed exception, fail-closed trailer-parse errors), `scripts/check_commit_attribution_test.sh` (rewritten — adds exception-contract and fail-closed fixtures), `.github/workflows/commit-attribution-guard.yml` (rewritten — `pull_request_target`, trusted-base checkout, data-only PR head fetch), `CONTRIBUTING.md` (small truthful addition describing the trusted-base execution model), `.ai/tasks/tnyx-232-ai-attribution-guard.md` (refreshed).

Correction commit 2 (G4, this pass, same PR #310, same branch): `.github/workflows/commit-attribution-guard.yml` (fetch step given `id: fetch_pr_head`; `GITHUB_ENV`/`${{ env.* }}` replaced with `GITHUB_OUTPUT`/`${{ steps.fetch_pr_head.outputs.head_sha }}`), `.ai/tasks/tnyx-232-ai-attribution-guard.md` (G4 recorded and resolved; G3 wording corrected to not overclaim fixture coverage of the `git interpret-trailers` failure branch specifically).

### Actual Behavior

Repository-wide PR guard exists, is trust-boundary-hardened (base-controlled, PR head read as data only, fail-closed exception and error handling, correct step-output wiring for the runtime head SHA), and is locally proven correct against 18 fixtures plus real repository history. It is not yet a required check on `main` (no branch protection/ruleset configured — confirmed absent, out of scope for this pass), and it still cannot bootstrap-execute against PR #310 itself (expected `pull_request_target` behavior — the trusted version does not yet exist on `main`).

### Known Limitations

- Not yet a hard merge gate; requires a separate owner/admin action to configure `Commit attribution guard` as a required status check on `main`.
- v1 does not scan PR title/body (deliberate, see Clarification table).
- Direct pushes to `main` (bypassing PRs entirely) are not covered by a `pull_request_target`-only trigger; this was flagged as a known, accepted limitation in the prior audit and not expanded in this slice to avoid speculative scope growth.
- The corrected trusted workflow, including the G4 output-wiring fix, has not yet had a live GitHub Actions run against a real PR (bootstrap limitation — it only becomes live once merged to `main`). A post-merge validation PR is required before any required-check configuration.
- GitHub's `pull_request_target` public-repo Actions event policy has stricter enforcement scheduled for 2026-11-02; the final admin follow-up must verify/allow this workflow remains permitted under that policy. Not changed in this pass.
- The `git interpret-trailers` fail-closed branch (G3) is implemented but not fixture-forced to fail in isolation — see the G3 row's "Precise validation status" note.

### Final Status

`REVIEW` — implementation plus two correction passes complete and locally validated (18/18 fixtures, real regression/clean/invalid-ref scenarios, corrected output wiring manually traced end-to-end); PR #310 open (Draft) and awaiting review/merge decision; post-merge live validation, required-check, and Actions-event-policy follow-ups outstanding.

## 8. Superseding Decision — Option C (dedicated GitHub App required check)

This section supersedes any earlier wording in this brief (including the Active Handoff "Next exact action" and the Known Limitations above) that plans to make the `github-actions`-sourced job (app ID 15368) the required `main` check. The active execution record for the hard-gate work is `.ai/tasks/tnyx-232-option-c-app-check.md`.

- PR #310 merged the trusted guard (`3ebe9f7c3a526abbaed5364c9db88054cfea03b9`). Live PASS / deliberate-trailer FAIL / remediated PASS evidence was collected on PR #311 (still Draft/open; its `.ai/tasks/*` evidence lands on `main` when PR #311 merges).
- Required status checks bind only to a check name plus an optional source app, not to a workflow path or event type. Every Actions workflow in this repository reports as `github-actions` (app 15368), so that identity cannot uniquely prove the trusted workflow produced a result. A hard gate therefore needs a distinct source identity.
- Owner decision (locked): Option C — a dedicated custom GitHub App (Tio Attribution Guard) publishes the required `Commit attribution guard` Check Run; the Actions job is renamed `Attribution guard runner` and is not required. D1 locked: `enforce_admins = true`, so direct pushes to `main` (including post-merge docs) must go through PRs.
- Branch protection is deferred until the custom App check has been observed live on a real PR after the App-backed workflow lands on `main`.
