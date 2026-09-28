# ADR-0013: Delegated OAuth authorization contract

Document Status: Architecture Decision Record
Last Verified: 2026-09-28
Owner: Security & Identity + Connector Architecture
Truth Boundary: Authoritative for the durable delegated OAuth client/grant/scope/token-lifecycle direction; not proof that OAuth endpoints, connector persistence, or a production connector runtime exist.

- **Status:** Accepted
- **Date:** 2026-09-28

## Context

ADR-0012 established that external connectors use Tio-controlled delegated credentials over a user-owned connector grant, while Supabase Auth remains Tio's canonical identity authority. It intentionally deferred the exact OAuth client, consent, token, revocation, and persistence contract.

TNYX-173 must freeze those semantics before TNYX-245 builds an authorization server or TNYX-246 creates connector grant/token persistence.

The design must:

- preserve the canonical Tio user identity rather than create a second identity authority;
- support least-privilege user consent;
- make revocation/scope reduction effective without waiting for stale token expiry;
- remain compatible with current Supabase-hosted protected execution and future `services/api`;
- avoid treating an evolving OAuth 2.1 Internet-Draft as a final RFC;
- follow published OAuth security best practices.

## Decision

Tio uses a pre-registered delegated OAuth client model for the first connector release.

Redirect-based delegated authorization uses **Authorization Code + PKCE S256** for supported public and confidential connector clients.

The external authorization chain is:

```text
registered connector client
  -> authenticated canonical Tio user
  -> explicit user-owned connector grant
  -> one-time authorization code + PKCE
  -> Tio connector credential
  -> current client + current grant validation
  -> canonical Tio user from grant
  -> effective scopes
  -> Tio domain/resource authorization
  -> bounded capability
```

V1 client registration is controlled/pre-registered. Dynamic/open client registration is not part of V1.

The initial read-scope families are:

```text
profile.read
goals.read
nutrition.read
workout.read
progress.read
sleep.read
```

`sleep.read` is not effective until the canonical Tio data/capability exists.

The known future write-scope families `plan.write`, `nutrition.write`, and `workout.write` are reserved taxonomy only and are not requestable/effective in the first read-only release.

For every protected request, effective scope is constrained by current server-authoritative state:

```text
token scope ceiling
∩ current active grant scopes
∩ current active client scope ceiling
∩ enabled capability policy
```

Domain/resource authorization, entitlement, quota, rollout, and future write-confirmation policy still apply afterward.

Consequently:

- a revoked grant fails future requests even if an access token has not expired;
- a scope downgrade takes effect immediately;
- a scope upgrade requires explicit re-consent and new credential authority;
- a connector token/client subject is not the canonical Tio user; the canonical user comes from the validated grant;
- user disconnect revokes the grant and associated refresh capability/token families;
- normal first-party Supabase logout is distinct from external connector disconnect;
- account deletion invalidates delegated access and joins connector authorization state to the deletion lifecycle.

Access tokens are short-lived. Exact token format, cryptographic method, and lifetime are deferred to TNYX-245.

When refresh tokens are issued, rotation and replay/reuse detection are required. Refresh reuse fails closed and the affected token family becomes unusable according to the implementation contract.

A confidential client proves its own client identity using an approved token-endpoint authentication method; that does not prove a Tio user or domain permission. Public clients do not gain security from embedded client secrets.

OIDC identity scopes/ID tokens are not required for V1 connector authorization and never replace Tio domain scopes. Any future OIDC issuance requires a separately justified interoperability need.

Tio uses published OAuth security standards, especially RFC 9700, as the normative security baseline. OAuth 2.1 compatibility is directional while OAuth 2.1 remains an Internet-Draft.

The public authorization semantics are runtime-neutral. This ADR does not choose Supabase vs `services/api` as the OAuth authorization-server host.

## Alternatives

### Reuse Supabase user sessions as external connector credentials

Rejected by ADR-0012. It would couple external clients to first-party session semantics and weaken the explicit client/grant/scope boundary.

### Treat token claims as the complete authorization snapshot until token expiry

Rejected. User disconnect, scope downgrade, account deletion, or client disable must take effect against current server-authoritative state.

### Allow dynamic/open client registration in V1

Rejected. The initial connector product does not require an unaudited registration surface, and pre-registration materially reduces redirect/client-trust attack surface.

### Enable documented write scopes immediately

Rejected. ADR-0012 freezes the first connector release as read-only. Write policy and pilots remain separately gated.

### Scaffold `services/api` now for OAuth

Rejected. ADR-0007 requires a concrete protected-server trigger in the implementation slice; TNYX-173 is a runtime-neutral architecture contract.

## Consequences

### Positive

- TNYX-245 and TNYX-246 can implement one consistent user/client/grant/scope model.
- Revocation and scope reduction remain server-authoritative.
- Public and confidential clients share one PKCE-based redirect-flow baseline.
- External clients do not depend on Supabase sessions or persistence details.
- Scope naming stays stable across a future host migration.
- First-release risk is bounded by pre-registered clients and read-only effective scopes.

### Constraints / Trade-offs

- Protected connector requests must consult enough current client/grant state to enforce revocation/downgrade even if signed/self-contained access tokens are chosen.
- Token format/key strategy, exact lifetimes, sender-constrained token support, and token-endpoint client-auth method remain implementation decisions.
- Consent UI and Connected Apps UX remain separate approved product work.
- Connector persistence will require a later Supabase table/column owner-approval gate.
- OAuth 2.1 is still work in progress, so TNYX-245 must re-check standards at implementation time.

## Links

- Linear: https://linear.app/tnyx/issue/TNYX-173/c01-define-delegated-oauth-scopes-consent-token-lifecycle-and
- Canonical delegated authorization policy: [Delegated OAuth Authorization Contract](../integrations/DELEGATED_OAUTH_AUTHORIZATION.md)
- Parent trust decision: [ADR-0012](0012-delegated-external-connector-trust-boundary.md)
- Runtime-host boundary: [ADR-0007](0007-active-supabase-and-future-services-api.md)
- Authentication architecture: [Authentication Architecture](../security/AUTH_ARCHITECTURE.md)
- Privacy policy: [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md)
