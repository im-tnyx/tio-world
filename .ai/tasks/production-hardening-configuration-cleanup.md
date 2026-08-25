# Production Hardening — Configuration Cleanup

**Status:** Ready  
**Primary owner:** `apps/app` runtime configuration boundary  
**Affected platforms:** Flutter phone app; build/release configuration  
**Tracking:** production hardening #5 — Configuration cleanup

## 1. Discovery

### User Outcome

A release build must never silently select a Supabase project because build-time configuration was omitted, while local/test harnesses remain constructible without fabricated backend readiness.

### Success Criteria

- release configuration selection is explicit and fail-safe;
- `main.dart` and provider composition consume one resolved Supabase configuration instead of duplicating environment/default logic;
- current live production project URL/publishable key are not embedded as implicit defaults in runtime source;
- modern Supabase publishable-key naming/API is used, with only bounded compatibility for an explicitly supplied legacy `SUPABASE_ANON_KEY` if needed;
- release initialization/configuration failures are not swallowed as a headless-test fallback;
- no service-role/secret key is introduced to the client;
- timezone audit is documented without speculative schema/runtime work;
- full exact-SHA Flutter/Dart + Android validation is green before freeze.

### Scope

- `apps/app/lib/main.dart`
- `apps/app/lib/app/network_providers.dart`
- one small app-owned runtime/Supabase configuration contract if needed
- focused app configuration tests
- minimal developer/release configuration documentation/example only if required to make explicit build-time configuration usable

### Non-Goals

- no Supabase schema migration;
- no RLS/Auth/provider redesign;
- no backend-service creation;
- no secret-manager architecture;
- no staging project creation or invented project mapping;
- no timezone package/plugin addition while no current timezone consumer exists;
- no UI/navigation/visual change;
- no change to canonical owner tables.

## 2. Codebase Exploration

### Verified Evidence

Audit head:

```text
95e95a5b03815814002275b323844a80693e4610
```

Source/config inspected:

- `apps/app/lib/main.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/app/test/app/network_providers_test.dart`
- `apps/app/lib/app/**`
- `apps/app/pubspec.yaml`
- `apps/app/pubspec.lock`
- `.github/workflows/**`
- `.gitignore`
- current Supabase project URL/publishable-key metadata
- live `public.users`, `user_profiles`, `user_app_preferences`, and `user_devices` columns
- current device identity + device-sync repositories

Reproducible findings:

1. `main.dart` resolves `SUPABASE_URL` with the live `tio-world` project URL as a `defaultValue` and resolves `SUPABASE_ANON_KEY` with the live modern `sb_publishable_...` key as a `defaultValue`.
2. `network_providers.dart` independently duplicates the same environment names and same live-project defaults.
3. Therefore any build that omits Dart defines silently selects the live project. This is a wrong-environment release risk even though the publishable key itself is client-safe/non-secret.
4. `main.dart` catches every Supabase initialization exception and continues. The comment describes a headless-test fallback, but the same catch applies to a real release startup failure.
5. Provider composition then catches an uninitialized `Supabase.instance.client` and falls back to no-Supabase/in-memory boundaries. Product Onboarding completion fails closed, but release startup itself does not make the configuration failure explicit.
6. Current locked `supabase_flutter` is `2.17.1`; current Supabase guidance exposes `publishableKey` and recommends publishable keys for public/mobile clients. The current code still passes the modern publishable key through the deprecated `anonKey` parameter and legacy environment name.
7. Repository search found no existing `--dart-define` build contract or checked example configuration.
8. Live database has a nullable `public.users.timezone` compatibility column, but all current rows have it unset.
9. The removed broad `SupabaseProfileSetupRepository` was the historical source reference returned by timezone search; it is absent on the current head. Current `FlutterDeviceIdentityProvider` and `SupabaseUserDeviceRepository` do not capture or persist timezone.
10. No current product/runtime consumer was found that requires persisted timezone for correctness in this release-hardening slice.

### Existing pattern to follow

- compile-time Flutter values use `String.fromEnvironment`;
- provider tests already explicitly override Supabase availability and prove no-Supabase finalization fails closed;
- `.gitignore` already excludes `.env`/local/secret files and permits an `.env.example`, but no example currently exists.

### Tests or validation already present

- `apps/app/test/app/network_providers_test.dart`
- full Flutter/Dart CI
- Android Native CI (phone + Wear debug APKs)

## 3. Clarification

### Decisions Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Treat Supabase publishable key as client-safe, not a secret | Made | current Supabase contract; RLS/auth remains the protection boundary | app/platform |
| Remove implicit live-project defaults from production runtime selection | Made | omission must not silently choose production | app composition |
| Keep local/test no-Supabase composition constructible | Made | current tests and non-backend harnesses intentionally use explicit unavailable fallbacks | app composition |
| Prefer `SUPABASE_PUBLISHABLE_KEY`; allow explicit legacy `SUPABASE_ANON_KEY` compatibility only if bounded | Made | current key is modern publishable; legacy naming/API should not be the primary contract | app composition |
| Release configuration/init failure must fail closed instead of being swallowed | Made | a release must not continue under false backend assumptions | startup |
| Do not add timezone persistence/schema work now | Made | no current consumer, 0 populated live values, and no current runtime write/read path | configuration cleanup |
| Future canonical timezone representation should be an IANA zone identifier, not a raw UTC offset | Made | offsets are snapshots and do not encode DST/travel zone rules | future product/data owner |
| Do not assign a new canonical timezone table/owner in this slice | Made | product semantics/consumer do not yet justify an ownership migration | #44 owner map |

## 4. Architecture Design

### Chosen Approach

Introduce one app-owned resolved Supabase runtime configuration contract consumed by both startup initialization and Riverpod provider composition.

Expected behavior:

```text
build-time environment
    -> one SupabaseRuntimeConfig resolver
       -> startup validates config
       -> Supabase.initialize(...) when explicitly configured
       -> same resolved config injected into ProviderScope
       -> providers use initialized client only
```

Release mode:

- no embedded live-project default;
- missing/partial Supabase config is a startup configuration error;
- initialization failure is surfaced/fails closed;
- only publishable/legacy-anon client-safe keys are accepted by this boundary.

Debug/test mode:

- missing config may remain intentionally unconfigured so tests/local non-backend harnesses can compose no-Supabase fallbacks;
- an explicitly supplied valid config initializes normally;
- no automatic production selection.

### Alternative Rejected

- Keep current live project as a debug/release default: rejected because omission remains an implicit production connection.
- Add service-role/secret key handling to Flutter: rejected; elevated keys never belong in a public mobile client.
- Create staging/dev Supabase projects or hardcode an environment-to-project mapping: rejected as outside current audited evidence.
- Add timezone plugin/schema columns now: rejected because there is no current runtime consumer or populated canonical data.

### Failure and Accessibility States

No UI change. Release configuration failure occurs before normal app composition and must be diagnosable rather than silently degrading into an in-memory production session.

## 5. Implementation Plan

- [ ] add a single testable Supabase runtime configuration resolver/contract;
- [ ] remove live project URL/key `defaultValue` usage from `main.dart` and `network_providers.dart`;
- [ ] prefer `SUPABASE_PUBLISHABLE_KEY` and modern `publishableKey:` initialization;
- [ ] keep an explicit legacy `SUPABASE_ANON_KEY` compatibility path only if it does not restore implicit fallback behavior;
- [ ] make release missing/partial configuration fail closed;
- [ ] make release Supabase initialization failure propagate instead of being swallowed;
- [ ] inject the same resolved config into provider composition so startup/provider selection cannot drift;
- [ ] add focused tests for complete, missing, partial, publishable-key, and legacy-key resolution plus release/debug policy;
- [ ] add the smallest usable build-time configuration example/documentation if required;
- [ ] run full exact-SHA Flutter analyze, Dart analyze, Flutter tests, Dart tests, phone Android debug APK, and Wear Android debug APK;
- [ ] freeze accepted checkpoint in #5 and keep PR #50 Draft/open/unmerged until explicit merge authorization.

## 6. Quality Review

### Validation Run

```text
Audit only. Implementation validation not run yet.
```

### Review Findings and Resolution

- Merge-blocking concrete defect: implicit live Supabase project selection + release-wide swallowed initialization failure.
- Timezone: audited/classified; representation strategy documented, no current implementation defect authorizes schema/runtime expansion.

## 7. Final Handoff

### Changed Files

Audit brief only.

### Actual Behavior

Current release/runtime source still contains the audited implicit live-project defaults until the implementation checklist is executed.

### Known Limitations

There is no release deployment workflow in `.github/workflows`; current CI validates source/tests and debug Android compilation. This slice should make application configuration safe independently of any future store/deployment pipeline.

### Final Status

`REVIEW`
