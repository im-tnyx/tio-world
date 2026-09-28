# Delegated OAuth Authorization Contract

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: Security & Identity + Connector Architecture
Truth Boundary: Authoritative for Tio's delegated connector client, scope, consent, token-lifecycle, and revocation semantics; not proof that an OAuth authorization server, connector persistence, consent UI, or connector runtime is implemented.

## Status

**Architecture/security contract for TNYX-173 C0.1. Runtime implementation is not started by this document.**

This document builds on [Connector Trust Boundary and V1 Exposure Policy](CONNECTOR_TRUST_BOUNDARY.md) and [ADR-0012](../adr/0012-delegated-external-connector-trust-boundary.md).

Tio's external connector authorization is a Tio-controlled delegated-access system. It is not a Supabase user session exposed to another application, and it is not a second Tio identity authority.

The first connector release remains **read-only**.

## Standards Baseline

Tio's delegated authorization design follows published OAuth 2.0 security standards and keeps compatibility with the direction of OAuth 2.1.

As of 2026-09-28:

- [RFC 9700 — OAuth 2.0 Security Best Current Practice](https://www.rfc-editor.org/rfc/rfc9700.html) is the published security baseline.
- [RFC 7636 — Proof Key for Code Exchange (PKCE)](https://www.rfc-editor.org/rfc/rfc7636.html) defines PKCE.
- [RFC 7009 — OAuth 2.0 Token Revocation](https://www.rfc-editor.org/rfc/rfc7009.html) defines token revocation behavior.
- [RFC 8414 — OAuth 2.0 Authorization Server Metadata](https://www.rfc-editor.org/rfc/rfc8414.html) defines authorization-server metadata.
- [RFC 8252 — OAuth 2.0 for Native Apps](https://www.rfc-editor.org/rfc/rfc8252.html) applies if Tio later approves native public connector clients.
- The OAuth 2.1 framework is still an active IETF Internet-Draft, not a final RFC. Tio may track its direction but must not claim final OAuth 2.1 conformance until the standard and implementation actually justify that claim.

When a later implementation begins, TNYX-245 must re-check the current published standards and client-provider requirements rather than assuming this document freezes external standards forever.

## Authorization vs Identity vs Domain Permission

Three concepts remain separate:

```text
canonical Tio authentication
  = who the Tio user is

delegated OAuth authorization
  = which registered connector client has which user-owned grant/scopes

Tio domain authorization
  = whether that resolved user/client/grant may perform the requested capability on the requested resource
```

Supabase Auth remains the canonical Tio identity authority.

A connector credential, client identifier, external account, OAuth token subject, Email, Phone, conversation text, or another app's identity is not independently authoritative for the canonical Tio user.

Every protected connector request must resolve:

```text
validated connector credential
  -> active registered connector client
  -> active user-owned connector grant
  -> canonical Tio user from that grant
  -> effective Tio scopes
  -> capability availability / rollout / entitlement / quota / confirmation
  -> Tio domain/resource authorization
  -> bounded operation
```

## Client Registration Contract

### V1 registration model

The first production connector clients are **pre-registered** by Tio.

V1 does not provide an open or dynamic client-registration endpoint.

Each registered client conceptually has:

- a stable opaque `client_id`;
- environment ownership: development/staging/production identities do not share production authority;
- client type: public or confidential;
- active/disabled status;
- approved redirect URI set where redirect flows apply;
- approved scope ceiling;
- human-reviewable client display/publisher metadata for consent;
- an approved token-endpoint authentication method when the client is confidential;
- operational ownership/contact information outside user-visible secrets.

This is a contract, not a persistence schema. TNYX-246 owns the eventual data model.

### Public clients

A public client cannot safely keep a client secret.

Rules:

- no client secret may be treated as confidential merely because it is embedded in a native/browser app;
- redirect-based delegated authorization uses Authorization Code + PKCE with `S256`;
- a public client cannot gain authority because it knows its `client_id`;
- a browser-based public client is not automatically approved by this contract and requires the applicable current browser-app security review before production use;
- a native public client, if later approved, must follow the applicable native-app BCP and platform redirect rules.

### Confidential clients

A confidential client runs in a trusted server environment capable of protecting its authentication material.

Rules:

- it must authenticate to the token endpoint using an approved method selected by TNYX-245;
- its client secret/private key, if any, is server-only under [Secrets & Environment Strategy](../security/SECRETS_AND_ENVIRONMENTS.md);
- Tio requires PKCE `S256` for supported redirect-based confidential connector clients as a consistent defense-in-depth contract;
- a confidential client credential proves the connector client, not the Tio user and not a domain permission.

Where practical and interoperable, TNYX-245 should prefer stronger client-authentication mechanisms over long-lived shared symmetric secrets, consistent with current OAuth security guidance.

### First-party vs third-party designation

A first-party designation may affect administrative registration/trust review, but it does **not** bypass:

- user-owned grant resolution;
- requested/granted scope checks;
- domain/resource authorization;
- entitlement/quota/rollout controls;
- write confirmation rules when writes are eventually approved.

Third-party clients require production approval/verification before registration. This slice does not design a public developer-registration program.

## Authorization Request Contract

For redirect-based delegated access, Tio's direction is Authorization Code flow with PKCE.

The authorization request must be bound to:

- one registered client;
- one approved redirect URI;
- one authorization transaction;
- one authenticated canonical Tio user session at the authorization boundary;
- one PKCE `S256` challenge;
- explicit requested Tio scopes;
- CSRF/request-correlation state appropriate to the client flow.

Rules:

- requested redirect URIs must match the client's pre-registered values exactly in V1;
- no arbitrary redirect forwarding/open redirector is allowed;
- no implicit grant/token-in-redirect flow is part of the Tio connector contract;
- the resource owner must not share Tio primary credentials with the connector;
- authorization codes are single-use and short-lived;
- the authorization code is bound to the client, redirect transaction, PKCE verifier/challenge, user-owned grant, and approved scope result;
- unknown, disabled, unavailable, or unapproved scopes fail closed;
- an omitted scope parameter must not silently become an all-data grant.

A later explicitly approved native loopback client may implement the applicable RFC 8252 loopback-port rule rather than weakening general redirect matching.

## Scope Taxonomy

### V1 read families

The first read-only connector release recognizes these scope families:

```text
profile.read
goals.read
nutrition.read
workout.read
progress.read
sleep.read
```

Rules:

- a scope is permission to evaluate bounded capabilities in that domain, not raw-table or unrestricted-history access;
- `sleep.read` remains unavailable until canonical Tio sleep/recovery data and its capability contract exist;
- scope presence never replaces domain ownership checks;
- scopes do not authorize secrets, internal audit data, service credentials, or operator controls;
- no wildcard/all-user/all-health scope exists in V1;
- requested scopes must be within both the registered client's allowed scope ceiling and the currently enabled product capability set.

### Future write families

Known future write scope families are:

```text
plan.write
nutrition.write
workout.write
```

They are **reserved taxonomy only** in V1.

The V1 authorization server implementation must not issue effective write authority merely because these names are documented. Write activation requires the later safe-write policy and its separately approved implementation slices.

### OIDC/identity scopes

OIDC scopes/claims such as `openid`, `profile`, or `email`, if ever supported for an approved interoperability need, are identity-layer concepts.

They do not grant Tio domain access and do not replace `profile.read`, `nutrition.read`, `workout.read`, or other Tio capability scopes.

V1 connector authorization does not require Tio to issue ID tokens. Any future OIDC ID-token surface requires an explicit implementation requirement and security review.

## Effective Permission Calculation

A token's scope representation is an **issuance ceiling**, not a permanent authorization snapshot.

For every protected request:

```text
effective scopes
  = scopes represented by the validated credential
  ∩ current active grant scopes
  ∩ current client allowed scopes
  ∩ currently enabled capability/scope policy
```

Then Tio still applies:

```text
effective scopes
  + canonical Tio user
  + resource/domain ownership
  + entitlement / quota / rollout
  + write confirmation when applicable
  -> effective permission
```

Consequences:

- grant revocation takes effect even if a previously issued access token has not expired;
- a scope downgrade takes effect without waiting for old access-token expiry;
- a scope upgrade does not make an old token more powerful; the client must complete the required re-consent/authorization flow and receive new credential authority;
- disabled clients fail before domain operations;
- token claims alone cannot bypass current server-authoritative grant/client policy.

This requirement constrains TNYX-245/TNYX-246 implementation choices. A self-contained token format is acceptable only if the protected resource path can still enforce current client/grant state.

## Consent Contract

Consent is granted to a specific **client + canonical Tio user + scope set**.

The future consent experience must communicate:

- which connector/client is requesting access;
- whether each requested permission is read or future write authority;
- which Tio domain/purpose the permission covers in user-understandable language;
- that access can be disconnected/revoked;
- that a scope is bounded and does not imply unrestricted export;
- any material provider/privacy implication required by the canonical privacy policy.

Consent rules:

- the user grants an explicit approved subset of requested scopes;
- unknown/unavailable scopes cannot be consented into existence;
- scope upgrade requires explicit re-consent before the new authority becomes active;
- scope downgrade takes effect immediately in current grant evaluation;
- write scope activation, when later allowed, may require stronger confirmation than read consent;
- consent/audit records store authorization metadata, not health payloads;
- first-party designation alone does not eliminate the user-owned grant model.

This document defines semantics, not screen layout/copy styling. Product-visible consent UI requires its owning approved UI slice.

## Credential Lifecycle

### Authorization codes

Authorization codes are:

- single-use;
- short-lived;
- transaction-bound;
- unusable without the matching PKCE verifier;
- invalid after redemption, expiry, cancellation, or relevant transaction invalidation.

Authorization-code values must not appear in normal logs/analytics.

### Access tokens

Access tokens are:

- short-lived;
- audience/resource constrained to approved Tio connector resources as defined by the implementation;
- free of unnecessary Personal/Health-context claims;
- validated before every protected request;
- insufficient by themselves without current client/grant/domain authorization.

Exact token format, signing/verification method, and lifetime are owned by TNYX-245.

An opaque token or a signed/self-contained token may be selected later. Neither choice may weaken the current-grant evaluation requirement.

### Refresh tokens

Refresh tokens are not automatic for every client/use case.

When issued:

- they are sensitive credentials;
- they are bound to the registered client, user-owned grant, and token family;
- rotation is required;
- a used refresh token becomes invalid for another successful rotation;
- reuse of an already-rotated refresh token is treated as compromise/replay and must fail closed;
- the affected token family must be invalidated or otherwise made unusable according to the concrete TNYX-245/TNYX-246 design;
- refresh never resurrects a revoked/disabled grant or a removed scope;
- refresh issuance/storage never requires plaintext long-term token persistence when a safer verifier/hash design can satisfy the implementation.

Exact expiry/authorization-duration values remain an implementation decision and must be documented before production.

### Sender-constrained tokens

Published OAuth security guidance recommends sender-constrained access tokens where practical.

TNYX-245 must evaluate supported clients/provider interoperability for DPoP, mTLS, or another approved mechanism. If V1 uses bearer access tokens instead, the implementation review must explicitly record the compensating short lifetime, grant-state enforcement, replay/abuse controls, and interoperability rationale.

This architecture slice does not pre-select DPoP or mTLS.

## Re-Consent, Revocation, Disconnect, and Logout

### Scope upgrade

```text
existing grant
  -> request additional scope
  -> explicit re-consent
  -> update approved grant authority
  -> issue credentials reflecting the new ceiling
```

No silent scope escalation is allowed.

### Scope downgrade

A user/client may reduce requested authority.

After downgrade:

- current grant scopes are reduced immediately;
- refresh cannot restore removed scopes;
- existing access-token scope claims cannot exceed the reduced effective grant;
- implementation may rotate/revoke affected token families as defense in depth.

### Token revocation

TNYX-245 will implement the token-revocation surface consistent with RFC 7009 or the then-current applicable standard.

Revoking one token and disconnecting a Connected App are distinct operations.

### User disconnect

Disconnect means the user revokes the connector grant.

It must:

- make the grant inactive/revoked;
- prevent subsequent protected operations under that grant;
- invalidate refresh capability/token families associated with that grant;
- prevent stale access tokens from retaining effective access because current grant state is mandatory;
- create minimal audit history without sensitive payloads.

### First-party Tio logout

Logging out of a Tio phone/watch session and disconnecting an external connector are separate lifecycles.

A normal Supabase Auth logout does not silently become connector-grant revocation. A connector remains governed by its own grant until the user disconnects it, account deletion invalidates it, it expires under an approved future policy, or an operator/security control disables it.

### Client compromise/operator disable

When a connector client is compromised or administratively disabled:

- new authorization/token activity fails;
- protected resource requests for the disabled client fail before domain operations;
- token families/grants may be invalidated according to the incident policy;
- restoration requires explicit operator action and must not silently revive revoked user grants.

TNYX-177 owns the detailed operational kill-switch and incident-response contract.

## Account Deletion

Connector authorization state must participate in Tio's account-deletion lifecycle.

Account deletion must ensure:

- no future connector request can resolve an active grant for the deleted account;
- refresh/token-family use for that user's grants fails;
- connector-owned user records join the deletion/expiry/approved-retention graph;
- provider-held artifacts follow the documented provider deletion/expiry limitations;
- security/audit records retained for an approved purpose minimize identity linkage and health content.

TNYX-246 owns concrete persistence/deletion implementation. This document does not authorize table creation.

## Service-to-Service Credentials

Machine/service credentials are distinct from end-user delegated authorization.

A service-to-service credential:

- does not represent a user's connector consent;
- must not carry end-user `profile.read`/health scopes as a shortcut to impersonation;
- has its own trusted workload identity, audience, permission, secret, and operational lifecycle;
- cannot be exchanged for a user grant merely because it belongs to the same organization/client.

Any future service-to-service connector capability requires a separately approved implementation contract.

## Error and Fail-Closed Semantics

The authorization/resource boundary must fail closed for at least:

- unknown/disabled client;
- redirect mismatch;
- invalid/missing PKCE transaction;
- authorization-code expiry/reuse/mismatch;
- invalid/expired/revoked credential;
- refresh-token replay/reuse;
- inactive/revoked/deleted grant;
- scope not granted or no longer enabled;
- unresolved canonical Tio user;
- cross-user resource substitution;
- missing domain authorization;
- unsupported canonical data/capability.

Public errors must be sanitized and must not reveal whether another user/account/grant exists.

OAuth protocol error shapes are owned by TNYX-245 and must follow the applicable standard without leaking secrets/internal state.

## Audit and Privacy Contract

Authorization telemetry may record safe metadata such as:

- request/correlation ID;
- connector client identifier;
- safe grant reference;
- safe canonical-user reference;
- requested/granted scope names;
- authorization/consent/revocation event type;
- token-family safe reference where needed;
- result/error class;
- environment;
- timestamps required for security/operations.

It must not log:

- access tokens;
- refresh tokens;
- authorization codes;
- PKCE verifier;
- Authorization headers;
- client secrets/private keys;
- raw Health-context payloads;
- unnecessary Email/Phone/profile data.

Provider/privacy review remains required before a production external client receives Personal, Sensitive, or Health-context data.

## Runtime-Host Neutrality

This contract does not select the OAuth authorization-server host.

The public semantics remain:

```text
registered client
  -> delegated authorization
  -> client + grant + canonical Tio user + effective scopes
  -> domain authorization
  -> bounded capability
```

A later approved implementation may use a narrow Supabase server boundary only if the complete security contract can be enforced safely there.

Future `services/api` is used only when TNYX-245 or another approved slice proves an ADR-0007 protected-server trigger.

The external client must not depend on:

- Supabase table names;
- RLS policy names;
- Edge Function URLs as durable domain identity;
- Supabase user sessions;
- service-role credentials;
- internal token persistence layout.

## Implementation Handoff

### TNYX-245 must implement

- authorization endpoint;
- token endpoint;
- revocation endpoint;
- Authorization Code + PKCE S256;
- exact registered redirect validation;
- state/CSRF and applicable mix-up protections;
- short-lived access credential issuance/validation;
- refresh rotation/reuse handling when refresh is enabled;
- environment-isolated client registration;
- authorization-server metadata where applicable;
- token/client authentication strategy;
- current-standards revalidation;
- automated negative-path tests.

### TNYX-246 must implement

- server-authoritative client/grant persistence;
- canonical Tio user bridge;
- current grant status/scope evaluation for protected requests;
- token-family/consent/revocation metadata required by the approved token strategy;
- account-deletion integration;
- migration/RLS/privileged-access strategy with separate data-shape approval;
- cross-user substitution tests.

### TNYX-174 and domain contracts must define

- tool/capability schemas;
- capability-to-scope mapping;
- bounded field/range semantics;
- protocol/vendor-neutral domain contracts.

### TNYX-177 must define/implement before production

- abuse/rate controls;
- audit operations;
- operator client disable/kill switch;
- compromised-client incident handling;
- user-visible safe connection history requirements.

## Explicit Non-Goals

TNYX-173 Slice A does not:

- deploy an OAuth authorization server;
- create authorization/token/revocation endpoints;
- create connector tables, migrations, RLS, RPCs, triggers, or views;
- mint or store real client secrets/signing keys/tokens;
- create Supabase Edge Functions;
- scaffold `services/api`;
- build consent/Settings/Integrations UI;
- register or publish a ChatGPT client;
- expose any connector tool;
- enable write scopes;
- select a token signing algorithm/provider;
- set production token lifetime numbers;
- create a public developer/dynamic client-registration system.

## Related Policy

- [Connector Trust Boundary and V1 Exposure Policy](CONNECTOR_TRUST_BOUNDARY.md)
- [Authentication Architecture](../security/AUTH_ARCHITECTURE.md)
- [Security](../security/SECURITY.md)
- [Secrets & Environment Strategy](../security/SECRETS_AND_ENVIRONMENTS.md)
- [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md)
- [Supabase Server Access](../data/SUPABASE_SERVER_ACCESS.md)
- [ADR-0007: Active Supabase and Future services/api](../adr/0007-active-supabase-and-future-services-api.md)
- [ADR-0012: Delegated external connector trust boundary](../adr/0012-delegated-external-connector-trust-boundary.md)
- [ADR-0013: Delegated OAuth authorization contract](../adr/0013-delegated-oauth-authorization-contract.md)
