# Connector Trust Boundary and V1 Exposure Policy

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: Connector Architecture + Security & Identity
Truth Boundary: Authoritative for Tio's pre-implementation external-connector trust boundary, V1 exposure classes, threat baseline, and runtime-host escalation rule; not proof that connector OAuth, grants, tools, ChatGPT publishing, or services/api are implemented.

## Status

**Architecture/security baseline for TNYX-172 C0.0. Runtime implementation is not started by this document.**

Tio may expose bounded user-owned capabilities to ChatGPT-style and future external clients only through a Tio-controlled delegated-authorization boundary. External clients do not become a Supabase client/session boundary and do not receive persistence-level access.

The first connector release is **read-only**. Write capabilities remain separately gated.

The durable decision history for this boundary is recorded in [ADR-0012: Delegated external connector trust boundary](../adr/0012-delegated-external-connector-trust-boundary.md).

## Canonical Trust Boundary

~~~text
External AI / connector client
  -> Tio delegated authorization boundary
  -> authenticated connector credential
  -> connector client identity
  -> user-owned connector grant
  -> canonical Tio user identity
  -> effective scopes / capability eligibility
  -> Tio domain authorization
  -> bounded application/domain capability
  -> current approved Supabase protected execution when sufficient
     OR future services/api only after a concrete approved trigger
  -> canonical Tio data
~~~

The following are never authorization signals by themselves:

- conversation text;
- model inference;
- an external display name;
- another app/connector's account or token;
- a client-supplied Tio user_id;
- a raw Email/phone value;
- a Supabase table name or row identifier not already authorized through a Tio domain capability.

Every connector request must independently resolve the Tio-controlled user/client/grant/scope context required for the requested capability.

## Identity and Authorization Invariants

Supabase Auth remains Tio's canonical identity authority.

External connector credentials are a delegated-access mechanism, not a replacement Tio identity provider. The public connector contract must not expose an implementation-specific Supabase session, Supabase service_role, secret key, privileged database credential, raw SQL interface, or direct table API.

Authentication and authorization remain separate:

~~~text
valid connector credential
  != authorization to every Tio capability

resolved Tio user
  + connector client
  + connector grant
  + effective scope
  + domain/resource authorization
  + applicable rollout/entitlement/quota/confirmation policy
  -> effective permission
~~~

Delegated client registration, scope, consent, PKCE, token-lifecycle, and revocation semantics are defined by [Delegated OAuth Authorization Contract](DELEGATED_OAUTH_AUTHORIZATION.md) and [ADR-0013](../adr/0013-delegated-oauth-authorization-contract.md). TNYX-245 owns the authorization-server endpoints/token implementation, and TNYX-246 owns grant/token persistence plus the canonical-user bridge.

## V1 Capability Classification

### V1 external-safe read class

The first connector implementation may expose only approved, bounded, task-oriented reads. Candidate capabilities already tracked in Linear include:

- profile and goal reads;
- purpose-built nutrition summaries;
- training/workout summaries;
- progress summaries;
- activity/adherence summaries;
- bounded profile/progress audit inputs;
- bounded Workout objects such as routines/workouts only after their domain contracts are explicitly defined;
- exercise/history reads only after the canonical Workout source supports the required identity/range semantics;
- sleep/recovery only after canonical Tio data and its own approved scope exist.

These are capability classes, not authorization to expose every named candidate immediately.

### Future write class

Writes are not part of V1. Examples already tracked for later policy/implementation include:

- goal updates;
- meal logging;
- workout/routine creation or logging;
- plan application;
- notification-preference updates.

A future write must have its own explicit write scope, domain validation, action-risk classification, confirmation policy where required, idempotency, user/client attribution, and audit outcome. TNYX-176 owns the safe-write policy; TNYX-250/TNYX-253 own bounded write pilots.

### Internal-only / not a connector capability

The connector contract must never expose:

- raw Postgres tables or generic row CRUD;
- raw SQL;
- Supabase service_role / secret keys;
- unrestricted database RPC execution;
- private provider/API secrets;
- signing secrets or refresh-token storage internals;
- unrestricted health-history export;
- security/account-administration mutation merely because a user granted ordinary connector access;
- operator controls, internal incident tooling, or kill-switch administration;
- provider-specific payloads where Tio owns a normalized domain contract.

## Data Classification and Purpose Limitation

Connector access inherits Tio's privacy classification and minimization rules.

| Data class | Connector treatment |
|---|---|
| Public/non-user-specific catalog facts | May be exposed only through approved domain capabilities and bounded schemas |
| Personal profile/account context | Minimum fields required for the requested purpose and granted scope |
| Health-context: workout, nutrition, progress, weight/body metrics, fasting/wellness/coaching context, progress photos, biometric, sleep/recovery | Highest applicable product-data caution; private by default; minimum-purpose fields/ranges, bounded pagination/summary, and explicit approved scope/canonical source where required |
| Secrets/tokens/provider credentials | Never returned in connector payloads |
| Internal audit/security metadata | Not part of ordinary connector responses; expose only user-safe connection history where separately designed |

A broad scope does not justify a broad response. The requested operation still determines the minimum necessary fields and time range.

## V1 Scope Taxonomy Direction

TNYX-173 owns the final delegated-authorization contract. The initial scope families already established in Linear are:

~~~text
profile.read
goals.read
nutrition.read
workout.read
progress.read
sleep.read
~~~

Future write families include:

~~~text
plan.write
nutrition.write
workout.write
~~~

Rules:

- read and write scopes remain distinct;
- identity scopes do not replace Tio domain scopes;
- a scope permits evaluation of a capability, not unconditional access to all data in that domain;
- scope upgrade requires explicit grant update/re-consent according to the OAuth contract;
- unsupported/canonical-data-missing capability requests fail closed rather than fabricating data.

## Threat Baseline

The connector architecture must explicitly defend against at least the following threats.

### Over-broad scope or response

**Risk:** a connector receives more Tio data than required.

**Required property:** least-privilege grants plus operation-level field/range minimization. Raw-history export is not the default analysis path.

### Token theft or connector credential leakage

**Risk:** an attacker reuses delegated credentials.

**Required property:** short-lived/rotatable/revocable credential design under TNYX-173/TNYX-245, secret-safe logging, environment isolation, and immediate grant/client disable paths.

### Cross-user substitution

**Risk:** a caller substitutes another Tio UUID/object/grant.

**Required property:** canonical user identity is derived from validated connector context; user IDs from request text/body are never accepted as authentication proof. Ownership checks remain server-side.

### Confused deputy / cross-app composition

**Risk:** another connected app, model output, or conversation content is treated as authorization to broaden a Tio call.

**Required property:** every Tio call independently resolves Tio credential -> client -> grant -> user -> scope -> domain authorization. TNYX-251 owns the expanded cross-app/egress policy.

### Prompt injection through retrieved/external content

**Risk:** content causes the agent to request broader Tio data or unsafe actions.

**Required property:** Tio authorization is policy/code enforced and cannot be expanded by prompt text. Minimum-necessary tool schemas limit available authority.

### Replay and duplicate execution

**Risk:** credentials/codes/actions are replayed.

**Required property:** token/code replay controls are owned by TNYX-245; future writes additionally require semantic idempotency under TNYX-176 and the canonical async/idempotency policy.

### Excessive export

**Risk:** repeated bounded reads reconstruct an unrestricted health/history export.

**Required property:** pagination/range limits, per-user/per-client/per-tool rate controls, usage/audit attribution, and separately designed stronger export policy if broad export is ever added.

### Stale consent / revoked grant

**Risk:** access continues after the user disconnects or scopes change.

**Required property:** server-authoritative grant state; revoked/downgraded grants fail future access/refresh according to TNYX-173/TNYX-177/TNYX-246.

### Connector compromise

**Risk:** one client becomes malicious or leaks credentials.

**Required property:** client-specific registration, audit attribution, environment separation, operator disable/kill switch, and no shared privileged database credential in the external contract.

### Sensitive logging

**Risk:** tokens or health payloads leak through operational telemetry.

**Required property:** request/client/grant/outcome correlation without raw Bearer/refresh tokens or unnecessary health payloads.

## Runtime-Host Decision

### Current evidence

The repository already has narrow Supabase protected-function patterns:

- supabase/functions/nutrition-meal-text-parse/index.ts authenticates a signed-in Supabase user through createSupabaseContext(..., { auth: "user" }), performs a user-scoped user_profiles read, and does not use a privileged DB client.
- supabase/functions/google-login-admission/index.ts demonstrates a bounded external-token verification/admission path with server-held privileged access limited to one reviewed resolver operation.
- supabase/config.toml tracks separate JWT policy for those functions.

These patterns prove that narrowly scoped server-side execution exists in the current Supabase boundary. They do **not** prove that a connector can reuse a Supabase user session or that all connector/OAuth requirements fit an Edge Function.

### C0.0 decision

Do **not** scaffold services/api for connector architecture symmetry.

For the first bounded read-only connector, the implementation target may remain in an approved narrow Supabase protected boundary **only if** the later OAuth/grant design can enforce connector credential -> client -> grant -> canonical Tio user -> scope/domain authorization without exposing Supabase internals as the public contract.

Escalate to services/api only when an approved implementation slice proves an ADR-0007 trigger, for example:

- a connector OAuth/token lifecycle needs a protected server contract that is no longer narrow/suitable for an Edge Function;
- shared protected authorization/orchestration must be enforced consistently across multiple connector routes/capabilities;
- server-only integrations/providers require a coherent protected API boundary;
- long-running/async execution or operational isolation exceeds a narrow function boundary.

The OAuth authorization-server host remains **unselected by the architecture contract**. TNYX-173 keeps the delegated semantics runtime-neutral; TNYX-245 must select an implementation host only after proving the relevant ADR-0007 trigger and current standards/client requirements.

## Migration Invariant

External clients depend on stable Tio connector capability contracts, never on Supabase table/RPC/Edge Function implementation details. The canonical capability/adaptor semantics are defined by [Connector Capability Contract](CONNECTOR_CAPABILITY_CONTRACT.md) and [ADR-0014](../adr/0014-vendor-neutral-connector-capability-contract.md).

A host migration must preserve this logical sequence:

~~~text
external tool contract
  -> delegated authorization semantics
  -> Tio capability/domain contract
  -> implementation adapter
~~~

Therefore moving an approved capability from a Supabase-hosted adapter to services/api later must not require:

- changing its domain owner;
- exposing database schema;
- inventing a second connector identity model;
- changing a Tio canonical identifier merely because transport changed;
- duplicating Workout/Nutrition/Progress business rules in the adapter.

## Minimum Audit/Operations Requirements

Before a production connector pilot, three independent gates apply:

1. **Provider/privacy gate:** before ChatGPT or any other external provider/client receives Personal, Sensitive, or Health-context data, record the provider-specific review required by [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md): provider/capability, transmitted data classes, purpose, authentication/secret boundary, provider storage, configured retention/training/reuse controls, deletion/export limitations, fallback/failure behavior, and ownership for replacement/contract changes.
2. **Account-deletion lifecycle gate:** connector clients/grants/token families and any connector-owned user records must explicitly join Tio's account-deletion graph. Account deletion must prevent future delegated access/refresh by revoking or invalidating the relevant grant/token family, and each connector/provider artifact must have one documented outcome: synchronous deletion, bounded queued deletion, defined short-lived expiry, or explicitly approved retention with minimized linkage. Provider-held artifact deletion/expiry limitations must be recorded rather than assumed.
3. **Operational/audit gate:** Tio must be able to attribute requests without logging unnecessary sensitive payloads.

At minimum the operational model must support:

- connector client identity;
- connector grant identity;
- canonical user attribution through a safe internal reference;
- effective scopes/capability;
- request/correlation ID;
- outcome/error class;
- revocation/consent lifecycle events;
- connector-vs-first-party traffic distinction;
- per-user/per-client/per-tool abuse/rate controls;
- operator client disable / capability kill switch.

TNYX-177 owns the production operational-control implementation contract.

## V1 Explicit Non-Goals

TNYX-172 does not authorize or implement:

- OAuth authorization/token/revocation endpoints, refresh rotation, signing keys, or client secrets;
- connector-client/grant/token tables or RLS;
- ChatGPT client registration, callback domains, listing metadata, publishing, or interactive app UI;
- Tio Settings -> Integrations UI;
- generic raw-history export;
- write actions;
- account deletion/security/billing administration as ordinary connector capabilities; this does not exempt connector grants/tokens/provider artifacts from the account-deletion lifecycle gate above;
- AI-generated Workout/Nutrition plans or plan persistence;
- new queue/worker/cache infrastructure;
- speculative services/api scaffolding.

## Dependency Handoff

After this baseline is accepted:

~~~text
TNYX-172 C0.0
  -> TNYX-173 C0.1 delegated OAuth contract
  -> TNYX-174 C1.0 vendor-neutral capability/gateway contract
  -> TNYX-251 C0.5 cross-app composition/egress policy
~~~

Implementation remains further gated:

~~~text
TNYX-173 -> TNYX-245 OAuth authorization server
TNYX-173 + TNYX-245 -> TNYX-246 grants/token persistence/identity bridge
TNYX-174 -> TNYX-247 / TNYX-252 bounded domain read contracts
TNYX-174 + TNYX-245 + TNYX-246 + domain contracts -> TNYX-248 ChatGPT adapter
~~~

The first production pilot remains TNYX-178 after its complete blocker set is satisfied.

## Related Canonical Policy

- [Authentication Architecture](../security/AUTH_ARCHITECTURE.md)
- [Supabase Server Access](../data/SUPABASE_SERVER_ACCESS.md)
- [Secrets & Environments](../security/SECRETS_AND_ENVIRONMENTS.md)
- [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md)
- [Feature Rollout & Kill Switch](../planning/FEATURE_ROLLOUT.md)
- [ADR-0007: Active Supabase and Future services/api](../adr/0007-active-supabase-and-future-services-api.md)
- [Delegated OAuth Authorization Contract](DELEGATED_OAUTH_AUTHORIZATION.md)
- [Connector Capability Contract](CONNECTOR_CAPABILITY_CONTRACT.md)
- [ADR-0012: Delegated external connector trust boundary](../adr/0012-delegated-external-connector-trust-boundary.md)
- [ADR-0013: Delegated OAuth authorization contract](../adr/0013-delegated-oauth-authorization-contract.md)
- [ADR-0014: Vendor-neutral connector capability contract](../adr/0014-vendor-neutral-connector-capability-contract.md)
