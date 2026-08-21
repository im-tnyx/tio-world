# App Mode Foundation

**Status:** In progress — local foundation validated; durable account preference slice approved  
**Primary owners:** `apps/shared`, `apps/app`, onboarding, Settings, `user_app_preferences`

## Outcome

Give each user one selected phone mode (`workout`, `nutrition`, or `hybrid`) that drives guided navigation and survives restart, fresh install, cleared local storage, and cross-device login.

## Historical local-first foundation

The first App Mode slice intentionally persisted confirmed mode device-locally through `SharedPreferencesAppModePreference` while account/profile persistence architecture was still unresolved.

That decision was valid for the first slice but is **not the final durability contract**.

Current runtime still constructs:

```text
AppModeController
→ SharedPreferencesAppModePreference
→ local key app_mode
```

`onboarding_drafts.payload.selected_mode` is draft/resume state only and must not become final App Mode authority.

## Approved final persistence decision

Canonical owner:

```text
user_app_preferences
├─ user_id → public.users(id)
├─ app_mode
└─ active_tabs
```

`users` remains the account/domain root. App Mode/navigation preferences do not belong in `users` or `user_profiles`.

SharedPreferences becomes cache/pre-auth staging only after durable cutover.

See:

- `.ai/tasks/account-profile-app-preferences-canonical-split.md`;
- Issue #11;
- Issue #44.

## Canonical semantics

### `app_mode`

Semantic product experience:

```text
workout
nutrition
hybrid
```

It derives the default guided destinations.

### `active_tabs`

Ordered stable destination IDs representing the user's effective navigation preference.

Initial defaults:

```text
workout   → [home, workout, progress]
nutrition → [home, nutrition, progress]
hybrid    → [home, workout, nutrition, progress]
```

`active_tabs` is distinct from `app_mode`: mode is semantic intent; tabs are effective navigation configuration.

Custom 3–6 tab editing remains a separate product slice and must not be pulled into the durability migration.

## Existing validated foundation

- [x] `apps/shared` owns `AppMode`, `AppDestination`, guided destination mappings, and the pure-Dart preference boundary;
- [x] app shell derives visible guided tabs from mode;
- [x] onboarding selects mode;
- [x] Settings can change mode;
- [x] local mode survives device-local app restart;
- [x] routing safely handles missing/invalid local mode without inventing a semantic mode;
- [x] focused controller/route/navigation tests exist.

## Current verified durability gap

Live `tio-world` Supabase audit confirms:

```text
public app_mode column     absent
public active_tabs column  absent
```

Therefore a completed account can restore durable onboarding completion while losing App Mode after local data loss or on another device.

Issue #11 tracks this exact gap.

## Durable App Mode slice — execute after schema P1

Dependency:

```text
P1 create user_app_preferences
        ↓
P2 App Mode / navigation repository cutover
```

P2 requirements:

- [ ] backend-neutral App Preferences repository/domain contract;
- [ ] Supabase adapter for `user_app_preferences`;
- [ ] onboarding completion writes `app_mode` + derived `active_tabs` before publishing completion;
- [ ] Settings App Mode save writes the same canonical row;
- [ ] authenticated bootstrap restores remote preferences before final shell configuration;
- [ ] valid remote canonical state wins over stale local cache;
- [ ] SharedPreferences remains cache/fast-path and pre-auth staging only;
- [ ] completed legacy user with no canonical mode uses safe compatibility behavior; never silently invent Hybrid;
- [ ] reject unsupported mode/tab IDs at domain boundary;
- [ ] preserve active tab order;
- [ ] fresh-install / cleared-cache / second-device tests;
- [ ] full Flutter/Dart validation.

## Out of scope for P2

- custom 3–6 tab editor implementation;
- enabling reserved Meal Plan/Library/Social/Tio AI destinations;
- watch synchronization policy;
- UI redesign;
- Profile/Body migration except dependencies needed to access `user_app_preferences`.

## Source-of-truth precedence after cutover

```text
authenticated account
→ read user_app_preferences
→ valid active_tabs: restore effective navigation
→ app_mode present but active_tabs absent: derive defaults
→ both absent for completed legacy account: compatibility nav / explicit recovery; no invented mode
→ update local cache after canonical read
```

Before authentication, pending App Mode may remain device-local staging and must not mutate another signed-in account's canonical preference.

## Guardrails

- `user_app_preferences`, not `users`, owns final App Mode/navigation preferences;
- `user_profiles` owns common Profile only;
- mode visibility never deletes hidden Workout/Nutrition/Body data;
- no permanent local/remote competing authorities;
- no silent mode inference;
- future backend consumes the same backend-neutral preference contract/table.

## Final status

`PARTIAL` — local mode/navigation foundation is implemented. Durable account-level persistence is approved and queued as P2 after the additive P1 schema foundation.
