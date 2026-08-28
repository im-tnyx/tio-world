# Provider-aware Username, Mobile Step & Google Photo Bootstrap

**Status:** In progress — auth consolidation and required post-auth Username hardening implemented; provider-aware Mobile and remaining Google-photo validation pending
**Parent tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`
**Primary owners:** `apps/features/auth` + `apps/features/onboarding` + `apps/features/profile` + `apps/app`

## 1. Purpose

Define the signup/auth surface consolidation, post-auth onboarding behavior for fresh account signup, the new Username screen, Google/email signup, future mobile/Truecaller auth, optional mobile collection, and first-signup Google profile-photo bootstrap.

This focused task is the source of truth for these rules and supersedes earlier wording that:

- mobile-number entry is required;
- `AuthLandingPage` must remain the signup/provider gateway;
- the legal disclaimer must remain owned by AuthLanding;
- Username should remain a pre-auth field inside the canonical Signup form.

## 2. Auth surface consolidation — remove standalone AuthLanding

The standalone AuthLanding screen is now considered redundant for the target product flow and should be retired after its routes, tests, callbacks, and legal/provider responsibilities are migrated safely.

### Canonical screen ownership

```text
Login
= existing-account authentication only

Signup
= all fresh-account creation options
= Email/password form
+ Google signup
+ future Truecaller signup
+ legal disclaimer

Username
= authenticated fresh-account username bootstrap

Onboarding
= product/profile data collection
```

Target navigation from Login:

```text
Login
→ "Don't have an account? Sign Up"
→ Signup
   - Email/password creation
   - Continue with Google
   - future Continue with Truecaller
   - legal disclaimer
→ auth success
→ Username
→ provider-aware optional Mobile
→ onboarding continuation/start
```

There must be no intermediate AuthLanding screen in this path.

### Onboarding auth checkpoint uses the same Signup screen

When a signed-out onboarding flow reaches its auth checkpoint:

```text
App Mode / Profile already collected locally
→ Signup
   - same Email UI
   - same Google button
   - same future Truecaller button
   - same legal disclaimer
→ auth success
→ Username
→ provider-aware optional Mobile
→ resume the exact durable post-auth onboarding step
```

The Signup screen must not hide/show social buttons based on whether it was opened from Login or from the onboarding checkpoint. Entry context affects **post-auth continuation**, not the visible provider set.

### Current Signup username field must be migrated out

Current `EmailSignupPage` includes `TioUsernameInputField` before Email/Password. That field belongs to the old pre-auth form model and must not remain in the canonical unified Signup screen.

Target:

```text
Signup
→ Email/password OR Google OR future Truecaller
→ authentication succeeds
→ Username screen opens
→ username is checked/saved for authenticated user
```

Frozen rules:

- Remove/migrate the current pre-auth username field from Signup.
- Do not require Google users to fill a username before opening the Google account chooser.
- Do not keep Username only for Email while Google uses a separate rule.
- Email and Google fresh signup converge on the same post-auth Username screen.
- Do not stage username locally before auth merely to preserve the old Signup layout; authenticated ownership is cleaner and is the target contract.
- Current Email Signup behavior that passes the username input through the email signup call as `name` must be audited and removed/re-mapped; `name` and `username` are separate concepts and must not be conflated.

### Returning/existing identity selected from Signup

Provider signup actions may discover that the selected identity already owns an existing Tio account.

```text
Signup provider action
→ existing completed Tio account resolved
→ authenticated bootstrap remains authoritative
→ Home
→ do not force Username/Mobile/onboarding restart
```

For an existing incomplete account, durable account/onboarding state remains authoritative.

### Legal disclaimer ownership

`TioTermsDisclaimer` should move to the canonical Signup screen and remain visible with the account-creation methods there.

Target ownership:

```text
Welcome
→ no Terms/Privacy disclaimer

Login
→ no signup legal disclaimer

Signup
→ TioTermsDisclaimer present

AuthLanding
→ retired/removed after migration
```

Do not duplicate the disclaimer across Login and Signup merely because both contain provider buttons.

### Migration guardrails

- Do not delete AuthLanding first and repair routing later; migrate callers/tests/routes deliberately, then remove dead ownership.
- Preserve current Login existing-account-only Google admission behavior.
- Signup Google intent remains account-creation-or-existing-account aware.
- Preserve onboarding local-draft handoff semantics from issue #13.
- No conditional social-button rendering based on entry source.
- Do not introduce a second provider-selection screen after this consolidation.

## 3. Fresh-signup post-auth order

For a genuinely newly created Tio account, authentication establishes ownership before account-specific profile fields are written to Supabase.

```text
Fresh signup authentication succeeds
→ Username screen
→ Mobile screen when provider-aware rules require it
→ remaining onboarding flow
```

If Signup was entered from Login with no pre-auth onboarding draft:

```text
Login
→ Signup
→ fresh account created
→ Username
→ Mobile when applicable
→ onboarding begins at its normal first product step
```

If Signup was entered from an onboarding auth checkpoint:

```text
pre-auth App Mode/Profile draft exists
→ Signup
→ fresh account created
→ Username
→ Mobile when applicable
→ existing local resume checkpoint wins
→ App Mode/Profile are not repeated
```

Returning existing accounts must not be forced through this fresh-signup bootstrap sequence just because they authenticate again.

## 4. Username screen contract

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
- Username is **required** for fresh/incomplete authenticated accounts whose canonical username is missing; there is no Skip action at this checkpoint.
- Completed legacy accounts are exempt from this retroactive gate even when their historical username is null.
- The screen is fresh-account bootstrap, not a normal returning-login screen.
- Persist to the canonical `public.users.username` field.
- Do not silently overwrite an existing username on later login.
- Existing incomplete accounts resume according to durable account/onboarding state; Username is required only when that account still lacks its canonical username.
- `public.users.username` remains nullable for legacy compatibility; do not add a global `NOT NULL` constraint.
- A missing username starts with an empty input and a generic placeholder only. Do not prefill a newly created handle from identity/profile data.

### 4.1 Username normalization, availability, filtering, and suggestions

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

- Canonical comparison is case-insensitive. A mixed-case form and its lowercase form must be treated as the same handle.
- Normalize candidate input consistently before checking/saving, including trim + lowercase canonical comparison.
- Initial public-handle character policy is ASCII letters, numbers, underscore, and dot unless a later reviewed policy expands it.
- Canonical length is **3–30 characters**, enforced in UI, server policy, and the database persistence boundary.
- Reserved and misleading handles must be rejected before normal availability succeeds. The initial reviewed server policy protects Tio/system/support/admin/security/billing/official-style exact handles, system-role namespaces, and clear Tio-role combinations.
- Comprehensive profanity/abuse filtering is a separate reviewed product-policy item; do not invent an unreviewed dictionary in this engineering slice.
- Do not expose broad `public.users` lookup access merely to implement username availability. Current users-table RLS is owner-scoped, so availability uses a narrowly scoped backend/RPC contract that returns availability/suggestions only.
- Availability UI is advisory; the database unique constraint remains the final concurrency authority when the user saves.
- If a handle becomes taken between availability check and final save, return a controlled conflict state and refresh alternatives instead of failing generically.

### 4.2 Username privacy boundary

The only allowed seed for new username alternatives is the username candidate the user explicitly typed in the Username field.

The Username UI and suggestion engine MUST NOT derive, prefill, hint, rank, or suggest handles from:

- Profile `Name` or name parts;
- Google/provider display name;
- email or email local-part;
- phone/mobile number;
- DOB, birth year, age, or the current year;
- avatar/profile metadata;
- any other personal profile/account attribute.

A persisted canonical username may populate the field normally. When no canonical username exists, the field remains blank and the placeholder remains generic, for example `e.g. your.name`.

Suggestion policy:

```text
@yourhandle taken
→ candidate generator uses only the explicitly typed `yourhandle` candidate as its seed
→ generator builds a bounded pool of neutral variations
→ backend filters every candidate through the same policy + availability rules
→ UI receives only verified-available alternatives
```

Illustrative shapes may include:

```text
@yourhandle27
@yourhandle_314
@yourhandle.82
@yourhandle4921
@yourhandle_56
```

These are documentation examples only, not runtime defaults or a hard-coded list.

Rules:

- No fixed product/trend suffix such as `_fit` or `_tio` is mandatory or preferred.
- **Current year has no special role in username suggestions and must not be automatically appended or preferred.**
- A numeric suffix is a neutral variation only; it must not encode or imply a year unless the user explicitly typed/chose that value.
- Suggestions must be dynamic rather than a permanent hard-coded list or one mandatory suffix format.
- The generator may vary separators and neutral suffix lengths/shapes, but candidate content must remain derived from the explicit typed candidate plus non-personal deterministic/random variation.
- No private profile or identity lookup is needed to generate alternatives.
- Reserved/system candidates must not produce lookalike alternatives inside the same protected namespace. A neutral fallback may be used, but its variation seed must still come only from the explicit typed candidate and never from profile/account data.
- Return 3–5 alternatives when the bounded server search can find them; every returned alternative must have passed the authoritative policy and availability check.

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

Backend contract:

```text
check_username_availability(candidate)
→ normalized candidate
→ isAvailable
→ safe reason category
→ verified available suggestions

claim_username(candidate)
→ canonical policy check
→ owner-only atomic claim
→ controlled taken/profile-missing result
```

The RPCs must not reveal the identity or profile of the account that already owns a taken username.

### Step 2B implementation note

Production migrations `20260817000002_harden_username_policy.sql` and `20260817000003_refine_username_impersonation_policy.sql` implement the server policy, narrow authenticated RPCs, canonical claim path, and database policy constraint. Forward-only migration `20260826072000_refine_username_suggestions.sql` replaces the old fixed three-item/single-template suggestion helper with a bounded multi-shape generator seeded only by the explicit typed candidate. The final `lower(username)` unique index remains the concurrency authority.

The public username RPCs intentionally use `SECURITY DEFINER` with a fixed empty `search_path` because owner-scoped RLS cannot otherwise answer cross-account collision questions. `PUBLIC`/`anon` execute is revoked; `authenticated` execute is granted only to the narrow RPC surface. Private helpers are not executable by API roles.

## 5. Frozen Mobile-step contract

### Google fresh signup

```text
Signup → Google
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
Signup → Email/password create account
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
Signup → Truecaller
→ Truecaller auth succeeds
→ Username screen for a genuinely fresh account
→ mobile supplied by provider
→ skip Mobile onboarding screen
→ provider may also return email
→ do not treat that email as verified unless provider/backend evidence proves it
→ continue onboarding
```

Provider-supplied mobile should only be marked verified once Truecaller verification semantics are explicitly validated.

## 6. Returning-user behavior

```text
Existing completed Tio account login
→ restore account/session
→ do not inject Username
→ do not inject Mobile onboarding
→ Home
```

For an existing incomplete account, resume the durable saved onboarding state. Do not restart provider-specific setup just because the current login provider is Google/email.

## 7. Google profile photo — first signup only

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

## 8. Persistence ownership

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

## 9. Required implementation tests

### Auth-surface consolidation

- [ ] Login `Sign Up` routes directly to the canonical Signup screen, never through AuthLanding;
- [ ] onboarding auth checkpoint routes directly to the same canonical Signup screen;
- [ ] Signup shows Email creation + Google + future Truecaller surface consistently regardless of entry source;
- [ ] canonical Signup no longer contains the pre-auth Username input;
- [ ] Email and Google fresh signup both route to the same post-auth Username screen;
- [ ] Google account chooser/auth is not blocked on a pre-auth username value;
- [ ] email signup does not conflate username with `name` in its auth creation call;
- [ ] Signup owns `TioTermsDisclaimer`;
- [ ] Login does not gain the signup legal disclaimer;
- [ ] AuthLanding routes/callbacks/tests are migrated before the screen is removed;
- [ ] no second provider-selection screen remains after migration;
- [ ] existing completed account selected through a Signup provider action routes according to completed bootstrap state rather than fresh onboarding;
- [ ] signed-out onboarding draft resumes correctly after Signup authentication;

### Username

- [x] fresh/incomplete authenticated account missing username routes to Username before later onboarding;
- [x] missing username starts blank with a generic placeholder and no identity-derived prefill;
- [x] persisted canonical username still hydrates normally;
- [x] returning completed login does not show Username retroactively;
- [x] existing username is not overwritten by later login bootstrap;
- [x] username normalization is case-insensitive and matches backend uniqueness semantics;
- [x] invalid/reserved/system-impersonation usernames are rejected by the reviewed initial policy;
- [x] availability is checked through a narrow backend contract rather than broad users-table reads;
- [x] unavailable username returns only server-verified available suggestions;
- [x] suggestion generation is seeded only by the candidate explicitly typed in the Username field;
- [x] Profile `Name`, provider display name, email, phone, DOB/year, and other private attributes are not suggestion seeds;
- [x] suggestions are dynamic and do not require a fixed product suffix, current year, or a single mandatory suffix format;
- [x] tapping a suggestion re-checks/validates it before showing Available;
- [x] stale async availability responses cannot overwrite the current input state;
- [x] final save handles a unique-race conflict with controlled UX and an authoritative suggestion refresh;
- [ ] comprehensive profanity/abuse policy reviewed and implemented, if product requires one beyond the initial reserved/system policy.

### Mobile / provider behavior

- [ ] fresh Google signup routes to Mobile after Username;
- [ ] fresh Email signup routes to Mobile after Username;
- [ ] blank Mobile screen can continue with `Next`;
- [ ] blank mobile persists no fake/default value;
- [ ] entered mobile persists while `mobile_verified_at` remains null when OTP is not completed;
- [ ] returning completed Google/email login does not show Mobile onboarding;
- [ ] incomplete returning account resumes its durable saved step;
- [ ] future mobile-auth path skips Mobile screen;
- [ ] future Truecaller path skips Mobile screen and does not mark provider email verified without evidence;

### Google photo

- [ ] fresh Google signup imports provider photo once when Tio avatar is empty;
- [ ] later Google login does not overwrite a custom/user-owned avatar;
- [ ] missing Google photo does not block signup.

## 10. Non-goals

- Do not implement Truecaller in this slice.
- Do not implement/send OTP in this slice unless separately approved.
- Do not require a mobile number to continue onboarding.
- Do not mark typed mobile verified.
- Do not overwrite existing/custom profile photos from Google on later logins.
- Do not add pre-auth Supabase writes.
- Do not make `public.users.username` globally `NOT NULL` or force completed legacy accounts through the Username checkpoint.
- Do not expose broad user-directory reads for availability checking.
- Do not treat locally generated username suggestions as authoritative availability results.
- Do not seed username hints, prefills, or suggestions from Profile `Name`, provider identity, email, phone, DOB/year, avatar, or other private profile/account data.
- Do not bias username suggestions toward the current year or any fixed product/trend suffix.
- Do not keep AuthLanding as an extra hop after canonical Signup takes over its responsibilities.
- Do not add entry-source-specific social-button visibility logic to Signup.
- Do not keep Username as a pre-auth Signup field after the post-auth Username screen becomes canonical.
