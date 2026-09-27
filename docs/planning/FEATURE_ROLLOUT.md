# Feature Rollout, Remote Capability & Emergency Kill-Switch Policy

## Status

**Canonical provider-neutral rollout-control policy for Tio World.**

This document defines how future backend-controlled capabilities, AI workflows, billing-dependent features, integrations, expensive operations, and other remotely controlled product behavior may be enabled, staged, disabled, or rolled back safely.

It is an architecture/documentation contract only. It does **not** add a remote-config SDK, feature-flag provider, backend service, API route, worker, entitlement engine, analytics SDK, or runtime kill switch.

Related policy boundaries:

- [API Lifecycle & Client Compatibility](API_LIFECYCLE.md)
- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)
- [Security](SECURITY.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)
- [ADR policy](adr/README.md)

Linear planning owners remain authoritative for implementation sequencing and acceptance. This document preserves the cross-cutting rollout contract.

## Core Principle

A feature flag controls **availability or rollout state**. It does not replace any security, commercial, or correctness control.

```text
feature/capability state
!= authentication
!= authorization
!= entitlement
!= billing verification
!= quota enforcement
!= validation
!= rate limiting
!= safety policy
```

A client hiding a button is never evidence that an operation is unauthorized or disabled.

For sensitive, costly, privileged, destructive, AI/provider-backed, billing-gated, or otherwise high-risk operations, the trusted server-side boundary must enforce the capability state before performing the operation.

## Provider-Neutral Tio Boundary

Do not spread vendor-specific remote-config or feature-flag SDK calls through Flutter features, future API routes, workers, or domain logic.

Target conceptual boundary:

```text
product/domain code
      ↓
Tio capability / rollout contract
      ↓
normalized capability state
      ↓
provider adapter or Tio-owned configuration source
```

Possible future implementation shapes may include a hosted flag provider, Tio-owned database/configuration, deployment configuration, or another service. This policy intentionally does not choose one.

A provider selection becomes an ADR candidate only if it is a durable architecture decision that meets the repository ADR threshold.

## Terms

### Feature flag

A named control used to enable, disable, stage, or vary approved behavior.

### Capability

A stable semantic statement that a client or service can safely perform/use a behavior in the current context.

Examples:

```text
progress_photo_upload
coach_streaming
meal_ai_parse
subscription_purchase
```

Capability names describe product behavior, not widget names or vendor keys.

### Rollout rule

A rule deciding which approved environments/cohorts receive an enabled capability.

### Kill switch

An emergency control that disables new use of an optional, risky, costly, or failing capability without waiting for a mobile-store release.

### Entitlement

Commercial access truth such as a paid-plan capability. Entitlements are not feature flags and remain server-authoritative under the subscription/entitlement architecture.

## Capability State Model

Prefer a small explicit state model instead of ambiguous booleans when behavior needs more than enabled/disabled.

Conceptual states:

```text
disabled
enabled
unavailable
unsupported_client
degraded        # only when an approved degraded mode exists
```

Do not invent `degraded` behavior unless the owning feature defines a safe fallback.

For simple presentation-only flags, a boolean may be enough.

## Authority by Surface

### Client / Flutter / Wear / watchOS

Clients may:

- hide or show optional entry points;
- present disabled/unavailable states;
- cache approved non-sensitive rollout metadata;
- refresh rollout state at bounded lifecycle points;
- use a local safe default when explicitly allowed;
- surface update-required or temporarily-unavailable UX.

Clients must not:

- authorize privileged operations from a local flag;
- unlock paid capabilities from local state;
- bypass a server-disabled capability because cached state says enabled;
- receive secret targeting rules or privileged flag-management credentials;
- treat analytics/experimentation assignment as authorization.

### Future protected API

For server-owned operations, the API is the authoritative enforcement point for:

- capability enabled/disabled state;
- supported-client requirements when applicable;
- rollout/cohort eligibility;
- authorization and entitlement checks;
- quota/cost controls;
- safe client-facing rejection.

Exact check ordering may vary by route, but no ordering may leak sensitive eligibility or bypass authentication/authorization.

### Future workers/jobs

Workers must re-check the controls required for safe execution rather than assuming a queued job remains valid forever.

A queued job may need to stop before a costly/provider side effect when:

- an emergency kill switch has been activated;
- entitlement or authorization is no longer valid where revalidation is required;
- the provider/capability is disabled;
- a safety gate now blocks execution.

Do not blindly cancel already-committed external side effects. In-flight/cancellation semantics belong to the owning workflow and must be explicit.

### Deployment/runtime configuration

Deployment configuration may provide bootstrap/default values, but runtime rollout state and application deployment are separate concerns.

A code rollback is not the same thing as disabling a feature flag, and a feature kill switch is not a substitute for deployment rollback when the service itself is defective.

## Default-Deny Rules

When rollout state is unavailable, malformed, stale beyond its accepted TTL, unauthorized, or cannot be evaluated safely:

### Sensitive / costly / privileged server capability

Default:

```text
fail closed
→ do not perform protected/costly side effect
→ return controlled unavailable/disabled behavior
```

Examples include:

- AI/provider requests with material cost;
- paid capability execution;
- external integrations;
- privileged account/admin operations;
- destructive workflows;
- uploads or processing with explicit safety/cost gates.

### Optional presentation-only capability

A local fallback may be used only when the owning feature explicitly documents that stale or local behavior cannot cause a security, privacy, billing, data-integrity, or cost problem.

Do not use one global fallback rule for every flag.

## Remote Configuration Failure Matrix

Every implemented flag/capability must define expected behavior for at least:

| Condition | Required policy |
| --- | --- |
| Fresh enabled state | Execute only after all other required controls pass. |
| Fresh disabled state | Fail closed for protected operation; provide safe optional fallback/UI. |
| Config service unavailable | Use approved bounded cache or safe default; protected operations must remain server-enforced. |
| Cache stale beyond TTL | Do not preserve risky enabled state indefinitely. |
| Malformed value/schema | Treat as configuration failure, not as enabled. |
| Unauthorized flag fetch/evaluation | Fail safely; never expose privileged targeting details. |
| Rollback/kill switch activated | New protected operations must stop according to the capability contract. |
| Client state disagrees with server | Server wins. |

## Environment Separation

Rollout state must be environment-scoped.

At minimum keep independent state for environments such as:

```text
local/development
preview/staging
production
```

Rules:

- production targeting must not accidentally inherit staging/test allowlists;
- test identities must not require exposing real user PII in configuration;
- provider projects/environments/keys, if later selected, must be separated appropriately;
- environment identity must be server/deployment controlled rather than supplied by an untrusted client;
- a production flag change must not be testable only by mutating the production user population.

## Rollout Strategies

Use the least complex strategy that satisfies the real launch need.

### All-off / all-on

Use for simple readiness gates or when staged rollout provides no benefit.

### Internal allowlist

Useful for staff/tester validation before broader launch.

Prefer stable internal identifiers over email addresses or other PII in flag configuration.

### Explicit cohort

Use when a reviewed group needs access, such as a controlled beta.

Cohort membership must be purpose-limited and must not reveal sensitive health information to the flag provider/configuration system.

### Percentage rollout

Percentage assignment must be stable for a given subject and flag instead of randomly changing on every request/session.

Conceptual approach:

```text
stable non-sensitive subject key
+ capability key
+ rollout salt/version
→ deterministic bucket
→ percentage decision
```

Do not expose the hashing salt or targeting internals to untrusted clients when that would allow bypassing server enforcement.

### Platform/client-specific rollout

May be used when capability support differs materially by Android/iOS/Wear/watchOS/web/client contract.

This must align with [API Lifecycle](API_LIFECYCLE.md); app version is not itself authorization.

## Targeting Privacy

Default targeting data must be coarse and purpose-limited.

Allowed candidates when genuinely needed may include:

- environment;
- platform/surface;
- supported client capability/version class;
- stable pseudonymous/internal subject identifier;
- explicit beta cohort;
- coarse region only when legally/operationally justified and privacy-reviewed;
- entitlement class only through the authoritative commercial boundary when necessary.

Do **not** target generic rollout flags on raw sensitive health or AI content by default.

Examples of prohibited/default-excluded targeting inputs:

- exact weight/body measurements;
- diagnoses or medical conditions;
- medication details;
- detailed meal diary content;
- raw sensor/HealthKit/Health Connect data;
- raw AI prompts/responses;
- authentication tokens/OTP/secrets;
- unrestricted user-generated text.

Any exceptional sensitive targeting requires a separate privacy review under [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md).

## Server Enforcement vs Client Presentation

For a protected feature:

```text
client flag state
→ presentation hint

server capability state
→ authoritative availability enforcement
```

Example:

```text
client shows Coach action
→ user taps
→ server authenticates caller
→ server evaluates capability/rollout safely
→ server evaluates authorization + entitlement/quota/safety
→ execute only if all required controls pass
```

A stale client may still show a button after an emergency disable. The server must reject the operation safely; this is expected behavior, not a rollout failure.

## Relationship to API Client Compatibility

API version, app version, capability state, and rollout state are independent:

```text
API namespace (/v1)
client app/build version
client capability support
remote rollout state
minimum supported client
entitlement/authorization state
```

Use minimum-supported-client enforcement when an old client is unsafe or contract-incompatible.

Use capability negotiation when the server/client need to know whether a behavior is understood/supported.

Use rollout control when an otherwise supported capability should be enabled only for a subset or disabled operationally.

Do not use a feature flag to hide a permanently breaking API contract.

## Relationship to Entitlements and Billing

Feature rollout and commercial access are separate gates.

```text
rollout enabled
+ entitlement valid
+ authorization valid
+ quota/safety checks pass
→ capability may execute
```

A rollout flag may temporarily disable a paid capability for safety/incident reasons, but enabling a flag must never grant a paid entitlement.

Purchase callbacks, client UI, cached flag state, and analytics events are not authoritative commercial truth.

The detailed subscription/purchase lifecycle remains owned by Linear TNYX-124.

## Relationship to Rate Limits and Cost Controls

A kill switch is not a rate limiter.

Rate limiting and request/resource bounds remain owned by the API protection work (Linear TNYX-29).

For expensive capabilities, both may apply:

```text
capability enabled
→ authorization/entitlement
→ quota/rate/cost control
→ provider call
```

Emergency disable may stop new expensive calls quickly; normal quota/rate controls still remain required when enabled.

## Relationship to Observability and Analytics

### Operational observability

Flag evaluation and kill-switch behavior need enough telemetry to answer:

- which capability key was evaluated;
- enabled/disabled/error outcome;
- environment;
- configuration revision where safe;
- client/app version class where relevant;
- correlation/request/job ID;
- reason category without exposing sensitive targeting data.

Detailed metrics/log/tracing ownership remains Linear TNYX-37.

### Product analytics

Analytics may measure rollout adoption only through approved semantic events and privacy-safe dimensions.

Do not send raw targeting rules, sensitive user attributes, health content, tokens, or secret flag configuration to analytics.

Provider/tool selection and event taxonomy remain Linear TNYX-52.

## Emergency Kill Switch

Every optional capability with meaningful cost, safety, privacy, dependency, or availability risk should define whether an emergency server-side kill switch is required before production launch.

Examples likely to require one:

- AI coach/provider execution;
- expensive parsing/generation flows;
- third-party integrations;
- experimental uploads/processing;
- billing/purchase entry where provider behavior is unsafe;
- new external data-sync jobs;
- optional high-risk workflows.

### Required kill-switch properties

A production kill switch should be:

- independently changeable without a mobile-store release;
- server-enforced for protected operations;
- scoped to the smallest useful capability rather than shutting down unrelated product areas;
- auditable with actor/time/reason where the chosen platform supports it;
- reversible after incident review;
- testable in non-production;
- documented with an owner and fallback UX/behavior.

### Fail-safe result

When activated:

```text
new optional protected operation
→ blocked before avoidable external/costly side effect
→ controlled unavailable response
→ unaffected core product remains usable where possible
```

Do not mark an entire API/service unhealthy merely because one optional provider-backed capability is killed. Readiness semantics remain owned by TNYX-29/TNYX-39.

### In-flight work

A kill switch primarily controls **new work** unless the owning workflow explicitly supports cancellation.

For queued/in-flight jobs, define whether to:

- finish safely;
- re-check and stop before provider side effect;
- cancel idempotently;
- compensate/reconcile after partial completion.

Never assume a flag toggle can undo an already committed external transaction.

## Ownership, Auditability & Lifecycle

Every non-permanent rollout flag should have metadata equivalent to:

```text
key
purpose
owner
created_at
intended environments
safe default
targeting basis
expiry/review date
kill-switch semantics
linked Linear issue
```

Temporary flags require an explicit review/cleanup date.

A flag should be removed when:

- rollout reaches a stable permanent state;
- the old code path is no longer supported;
- the experiment ends;
- the capability is retired;
- another durable mechanism replaces it.

Do not accumulate permanent dead flags or leave stale alternate code paths indefinitely.

If a flag represents a long-lived product entitlement/configuration concept rather than temporary rollout, model that concept explicitly instead of pretending it is a temporary flag.

## Change Safety

Production flag changes are operational changes and require appropriate discipline.

At minimum:

- know the capability owner;
- understand enabled/disabled behavior;
- validate non-production behavior first when practical;
- use the smallest affected cohort/scope;
- have rollback/disable instructions;
- observe impact with privacy-safe telemetry;
- record incident/change evidence for high-impact emergency actions.

Do not depend on undocumented dashboard click-ops as the only durable source of important production rollout state. The future implementation must provide an auditable/reconcilable configuration contract appropriate to the selected provider/runtime.

## Mobile Cache & Refresh Semantics

Exact TTL values belong to implementation because risk and provider behavior differ by capability, but the rules are fixed:

1. cache only the minimum capability state needed by the client;
2. never cache management credentials or sensitive targeting rules;
3. record when cached state was evaluated/fetched;
4. bound how long an enabled state may be trusted;
5. refresh at controlled lifecycle moments instead of polling aggressively;
6. server enforcement wins even while client cache is stale;
7. critical kill switches must not depend on waiting for every mobile client cache to expire.

Reasonable future refresh triggers may include:

- authenticated bootstrap;
- app foreground/resume after an accepted interval;
- explicit session/account change;
- successful client update/version change;
- server response indicating capability state is stale/unsupported.

Do not choose a universal refresh interval before a provider and concrete use case exist.

## Offline Behavior

Offline behavior depends on whether the capability is local-only or requires a protected server action.

### Server-backed capability

Cached enabled state may keep presentation stable, but it cannot guarantee execution while offline.

Preferred behavior:

```text
offline
→ show controlled offline/deferred state
→ do not fabricate successful protected execution
→ re-evaluate server capability before side effect after reconnect
```

### Purely local optional capability

A cached/local default may continue if the feature has no security, privacy, billing, server-authoritative, or external side-effect dependency and the owning feature explicitly approves it.

## Schema and Configuration Validation

Flag definitions/configuration should be validated like any other external/config input.

Required principles:

- unknown state does not silently become enabled;
- type/schema mismatch fails safely;
- required metadata such as owner/expiry is enforceable where practical;
- client-facing capability payloads expose only allowlisted fields;
- provider errors map to Tio-owned normalized outcomes;
- configuration parsing must not execute arbitrary code or trust unvalidated client input.

## Testing Strategy

Every protected capability implementation should test the states relevant to its risk profile.

Minimum matrix:

```text
enabled
→ expected path works

disabled
→ protected side effect does not execute

remote/config failure
→ safe fallback/default

stale cache
→ bounded behavior; server remains authoritative

malformed state
→ fail safe

unsupported client
→ controlled compatibility response

wrong entitlement/authorization
→ remains denied even if flag enabled

kill switch during incident
→ new work stops without mobile release

re-enable/rollback
→ capability returns without corrupt duplicate work
```

For cohort/percentage rollouts also test deterministic/stable assignment.

For queued jobs test re-evaluation/idempotency where required.

For optional dependencies test that disabling one capability does not make unrelated readiness fail.

## Rollout Readiness Checklist

Before the first backend-controlled production rollout for a capability:

- [ ] capability has a stable semantic key;
- [ ] client presentation and server enforcement responsibilities are explicit;
- [ ] authorization/entitlement/quota/safety remain separate controls;
- [ ] safe default is documented;
- [ ] config unavailable/stale/malformed behavior is tested;
- [ ] environment separation is verified;
- [ ] targeting inputs are privacy-reviewed and minimal;
- [ ] cohort/percentage assignment is stable if used;
- [ ] cache TTL/refresh/offline behavior is defined;
- [ ] kill-switch requirement and behavior are defined;
- [ ] owner and review/expiry date exist for temporary flags;
- [ ] telemetry is privacy-safe and correlatable;
- [ ] rollback/re-enable behavior is tested;
- [ ] flag cleanup path is known;
- [ ] mobile/API compatibility follows `API_LIFECYCLE.md`;
- [ ] production security/resilience review includes applicable rollout controls.

## Explicit Non-Goals

This policy does not:

- choose LaunchDarkly, Firebase Remote Config, ConfigCat, Unleash, Supabase, or another flag provider;
- install a client or server remote-config SDK;
- create a feature-flag database table;
- create a capability API endpoint;
- implement percentage rollout;
- implement an emergency dashboard;
- create backend/worker runtime code;
- implement entitlement/billing truth;
- implement rate limiting;
- choose analytics/observability vendors;
- turn all compile-time/local product configuration into remote flags.

Introduce implementation only when a concrete rollout need is approved.

## Related Linear Ownership

This policy intentionally links rather than duplicates adjacent work:

- **TNYX-29** — API rate limiting, health checks and structured logging;
- **TNYX-37** — observability baseline;
- **TNYX-39** — deployment and rollback architecture;
- **TNYX-40** — production security and resilience review;
- **TNYX-50** — API lifecycle and client compatibility;
- **TNYX-52** — app analytics, attribution and tracking stack;
- **TNYX-124** — subscription, entitlement, paywall and purchase lifecycle;
- **TNYX-126** — mobile launch/store submission and release-readiness gate.

## Current Decision

As of 2026-08-28:

```text
provider selected: NO
remote-config SDK installed by this policy: NO
backend-controlled rollout runtime implemented by this policy: NO
canonical rollout safety contract: YES
```

The first concrete remote-rollout implementation must re-audit this policy against the actual capability, deployment model, privacy requirements, and selected provider before production use.
