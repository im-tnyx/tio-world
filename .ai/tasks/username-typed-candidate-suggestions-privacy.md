# Username Typed-Candidate Suggestions Privacy

**Status:** DONE  
**Tracking:** GitHub issue #116  
**Primary owners:** Account Setup + Core UI + Supabase username RPC policy  
**Accepted runtime/source-test SHA:** `2a561637a1ff9d8ac9808b0fe9bc47d923f4ebfc`

## 1. Outcome

Username bootstrap and alternatives preserve a strict privacy boundary:

- a missing canonical username starts blank with the generic `e.g. your.name` hint;
- an existing persisted canonical username may hydrate normally;
- Profile `Name`, provider display name, email/local-part, phone, DOB/year/age, avatar metadata, and other personal profile/account attributes never seed a new username candidate;
- the only seed for generated alternatives is the username candidate explicitly typed by the user;
- unavailable candidates receive bounded, human-readable, server-verified alternatives rather than one fixed `.<hash>` template;
- tapping an alternative re-runs the authoritative availability check;
- existing stale-response and save-race protections remain authoritative.

The broader source-of-truth contract is frozen in `.ai/tasks/auth-provider-aware-mobile-and-google-photo.md`.

## 2. Implementation

### Flutter regression coverage

`apps/features/account_setup/test/presentation/username_step_test.dart` locks:

- blank missing-username state and generic hint;
- persisted canonical username hydration;
- server-supplied alternatives;
- suggestion tap followed by authoritative re-check;
- save-race alternative refresh.

### Supabase forward migration

`supabase/migrations/20260826075218_refine_username_suggestions.sql`

The migration replaces only `private.username_suggestions(text, uuid)` and does not add/remove/alter application tables, columns, indexes, or stored user rows.

Generation contract:

- lowercase/trim the explicit typed candidate;
- use the typed candidate as the only variation/hash seed;
- clean repeated/edge separators for readable suggestion bases;
- use neutral `user` fallback for protected or separator-only bases without reading identity/profile data;
- vary numeric suffix length and separator shape;
- cap generated usernames at 30 characters;
- re-check every candidate with `private.username_unavailability_reason(...)` before returning it;
- return up to five verified alternatives from a bounded search.

The private helper remains non-executable by API roles. Public authenticated username RPCs retain their reviewed narrow `SECURITY DEFINER` boundary so owner-scoped RLS does not require broad user-directory reads.

## 3. Validation

### Source CI

```text
Accepted source SHA:
2a561637a1ff9d8ac9808b0fe9bc47d923f4ebfc

Flutter CI #2072 / run 32944095016 ✅
Android Native CI #484 / run 32944095056 ✅
```

Flutter/Dart analyze, Flutter/Dart tests, Phone Android debug APK, and Wear Android debug APK completed successfully on the accepted source SHA.

### Live Supabase migration

Applied to the canonical `tio-world` Supabase project after explicit owner approval.

```text
Live migration version: 20260826075218
Live migration name:    refine_username_suggestions
Result:                 ✅ success
```

### Post-migration production verification

Read-only verification against the live database confirmed:

- installed function signature is `private.username_suggestions(text,uuid)`;
- function remains `STABLE`, `SECURITY INVOKER`, and executable only by `postgres`;
- function definition contains the repeated/edge separator cleanup;
- deterministic variation seed remains `v_username` only;
- `runner`, `a..`, `...`, `foo__bar`, `admin`, and a 30-character candidate each returned five alternatives in the verification sample;
- every returned alternative passed the authoritative availability/policy helper;
- all returned alternatives matched the 3–30 character lowercase ASCII handle policy;
- no returned alternative contained repeated dot/underscore separators in the verification set;
- reserved `admin` did not produce an `admin` namespace lookalike.

Representative verified live results included:

```text
runner   -> runner71, runner_187, runner.436, runner4113, runner_58
a..      -> a55, a_251, a.227, a6258, a_59
admin    -> user66, user_535, user.615, user4805, user_35
```

No test rows or usernames were inserted or mutated by these verification queries.

## 4. Advisor Review

Supabase advisor checks after the DDL reported no finding introduced by the private suggestion helper.

Existing security warnings remain for intentionally callable authenticated `SECURITY DEFINER` RPCs such as `check_username_availability` and `claim_username`; that narrow boundary is intentional and documented because username collision checks must not require broad `public.users` reads. Existing unrelated Auth/RLS/index advisor warnings are outside issue #116.

## 5. Final Acceptance

- [x] Missing username remains blank with generic hint.
- [x] Persisted canonical username still hydrates.
- [x] Personal/profile/provider data cannot seed suggestions.
- [x] Only explicit typed candidate seeds generated alternatives.
- [x] Suggestions use multiple readable shapes rather than one mandatory template.
- [x] Returned alternatives are server-verified.
- [x] Reserved/system policy remains authoritative.
- [x] Character and 3–30 length policy remains authoritative.
- [x] Suggestion tap re-checks availability.
- [x] Race/stale-response regressions remain covered.
- [x] Forward migration applied successfully to canonical Supabase.
- [x] Live post-migration verification passed.

## 6. Known Limitations / Non-Goals

Comprehensive profanity/abuse policy remains a separate reviewed product-policy concern. This task does not change canonical username storage, uniqueness semantics, or expose broad user-directory reads.

## Final Status

`DONE` — issue #116 runtime, tests, source CI, live migration, and production read-only verification are accepted.