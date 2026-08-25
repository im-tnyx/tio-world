# Production Hardening — Onboarding Persistence Churn

**Status:** Complete / frozen
**Primary owner:** Product Onboarding / production hardening #5 item 18
**Affected platforms:** Flutter phone app; app-owned onboarding persistence composition

## Global UI / Design-System Guardrail

No visual change was authorized or made. Current onboarding rendering, navigation, copy, geometry, and design-system behavior remain unchanged.

## 1. Discovery

### User Outcome

Keep unfinished onboarding durable and resume-safe without redundant status writes or overlapping draft saves that can persist stale snapshots out of order.

### Success Criteria

- `OnboardingStatus.inProgress` is not rewritten when already durably persisted.
- Failed status persistence remains retryable on a later user edit.
- Existing 300 ms ordinary-edit debounce and immediate navigation/branch saves are preserved.
- Production draft repository calls are serialized so an older request cannot complete after and overwrite a newer snapshot.
- Existing O8/O9 furthest-valid resume, edit-back, failure recovery, completion ordering, retry, and idempotency contracts remain unchanged.

### Final Scope

- `apps/app/lib/app/onboarding/app_onboarding_controller.dart`
- `apps/app/test/app/onboarding_persistence_churn_test.dart`
- this task brief

The storage-neutral feature `OnboardingController` scheduler was intentionally left unchanged. Production already replaces it with the app-owned `AppOnboardingController`, so the hardening was composed at that production boundary instead of broadening the feature controller contract.

### Non-Goals

- no Supabase schema/RLS/migration change;
- no `onboarding_drafts` ownership or payload format change;
- no navigation/flow/eligibility change;
- no completion ordering change;
- no UI/design change;
- no generic repository rewrite.

## 2. Codebase Exploration

### Verified Evidence

Audit predecessor:

```text
a76ec4502395296f6ee4b47c5564c6a8def088c8
```

Inspected:
- feature `OnboardingController` scheduling/status behavior;
- production `AppOnboardingController` override in `apps/app/lib/main.dart`;
- `OnboardingStatusRepository` and SharedPreferences implementation;
- `OnboardingDraftRepository`, Supabase/Auth-aware production composition;
- existing controller draft-persistence tests;
- O8D autosave failure-recovery acceptance.

Existing semantics retained:
- 300 ms debounce for ordinary edits;
- immediate saves for navigation/branch transitions;
- failed draft saves preserve current in-memory truth;
- later user edits can retry persistence.

### Reproducible Findings

1. Base `_markInProgress()` invokes status persistence for every edit even after local state is already `inProgress`; the production repository boundary had no dedupe, so repeated edits caused repeated durable writes.
2. Multiple immediate `_flushDraftSave()` calls could reach the production repository concurrently. Revision counters prevent some duplicate starts but do not prevent an older network request from finishing after a newer save and overwriting it.

## 3. Clarification

| Decision | Result | Rationale |
|---|---|---|
| Harden the app-owned production composition | Accepted | `main.dart` already overrides the feature controller with `AppOnboardingController` |
| Check persisted status before first dedupe decision | Accepted | hydrated `inProgress` resume must not cause one unnecessary rewrite per controller instance |
| Serialize production draft repository operations | Accepted | preserves existing scheduler call sites while eliminating stale completion ordering |
| Preserve failure retry semantics | Accepted | failed status/draft persistence must not be memoized as success |
| No automatic retry loop | Accepted | avoids outage spin and preserves O8D later-edit retry behavior |

## 4. Architecture Design

### Accepted Approach

```text
Onboarding UI
  -> feature OnboardingController scheduler (unchanged)
  -> production AppOnboardingController composition
     -> _DeduplicatingOnboardingStatusRepository
        -> SharedPreferencesOnboardingStatusRepository
     -> _SerializingOnboardingDraftRepository
        -> Auth-aware / Supabase draft repository
```

`_DeduplicatingOnboardingStatusRepository`:
- lazily reads the currently persisted status before the first write decision;
- suppresses an already-durable identical status;
- shares an identical in-flight status operation;
- records success only after the delegate succeeds;
- permits a later edit to retry after read/write failure.

`_SerializingOnboardingDraftRepository`:
- queues save/clear operations in mutation order;
- never allows two delegate writes from one live app controller to overlap;
- surfaces each operation's failure to the existing feature controller handling;
- keeps the internal queue usable after a failed operation.

### Rejected Alternatives

- schema revision/timestamp conflict machinery: unnecessary storage-contract expansion;
- removing immediate saves: weakens accepted resume durability;
- changing base flow/navigation scheduler semantics: broader than the reproducible production issue;
- automatic background retry loops: changes accepted failure-recovery behavior.

## 5. Implementation

- [x] production status persistence deduplicates repeated `inProgress` writes;
- [x] already-persisted `inProgress` is detected without rewriting;
- [x] failed status persistence can retry on a later edit;
- [x] production draft writes are serialized in mutation order;
- [x] 300 ms debounce and immediate-save call sites preserved;
- [x] focused regressions added;
- [x] no UI/navigation/schema/ownership changes.

## 6. Quality Review

### Exact Accepted Runtime Checkpoint

```text
cf7ed40bb3942646d0cfa23f04ed2fa16b3d9aa0
Flutter CI #1965 / run 32841098222 ✅
Android Native CI #377 / run 32841098217 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

The earlier `f40a076811542d9eaa16fb7997c9359546f74eb1` candidate failed only the `use_super_parameters` analyzer lint and was not accepted.

Focused regression file:

```text
apps/app/test/app/onboarding_persistence_churn_test.dart
```

Coverage locks:
- repeated edits produce one successful `inProgress` write;
- already-persisted `inProgress` produces zero rewrite;
- failed status write retries on a later edit;
- a second immediate draft save waits behind a blocked first save and preserves mutation order.

## 7. Final Handoff

### Changed Runtime Files

```text
apps/app/lib/app/onboarding/app_onboarding_controller.dart
apps/app/test/app/onboarding_persistence_churn_test.dart
```

### Actual Behavior

Production phone onboarding now removes redundant status churn and stale overlapping draft-save risk without changing Product Onboarding state semantics, flow, visuals, or database ownership.

### Known Limitations

No offline queue or cross-device merge algorithm is introduced. Serialization is intentionally scoped to writes generated by one live production app-controller instance; Supabase remains the durable owner under the existing Auth-aware repository contract.

### Final Status

`PASS / COMPLETE / FROZEN`

This task/tracker-only closeout commit does not replace the exact accepted runtime checkpoint `cf7ed40bb3942646d0cfa23f04ed2fa16b3d9aa0` above.
