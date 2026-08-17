# Provider-aware Mobile Step & Google Photo Bootstrap

**Status:** Planned — product contract frozen, implementation pending
**Parent tracking:** GitHub issue #10
**Source branch:** `codex/onboarding-mode-migration`
**Primary owners:** `apps/features/auth` + `apps/features/onboarding` + `apps/features/profile` + `apps/app`

## 1. Purpose

Define the post-auth onboarding behavior for Google/email signup, future mobile/Truecaller auth, optional mobile collection, and first-signup Google profile-photo bootstrap.

This focused task is the source of truth for these rules and **supersedes any earlier wording that said mobile-number entry is required**.

## 2. Frozen Mobile-step contract

### Google fresh signup

```text
Get Started / explicit signup
→ Google auth succeeds
→ Mobile screen
→ user MAY enter a mobile number OR leave it blank
→ OTP verification is optional/deferred for the current release
→ Next is allowed whether mobile is present or absent
→ continue onboarding
```

Rules:

- The Mobile screen is shown for fresh Google signup.
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
→ mobile supplied by provider
→ skip Mobile onboarding screen
→ provider may also return email
→ do not treat that email as verified unless provider/backend evidence proves it
→ continue onboarding
```

Provider-supplied mobile should only be marked verified once Truecaller verification semantics are explicitly validated.

## 3. Returning-user behavior

```text
Existing completed Tio account login
→ restore account/session
→ do not inject Mobile onboarding
→ Home
```

For an existing incomplete account, resume the durable saved onboarding state. Do not restart provider-specific setup just because the current login provider is Google/email.

## 4. Google profile photo — first signup only

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

## 5. Persistence ownership

```text
Before auth
→ onboarding draft remains device-local only
→ no Supabase user-owned writes

After auth
→ optional entered mobile can be persisted for that authenticated user
→ Google photo bootstrap can persist for fresh Google signup only
```

Mobile may remain null forever if the user chooses not to provide it.

## 6. Required implementation tests

- [ ] fresh Google signup routes to Mobile after auth;
- [ ] fresh Email signup routes to Mobile after auth;
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

## 7. Non-goals

- Do not implement Truecaller in this slice.
- Do not implement/send OTP in this slice unless separately approved.
- Do not require a mobile number to continue onboarding.
- Do not mark typed mobile verified.
- Do not overwrite existing/custom profile photos from Google on later logins.
- Do not add pre-auth Supabase writes.
