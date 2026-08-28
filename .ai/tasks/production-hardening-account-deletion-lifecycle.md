# Production Hardening — Account Deletion Lifecycle

## Status

**COMPLETE / FROZEN.**

Owner tracker: #5 P1 item 14.
Implementation PR: #50 (Draft/open/unmerged).

Fresh audit head:

```text
1e4702215dfbbedd14d83766ce09e611e378dd15
```

Accepted source/test checkpoint:

```text
8f91280634cfc3cf5002ee8c00b0df45df23f0fd
Flutter CI #1945 / run 32827016471 ✅
Android Native CI #357 / run 32827016528 ✅
```

This accepted head includes the completed item 14 implementation plus the later item 15 Splash-only hardening. Item 14's implementation boundary remains the commits and files documented below; the later Splash work does not change the deletion contract.

## Goal

Make Delete Account failure-safe and complete across Supabase Storage, Postgres/Auth ownership, local session cleanup, and navigation without false success or destructive test-data shortcuts.

## Historical audit findings

At audit time, live `public.delete_user_account()` was absent. The repository's historical `20260815000003_delete_user_account_rpc.sql` also attempted direct `DELETE FROM storage.objects`, which is not a safe Supabase Storage deletion lifecycle because physical objects must be removed through the Storage API.

The live FK graph already supported one authenticated Auth-root delete:
- `public.users.id -> auth.users.id ON DELETE CASCADE`;
- `user_devices`, `onboarding_drafts`, nutrition/workout profile rows reference `auth.users` with `ON DELETE CASCADE`;
- Body/Profile/App Preferences/Wellness/Nutrition Targets/Workout Targets reference `public.users` with `ON DELETE CASCADE`.

All current live identities/rows are user-owned testing data and were explicitly protected from destructive acceptance shortcuts.

## Final architecture

### A. Storage cleanup owner

`SupabaseAccountDeletionRepository` removes the authenticated user's owned objects through the Supabase Storage API before irreversible account deletion.

Current owned bucket in scope: `avatars`.

- list only the authenticated user's folder;
- remove returned object paths through Storage API;
- Storage cleanup failure stops the flow before the RPC;
- empty/missing owned folders are success;
- external/provider URLs are not treated as owned Storage paths.

### B. Database/Auth deletion owner

Forward-only live migrations:

```text
20260825074245 create_delete_user_account_rpc
20260825074318 restrict_delete_user_account_rpc_execute
```

`public.delete_user_account()` now:
- is `SECURITY DEFINER` with `search_path = ''`;
- requires the authenticated `auth.uid()` identity;
- deletes only `auth.users.id = auth.uid()`;
- relies on reviewed FK cascades for canonical child rows;
- contains no Storage SQL;
- is executable by `authenticated` and the owning `postgres` role, not `anon` or `service_role`.

### C. UI lifecycle

- system Back, top Close, Keep Account, and duplicate destructive interaction are blocked while deletion is in flight;
- backend failure remains on the destructive step with recoverable error feedback;
- `Account Deleted` is shown only after Storage cleanup + RPC success;
- the 5-second hold starts deterministically on raw pointer down and resets on pointer up/cancel.

### D. Local finalization/navigation

The destructive callback owns server deletion only. After confirmed overlay success:
- local Supabase session cleanup is best-effort;
- bootstrap is forced unauthenticated and user-scoped state is invalidated;
- navigation to Auth has one owner and happens exactly once;
- server deletion failure never signs out/navigates as fake success.

## Implementation evidence

- [x] Storage API cleanup added to `SupabaseAccountDeletionRepository`.
- [x] Repository regressions cover signed-out, empty folder, cleanup failure, RPC failure, and ordering.
- [x] Forward-only replacement RPC migrations added; historical applied/legacy migration was not edited.
- [x] Live RPC deployed and verified without deleting an existing identity.
- [x] Supabase security/performance advisors reviewed after DDL.
- [x] Delete overlay hardened for in-flight controls, Back handling, retry state, and duplicate submission.
- [x] Focused destructive-flow widget regressions added.
- [x] Post-delete sign-out/bootstrap/navigation moved behind confirmed success.
- [x] Raw pointer lifecycle makes the 5-second hold deterministic.
- [x] Exact-head Flutter/Dart + Android CI green.

## Live verification

Final read-only verification:

```text
auth.users                         4
public.users                       4
public.delete_user_account()       exists
SECURITY DEFINER                   true
search_path                        ''
EXECUTE                            authenticated, postgres
anon EXECUTE                       no
service_role EXECUTE               no
```

All four existing live test identities remained intact throughout acceptance.

The Supabase security advisor flags authenticated access to a `SECURITY DEFINER` function as a generic warning. For this RPC the authenticated call surface is intentional: the function itself binds deletion to `auth.uid()` and deletes only that same Auth UUID. The existing username SECURITY DEFINER warnings, leaked-password-protection warning, RLS init-plan notices, and unused-index notices remain separate #5/config hardening debt and were not expanded into this slice.

## Acceptance

- [x] Failed Storage cleanup never proceeds to Auth/DB deletion and never shows success.
- [x] Failed RPC never signs out/navigates/shows `Account Deleted`.
- [x] Successful server-deletion contract uses reviewed FK cascades and no Storage SQL.
- [x] In-flight deletion cannot be dismissed/backed out or submitted twice.
- [x] Failure remains recoverable in-place.
- [x] Confirmed success clears local auth/bootstrap state and navigates exactly once.
- [x] Existing live test identities remain untouched.
- [x] Live RPC exists with restricted grants and secure empty search path.
- [x] Exact-SHA CI green.

A destructive live-disposable identity was intentionally not created/deleted during acceptance because the current live identities are protected user testing data. Code, database contract, non-destructive live verification, and regression coverage are frozen; any future disposable-environment destructive smoke test must not reuse these identities.

## Guardrails

- No applied migration edits.
- No `CASCADE` DDL.
- No direct SQL deletes from `storage.objects`.
- No fake success.
- PR #50 remains Draft/open/unmerged unless separately authorized.
