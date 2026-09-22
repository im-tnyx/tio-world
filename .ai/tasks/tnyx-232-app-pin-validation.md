# TNYX-232 / GitHub #283 — Required-Check App Source Pin Validation Carrier

**Status:** In progress
**Primary owner:** repository governance
**Affected platforms:** None (docs-only validation carrier)

## Purpose

Disposable carrier for a pull request that is never merged. All commits are clean, so the Tio Attribution Guard App (App ID `5032971`) should post `Commit attribution guard` as success. A PR-only workflow also publishes a `github-actions` check with the same name that fails deliberately. If `main` protection is pinned to App ID `5032971`, the failing same-name `github-actions` check must not block the merge.

## Scope

No workflow on `main`, checker, product, runtime or Supabase change. The probe workflow exists only on this disposable branch.
