# Data & Privacy Governance

## Status

**Canonical cross-cutting policy baseline for Tio World data handling.**

This document defines how Tio classifies, collects, uses, shares, retains, exports, and deletes user data before AI, analytics, coaching, private media, and other sensitive workflows expand.

It complements [Security](SECURITY.md), [Authentication Architecture](AUTH_ARCHITECTURE.md), and [Supabase Server Access Modes](SUPABASE_SERVER_ACCESS.md). It does not replace security controls, product-specific ownership rules, or future legal review.

No backend/runtime implementation is introduced by this document.

## Core Principles

1. **Minimize by default.** Collect, load, transmit, and retain only what a concrete workflow requires.
2. **Purpose-bound use.** Sensitive data collected for one purpose must not silently become analytics, advertising, AI-training, or unrelated personalization input.
3. **Least exposure.** Prefer user-scoped access, narrow projections, aggregates, and derived signals over broad raw-record access.
4. **Private by default.** Health-context data and user media are not public unless a separately approved product flow explicitly requires sharing.
5. **Deletion must propagate.** Account deletion must define downstream effects for database rows, Storage objects, caches, analytics identifiers, provider-held data, queued jobs, and derived artifacts where applicable.
6. **No production-data shortcuts.** Real production personal/health data must not become routine development fixtures, screenshots, logs, or support artifacts.
7. **No invented compliance claims.** Do not assume a jurisdiction, certification, retention period, or legal basis until concrete product/business requirements establish it.

## Data Classification

Every new data flow should classify the data it handles. Use the highest applicable class.

| Class | Examples | Default handling |
| --- | --- | --- |
| Public | deliberately public profile/share content approved by product policy | May be exposed only through an explicit public feature |
| Internal | non-user-sensitive operational metadata, feature configuration, schema/version metadata | Keep inside trusted systems; exclude secrets |
| Personal | name, Email, Phone, username, device/account identifiers, profile attributes | User-scoped access; minimize logs/analytics |
| Sensitive | DOB, precise location if introduced, private media, support/account-recovery context | Narrow access; avoid general analytics/logs |
| Health-context | weight, body metrics, nutrition, workouts, fasting, wellness, health concerns, coaching context, progress photos | Highest product-data caution; private by default; minimum-purpose access |
| Secret / credential | passwords, OTPs, access/refresh tokens, service-role keys, provider secrets, private signing material | Never analytics/logging/client exposure; server-only where applicable |

A field may move into a stricter class depending on context. For example, a timestamp is ordinary operational metadata in isolation but may become sensitive when attached to a private health event.

## Ownership and Access

### Canonical identity

Supabase Auth remains the canonical identity authority. User-owned application data must be bound to the canonical authenticated user UUID according to approved ownership contracts.

### User-scoped operations

Normal caller-owned operations should preserve user authorization/RLS semantics. A backend or Edge Function existing in the path is not itself justification for privileged access.

### Privileged operations

Cross-user/system access requires an explicit trusted trigger, authorization rule, narrow scope, and safe auditability. Failed RLS or ordinary authorization must never auto-escalate into privileged access.

## Collection and Purpose Limitation

Before adding a new sensitive field, event, media object, provider call, or AI context source, define:

- what data is required;
- why it is required;
- which feature/workflow owns it;
- which systems may read it;
- whether it leaves Tio-controlled infrastructure;
- how long it needs to exist;
- how deletion/export applies;
- whether a less sensitive derived value can satisfy the same purpose.

Do not collect speculative future data merely because it may be useful later.

## Logging and Analytics Boundary

General logs, crash reports, analytics, and attribution systems must exclude sensitive payload content by default.

### Never log or send to general analytics

- passwords, OTPs, access tokens, refresh tokens, Authorization headers, provider secrets;
- raw Email/Phone where an event can work without them;
- DOB or age-source values unless a specifically reviewed operational need requires them;
- raw weight/body measurements, health conditions/concerns, nutrition entries, workout notes, fasting notes, or progress-photo content;
- raw onboarding answers containing personal/health context;
- raw AI prompts/responses when they contain user health/personal context;
- private Storage URLs/object contents;
- full user exports or database rows.

### Preferred analytics shape

Use the least-sensitive signal that answers the product question, for example:

```text
meal_logged = true
workout_completed = true
onboarding_step = "nutrition_goal"
request_outcome = "success"
provider_latency_bucket = "500-1000ms"
```

rather than copying entered health values or free text into analytics.

Analytics/attribution provider selection remains a separate decision. This policy applies regardless of vendor.

## AI and External Provider Data Boundary

AI/provider integrations must be purpose-bound and minimize transmitted context.

Rules:

- Product modules must not send an entire user profile/history when a small subset is sufficient.
- Load only the data classes required for the specific request.
- Prefer structured, bounded context over unrestricted database dumps.
- Exclude secrets, authentication material, and unrelated personal identifiers.
- Raw private media must not be sent to a provider unless the approved feature explicitly requires that media input.
- Provider data-sharing must be documented before launch: provider, purpose, data classes sent, retention/training controls where applicable, and failure/deletion implications.
- Do not assume provider "no training" or retention behavior; verify the provider contract/configuration at implementation time.
- AI output must not become a new authoritative source for health/account facts without a separately approved product rule.

Future AI safety/orchestration tasks may add stricter rules but must not weaken this baseline.

## Private User Media

Profile, Nutrition, Workout, and Progress media are private user data boundaries, not generic file dumps.

Before a bucket/workflow is launched, define:

- owner-scoped object paths and Storage RLS;
- permitted content types and size limits;
- metadata stored in PostgreSQL, if any;
- who may read/delete the object;
- whether transformations/thumbnails create derived objects;
- retention/deletion behavior for originals and derivatives;
- whether any third-party processor receives the media.

Public buckets/public URLs are not the default for health/fitness media.

## Account Deletion

Account deletion is a lifecycle, not only one database row delete.

The existing Account Deletion contract remains authoritative for current implemented behavior. New data stores/providers introduced later must explicitly join the deletion graph.

For every new user-data system, document one of:

- deleted synchronously with account deletion;
- queued for bounded downstream deletion;
- expired through a defined short-lived retention rule;
- retained only where an explicit, approved requirement requires it, with identity/linkage minimized where possible.

Deletion must consider, where applicable:

- Supabase Auth root;
- PostgreSQL canonical/user-owned rows;
- Supabase Storage objects and derived media;
- caches/search/vector indexes;
- queued/scheduled work;
- analytics/attribution identifiers;
- external AI/provider artifacts;
- billing/integration records under their own approved retention requirements;
- backups according to the future backup/recovery policy.

Do not claim immediate deletion from systems whose architecture only supports delayed expiry; document the actual behavior.

## Export and Portability

Tio should support a user-data export strategy before production maturity requires it, but this baseline does not invent an export API now.

Future export implementation should:

- authenticate the requesting user strongly enough for the sensitivity of the export;
- include user-owned canonical product data in a documented machine-readable format where practical;
- avoid exposing internal secrets, security metadata, other users' data, or privileged system records;
- identify separately stored media and provide a safe export mechanism when included;
- use bounded, auditable generation for large exports;
- expire temporary export artifacts and signed links;
- avoid Emailing raw sensitive exports as attachments by default.

Provider-derived data that Tio cannot legally/technically re-export must be documented rather than silently omitted.

## Retention and Expiry

Do not invent one global retention duration for all Tio data.

Each durable data class/workflow must eventually have an owner-approved retention rule based on product need, recovery requirements, operational safety, and concrete legal/business obligations.

Until a duration is explicitly approved:

- retain canonical user-owned product data only while it serves the active product/account purpose;
- keep temporary artifacts short-lived by design;
- do not create indefinite debug/log retention for sensitive content;
- do not duplicate raw data into analytics or provider systems merely for convenience;
- require a retention decision before launching a new external provider that stores sensitive Tio data.

Suggested policy categories to define per implementation are:

```text
session/ephemeral
short-lived operational
durable user-owned
security/audit
analytics/aggregate
provider-held
backup/recovery copy
```

Exact durations belong to the owning implementation/production-hardening decision once requirements are known.

## Development, Test, and Support Data

Production personal/health data must not become routine non-production data.

Rules:

- use synthetic fixtures by default;
- never copy production database dumps into local/dev environments as a normal workflow;
- avoid real user Emails, Phones, health values, photos, exports, or tokens in tests, docs, screenshots, issues, PRs, demos, or fixtures;
- sanitize support evidence before sharing;
- production-only credentials remain outside development/client artifacts;
- if production debugging ever requires sensitive inspection, it needs an explicit narrow operational reason and must avoid creating persistent secondary copies.

Supabase development branches should use synthetic/disposable fixtures rather than production identity or health records.

## Consent and User Controls

Consent/UI language is product/legal dependent and must not be invented generically in architecture docs.

Where a feature requires user permission or an explicit user choice, implementation must make that control meaningful and aligned with the actual data flow. Examples may include connected health providers, private-media analysis, AI features using sensitive context, notification permissions, or future public sharing.

A consent screen does not authorize unrelated secondary data use.

## Third-Party Provider Review

Before a new provider receives Personal, Sensitive, or Health-context data, record at minimum:

- provider and capability;
- data classes transmitted;
- purpose;
- authentication/secret boundary;
- whether data is stored by the provider;
- configured retention/training/reuse controls where applicable;
- deletion/export limitations;
- fallback/failure behavior;
- owner for future provider replacement or contract changes.

Do not spread provider SDK calls across product modules when a shared internal boundary is appropriate.

## Relationship to Security

Security asks whether data and systems are protected from unauthorized access or misuse.

Privacy governance additionally asks:

- should Tio collect this data at all?
- should this workflow receive it?
- should it leave Tio-controlled systems?
- how long should it exist?
- what happens on deletion/export?

Both are required. Passing security review does not automatically make unnecessary collection or sharing acceptable.

## Implementation Gate

This policy does not authorize runtime/backend work.

Until separately approved tasks execute:

- no `services/api` scaffold is required;
- no analytics/attribution SDK is selected;
- no AI provider integration is started;
- no new Storage bucket is created solely because it is described here;
- no export service/job is implemented;
- no retention cron/job is introduced;
- no Supabase schema/configuration is mutated;
- no jurisdiction/certification is declared.

## Acceptance for TNYX-48

- [x] Sensitive data classes and default handling are explicit.
- [x] Data minimization and purpose limitation are defined.
- [x] Logging and analytics exclusions are documented.
- [x] AI/provider context and data-sharing boundaries are explicit.
- [x] Private user-media handling is defined at architecture level.
- [x] Deletion propagation responsibilities are defined without replacing the existing Account Deletion contract.
- [x] Export/portability strategy is defined without premature implementation.
- [x] Retention categories/rules are defined without inventing unsupported durations.
- [x] Production vs development/test data separation is explicit.
- [x] Policy complements Security rather than duplicating it.
- [x] No legal jurisdiction/certification is assumed.
- [x] No backend/runtime/Supabase mutation is introduced by this documentation slice.
