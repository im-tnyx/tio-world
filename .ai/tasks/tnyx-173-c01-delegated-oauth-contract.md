# TNYX-173 C0.1 Slice A — Delegated OAuth authorization contract

**Status:** In progress
**Primary owner:** Security & Identity / Connector Architecture
**Affected platforms:** External connectors / delegated authorization / current Supabase protected boundary / future services/api

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner said `Go` on 2026-09-28 after the fresh post-TNYX-172 connector sequencing audit.
**Approved product/UI/data-shape boundaries:** Architecture/readiness only: freeze Tio's delegated authorization semantics, client classes/registration policy, scope families, consent/re-consent rules, token lifecycle/revocation semantics, account-deletion interaction, and runtime-neutral implementation requirements.
**Explicit non-changes:** No OAuth authorization/token/revocation endpoint implementation; no connector client/grant/token tables or migrations; no RLS/RPC changes; no Supabase Edge Function implementation; no `services/api` scaffold; no client secrets/signing keys; no Settings/consent UI implementation; no ChatGPT registration/publishing; no connector tools; no write capability enablement.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Codex / independent PR review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@f8e861094ed14a125b11d94aac49c0db97479f20`
**Branch:** `tnyx/tnyx-173-c01-delegated-oauth-contract`
**HEAD SHA:** `02f5413e64dabaa1f34ffaf54f0540df4cb63afd` at the latest completed content validation before this review-handoff update
**Observed working-tree state:** GitHub connector branch; no local working tree available.
**Observed uncommitted/dirty files:** Not applicable through GitHub connector.
**PR / tracker:** Linear TNYX-173 In Progress; PR publication pending this handoff commit.
**Current implementation state:** Delegated OAuth authorization semantics, ADR-0013, standards baseline, and canonical Auth/connector authority links are authored; connector OAuth/client/grant runtime remains unimplemented.
**Relevant execution surface:** Current Supabase Auth + protected functions remain runtime truth; connector OAuth host is intentionally unselected in this slice.
**Validation completed at SHA:** `02f5413e64dabaa1f34ffaf54f0540df4cb63afd` — `main` unchanged at `f8e861094ed14a125b11d94aac49c0db97479f20`; branch ahead 10 / behind 0 with exactly 9 owned docs/AI files. Canonical delegated OAuth contract, ADR-0013, docs indexes, connector trust-boundary handoff, Auth link, and ADR-0012 follow-up link were reviewed. Official OAuth standards were re-checked: RFC 9700 is the published security BCP; OAuth 2.1 draft-16 remains an active Internet-Draft.
**Validation remaining:** this handoff update moves HEAD; publish PR, refresh exact-head compare/checks, move Linear to In Review, request/inspect independent review, and resolve only validated findings within scope. Local `git diff --check` is unavailable through connector-only execution and is not claimed as run.
**Current blocker:** none.
**Open review finding IDs:** none.
**Next exact action:** publish the focused PR from this branch, reconcile Linear to In Review, and inspect exact-head required/supplemental security checks plus Codex review.

## 1. Discovery

### User Outcome

Define a stable, least-privilege delegated authorization contract so ChatGPT-style and future external clients can connect to Tio without receiving primary credentials, Supabase sessions, privileged database access, or broader authority than the user's explicit grant.

### Success Criteria

- OAuth authorization is clearly separated from Tio identity authority and domain authorization.
- Public and confidential connector client classes have explicit security expectations.
- Initial read-scope families and future write-scope families are defined without enabling writes.
- Consent, scope upgrade/downgrade, disconnect/revocation, token-family invalidation, and account-deletion behavior are explicit.
- Protected requests resolve client + active user-owned grant + canonical Tio user + effective scopes before domain authorization.
- Revoked/downgraded grants cannot retain stale effective authority merely because an access token has not expired.
- Token/client secrets and health payloads are excluded from ordinary logs/analytics.
- Contract remains runtime-neutral between a later approved narrow Supabase host and future `services/api`.
- TNYX-245 and TNYX-246 can implement from one stable contract without inventing identity/consent semantics.

### Scope

- standards/security baseline for delegated OAuth;
- client classes and initial registration policy;
- authorization-code + PKCE direction;
- redirect/CSRF/mix-up expectations;
- scope taxonomy and effective-scope calculation;
- consent and re-consent semantics;
- access/refresh token lifecycle semantics;
- revoke/disconnect/compromised-client behavior;
- account deletion interaction;
- service-to-service separation;
- OIDC compatibility boundary;
- audit/minimization requirements;
- runtime-host neutrality and implementation handoff.

### Non-Goals

- endpoint implementation;
- OAuth server framework/provider selection;
- token signing algorithm/key-management implementation;
- exact token lifetime numbers;
- persistence/table/RLS design;
- dynamic client registration;
- consent/Settings UI design;
- domain tool schemas;
- write-action confirmation implementation;
- ChatGPT publishing;
- production deployment.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` requires audit-first bounded slices and treats OAuth/external integrations/secrets/Auth/Supabase as security-sensitive boundaries.
- TNYX-172 is Done and its validated archive + canonical connector trust boundary establish a read-only V1 and Tio-controlled delegated credential -> client -> user-owned grant -> canonical Tio user -> effective scopes -> domain authorization chain.
- TNYX-173 is the next C0 authorization contract and blocks TNYX-245, TNYX-246, TNYX-251, TNYX-175, TNYX-176, TNYX-177, and TNYX-249.
- TNYX-245 owns OAuth authorization/token/revocation endpoint implementation; TNYX-246 owns grants/token persistence and the canonical-user bridge.
- GitHub source search on `main@f8e86109...` found no connector OAuth endpoints, PKCE/code-exchange runtime, `connector_clients`, or `connector_grants` implementation.
- `supabase/config.toml` shows current first-party Supabase Auth plus narrow protected-function policies only.
- `nutrition-meal-text-parse` uses a signed-in Supabase user context and user-scoped reads.
- `google-login-admission` verifies an external Google ID token before a Supabase session exists and uses a server-held privileged key only for one narrow resolver operation; this is an admission pattern, not connector delegated OAuth.
- `AUTH_ARCHITECTURE.md`, `SECURITY.md`, and ADR-0012 already separate first-party Supabase-session callers from delegated connector callers.
- `DATA_PRIVACY_GOVERNANCE.md` requires minimum-purpose external sharing and propagated deletion.
- `SECRETS_AND_ENVIRONMENTS.md` classifies access/refresh tokens as sensitive user/session credentials and server client secrets/signing material as server-only.
- Official standards status checked 2026-09-28: OAuth 2.1 is still active Internet-Draft `draft-ietf-oauth-v2-1-16`, so it must not be described as a final RFC. Published OAuth Security BCP RFC 9700 is the current security baseline; RFC 7636/8252, RFC 7009, and RFC 8414 remain relevant published contracts.

### Existing Pattern To Follow

Preserve ADR-0012's delegated trust boundary and runtime-neutral public contract. Use published OAuth security BCP/RFC requirements as the implementation baseline while keeping OAuth 2.1 compatibility as a direction, not a false claim of final-standard conformance.

### Tests or Validation Already Present

No connector OAuth runtime tests exist because the runtime is not implemented. This slice is docs/architecture only; validation is source/standards reconciliation, exact branch scope, references, repository-required checks, and independent review.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| V1 connector authorization uses Authorization Code flow with PKCE for redirect-based delegated clients | Approved for contract | Strong default against code interception/injection; aligns published OAuth security BCP and OAuth 2.1 direction | Security & Identity |
| Require PKCE S256 for all supported redirect-based connector clients | Approved for contract | Simpler single security contract; public clients require it and confidential clients benefit from it | Security & Identity |
| Initial production clients are pre-registered; no dynamic client registration in V1 | Approved for contract | Limits trust/configuration attack surface before production operations mature | Connector Architecture |
| Supabase session/token is never the external connector credential | Locked by ADR-0012 | Prevents first-party session leakage/coupling | ADR-0012 |
| Canonical Tio user for delegated requests comes from validated active grant mapping, not connector token/client subject | Locked | Prevents cross-user substitution and second identity authority | Auth Architecture |
| Access-token format (opaque vs signed/self-contained) | Deferred | TNYX-245 implementation choice; effective authorization must still consult current grant state | TNYX-245 |
| Persistence schema/token-family storage shape | Deferred | TNYX-246; table/column changes require their own approved data-shape slice | TNYX-246 / Owner |
| OAuth authorization-server runtime host | Deferred | Must follow ADR-0007 concrete trigger; this contract remains runtime-neutral | TNYX-245 |
| OIDC ID-token issuance | Deferred/not required for V1 connector authorization | OIDC identity scopes do not replace Tio domain scopes; implement only if an approved client requirement proves need | TNYX-245 / Product |
| Write scopes | Taxonomy only; not requestable in V1 | ADR-0012 freezes first release read-only | TNYX-176/250/253 |

## 4. Architecture Design

### Chosen Approach

A Tio-controlled delegated OAuth authorization contract over pre-registered connector clients and user-owned grants. Redirect-based clients use Authorization Code + PKCE S256. Every resource request resolves current client/grant state and computes effective scopes before Tio domain authorization. Token representation and runtime host remain implementation details behind this stable contract.

### Ownership and Data Flow

```text
user authenticated by canonical Tio/Supabase Auth
  -> authorization request for a pre-registered connector client
  -> validate client + exact approved redirect + PKCE transaction
  -> show/record requested Tio scopes
  -> user grants approved subset
  -> one-time authorization code
  -> token exchange bound to client + PKCE + grant
  -> Tio connector credential
  -> protected request validates credential
  -> resolve active client + active user-owned grant
  -> canonical Tio user from grant
  -> effective scopes = token ceiling ∩ current grant ∩ capability policy
  -> entitlement/rollout/quota/confirmation as applicable
  -> domain/resource authorization
  -> bounded capability
```

### Alternative Rejected

- Reusing Supabase user sessions as connector credentials: rejected by ADR-0012 and canonical Auth architecture.
- Dynamic/open client registration for V1: rejected because the initial product does not need an unaudited registration surface.
- Token claims alone as durable authorization: rejected because disconnect, scope downgrade, account deletion, and client disable must take effect independently of remaining token lifetime.
- Implementing endpoints/schema before freezing this contract: rejected because TNYX-245/246 depend on TNYX-173 and would otherwise invent incompatible semantics.

### Failure and Accessibility States

No UI is implemented in this slice. Future authorization/consent surfaces must fail closed on invalid client/redirect/PKCE/state, unknown or unavailable scopes, revoked/disabled grants/clients, expired/reused token material, or unresolved canonical user identity. Consent copy must be understandable and separate read vs future write authority, but visual UX is owned by later approved UI work.

## 5. Implementation Plan

- [x] Reconcile root governance, current `main`, TNYX-172 archive/canonical output, TNYX-173 dependency graph, TNYX-245/246, and current source/config.
- [x] Verify current OAuth standards status and published security baseline.
- [x] Create approved focused task brief.
- [x] Create canonical delegated OAuth authorization policy under `docs/integrations/`.
- [x] Record durable delegated OAuth decision in ADR-0013 and index it.
- [x] Reconcile connector/Auth docs only where required to avoid conflicting authority; privacy/secrets policies already cover the needed boundaries and remain unchanged.
- [x] Add canonical doc to `docs/README.md`.
- [x] Add active task to `.ai/tasks/README.md`.
- [x] Audit exact branch delta and current `main` required-check metadata.
- [ ] Publish focused PR and move TNYX-173 to In Review only after review-ready.
- [ ] Inspect exact-head Codex/check state and stop at review handoff.

## 6. Quality Review

### Validation Run

```text
Validated content head: 02f5413e64dabaa1f34ffaf54f0540df4cb63afd
Base / merge-base: f8e861094ed14a125b11d94aac49c0db97479f20
Branch compare at that head: ahead 10 / behind 0
Changed files at that head: exactly 9 owned docs/AI paths
- .ai/tasks/README.md
- .ai/tasks/tnyx-173-c01-delegated-oauth-contract.md
- docs/README.md
- docs/adr/0012-delegated-external-connector-trust-boundary.md
- docs/adr/0013-delegated-oauth-authorization-contract.md
- docs/adr/README.md
- docs/integrations/CONNECTOR_TRUST_BOUNDARY.md
- docs/integrations/DELEGATED_OAUTH_AUTHORIZATION.md
- docs/security/AUTH_ARCHITECTURE.md

Runtime/source inspection: PASS
- no connector OAuth endpoints, PKCE/code exchange runtime, connector_clients, or connector_grants implementation on main
- current Supabase protected-function patterns remain first-party session auth or narrow external-token admission; no connector runtime is implied

Canonical reconciliation: PASS
- ADR-0012 trust boundary preserved
- ADR-0013 records the durable delegated OAuth decision
- Auth architecture points delegated callers to the new contract without changing Supabase Auth identity authority
- connector trust-boundary doc hands detailed OAuth semantics to the new canonical contract
- privacy/secrets existing policies already cover token secrecy, external-provider minimization, and deletion requirements

Standards evidence checked 2026-09-28:
- RFC 9700 is published OAuth Security BCP
- RFC 7009 / RFC 7636 / RFC 8252 / RFC 8414 remain applicable published standards
- RFC 10017 is current browser-based app BCP
- OAuth 2.1 draft-ietf-oauth-v2-1-16 is active work in progress, not a final RFC

Security-sensitive merge-gate baseline:
- main protected: YES
- required context: Commit attribution guard (app_id 5032971)
- exact-head checks after this handoff commit: PENDING by construction
- local git diff --check: NOT AVAILABLE through connector-only execution
- runtime/build tests: not applicable to this docs/architecture-only slice
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-173-c01-delegated-oauth-contract.md`
- `docs/README.md`
- `docs/adr/0012-delegated-external-connector-trust-boundary.md`
- `docs/adr/0013-delegated-oauth-authorization-contract.md`
- `docs/adr/README.md`
- `docs/integrations/CONNECTOR_TRUST_BOUNDARY.md`
- `docs/integrations/DELEGATED_OAUTH_AUTHORIZATION.md`
- `docs/security/AUTH_ARCHITECTURE.md`

### Actual Behavior

No runtime behavior changed. This slice defines the delegated OAuth client/scope/consent/token-lifecycle/revocation contract and its durable ADR only.

### Known Limitations

This slice defines architecture/security semantics only. OAuth endpoints, credential issuance, storage, client registration implementation, consent UI, tool contracts, and production deployment remain separately gated.

### Final Status

`REVIEW`
