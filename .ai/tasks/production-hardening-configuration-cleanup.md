# Production Hardening — Configuration Cleanup

**Status:** Complete / Frozen  
**Primary owner:** `apps/app` runtime configuration boundary  
**Affected platforms:** Flutter phone app; build/release configuration  
**Tracking:** production hardening #5 — Configuration cleanup

## 1. Discovery

### User Outcome

A release build must never silently select a Supabase project because build-time configuration was omitted, while local/test harnesses remain constructible without fabricated backend readiness.

### Success Criteria

- release configuration selection is explicit and fail-safe;
- `main.dart` and provider composition consume one resolved Supabase configuration;
- no live Supabase project URL/publishable key is embedded as an implicit runtime default;
- modern `SUPABASE_PUBLISHABLE_KEY` / `publishableKey:` is primary, with bounded explicit legacy anon compatibility;
- release configuration and initialization failures fail closed;
- no service-role/secret key is accepted by the Flutter client boundary;
- timezone audit is recorded without speculative schema/runtime work;
- exact-SHA Flutter/Dart + Android validation is green.

### Scope Implemented

- `apps/app/lib/app/supabase_runtime_config.dart`
- `apps/app/lib/main.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/test/app/supabase_runtime_config_test.dart`
- `docs/SUPABASE_RUNTIME_CONFIG.md`

### Non-Goals Preserved

- no Supabase schema migration;
- no RLS/Auth-provider redesign;
- no backend-service creation;
- no secret-manager architecture;
- no staging/dev project creation or invented project mapping;
- no timezone package/plugin or persistence work;
- no UI/navigation/visual change;
- no canonical owner-table change.

## 2. Codebase Exploration

### Verified Audit Evidence

Audit source head:

```text
95e95a5b03815814002275b323844a80693e4610
```

Reproduced before implementation:

1. `main.dart` used live `tio-world` Supabase URL/key `defaultValue`s.
2. `network_providers.dart` independently duplicated the same defaults.
3. Omitted Dart defines therefore silently selected the live project.
4. `main.dart` swallowed every Supabase initialization failure, including release startup failure.
5. Provider composition could then silently degrade to no-Supabase/in-memory boundaries.
6. Locked `supabase_flutter` is `2.17.1`; current API supports `publishableKey` and modern publishable keys.
7. No repository build-time Supabase configuration contract was documented.
8. Live `public.users.timezone` exists but all audited live rows were unset; current device/runtime code has no timezone persistence consumer.

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Treat publishable key as client-safe, not secret | Made | RLS/Auth remain the protection boundary |
| Remove implicit live-project defaults | Made | omission must not select production |
| Keep debug/test no-config composition constructible | Made | existing local/test harnesses intentionally support unavailable backend state |
| Prefer `SUPABASE_PUBLISHABLE_KEY` | Made | modern Supabase client contract |
| Allow legacy `SUPABASE_ANON_KEY` only when it is an anon-role JWT | Made | bounded compatibility without accepting service-role credentials |
| Reject `sb_secret_` client configuration | Made | elevated keys never belong in Flutter client |
| Release missing/partial config fails closed | Made | no false production backend readiness |
| Release initialization errors propagate | Made | no silent in-memory production degradation |
| Future timezone canonical form is IANA zone ID | Made | raw offsets do not encode DST/travel semantics |
| Do not implement timezone persistence now | Made | no current consumer or populated live data |

## 4. Frozen Architecture

```text
compile-time Dart defines
    -> SupabaseRuntimeConfig.fromEnvironment()
       -> validate URL + client-safe key contract
       -> initializeSupabaseRuntime()
          -> Supabase.initialize(publishableKey: ...)
       -> same resolved config injected into ProviderScope
       -> supabaseConfigProvider
       -> supabaseClientProvider
```

Release policy:

- `SUPABASE_URL` + `SUPABASE_PUBLISHABLE_KEY` are required;
- explicit legacy `SUPABASE_ANON_KEY` is compatibility-only;
- missing/partial config throws before normal app composition;
- initialization failure propagates;
- provider composition does not convert an unavailable initialized client into a silent release fallback.

Debug/test policy:

- no Supabase values => explicit unconfigured state;
- existing no-Supabase test/local composition remains available;
- explicitly supplied malformed/partial config still fails rather than guessing.

## 5. Completed Implementation

- [x] added one testable `SupabaseRuntimeConfig` resolver/contract;
- [x] removed live URL/key defaults from `main.dart` and `network_providers.dart`;
- [x] switched primary key name to `SUPABASE_PUBLISHABLE_KEY`;
- [x] switched initialization to modern `publishableKey:` API;
- [x] bounded legacy `SUPABASE_ANON_KEY` to `role=anon` JWT compatibility;
- [x] rejected `sb_secret_` client keys;
- [x] made release missing/partial configuration fail closed;
- [x] made release initialization failure propagate;
- [x] injected the same resolved config into ProviderScope;
- [x] added focused complete/missing/partial/key-source/failure-policy tests;
- [x] documented explicit build-time configuration;
- [x] ran exact-SHA Flutter/Dart + phone/Wear Android validation;
- [x] froze accepted checkpoint in #5.

## 6. Quality Review

Accepted runtime/source-test checkpoint:

```text
faeb7e403c387cdc5561b8f2f9402886f6aaa94c
```

Exact-SHA validation:

```text
Flutter CI #2005 / run 32853309958 ✅
  Flutter analyze ✅
  Dart analyze    ✅
  Flutter tests   ✅
  Dart tests      ✅

Android Native CI #417 / run 32853309733 ✅
  Phone Android debug APK ✅
  Wear Android debug APK  ✅
```

Compare from the configuration audit brief head `3420ca8bf019175dd44677cbff841ee12f46d14d` to accepted runtime SHA contains only the bounded runtime config owner, startup/provider wiring, focused tests, and configuration documentation.

Issue #5 freeze comment:

```text
5411184764
```

## 7. Final Handoff

**Complete / Frozen.**

The accepted runtime/source-test SHA remains:

```text
faeb7e403c387cdc5561b8f2f9402886f6aaa94c
```

This documentation-only closeout commit does not replace that runtime acceptance checkpoint.

Timezone remains intentionally deferred until a concrete product consumer defines ownership and scheduling semantics.

Next bounded merge-hardening lane: canonical mobile-number normalization to E.164 across Account Setup, Account Settings, and Supabase Auth verification. No new country-code database column is implied by that next audit.

PR #50 must remain Draft/open/unmerged until explicit merge authorization.

### Final Status

`PASS`
