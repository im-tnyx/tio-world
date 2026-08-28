# Supabase Server Access Modes

## Status

**Canonical architecture for future server-side Supabase access.**

This document defines how future Tio server code chooses between user-scoped and privileged Supabase access. It is an architecture/documentation decision only; it does not start `services/api`, add middleware, deploy a worker, create credentials, or mutate Supabase.

Related identity contract: [Authentication Architecture](AUTH_ARCHITECTURE.md).

## Core Rule

The default server path is **user-scoped**, not privileged.

```text
verified caller identity
  -> user-scoped Supabase access
  -> existing RLS / ownership policy continues to apply
```

Privileged access is an explicit exception:

```text
trusted system workflow
  -> explicit privileged boundary
  -> narrow approved operation
  -> server-only credential
```

A server process being trusted to run Tio code does not automatically mean every database operation should bypass user authorization.

## Mode 1 — User-Scoped Access

Use user-scoped access when the operation is being performed on behalf of an authenticated end user and should continue to respect that user's normal authorization boundary.

Typical examples:

- user-owned Profile/account reads or writes;
- user-owned Workout/Nutrition/Progress operations;
- APIs that are primarily a protected transport/orchestration layer around data the caller could otherwise access through approved RLS policy;
- server workflows where preserving `auth.uid()`-style ownership semantics is part of the security contract.

Conceptual flow:

```text
Tio client
  -> Supabase Auth access token
  -> future Tio API verifies token
  -> canonical user UUID derived from verified `sub`
  -> Supabase request executes in caller context
  -> RLS / owner policy authorizes the data operation
```

Rules:

- The caller identity must come from the verified Supabase token, never from a request-body `user_id`.
- The access mode should preserve user authorization/RLS semantics where the operation is user-owned.
- The server must not silently replace a user-scoped operation with privileged credentials merely because doing so is easier.
- A valid authenticated identity still does not authorize access to another user's rows.
- Module/business authorization may be stricter than database RLS and must be checked where required.

## Mode 2 — Privileged Access

Privileged Supabase access is reserved for trusted system work that cannot correctly be expressed as an ordinary end-user operation.

Candidate categories:

- verified webhook processing;
- internal reconciliation/repair workflows;
- scheduled or queued system jobs;
- tightly scoped administrative operations;
- cross-user aggregation or maintenance that is explicitly authorized by product/security policy;
- trusted Auth/admission operations that require a server-only capability and intentionally do not expose arbitrary account lookup to normal clients.

Privileged mode must **not** be selected simply because:

- a route is implemented on the backend;
- the caller is authenticated;
- RLS blocks an operation that was not properly designed;
- a developer wants to avoid writing ownership/authorization checks;
- a provider SDK is easier to initialize with a secret credential.

## Privileged Boundary Requirements

Every privileged operation must have an explicit reason and a narrow contract.

At minimum, the implementation slice must define:

1. **Trigger/actor** — authenticated admin, verified webhook, scheduled job, queue worker, internal reconciliation, etc.
2. **Authorization rule** — why the workflow is allowed to use elevated access.
3. **Scope** — exact tables/functions/resources and actions required.
4. **Input trust** — which inputs are authenticated/verified before privileged access is used.
5. **Data minimization** — fetch/change only what the workflow requires.
6. **Auditability** — sufficient safe metadata to diagnose the operation without logging secrets or unnecessary health/private data.
7. **Failure behavior** — fail closed; never fall back from failed user-scoped authorization to privileged access.

A generic "admin Supabase client available everywhere" is not an approved architecture.

## Credential Rules

Server-secret / privileged Supabase credentials are server-only.

They must never be present in:

- Flutter phone builds;
- Wear OS builds;
- future watchOS builds;
- public web/client bundles;
- committed `.env` files;
- logs, analytics, crash reports, screenshots, issue text, or client-visible error payloads.

Future runtime secrets must come from approved server-side secret/environment management and be rotatable without code changes.

Client-safe Supabase configuration and server-secret credentials are separate categories and must never be conflated.

## Authentication vs Database Access Mode

Authentication and Supabase access mode are separate decisions.

```text
Step 1: authenticate caller
  -> verify Supabase access token
  -> derive canonical user identity

Step 2: authorize requested workflow
  -> decide whether operation is user-scoped or explicitly privileged

Step 3: execute minimum required data operation
```

An authenticated caller does not justify privileged access.

Likewise, a privileged system workflow may have no end-user caller at all, but it still requires an explicit trusted trigger and authorization contract.

## Decision Matrix

| Workflow | Default mode | Why |
| --- | --- | --- |
| User reads/updates own profile | User-scoped | Preserve normal ownership/RLS |
| User logs own workout/meal/progress | User-scoped | Caller-owned data |
| Protected API adds orchestration around caller-owned data | User-scoped | Backend presence alone is not privilege |
| Verified provider webhook reconciliation | Privileged | Trusted system event, no normal user session |
| Scheduled maintenance/reconciliation job | Privileged | System-owned operation with explicit scope |
| Cross-user admin/support action | Privileged, only if separately authorized | Elevated business capability |
| RLS denies an ordinary user request | **Do not escalate** | Authorization failure is not a reason to bypass RLS |
| Pre-login canonical Auth admission helper | Privileged narrow helper where required | Must be server-owned and intentionally constrained |

## Current Repository Grounding

The repository already demonstrates why the distinction matters:

- normal application data ownership is designed around authenticated users and RLS;
- server-owned Auth/admission helpers use narrowly scoped trusted paths rather than exposing arbitrary account existence/ownership lookup to clients;
- `google-login-admission` is an example of a bounded trusted operation where server-side authority is required for admission classification;
- service-role/secret material must remain outside Flutter/watch clients.

These existing patterns do not authorize a future backend to use privileged access globally. The future API should begin with user-scoped access and introduce privileged clients only inside explicitly reviewed infrastructure/module boundaries.

## Recommended Future Code Shape

No code is created by this task, but future implementation should make the distinction visible in naming/composition rather than hiding it behind one generic Supabase singleton.

Conceptual shape only:

```text
infrastructure/supabase/
  user-scoped client/factory
  privileged client/factory   # server-only, narrowly injected
```

Module code should receive only the capability it needs. A normal user-facing module should not automatically receive a privileged client.

Exact file names and SDK APIs belong to the future implementation slice.

## Fail-Closed Rules

- Never retry an RLS/authorization denial with privileged credentials.
- Never trust a client-provided user UUID as the privileged-operation target without deriving/authorizing it through the workflow contract.
- Never expose privileged errors that reveal private account existence or cross-user data.
- Never log server secrets or raw Bearer credentials.
- Never make privileged access the implicit fallback when user-scoped configuration is unavailable.

## Backend Implementation Gate

This architecture decision does not authorize backend runtime work.

Until a separate implementation task is explicitly started:

- no `services/api` scaffold is required;
- no Supabase server client wrapper is required;
- no privileged key/secret is created or rotated;
- no Edge Function is redeployed;
- no database/RLS change is required;
- no worker/job infrastructure is created.

## Acceptance for TNYX-25

- [x] User-scoped and privileged Supabase server access are explicitly separated.
- [x] User-scoped access is the default for caller-owned operations that should preserve RLS/authorization semantics.
- [x] Privileged access requires an explicit trusted trigger, authorization reason, and narrow scope.
- [x] Service-role/secret credentials are explicitly forbidden from Flutter/watch/client distribution.
- [x] Authorization failures must not auto-escalate to privileged access.
- [x] Future server composition must avoid a globally available privileged client by default.
- [x] No backend runtime or Supabase mutation is introduced by this documentation slice.
