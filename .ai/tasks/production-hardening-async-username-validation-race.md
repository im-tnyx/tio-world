# Production Hardening — Async Username Validation Race

## Status

**COMPLETE / FROZEN — NO LONGER REPRODUCIBLE. NO SOURCE CHANGE REQUIRED.**

Fresh audit head:

```text
1ef03b3c2db9b2b4de95639203ba32ebc7a0f3f2
```

Current source/test checkpoint already validated by:

```text
a49605481aa3f712bd7f623ffe83c7aa22a3f355
Flutter CI #1920 / run 32821216282 ✅
Android Native CI #332 / run 32821216283 ✅
```

Owner tracker: #5 P1 item 13.

## Goal

Re-audit `TioUsernameInputField` for the historical async availability race where a slower response for an older username could overwrite the state for a newer input.

## Fresh current-head findings

`TioUsernameInputField` already owns explicit stale-response protection:

- `_availabilityGeneration` increments whenever pending work is cancelled/invalidated;
- each scheduled availability check captures its generation;
- completion is ignored when the captured generation no longer matches;
- completion also rechecks the current normalized controller value against the requested handle;
- changing input cancels the previous debounce and invalidates any already-running response;
- applying a suggestion invalidates prior work and rechecks the suggestion before marking it available;
- `availabilityRefreshToken` invalidates/rechecks server state without fabricating a user text-change event.

Existing focused regression:

```text
apps/core/test/ui/components/tio_username_input_field_test.dart
```

explicitly starts two availability futures, resolves the newer handle first, then resolves the older request as unavailable, and proves the stale response cannot replace the newer available state.

The same suite also proves suggestion recheck and refresh-token revalidation behavior.

## Acceptance

- [x] Older async availability results cannot overwrite newer input state.
- [x] Both request-generation and current-controller-value guards are present.
- [x] Debounced pending checks are invalidated on input change/dispose.
- [x] Suggestions are rechecked before becoming available.
- [x] Explicit refresh invalidates prior availability without reporting a fake text change.
- [x] Existing focused test reproduces out-of-order completion and proves stale-response rejection.
- [x] No production source change required.
- [x] No DB migration.

## Classification

The historical item 13 async username validation race is **no longer reproducible** on the current component. Adding another mutex/debounce layer would duplicate existing protection and add unnecessary state complexity.

## Guardrails

- Preserve generation invalidation and controller-value verification together.
- Do not mark a suggestion available without rechecking it.
- Keep persistence-time username claim races handled by the authoritative repository/server contract; UI availability is advisory, not ownership proof.
- PR #50 remains Draft/open/unmerged unless separately authorized.
