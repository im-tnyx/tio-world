# TNYX-232 / GitHub #283 — Trusted Attribution Guard Live Validation

**Status:** In progress
**Primary owner:** repository governance (validation only; no guard/workflow/script ownership)
**Affected platforms:** None (documentation-only validation artifact; no Flutter/Supabase/product runtime change)

## Purpose

Clean live validation of the `Commit attribution guard` workflow (`.github/workflows/commit-attribution-guard.yml`) now landed on `main` via PR #310 (squash SHA `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`). This PR exists only to prove, with real GitHub Actions evidence, that the trusted `pull_request_target` design actually runs from `main` and evaluates a PR without ever checking out or executing PR-controlled code.

## Non-Goals

- No product/runtime change (no Flutter/Supabase/app code).
- No modification to `.github/workflows/commit-attribution-guard.yml`.
- No modification to `scripts/check_commit_attribution.sh` or `scripts/check_commit_attribution_test.sh`.
- No branch-protection/ruleset configuration change.
- No prohibited AI attribution trailer outside the one explicitly owner-authorized negative-test commit recorded below (since remediated and no longer reachable).
- No merge of this validation PR unless separately authorized.

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Documentation-only validation artifact; matches none of `AGENTS.md`'s three Owner Approval triggers.
**Explicit non-changes:** see Non-Goals above.

## Evidence

- GitHub #283 (open)
- Linear TNYX-232 (In Review)
- PR #310 (merged, squash SHA `3ebe9f7c3a526abbaed5364c9db88054cfea03b9`)
- `.ai/tasks/tnyx-232-ai-attribution-guard.md` — full guard implementation/correction history (G1-G4)

## Expected Result

The `Commit attribution guard` check runs on this PR using the `pull_request_target` event, checks out only `main`'s trusted code, fetches this PR's head as Git object data only, and reports SUCCESS (no prohibited AI attribution trailer present in this PR's own commits).

## Live Result

GitHub Actions run [35713989929](https://github.com/im-tnyx/tio-world/actions/runs/35713989929) — event `pull_request_target`, conclusion `SUCCESS`.

- `Checkout trusted base` → `git checkout ... 3ebe9f7c3a526abbaed5364c9db88054cfea03b9` (the merged base commit, not this PR's head).
- `Run fixture regression tests (trusted base code)` → `check_commit_attribution_test: 18 passed, 0 failed`.
- `Fetch PR head commit objects as data only` → `fetched PR #311 head eedccb9c4fdb09a4da23f9358ca3cdca9045ae38 as data only (not checked out, not executed)` — matches this PR's actual head SHA.
- `Check PR commits for prohibited AI attribution` → `Checking commit range 3ebe9f7c3a526abbaed5364c9db88054cfea03b9..eedccb9c4fdb09a4da23f9358ca3cdca9045ae38` → `no prohibited AI attribution found`.

This is direct log evidence (not inference) that the workflow definition and scripts executed came from trusted `main`, the working tree never left the base commit, and this PR's head was read only as Git object data.

A second clean run, [35714233104](https://github.com/im-tnyx/tio-world/actions/runs/35714233104) (`pull_request_target`, `SUCCESS`), covered head `882890bfb2419bbbae5ab9d3bf5fd9120d0842fd` (range `3ebe9f7c..882890bf`, both validation commits) with the same trusted-checkout / data-only-fetch log evidence.

## Negative Test + Remediation (owner-authorized destructive gate)

Explicit owner authorization covered exactly: one newest temporary empty commit carrying one prohibited trailer on this validation branch, a normal push, capture of the completed FAIL run, a message-only amend of that commit only, and one lease-pinned rewrite push of this branch only.

Pre-conditions verified immediately before mutation: working tree clean; local and remote branch head `882890bf`; `main` at `3ebe9f7c`; PR #311 OPEN/Draft/CLEAN with no reviews; `AI_ATTRIBUTION_EXCEPTION_PR` unset at every scope (repository variable 404; the only environment, `copilot`, has 0 variables; the guard job declares no `environment`).

| Step | Head | Run | Event | Result |
|---|---|---|---|---|
| Clean baseline | `882890bfb2419bbbae5ab9d3bf5fd9120d0842fd` | [35714233104](https://github.com/im-tnyx/tio-world/actions/runs/35714233104) | `pull_request_target` | SUCCESS |
| Bad trailer | `c50aa798fdf69986038c1137b25e9dae828e1a31` | [35715427972](https://github.com/im-tnyx/tio-world/actions/runs/35715427972) | `pull_request_target` | **FAILURE** (detector, exit 1) |
| Remediated | `9d3b8fa28b5af68eb221b35a7dffbd21a1924f58` | [35715530945](https://github.com/im-tnyx/tio-world/actions/runs/35715530945) | `pull_request_target` | SUCCESS |

**Bad commit** `c50aa798`: empty commit, parent `882890bf`, author/committer the repository owner. Its message ended with the historical PR #282 regression trailer `Co-Authored-By: Claude <noreply@anthropic.com>`; `git interpret-trailers --parse` confirmed it as a real trailer. Pushed as a normal fast-forward (`882890bf..c50aa798`).

**FAIL run 35715427972** (waited for completion before any remediation push, because the workflow uses `cancel-in-progress: true`): `Checkout trusted base` → `git checkout ... 3ebe9f7c3a526abbaed5364c9db88054cfea03b9`; fixtures `18 passed, 0 failed`; `fetched PR #311 head c50aa798fdf69986038c1137b25e9dae828e1a31 as data only (not checked out, not executed)`; `EXCEPTION_PR:` empty; range `3ebe9f7c..c50aa798`; detector line:

```text
PROHIBITED AI ATTRIBUTION: commit c50aa798 -- Co-Authored-By: Claude <noreply@anthropic.com> (provider-domain identity (anthropic.com))
```

then `prohibited AI Co-Authored-By attribution detected` and `Process completed with exit code 1`. Only the check step failed; checkout, fixtures, and fetch succeeded, so this is the detector path, not an infrastructure or technical (`rc=2`) failure. The earlier commits `eedccb9c` and `882890bf` in the same range were not flagged. This run still reads `completed / failure` after the remediation push (not cancelled).

**Remediation**: message-only `git commit --amend --allow-empty` of the newest commit only. Remediated commit `9d3b8fa2` has parent `882890bf`; the bad commit, the remediated commit, and their parent all have tree `7b81b3ebba99993b21bf2426b5f5a490ec1c33f2`, so only the commit message changed. The remediated message has no trailers. Immediately before the rewrite, `git ls-remote` showed the remote still at `c50aa798`. The single rewrite push used:

```bash
git push --force-with-lease=refs/heads/tnyx/tnyx-232-attribution-guard-live-validation:c50aa798fdf69986038c1137b25e9dae828e1a31 origin HEAD:refs/heads/tnyx/tnyx-232-attribution-guard-live-validation
```

Result `c50aa798...9d3b8fa2 (forced update)`. Plain `--force` was not used; `main`, `eedccb9c`, `882890bf`, and every other branch were not rewritten.

**PASS run 35715530945**: trusted checkout `3ebe9f7c`; fixtures 18/18; `fetched PR #311 head 9d3b8fa28b5af68eb221b35a7dffbd21a1924f58 as data only`; `EXCEPTION_PR:` empty; range `3ebe9f7c..9d3b8fa2`; `no prohibited AI attribution found`; job SUCCESS.

Residual trace: the bad SHA stays visible in PR #311's timeline as a force-push entry. It never reached `main`, so it does not affect the repository contributor graph.

External `Code scanning AI findings on PR #311` (`github-advanced-security`) runs failed on every head, including `c50aa798` (run 35715435651) and `9d3b8fa2` (run 35715535345), with the same `sweagent-capi:claude-opus-5[ReasoningEffort=medium]` unsupported-model infrastructure error seen on PR #310 — not repository guard evidence either way.

## Final Status

`In progress` — clean baseline PASS, deliberate FAIL, and post-remediation PASS all proven live. PR #311 left Draft/open, not merged. Remaining: required-check branch protection/ruleset, `pull_request_target` Actions-policy verification, and final GitHub #283 / TNYX-232 reconciliation — each a separate authorized gate.
