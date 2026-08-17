# Provider-aware Username, Mobile Step & Google Photo Bootstrap

**Status:** Planned — product contract frozen where specified, implementation pending
**Parent tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`
**Primary owners:** `apps/features/auth` + `apps/features/onboarding` + `apps/features/profile` + `apps/app`

## 1. Purpose

Define the post-auth onboarding behavior for fresh account signup, the new Username screen, Google/email signup, future mobile/Truecaller auth, optional mobile collection, and first-signup Google profile-photo bootstrap.

This focused task is the source of truth for these rules and **supersedes any earlier wording that said mobile-number entry is required**.

## 2. Fresh-signup post-auth order

For a newly created Tio account, authentication establishes ownership before account-specific profile fields are written to Supabase.

```text
Fresh signup authentication succeeds
→ Username screen
→ Mobile screen when provider-aware rules require it
→ remaining onboarding flow
```

The Username screen therefore belongs immediately after successful fresh-account authentication and before the optional Mobile screen.

Returning existing accounts must not be forced through this fresh-signup bootstrap sequence just because they authenticate again.

## 3. Username screen contract

### Fresh account

```text
Fresh Google / Email / future supported signup
→ auth succeeds
→ Username screen
→ persist username only for the authenticated user
→ continue to provider-aware Mobile step
```

Rules:

- Username is collected **after authentication**, never through a pre-auth Supabase user-owned write.
- The screen is fresh-account bootstrap, not a normal returning-login screen.
- Persist to the canonical `public.users.username` field unless repository/schema audit establishes a different canonical owner before implementation.
- Do not silently overwrite an existing username on later login.
- Existing incomplete accounts should resume their durable onboarding state instead of blindly restarting Username because of the provider used to sign in.

### 3.1 Username normalization, availability, filtering, and suggestions

The existing `TioUsernameInputField` candidate style may be used only as inspiration for candidate generation. Tio must not require fixed suffixes or present any single pattern as the preferred username format.

Target behavior:

```text
User enters candidate
→ normalize locally
→ local format validation
→ debounce
→ server-side username policy + availability check
→ available
   OR
→ unavailable + 3–5 server-verified alternative suggestions
```

Frozen rules:

- Canonical comparison is case-insensitive. Current production schema already has a unique index on `lower(username)`, so `Santosh` and `santosh` must be treated as the same handle.
- Normalize candidate input consistently before checking/saving, including trim + lowercase canonical comparison.
- Initial public-handle character policy should remain simple and spoof-resistant: ASCII letters, numbers, underscore, and dot unless a later reviewed policy expands it.
- Minimum/maximum length must be enforced consistently in UI, server policy, and final persistence. The current UI uses a 3-character minimum; the exact maximum must be frozen before implementation and then mirrored at the database boundary where appropriate.
- Reserved and misleading handles must be rejected before normal availability succeeds. The reviewed reserved set should include Tio/system/support/admin/security/billing/official-style names and impersonation-prone combinations.
- Public username policy must account for profanity/abuse and obvious brand/support impersonation without exposing which account owns a blocked or taken name.
- Do not expose broad `public.users` lookup access merely to implement username availability. Current users-table RLS is owner-scoped, so availability should use a narrowly scoped backend/RPC/API contract that returns availability/suggestions only.
- Availability UI is advisory; the database unique constraint remains the final concurrency authority when the user saves.
- If a handle becomes taken between availability check and final save, return a controlled conflict state and refresh alternatives instead of failing generically.

Suggestion policy:

```text
@santosh taken
→ candidate generator produces multiple neutral variations
→ backend filters every candidate through the same policy + availability rules
→ UI receives only verified-available alternatives
```

Examples may include:

```text
@santosh47
@santosh.j
@santosh_jangid
@santosh214
@santosh_fit
```

But:

- `_fit` is not mandatory.
- `_tio` is not mandatory and should not be mechanically appended to every user.
- **Current year has no special role in username suggestions and must not be automatically appended or preferred.**
- A numeric suffix is just a neutral candidate variation; it must not encode or imply a year unless the user explicitly typed/chose that value.
- Suggestions should be dynamic and context-appropriate rather than a permanent hard-coded three-item list.
- Avoid deriving numeric suffixes from private attributes such as date of birth.
- Candidate generation may use name parts and short neutral/random numeric suffixes, but only server-verified available candidates should be displayed as suggestions.

Suggestion tap behavior:

```text
user taps suggestion
→ populate field
→ run the same authoritative availability check
→ mark Available only after current candidate is confirmed
```

Never mark a suggestion available merely because it was generated locally.

Async/race protection:

- Debounced availability requests must carry candidate/generation identity.
- A late response for an older typed handle must not overwrite UI state for the current handle.
- Re-check or otherwise verify the selected suggestion before allowing it to be represented as available.

Backend contract target:

```text
check_username_availability(candidate)
→ normalized candidate
→ isAvailable
→ safe message/reason category as needed
→ verified available suggestions
```

The endpoint/RPC must not reveal the identity or profile of the account that already owns a taken username.

### Product decision still pending

The placement is frozen, but **whether Username is mandatory or may be skipped is not yet frozen**. Do not invent this rule in implementation. Before the Username slice starts, explicitly decide:

```text
Username screen
→ required before Next
OR
→ optional / Skip allowed
```

## 4. Frozen Mobile-step contract

### Google fresh signup

```text
Get Started / explicit signup
→ Google auth succeeds
→ Username screen
→ Mobile screen
→ user MAY enter a mobile number OR leave it blank
→ OTP verification is optional/deferred for the current release
→ Next is allowed whether mobile is present or absent
→ continue onboarding
```

Rules:

- The Mobile screen is shown for fresh Google signup after Username.
- Mobile number entry is **optional**.
- Blank mobile must not block `Next`.
- If the user enters a mobile number, persist it after authentication under the authenticated user.
- If the user leaves it blank, keep the canonical mobile field null/empty; do not invent a value.
- OTP is not implemented yet and must not block onboarding.
- Until OTP/provider proof exists, `mobile_verified_at` remains null.
- Typing a number is not verification.

### Email fresh signup

```text
Explicit Email signup
→ email auth succeeds
→ Username screen
→ Mobile screen
→ user MAY enter a mobile number OR leave it blank
→ OTP optional/deferred
→ Next always available
→ continue onboarding
```

Same persistence and verification rules as Google signup.

### Future mobile-number auth

```text
Mobile auth succeeds
→ Username screen for a genuinely fresh account
→ mobile identity already supplied by the auth provider
→ skip Mobile onboarding screen
→ continue onboarding
```

Do not ask the user to re-enter the same mobile number immediately after mobile authentication.

### Future Truecaller auth

Truecaller remains unavailable in the current release. Do not enable it in this task.

Future target:

```text
Truecaller auth succeeds
→ Username screen for a genuinely fresh account
→ mobile supplied by provider
→ skip Mobile onboarding screen
→ provider may also return email
→ do not treat that email as verified unless provider/backend evidence proves it
→ continue onboarding
```

Provider-supplied mobile should only be marked verified once Truecaller verification semantics are explicitly validated.

## 5. Returning-user behavior

```text
Existing completed Tio account login
→ restore account/session
→ do not inject Username
→ do not inject Mobile onboarding
→ Home
```

For an existing incomplete account, resume the durable saved onboarding state. Do not restart provider-specific setup just because the current login provider is Google/email.

## 6. Google profile photo — first signup only

Current defect: a fresh Google signup can authenticate successfully but the Google profile photo is not persisted into the Tio profile.

Target:

```text
Fresh Google signup
→ Google identity has profile photo
→ Tio user has no user-owned avatar yet
→ import provider photo once
→ persist into one canonical Tio avatar field
```

Rules:

- Import Google photo only during first-account bootstrap / fresh signup.
- Missing Google photo is valid and must not block signup.
- Returning Google login must not overwrite the avatar.
- A user-uploaded/custom Tio photo is always authoritative after signup.
- Provider-photo enrichment is non-critical; failure must not turn valid authentication into failure.
- Before implementation, choose one canonical DB/runtime field (`avatar_url` vs legacy `profile_image`) and avoid dual source-of-truth writes.

## 7. Persistence ownership

```text
Before auth
→ onboarding draft remains device-local only
→ no Supabase user-owned writes

After auth
→ Username can be persisted for the authenticated fresh account
→ optional entered mobile can be persisted for that authenticated user
→ Google photo bootstrap can persist for fresh Google signup only
```

Mobile may remain null forever if the user chooses not to provide it.

## 8. Required implementation tests

- [ ] fresh account authentication routes to Username before Mobile/later onboarding;
- [ ] returning completed login does not show Username;
- [ ] existing username is not overwritten by later login;
- [ ] username normalization is case-insensitive and matches backend uniqueness semantics;
- [ ] invalid/reserved/impersonation-prone usernames are rejected by the reviewed policy;
- [ ] availability is checked through a narrow backend contract rather than broad users-table reads;
- [ ] unavailable username returns only verified-available suggestions;
- [ ] suggestions are dynamic and do not require `_fit`, `_tio`, or any year-based suffix;
- [ ] current year is never automatically appended or preferred by the suggestion engine;
- [ ] tapping a suggestion re-checks/validates it before showing Available;
- [ ] stale async availability responses cannot overwrite the current input state;
- [ ] final save handles a unique-race conflict with controlled UX and refreshed suggestions;
- [ ] fresh Google signup routes to Mobile after Username;
- [ ] fresh Email signup routes to Mobile after Username;
- [ ] blank Mobile screen can continue with `Next`;
- [ ] blank mobile persists no fake/default value;
- [ ] entered mobile persists while `mobile_verified_at` remains null when OTP is not completed;
- [ ] returning completed Google/email login does not show Mobile onboarding;
- [ ] incomplete returning account resumes its durable saved step;
- [ ] future mobile-auth path skips Mobile screen;
- [ ] future Truecaller path skips Mobile screen and does not mark provider email verified without evidence;
- [ ] fresh Google signup imports provider photo once when Tio avatar is empty;
- [ ] later Google login does not overwrite a custom/user-owned avatar;
- [ ] missing Google photo does not block signup.

## 9. Non-goals

- Do not implement Truecaller in this slice.
- Do not implement/send OTP in this slice unless separately approved.
- Do not require a mobile number to continue onboarding.
- Do not mark typed mobile verified.
- Do not overwrite existing/custom profile photos from Google on later logins.
- Do not add pre-auth Supabase writes.
- Do not assume Username is mandatory or optional until that product decision is explicitly frozen.
- Do not expose broad user-directory reads for availability checking.
- Do not treat locally generated username suggestions as authoritative availability results.
- Do not bias username suggestions toward the current year.
