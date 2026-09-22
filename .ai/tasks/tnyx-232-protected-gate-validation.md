# TNYX-232 / GitHub #283 — Protected Gate Validation Carrier

**Status:** In progress
**Primary owner:** repository governance
**Affected platforms:** None (docs-only validation carrier)

## Purpose

Disposable carrier for a pull request that is never merged. It proves, against the classic `main` branch protection that requires `Commit attribution guard` from the Tio Attribution Guard App (App ID `5032971`), that:

- A. a clean head satisfies the required check;
- B. a prohibited AI `Co-Authored-By` trailer makes the App check fail and the pull request blocked;
- C. a same-name `github-actions` check that succeeds does not satisfy the requirement pinned to App ID `5032971`.

## Scope

This file changes no workflow on `main`, no checker, and no product, runtime or Supabase code. The negative-probe commit and the spoof-probe workflow exist only on this disposable branch.
