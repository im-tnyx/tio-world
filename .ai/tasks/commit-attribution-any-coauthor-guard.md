# Commit attribution guard: any co-author trailer

**Status:** In review on PR #742
**Primary owner:** Cursor
**Affected platforms:** GitHub Actions attribution guard only

## Active Handoff

**Planning owner:** Cursor
**Implementation owner:** Cursor
**Review owner:** independent GitHub reviewer
**Implementation ownership state:** Active
**Next exact action:** Keep the guard fix on PR #742. Do not merge from this slice.

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
