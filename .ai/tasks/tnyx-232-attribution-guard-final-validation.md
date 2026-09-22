# TNYX-232 / GitHub #283 — Attribution Guard Final Validation Record

**Status:** Validated
**Primary owner:** repository governance / `.github/workflows/commit-attribution-guard.yml`, `scripts/check_commit_attribution*.sh`
**Affected platforms:** None (CI/governance only; no Flutter/Supabase/product runtime change)

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Governance/CI evidence record; matches none of `AGENTS.md`'s Owner Approval triggers. Every destructive or settings-changing validation step below ran under its own explicit owner authorization.
**Approved product/UI/data-shape boundaries:** Not applicable.
**Explicit non-changes:** This record changes no guard behavior, workflow, script, branch protection, Actions policy, App, environment or secret.

## Active Handoff

**Planning owner:** current session
**Implementation owner:** current session
**Review owner:** repository owner
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-22 — `main` `298186e1d316acb503eca5dbf96fdffa6d065c83`, protected; rulesets `[]`; Actions policy 5216 active
**Branch:** `tnyx/tnyx-232-final-evidence` (fresh from `main`)
**HEAD SHA:** see the final evidence pull request
**Observed working-tree state:** clean before this record
**Observed uncommitted/dirty files:** none
**PR / tracker:** final evidence PR (this record); GitHub #283 open; Linear TNYX-232 `In Review` until this record lands and cleanup completes
**Current implementation state:** guard, App-backed required check and branch protection are live and validated
**Relevant execution surface:** `.ai/tasks/` only
**Validation completed at SHA:** see sections below
**Validation remaining:** none for the security gate; post-merge cleanup only
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** owner-authorized merge of the final evidence PR, then close PR #311 (superseded by this record), PRs #313/#314/#315 (disposable), delete their branches, and reconcile GitHub #283 / TNYX-232

## Final Security Conclusion

**A — SECURITY GATE VALIDATED, with a duplicate-name availability caveat.**

A pull request carrying a prohibited AI `Co-Authored-By` trailer cannot merge into protected `main`: the trusted guard fails, the dedicated App publishes the required check as failure, and a same-name check from any other source cannot override it. The only observed side effect of duplicate names is that a pull request author can block their own pull request.

## 1. Initial Guard — PR #310

- Squash-merged to `main` as `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`.
- Trusted `pull_request_target` workflow, base-commit checkout, PR head fetched as Git object data only, never checked out or executed.
- Checker `scripts/check_commit_attribution.sh` (4-argument form; rc 0 clean or exact exempted PR, rc 1 prohibited attribution, rc 2 technical failure) and 18 fixtures in `scripts/check_commit_attribution_test.sh`.
- Implementation history and review findings G1-G4: `.ai/tasks/tnyx-232-ai-attribution-guard.md`.

## 2. Original Live Validation — PR #311 (historical, superseded by this record)

PR #311 (branch `tnyx/tnyx-232-attribution-guard-live-validation`, last head `cb507660b62f8b695b0ec397ec4018d60577fc41`) was cut from `3ebe9f7c` and is now diverged from `main`. Its facts are reconciled here instead of merging it. At that time the required-check identity work had not started; the check came from the `github-actions` job itself.

| Step | Head | Run | Result |
|---|---|---|---|
| Clean | `eedccb9c4fdb09a4da23f9358ca3cdca9045ae38` | 35713989929 | SUCCESS |
| Clean (both validation commits) | `882890bfb2419bbbae5ab9d3bf5fd9120d0842fd` | 35714233104 | SUCCESS |
| Prohibited trailer | `c50aa798fdf69986038c1137b25e9dae828e1a31` | 35715427972 | FAILURE (detector, exit 1) |
| Remediated | `9d3b8fa28b5af68eb221b35a7dffbd21a1924f58` | 35715530945 | SUCCESS |

- Every run checked out trusted base `3ebe9f7c`, passed 18/18 fixtures, and fetched the PR head as data only with the fetched SHA matching the event head.
- Bad commit `c50aa798`: empty, parent `882890bf`, trailer `Co-Authored-By: Claude <noreply@anthropic.com>`. Detector line: `PROHIBITED AI ATTRIBUTION: commit c50aa798 -- Co-Authored-By: Claude <noreply@anthropic.com> (provider-domain identity (anthropic.com))`.
- Remediation (owner-authorized): message-only amend to `9d3b8fa2` (same tree `7b81b3eb…`), one `--force-with-lease` push of that validation branch only. `main` was never rewritten; the bad SHA never reached `main`.

## 3. Option C — PR #312

- Owner decision: required check published by a dedicated GitHub App (Option C) with `enforce_admins = true` (D1). Rationale: required status checks bind to check name plus optional source App, and every Actions workflow reports as `github-actions` (App 15368).
- Squash-merged to `main` as `298186e1d316acb503eca5dbf96fdffa6d065c83`.
- Actions job renamed `Attribution guard runner` (not required); it runs in environment `attribution-guard-trusted`, mints a token with `actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1` (v3.2.0), and publishes the `Commit attribution guard` check run on the PR head SHA: `in_progress` first, `success` only when the checker step succeeds with `rc=0`, otherwise `failure`.
- App: Tio Attribution Guard, slug `tio-attribution-guard`, App ID `5032971`, installation `163766339`, installed on `im-tnyx/tio-world` only; permissions Checks read/write and Metadata read-only (owner UI evidence).
- Environment `attribution-guard-trusted`: deployment branches `main` only, no reviewers, no wait timer, admin bypass off; secret `ATTRIBUTION_GUARD_APP_PRIVATE_KEY` (name only); variable `ATTRIBUTION_GUARD_APP_CLIENT_ID`.
- Setup detail and review: `.ai/tasks/tnyx-232-option-c-app-check.md`.

## 4. Custom App Live Proof — PR #313

- Head `f8c831955a92a441a12afed41ecce4af1d1885f2` (docs-only).
- Runner run 35730237151: attempt 1 failed at token minting (`Invalid keyData`; the first stored key was not a valid PEM private key), so no App check was created — fail-closed. After the owner replaced the key, attempt 2 succeeded.
- Custom check run `106756967663`: `Commit attribution guard`, source Tio Attribution Guard / App ID `5032971`, conclusion `success`.
- Attempt 2 log: trusted checkout `298186e1`, fixtures 18/18, PR head fetched as data only and matching the event head, checker `rc=0`, check created `in_progress` then finalized `success`. No token, key, JWT or authorization header in the log.

## 5. Branch Protection on `main`

Classic branch protection, applied with one `PUT` (API version `2026-03-10`, response `200 OK`):

| Setting | Value |
|---|---|
| Required check context | `Commit attribution guard` |
| Required source `app_id` | `5032971` |
| `strict` | `false` |
| `enforce_admins` | `true` |
| Required reviews | off |
| Push restrictions | off |
| Force pushes / deletions | not allowed |
| Rulesets | `[]` |

The `app_id` pin is read back from the protection object, the `required_status_checks` endpoint and the branch summary. GraphQL does not resolve the private App (`app: null`). With `enforce_admins = true`, changes to `main`, including docs, go through pull requests.

## 6. Protected Negative and Spoof Validation — PR #314

| Head | Change | Custom App check (App 5032971) | Same-name `github-actions` check (App 15368) | PR state |
|---|---|---|---|---|
| `9b616df07eb83ab4035f91880850dfd7c99adcf7` | clean docs carrier | `106760027210` success | none | `CLEAN` |
| `3c3edbf130c06361081ac3d77829080ca99e1992` | empty commit with `Co-Authored-By: Claude <noreply@anthropic.com>` | `106760304908` failure | none | `BLOCKED` |
| `461919ab1f88fc3c8a78db304e70881fa4480059` | PR-only workflow whose job is named `Commit attribution guard` and exits 0 | `106760656437` failure | `106760620137` success | `BLOCKED` |

- Negative detector line (run 35732186592, checker `rc=1`): `PROHIBITED AI ATTRIBUTION: commit 3c3edbf1 -- Co-Authored-By: Claude <noreply@anthropic.com> (provider-domain identity (anthropic.com))`.
- Result: a same-name `github-actions` success does not override the trusted App failure.

## 7. Reverse Same-Name Test — PR #315

| Head | Custom App check (App 5032971) | Same-name `github-actions` check (App 15368) | PR state |
|---|---|---|---|
| `bf48a048dffdc6bacdde6a6469ccbc1d22f84abb` | `106763178971` success | `106763123867` failure (deliberate `exit 1`) | `BLOCKED` (`mergeable: MERGEABLE`) |

Interpretation:

- This is duplicate-name availability behavior, not an integrity bypass, and not evidence that the `app_id` configuration is missing — protection still reads `app_id 5032971`.
- GitHub documents both relevant behaviors on "About protected branches": when a required check has an expected source App, merging is blocked if any other person or integration sets that status; and job names should be unique across workflows, because identical names can make required-check results ambiguous and prevent merging.
- A pull request author can block their own pull request this way, but cannot use it to merge prohibited attribution.
- GraphQL `isRequired` marks every same-name check as required, on both #314 and #315, so it is not used as evidence of source pinning.

## 8. Actions Policy

- ID `5216`, "Allow trusted attribution guard event", enforcement `active`.
- Scope: `workflow_path.include = [".github/workflows/commit-attribution-guard.yml"]`, `exclude = []`.
- Rule: `restrict_action_events` with `allowed_events = ["pull_request_target"]`. Other workflows are unaffected.
- The default public-repository `pull_request_target` block is enforced from 2026-11-02; guard runs so far show the policy does not block the guard, but they were not observed under that enforcement.

## Known Limitations

- **Missing App check with a spoof success was not forced.** Creating it would require deliberately breaking the trusted guard for every pull request. Protection for that case rests on the documented expected-source contract plus the read-back `app_id 5032971` configuration.
- **Duplicate job names.** No workflow on `main` other than the guard may use a job or check named `Commit attribution guard`.
- **Squash message edits.** The pre-merge guard sees pull request commits, not a message edited in the merge dialog; merges should use the audited squash message.
- **External check noise.** `github-advanced-security` (Copilot autofind) fails on every pull request with an unsupported-model infrastructure error. It is not an attribution-guard finding and is not required.
- **Private App visibility.** The `gh` OAuth token cannot read the private App's metadata; App permissions and install scope rest on owner UI evidence, with the live check source ID `5032971` as API proof of identity.

## Final Status

`PASS` — the guard, the App-backed required check and the protected-branch behavior are validated live. Remaining work is administrative cleanup: merge this record, close PR #311 as superseded and PRs #313/#314/#315 as disposable, delete their branches, then close GitHub #283 and TNYX-232.
