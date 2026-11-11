# Commit attribution guard: any co-author trailer

**Status:** In review on PR #742
**Primary owner:** Cursor
**Working agent:** Codex
**Affected platforms:** GitHub Actions attribution guard only

## Active Handoff

**Planning owner:** Cursor
**Implementation owner:** Codex
**Previous agent:** Cursor
**Last commit agent:** Codex
**Last commit SHA:** `759f0f15c1ed83a72f0c5c3d9d2cfe2a155e99ce` (fixture workflow commit; this handoff update is a later documentation commit)
**Review fix:** im-tio P2 on the raw co-author scan is present at `7eef4c4bd44cb5a39ce3c5b50e1f4148a8417ac2`.
**Review owner:** independent GitHub reviewer
**Implementation ownership state:** Active
**Ownership transition:** Cursor → Codex for the PR #742 review follow-up; no concurrent implementation owner is known.
**Repository state last verified:** `tnyx/w7c-brief-merge-status-af26@759f0f15c1ed83a72f0c5c3d9d2cfe2a155e99ce`, with only this task brief modified after the fixture workflow commit; `origin/main@975b6edd62dab505b66804aa80ac063073a6140d` is an ancestor.
**Current implementation state:** The new `pull_request` fixture workflow checks out the exact PR head with `contents: read` and no persisted checkout credentials. The trusted `pull_request_target` guard is unchanged.
**Validation completed at SHA:** `759f0f15c1ed83a72f0c5c3d9d2cfe2a155e99ce` — `bash scripts/check_commit_attribution_test.sh`: 26 passed, 0 failed (verified Git Bash executable); `git diff --check origin/main...HEAD`: pass; workflow YAML structure parsed locally.
**Validation remaining:** Hosted execution of the new workflow and independent re-review on the published head. Do not merge before both pass.
**Open review finding IDs:** None. Outdated thread `PRRT_kwDOTOXwB861vScg` was resolved after the local test passed.
**Next exact action:** Commit this handoff, push the same PR branch, inspect exact-head CI and request independent re-review if needed. Do not merge.

## Owner Approval and Scope Boundary

**Trigger:** None. Correctness fix to the existing attribution guard, requested on PR #742.
**Approval status:** Approved for this guard fix only.
**Explicit non-changes:** No ruleset, required check name, or branch-protection change. No product code, migration, or hosted deploy. Agent names stay out of commit metadata. A name inside a task file is not commit metadata and is not scanned.

## What failed

Original PR #742 commits, before the rewrite:

- `d3feb3030d7554458df647019f40cfa638241576`
- `26d197a8a322bc61b2035f17f6e5f159124ef004`

Both used author and committer `Cursor Agent <cursoragent@cursor.com>` and ended with:

`Co-authored-by: Santosh Jangid <im-tnyx@users.noreply.github.com>`

`Commit attribution guard` and `Attribution guard runner` were success on `26d197a8` (run 42829331296). The trusted checker from `main` printed no prohibited attribution and exited 0.

## Cause

`.github/workflows/commit-attribution-guard.yml` already passes every commit in `base.sha..head.sha` to `scripts/check_commit_attribution.sh`. The script rejected a `Co-authored-by` trailer only when the name or email domain was on the AI denylist (`scripts/check_commit_attribution.sh` identity filter). `Santosh Jangid <im-tnyx@users.noreply.github.com>` matched neither. Author and committer were not read, so `Cursor Agent <cursoragent@cursor.com>` was ignored. The check names and the `pull_request_target` base checkout were not the miss.

## Fix

Any `Co-authored-by` trailer fails. Author, committer, and other trailers fail when they match a known AI/agent name or provider domain, including `Cursor Agent` and `cursoragent@cursor.com`. The required check name stays `Commit attribution guard`. The job name stays `Attribution guard runner`.

## Still pending

This PR's live guard run still executes the checker from `main`, by design, until this fix is merged. Hosted workout rollout, device validation, and W7B-2B are unrelated and remain pending.
