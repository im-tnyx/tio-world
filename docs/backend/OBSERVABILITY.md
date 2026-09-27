# Observability Baseline

## Status

**Canonical operational-telemetry policy for future Tio API and worker processes.**

This document defines what Tio must be able to observe before protected backend/worker workloads are considered production-ready. It is documentation only: it does not create `services/api`, `services/worker`, logging middleware, dashboards, alerts, exporters, SDKs, or monitoring accounts.

Related boundaries:

- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)
- [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md)
- [Security](SECURITY.md)
- [Feature Rollout](FEATURE_ROLLOUT.md)

Linear ownership:

- TNYX-37 owns this observability contract.
- TNYX-29 owns future API implementation of request/correlation IDs, structured logging, health checks, rate limits, timeouts, and bounded dependency-failure behavior.
- TNYX-121 owns measurable SLO targets, alert thresholds, incident severity/runbooks, capacity triggers, and resilience exercises.
- TNYX-52 owns product analytics, attribution, crash-tool/provider selection, and user-behavior event taxonomy. Operational telemetry must not become an unreviewed product-tracking channel.

## Core Principle

Tio should be diagnosable from **safe metadata and system signals**, not raw user payloads.

```text
request / job / dependency operation
        ↓
structured safe telemetry
        ↓
logs + metrics + traces
        ↓
correlated diagnosis
        ↓
SLO / alert / incident policy (TNYX-121)
```

Observability is not permission to collect more user data. If a failure can be diagnosed with request metadata, route templates, status classes, durations, error codes, dependency names, and correlation IDs, do not record the underlying health/nutrition/workout/auth content.

## Telemetry Classes

Tio separates three operational telemetry classes:

1. **Structured logs** — discrete events used to explain what happened.
2. **Metrics** — bounded-cardinality numerical signals used to understand rates, latency, errors, saturation, and trends.
3. **Distributed traces** — causal timing across request, dependency, and future job boundaries.

A production-critical operation should emit the minimum useful combination of these signals rather than dumping raw objects into logs.

## Structured Logging Contract

Future API and worker logs must be machine-parseable structured records, not free-form multiline payload dumps.

Recommended common fields where applicable:

```text
timestamp
level
environment
service
service_version / release
instance_or_runtime_id         # ephemeral infrastructure identity only
operation / event_name
request_id
trace_id                       # when tracing exists
span_id                        # when tracing exists
route_template                 # e.g. /v1/workouts/:id, never raw sensitive path values
http_method
status_code / outcome
latency_ms
error_code                     # stable Tio-owned category where possible
dependency                     # e.g. supabase, provider category
retry_count
job_type                       # worker only
job_id                         # opaque system-generated ID
correlation_id / causation_id  # async handoff when applicable
```

Not every event needs every field. Schemas should remain small enough to use consistently.

### Log levels

Use levels consistently:

- `debug` — local/development diagnostics; disabled or heavily limited in production.
- `info` — normal lifecycle/operation milestones that are operationally useful.
- `warn` — degraded/retryable/unusual state requiring attention if sustained.
- `error` — failed operation requiring diagnosis.

Do not use `error` for expected client validation failures solely to increase visibility.

## Correlation Convention

Correlation must work without logging raw user identity.

### HTTP request

Each inbound protected API request should have a server-controlled `request_id`.

Rules:

- generate a new request ID when none exists;
- never trust an arbitrary client-provided value as authorization evidence;
- if an external correlation value is accepted, validate/bound its format and still retain a server-controlled identifier;
- return an appropriate request/correlation identifier in client-safe error responses so support can locate server telemetry without exposing internal details;
- propagate the safe correlation context to outbound dependency calls where supported.

### Distributed trace

When tracing is implemented, use OpenTelemetry-compatible/W3C Trace Context semantics so instrumentation is provider-portable.

`trace_id` / `span_id` are operational identifiers only. They must not encode user IDs, emails, phones, health values, or secrets.

### Async job

A future queued job should carry:

```text
job_id
job_type
correlation_id
causation_id or originating request/event reference when needed
```

This lets a user-facing request be traced into asynchronous work without copying the originating raw payload into telemetry.

API and worker telemetry must use the same field names and correlation semantics.

## Sensitive Data Exclusion

The default telemetry rule is **deny raw sensitive content**.

Do not log, metric-label, trace-attribute, or attach by default:

- `Authorization` headers, access tokens, refresh tokens, API keys, provider secrets, cookies, OTPs, passwords, signing material;
- request/response bodies containing health, nutrition, workout, body-measurement, recovery, medication, condition, or AI conversation data;
- raw email addresses, phone numbers, names, addresses, provider identity payloads, or unrestricted user text;
- raw Supabase JWT claims beyond narrowly approved non-sensitive operational fields;
- uploaded files, media URLs that grant access, signed URLs, or Storage object content;
- raw SQL bind values or database row contents;
- full provider/AI prompts and responses;
- payment credentials or webhook secrets.

If an error object may contain sensitive fields, sanitize it before serialization. "Log the exception" is not a safe default when third-party SDK exceptions can embed request or credential material.

### User correlation

Raw canonical user UUIDs should not be routine log dimensions or metric labels.

Prefer request/trace/job correlation. If a future support/security workflow genuinely requires cross-request actor correlation, define a separately reviewed opaque/pseudonymous reference with retention and access controls. Do not invent this capability inside ordinary logging middleware.

## Metrics Baseline

Metrics must use bounded-cardinality labels. Never create one time series per user, request ID, job ID, object ID, raw URL, free-text error, or provider payload.

### API

Minimum future API signals should cover:

- request count/rate by route template and method;
- response status class / stable outcome category;
- request latency distribution;
- active/in-flight requests where useful;
- timeout count;
- rejected/limited request count after rate limiting exists;
- liveness/readiness state exposed by the runtime, while TNYX-29 owns endpoint implementation.

### Worker / queue

When a real worker/queue exists, monitor:

- jobs accepted/started/succeeded/failed;
- queue depth where available;
- oldest-message / queue-delay age;
- processing duration;
- retry count/rate;
- dead-letter count/rate;
- duplicate/idempotency rejection count where implemented;
- worker concurrency/utilization/saturation signals appropriate to the runtime.

Queue semantics themselves belong to TNYX-30/TNYX-32.

### Database / Supabase

Observe system-level behavior without exposing row contents:

- operation latency/failure rates for server-owned calls;
- connection/pool saturation where applicable;
- timeout/exhaustion signals;
- slow-query counts/latency classes using sanitized query identity/fingerprint when available;
- RLS/authorization denial categories where operationally useful, without logging protected row values.

Do not turn observability into a shadow database audit dump.

### External providers

For each protected dependency/provider integration, collect safe signals such as:

- request count;
- latency distribution;
- timeout count;
- failure category/status class;
- retry count;
- circuit/degraded state when that pattern is later implemented;
- quota/throttle signals when exposed safely.

Provider names/categories are acceptable dimensions; prompts, user payloads, tokens, and unrestricted provider responses are not.

### Runtime / saturation

When the runtime exists, collect enough process/infrastructure signals to distinguish application failures from capacity failures, such as:

- CPU;
- memory;
- event-loop/runtime lag where relevant;
- process restarts/crashes;
- file/socket/connection saturation where relevant.

Exact scaling thresholds belong to TNYX-121, not this document.

## Distributed Tracing Baseline

Tio should remain **OpenTelemetry-ready** so future instrumentation can be exported to an approved backend without vendor-specific tracing calls spread through business modules.

Conceptual trace:

```text
HTTP ingress
  → route / application use case
  → Supabase / database span
  → provider span
  → enqueue span
      → worker consume span
      → provider / database span
```

Rules:

- use semantic spans around meaningful boundaries, not every helper function;
- record duration/status/error category, not raw request bodies;
- sanitize URL/query/header attributes;
- do not put secrets or health/user payloads into span events/baggage;
- baggage is allowlist-only because it propagates widely;
- sampling must not depend on sensitive health/user values;
- error traces must follow the same redaction rules as logs.

This policy does not select Datadog, Grafana, Honeycomb, Sentry, Firebase, New Relic, or any other telemetry vendor.

## Error Taxonomy

Operational diagnosis improves when failures use stable categories instead of arbitrary exception strings.

Future implementation should distinguish categories such as:

```text
validation
unauthenticated
forbidden
not_found
conflict
rate_limited
timeout
dependency_unavailable
dependency_rejected
internal
```

A provider-specific error may map into a stable Tio-owned category plus a safe provider status/code when useful.

Client-facing error messages, logs, metrics, and traces do not need identical detail. Internal telemetry may contain safe diagnostic metadata while client responses remain minimal and non-sensitive.

## Dashboards

Before a production API/worker is considered observable, operators should be able to answer without reading raw user payloads:

- Is the service receiving traffic?
- Is it available and ready?
- Are errors rising? Which route/dependency category?
- Is latency increasing? At ingress or a dependency?
- Are timeouts/retries growing?
- Is the database/provider failing or saturated?
- Is a future queue building backlog?
- Are workers processing successfully?
- Did a release correlate with the change?
- Is an optional provider degraded while core service remains healthy?

Dashboard panels should favor rates, distributions, bounded categories, and release/environment dimensions over raw log-stream walls.

## Alert Contract

TNYX-37 defines **what signals must exist**. TNYX-121 defines numerical SLO/error-budget thresholds, severity, ownership, escalation, and runbook requirements.

Future alerts must:

- be actionable;
- identify the affected service/capability/environment;
- link to the relevant dashboard/runbook when those exist;
- avoid embedding user/health/auth/secret data in notification payloads;
- use sustained/meaningful conditions rather than one noisy event where practical;
- distinguish core availability from optional-provider degradation;
- avoid alerting directly on high-cardinality raw log content.

Candidate alert classes include sustained error rate, latency/timeout degradation, readiness failure, dependency outage, queue backlog/dead-letter growth, resource saturation, and credential/configuration failure. Exact thresholds remain deferred to TNYX-121 and real workload evidence.

## Product Analytics Separation

Operational telemetry answers:

```text
Is the system healthy?
Why did an operation fail?
Where is latency or saturation occurring?
```

Product analytics answers:

```text
Which features do users adopt?
Where do funnels drop?
What drives retention/conversion?
```

Do not add user-behavior event collection to logs/traces merely because no analytics provider is selected yet. TNYX-52 owns analytics capability/provider decisions and must follow the privacy allowlist.

## Release And Environment Context

Every production telemetry stream should identify the non-secret deployment context needed for diagnosis, for example:

```text
environment
service
release/version/commit identifier
runtime/instance identifier where useful
region/location category when a deployment topology later has one
```

Never attach secret values or full environment dumps.

Environment names and configuration sourcing follow [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md).

## Retention And Access

Telemetry is production data and needs controlled access/retention.

Rules:

- retain only as long as operational/security needs justify;
- use shorter retention for verbose/debug telemetry;
- restrict production telemetry to authorized operators/tools;
- exports/support attachments must be sanitized before sharing;
- telemetry must follow deletion/privacy policy where it contains approved user-correlatable data;
- never assume a monitoring vendor is exempt from Tio provider/privacy review.

Exact provider retention settings are chosen only when a telemetry platform is implemented.

## Implementation Readiness Checklist

Before a future production API/worker declares TNYX-37 implemented at runtime, verify:

- [ ] structured logs use a stable schema;
- [ ] request IDs/correlation conventions work across API and worker boundaries;
- [ ] logs exclude raw sensitive payloads and credentials by default;
- [ ] metrics cover request/job/dependency latency, failures, and saturation with bounded cardinality;
- [ ] tracing is OpenTelemetry-compatible or has a documented equivalent portability path;
- [ ] trace/log correlation works without raw user identity;
- [ ] dependency/provider telemetry distinguishes timeout, rejection, and availability failures;
- [ ] dashboards diagnose core health without raw payload inspection;
- [ ] alert inputs exist, while TNYX-121 owns accepted thresholds/runbooks;
- [ ] release/environment context is attached safely;
- [ ] telemetry retention/access is explicitly configured;
- [ ] redaction tests cover representative auth/health/provider failures;
- [ ] product analytics remains separated from operational telemetry.

## Backend Implementation Gate

This policy does **not** authorize backend implementation.

Until separately authorized:

- no `services/api` or `services/worker` scaffold;
- no logger/tracing/metrics library installation;
- no OpenTelemetry collector/exporter;
- no monitoring SaaS account or provider selection;
- no dashboard/alert deployment;
- no Supabase configuration/schema mutation;
- no production secrets/config changes.

## Acceptance For TNYX-37

- [x] Structured log requirements are defined.
- [x] Metrics requirements cover API, future worker/queue, database/dependencies, providers, and runtime saturation.
- [x] OpenTelemetry-compatible distributed tracing readiness is defined without selecting a vendor.
- [x] Request/job/trace correlation conventions are consistent across future API and worker telemetry.
- [x] Provider/dependency latency and failure signals are explicit.
- [x] Sensitive user/health/auth/secret content is excluded by default.
- [x] Core service health can be diagnosed from safe metadata and system signals rather than raw user payloads.
- [x] TNYX-29, TNYX-121, and TNYX-52 ownership boundaries are explicit.
- [x] No backend/runtime observability implementation is introduced by this documentation slice.
