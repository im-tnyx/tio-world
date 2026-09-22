# TNYX-232 / GitHub #283 — Option C: Dedicated GitHub App Required Check

**Status:** In progress
**Primary owner:** repository governance / `.github/workflows/commit-attribution-guard.yml`
**Affected platforms:** None (CI/governance only; no Flutter/Supabase/product runtime change)

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** CI/governance hardening of an existing guard; matches none of `AGENTS.md`'s Owner Approval triggers. Owner explicitly selected Option C and locked D1 (`enforce_admins = true`).
**Approved product/UI/data-shape boundaries:** Not applicable.
**Explicit non-changes:** No change to detection semantics (`scripts/check_commit_attribution.sh`, `scripts/check_commit_attribution_test.sh` untouched); no second exception mechanism; no Flutter/Supabase/product files; no `main` history rewrite; PR #311 untouched; no branch protection in this slice until the App check is proven live.

## Active Handoff

**Planning owner:** current session
**Implementation owner:** current session
**Review owner:** Not applicable (pending PR review)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-22 — `main` `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`; rulesets `[]`; `main` protection 404; Actions policies 0; PR #311 Draft at `cb507660b62f8b695b0ec397ec4018d60577fc41`
**Branch:** `tnyx/tnyx-232-option-c-app-check` (from fresh `main`)
**PR / tracker:** Draft PR [#312](https://github.com/im-tnyx/tio-world/pull/312), GitHub #283 open, Linear TNYX-232 `In Review`; related PR #310 (merged), PR #311 (Draft, unchanged)
**Current implementation state:** trusted environment configured; workflow publishes the custom App check; workflow-scoped Actions policy active (ID 5216); owner-only App registration/installation/private-key steps pending
**Validation remaining:** owner App setup; live custom-App check (only possible after this workflow lands on `main`); branch protection; spoof/infra validation
**Current blocker:** owner-only UI steps (register App, install on `tio-world` only, store private key as environment secret, supply Client ID and numeric App ID)
**Open review finding IDs:** none
**Next exact action:** owner completes the App setup steps below; then environment variable `ATTRIBUTION_GUARD_APP_CLIENT_ID` is set and App identity verified read-only

## 1. Discovery

### User Outcome

A merge into `main` requires a `Commit attribution guard` check that only the trusted, base-controlled attribution workflow can produce, identified by a dedicated GitHub App rather than the shared `github-actions` identity.

### Success Criteria

- The Actions job is `Attribution guard runner` (source `github-actions`, not required).
- The dedicated Tio Attribution Guard App posts `Commit attribution guard` on `github.event.pull_request.head.sha`.
- The App private key is reachable only from the `main`-restricted `attribution-guard-trusted` environment.
- The App check is success only when the checker ran and returned `rc=0`; every other path is missing, `in_progress`, or failure.
- Branch protection on `main` pins the check to the App's numeric ID with `strict=false`, `enforce_admins=true`.

### Non-Goals

- No detection-logic change; no App-level exception; no metadata commit rule; no Enterprise migration.

## 2. Codebase Exploration — Verified Evidence

- Required status checks bind to check name plus optional source app only (`checks[].app_id`: "The ID of the GitHub App that must provide this check"). All repository workflows report as `github-actions` (app 15368), including GitHub's own dynamic `github-advanced-security` check on the same PR head, so 15368 does not uniquely identify the trusted workflow. Duplicate same-name Actions jobs can make required-check resolution ambiguous; this slice does not claim a proven bypass.
- Check-run write is "only available to GitHub Apps"; OAuth apps and authenticated users (PATs) cannot create check runs, so the owner token (and agents using it) cannot fabricate the App's check.
- Environment rules: for `pull_request_target` they "evaluate against the default branch"; for `pull_request`/`pull_request_review`/`pull_request_review_comment` they "evaluate against refs/pull/number/merge" (GitHub changelog 2025-11-07, effective 2025-12-08). Selected-branch patterns match `GITHUB_REF` via fnmatch, so `main` admits only `main`.
- Workflows on `main` before this slice: none reference `environment:` or `secrets.`; only this workflow uses `pull_request_target`.
- `actions/create-github-app-token` latest `v3.2.0`; `v3` and `v3.2.0` both resolve to commit `bcd2ba49218906704ab6c1aa796996da409d3eb1`; `client-id` is the supported input (`app-id` deprecated); `permission-checks` input exists; the token is revoked in the action's post step.
- `main` first-parent history shows occasional direct post-merge docs pushes (e.g. `b86bd3db`); with D1 these must become PRs.

## 3. Clarification — Decisions

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Option C: dedicated App publishes the required check | Locked | Distinct source identity pinned by `app_id` | Owner |
| D1 `enforce_admins = true` | Locked | Agents run with owner/admin credentials; admin direct push must not silently bypass | Owner |
| Env var `ATTRIBUTION_GUARD_APP_CLIENT_ID` (not App ID) at runtime | Made | Token action requires `client-id`; numeric App ID is recorded separately for branch protection | This slice |
| Focused brief `tnyx-232-option-c-app-check.md` instead of editing the live-validation brief | Made | The live-validation brief exists only on PR #311's branch, and PR #311 edits lines 15-37 of the main brief; a separate brief plus an appended section avoids add/add and hunk conflicts | This slice |
| Branch protection only after live App-check proof | Locked | A required App check must exist and be observed before it can gate merges | Owner |

## 4. Architecture Design

```text
PR targeting main
→ pull_request_target (workflow loaded from main)
→ job "Attribution guard runner", environment attribution-guard-trusted (main-only)
→ mint installation token (checks:write, tio-world only)
→ POST check-runs {name: "Commit attribution guard", head_sha: PR head, status: in_progress}
→ trusted base checkout → 18 fixtures → data-only PR head fetch + SHA verification → checker (rc captured)
→ always(): PATCH check-run → success only if checker outcome=success AND rc=0, else failure
→ branch protection requires "Commit attribution guard" from the App's numeric ID
```

Fail-closed: token/secret/environment unavailable or check creation failing → no App check (missing); checker rc 1/2/unexpected or any earlier step failing or cancellation → failure; finalize call failing → check stays `in_progress`. None of these satisfies a required check. Each new head SHA needs its own App check; a success on an older SHA does not carry over.

## 5. Implementation Plan

- [x] C. Environment `attribution-guard-trusted` created; custom branch policies on; exactly one policy `main` (type `branch`); no reviewers; no wait timer; no repo-wide secret.
- [ ] A. Owner registers the App (UI).
- [ ] B. Owner installs it on `tio-world` only (UI).
- [ ] D. Owner stores the private key as environment secret `ATTRIBUTION_GUARD_APP_PRIVATE_KEY` (UI or owner-run `gh secret set`); local `.pem` deleted.
- [ ] E. Environment variable `ATTRIBUTION_GUARD_APP_CLIENT_ID`; numeric App ID recorded.
- [x] F/G. Workflow change on this branch (runner rename, environment, pinned token action, App check create/finalize).
- [x] H. Local/static validation and Draft PR #312.
- [x] I. Workflow-scoped Actions policy created with API version `2026-03-10` and read back: ID `5216`, name `Allow trusted attribution guard event`, enforcement `active`, `workflow_path.include = [".github/workflows/commit-attribution-guard.yml"]`, `exclude = []`, rule `restrict_action_events` with `allowed_events = ["pull_request_target"]`. No other workflow's events are affected.
- [ ] Owner-authorized merge of this PR (not in this pass).
- [ ] Disposable clean PR → observe App check SUCCESS live.
- [ ] Branch protection PUT (payload below).
- [ ] Validation: clean, trailer, same-name spoof, Actions policy, infrastructure-failure observation.
- [ ] PR #311 merged through the new gate; final #283 / TNYX-232 reconciliation.

### Future branch protection payload (not applied)

`PUT /repos/im-tnyx/tio-world/branches/main/protection`

```json
{
  "required_status_checks": {
    "strict": false,
    "checks": [ { "context": "Commit attribution guard", "app_id": "<numeric Tio Attribution Guard App ID>" } ]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": null,
  "restrictions": null
}
```

`app_id` is an integer in the real request. Never pin `15368`. This PUT also sets `allow_force_pushes=false` and `allow_deletions=false` by default, consistent with `AGENTS.md`.

## 6. Quality Review

### Validation Run

See the PR description for the exact commands and results at this branch's head.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | | none | | |

## 7. Final Handoff

### Known Limitations

- Bootstrap: `pull_request_target` loads the workflow from `main`, so this PR is judged by the current (pre-Option-C) guard; the App-backed version can only be observed live after merge.
- The pre-merge guard sees PR commits only. A squash message edited in the merge dialog, or squash-time co-author generation from commit author identity, is outside its view (follow-up; not verified).
- Environment-bound jobs create deployment entries in PR timelines (cosmetic).

### Final Status

`PARTIAL` — repository-side implementation ready for review; owner-only App setup and all live validation pending.
