# Secrets & Environment Strategy

## Status

**Canonical provider-neutral policy for Tio World configuration, secrets, environment separation, and credential rotation.**

This document defines how current Supabase-backed surfaces and future Tio server workloads receive configuration safely. It is a documentation/architecture contract only. It does **not** create, read, rotate, revoke, or expose any real credential; start `services/api`; deploy a worker; change Supabase configuration; or select a secret-management vendor.

Related boundaries:

- [Security](SECURITY.md)
- [Authentication Architecture](AUTH_ARCHITECTURE.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)
- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)
- [Architecture](ARCHITECTURE.md)

## Core Rule

Configuration must be classified by **who is allowed to know it**, not by where it happens to be stored today.

```text
client-safe configuration
→ may be distributed to an approved client build
→ still environment-scoped
→ must never grant privileged server authority

server secret
→ trusted server/runtime only
→ never shipped to Flutter/Wear/watchOS/public web bundles
→ injected outside source code
→ rotatable/revocable without source-code changes
```

A value being present in an environment variable does **not** automatically make it secret. A value being called a “key” does **not** automatically make it safe for clients. The owning provider/security contract determines the classification.

## Configuration Classes

### 1. Client-safe configuration

Client-safe configuration is intentionally distributable and remains safe after an app bundle is inspected.

Examples may include, when the provider explicitly defines them as public/client-safe:

- public service/project URLs;
- public/publishable client identifiers or keys;
- non-sensitive feature metadata;
- public application identifiers;
- environment labels needed for safe client routing.

Rules:

- assume every mobile/watch/public-web value can be extracted by an end user;
- never rely on client-safe configuration as an authorization boundary;
- server/database authorization such as RLS must remain correct even when a client-safe value is public;
- do not place privileged scopes or secret fallback credentials next to client-safe values;
- re-check provider documentation when implementing a new integration instead of inferring safety from variable names.

### 2. Server-only secrets

Server-only secrets grant privileged capability or authenticate a trusted workload.

Examples include:

- Supabase privileged/service-role credentials;
- provider API secrets;
- webhook signing secrets;
- database passwords or privileged connection strings;
- private signing/encryption keys;
- service-account private credentials;
- deployment credentials;
- credentials that can bypass normal end-user authorization or incur protected provider actions/cost.

They must never be included in:

- Flutter phone builds;
- Wear OS builds;
- future watchOS builds;
- public browser bundles;
- committed source or documentation;
- committed `.env` files;
- screenshots, issue text, PR descriptions, analytics, crash reports, traces, or client-visible errors.

### 3. User/session credentials

Bearer access tokens, refresh tokens, OTPs, recovery codes, session cookies, and similar user/session material are sensitive credentials even though they are not deployment secrets.

They must follow the Auth/security storage and logging rules. They must never be treated as harmless configuration or copied into developer fixtures.

## Environment Model

Tio environments must be isolated by purpose.

Canonical conceptual stages:

```text
local / development
preview / staging
production
```

A project may use fewer pre-production stages initially, but production remains a separate trust boundary.

Rules:

- production secrets must not be reused in local development, test fixtures, PR previews, or staging;
- staging/test credentials must not gain production authority;
- a preview environment must not silently point to production merely because a dedicated dependency is unavailable;
- environment identity must come from trusted build/deployment configuration, not an untrusted request parameter;
- production data must not be copied into lower environments merely to make testing easier;
- environment-specific endpoints/identifiers may be client-safe, but privileged credentials remain server-only;
- every deployed workload must fail clearly when its required environment configuration is missing or invalid.

## Surface Responsibilities

### Flutter phone / Wear OS / future watchOS

Clients may receive only configuration that is safe to publish.

Client rules:

- no service-role/provider secret;
- no private signing key;
- no hidden “admin” credential for fallback behavior;
- no production secret embedded through Dart defines, generated files, assets, plist/resource files, Gradle properties, or code obfuscation;
- do not assume obfuscation turns a client value into a secret;
- sensitive user tokens follow the Auth/session security boundary, not general app configuration.

### Supabase Edge Functions

When an Edge Function requires a privileged/provider secret, the value belongs in the approved server-side runtime secret mechanism for that environment, not in function source.

Function code should reference a stable configuration name/contract while the actual value is supplied by the runtime environment.

### Future `services/api`

When backend implementation is separately authorized:

- configuration is validated at startup;
- required secrets are injected by the deployment/runtime environment;
- source code references semantic configuration names, not literal credentials;
- configuration errors are sanitized;
- privileged clients/adapters receive only the secrets they require;
- a globally available “all secrets” object is avoided where narrower injection is practical.

This policy does not authorize creation of `services/api`.

### Future workers / scheduled jobs

Workers follow the same server-secret rules as the API. A worker must not inherit every API secret by default; each workload receives the minimum required credentials.

## Source of Configuration

### Repository

The repository may contain:

- `.env.example` or equivalent examples with **names/placeholders only**;
- schemas describing required configuration;
- documentation explaining where a value comes from;
- tests using fake/disposable values.

The repository must not contain real secrets.

A committed example file must use obviously non-secret placeholders and must not contain a copied production value that was later “redacted” incompletely.

### Local development

Local secret values remain uncommitted and developer-scoped.

Current repository ignore rules already exclude `.env`, `.env.*`, common secret/credential paths, and local QA runtime configuration. Those ignore rules are defense-in-depth, not permission to place production credentials on developer machines unnecessarily.

Prefer disposable/local/test credentials with the minimum privileges required for the task.

### CI / deployment

CI and deployment systems receive secrets through their approved protected secret/environment facilities.

Rules:

- never echo secrets during setup/debugging;
- mask/redact known secret fields;
- do not pass secrets through command-line output when a safer injection mechanism exists;
- scope environment secrets to the jobs/environments that need them;
- production deployment credentials require stricter access than ordinary PR/test jobs;
- fork/untrusted PR contexts must not receive production secrets.

### Provider-managed runtime secrets

Provider-managed server runtimes may use their native protected secret facility when appropriate. Provider choice does not change Tio's classification, rotation, logging, and least-privilege rules.

## Naming & Contract Rules

Use semantic configuration names that describe purpose, not a pasted provider value.

Good conceptual pattern:

```text
<DEPENDENCY>_<PURPOSE>
```

Avoid one ambiguous variable that changes meaning between environments.

Configuration code/docs should make these properties knowable without exposing values:

- owner;
- environment;
- client-safe vs server-secret classification;
- required vs optional;
- consuming workload/surface;
- rotation/revocation owner;
- expected failure behavior when missing.

Do not publish a secret inventory containing actual values.

## Rotation Without Code Changes

A normal secret rotation must not require changing application source merely because the credential value changed.

Target flow:

```text
stable configuration name
→ runtime/secret store supplies value
→ rotate value outside source code
→ restart/redeploy/reload as required by runtime
→ verify new credential
→ revoke old credential
```

Where a provider supports overlapping credentials, prefer a safe staged rotation:

1. create/activate replacement credential;
2. inject replacement into the target environment;
3. deploy/restart or reload the consuming workload as required;
4. verify healthy requests/jobs and expected authorization;
5. revoke the old credential;
6. verify the old credential can no longer be used;
7. record safe rotation evidence without recording the credential value.

If overlap is not supported, the owning workflow must define an outage-safe or maintenance-window procedure before production use.

## Rotation Triggers

Rotate or revoke when appropriate, including:

- suspected or confirmed exposure;
- credential accidentally committed, logged, screenshotted, pasted, or sent to the wrong system;
- staff/service access change that invalidates the previous trust boundary;
- provider-required rotation;
- privilege/scope change;
- cryptographic/key-management policy requires it;
- periodic policy for a credential class, when such cadence is justified.

Do not rotate credentials performatively without an owner and verification path. The goal is reduced exposure and proven recovery, not churn.

## Secret Exposure Incident Rule

If a secret may have been exposed, deleting the text/file is **not** sufficient.

Required conceptual response:

```text
assume exposed
→ contain access
→ rotate/revoke credential
→ remove/redact exposed material where possible
→ verify replacement works
→ verify old credential is invalid
→ inspect available audit evidence for misuse
→ document incident safely
```

Git history rewrite, issue deletion, or log deletion does not make a leaked credential trustworthy again.

Never paste the leaked value into an incident ticket while reporting it.

## Least Privilege

Each credential should grant the minimum capability required for its workload.

Rules:

- separate client-safe and privileged credentials;
- separate production from non-production;
- separate unrelated provider/workload credentials where practical;
- do not give every future backend module a Supabase privileged credential;
- user-owned operations should preserve user-scoped access/RLS where appropriate;
- privileged credentials must not become a fallback for failed authorization.

See [Supabase Server Access](SUPABASE_SERVER_ACCESS.md).

## Logging, Errors & Telemetry

Never log or emit raw:

- Authorization/Bearer headers;
- access/refresh tokens;
- service-role/provider secrets;
- database passwords/connection strings containing credentials;
- webhook signing secrets;
- private keys;
- cookies/session secrets;
- OTP/recovery codes.

Requirements:

- redact sensitive configuration keys at logging boundaries;
- sanitize startup/config-validation errors;
- prefer “missing/invalid configuration `<name>`” over printing the value;
- HTTP/client errors must never echo server configuration;
- traces and analytics follow the same redaction rules as logs;
- secret length/prefix/partial-value logging is avoided unless a separately reviewed diagnostic method proves it cannot aid credential disclosure.

## Validation & Failure Behavior

When a required server secret/configuration is missing or malformed:

```text
fail startup / disable the owning capability safely
→ emit sanitized diagnostic metadata
→ do not substitute a privileged fallback
→ do not silently point to another environment
```

For optional integrations, the owning feature may define a safe disabled/degraded state under [Feature Rollout](FEATURE_ROLLOUT.md), but absence of a secret must never enable unsafe behavior.

## Configuration Change vs Code Change

A value rotation is usually an operational configuration change.

A change to any of the following is an architecture/implementation change and requires normal review:

- what a credential is allowed to do;
- which surface receives it;
- switching a value from client-safe to privileged or vice versa;
- adding a new privileged dependency;
- changing environment isolation;
- changing the secret-management/deployment mechanism in a durable way.

Provider/tool selection may require an ADR only when it crosses the repository's ADR threshold; this document intentionally does not select a secret manager.

## Pre-Production Checklist for a New Secret

Before a new server secret is used in production, verify:

- [ ] purpose and owner are explicit;
- [ ] environment is explicit;
- [ ] client-safe vs server-secret classification is reviewed;
- [ ] consuming workload is known;
- [ ] minimum privilege/scope is used;
- [ ] source is outside committed code;
- [ ] logs/errors/traces redact it;
- [ ] missing/invalid behavior fails safely;
- [ ] rotation/revocation procedure is known;
- [ ] production and non-production values are separate;
- [ ] no mobile/watch/public bundle receives the secret;
- [ ] incident response can invalidate the credential without waiting for an app-store release.

## Current Repository Grounding

Current repository safeguards already include:

- `.env`/common secret paths ignored by Git;
- local mobile QA runtime configuration ignored;
- Security policy forbidding committed env/secrets and client-side privileged credentials;
- Supabase Server Access policy reserving privileged credentials for narrow trusted server workflows;
- Supabase Auth as the identity authority;
- no `services/api` implementation yet.

This document fills the missing cross-surface environment and rotation lifecycle. It does not claim a production secret manager, rotation automation, or future backend runtime is already configured.

## Backend / Runtime Implementation Gate

TNYX-38 is complete at documentation level when this contract is accepted.

It does **not** authorize:

- creating `services/api` or `services/worker`;
- creating/rotating/revoking a Supabase or provider credential;
- changing GitHub/environment secrets;
- changing Supabase Edge Function secrets;
- selecting Vault, Doppler, cloud secret managers, or another vendor;
- changing deployment configuration;
- adding provider SDKs;
- exposing client-safe values through a new runtime mechanism.

Those actions require their own explicitly authorized implementation slice.

## Acceptance for TNYX-38

- [x] Client-safe publishable configuration is separated from server secrets.
- [x] Service-role/provider credentials are server-only.
- [x] Local/development, preview/staging, and production trust boundaries are explicit.
- [x] Secret values can rotate without source-code changes.
- [x] Logs, traces, analytics, crash reports, and error payloads must not expose secret values.
- [x] Exposure response requires rotation/revocation; deleting leaked text alone is insufficient.
- [x] No real credential, backend code, or runtime configuration is changed by this documentation slice.
