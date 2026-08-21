do $$
begin
  if exists (
    select 1 from public.users
    where date_of_birth is not null
      and dob is not null
      and date_of_birth <> dob
  ) then
    raise exception 'P1 blocked: users.date_of_birth and users.dob conflict';
  end if;

  if exists (
    select 1 from public.users
    where height_cm is not null and height_cm <= 0
  ) then
    raise exception 'P1 blocked: invalid non-positive users.height_cm';
  end if;

  if exists (
    select 1 from public.users
    where gender is not null and gender not in ('male','female','other')
  ) then
    raise exception 'P1 blocked: unsupported users.gender';
  end if;

  if exists (
    select 1 from public.users
    where activity_level is not null
      and activity_level not in ('sedentary','light','active','very_active','dynamic')
  ) then
    raise exception 'P1 blocked: unsupported users.activity_level';
  end if;

  if exists (
    select 1 from public.users
    where not (health_conditions <@ array['none','diabetes','hypertension','low_blood_pressure','other']::text[])
       or ('none' = any(health_conditions) and cardinality(health_conditions) > 1)
  ) then
    raise exception 'P1 blocked: unsupported users.health_conditions';
  end if;
end
$$;

alter table public.users
  add column email_verified_at timestamptz;

comment on column public.users.email_verified_at is
  'Provider-neutral timestamp for the currently stored email after trusted verification evidence is reconciled. Client sessions cannot directly forge this value.';

create function public.protect_user_contact_verification()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.email_verified_at := null;
      new.mobile_verified_at := null;
      return new;
    end if;

    if new.email is distinct from old.email then
      new.email_verified_at := null;
    elsif new.email_verified_at is distinct from old.email_verified_at then
      new.email_verified_at := old.email_verified_at;
    end if;

    if new.mobile is distinct from old.mobile then
      new.mobile_verified_at := null;
    elsif new.mobile_verified_at is distinct from old.mobile_verified_at then
      new.mobile_verified_at := old.mobile_verified_at;
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_users_protect_contact_verification
before insert or update of email, email_verified_at, mobile, mobile_verified_at
on public.users
for each row execute function public.protect_user_contact_verification();

update public.users u
set email_verified_at = a.email_confirmed_at
from auth.users a
where a.id = u.id
  and u.email is not null
  and a.email is not null
  and lower(trim(u.email)) = lower(trim(a.email))
  and a.email_confirmed_at is not null
  and u.email_verified_at is null;

update public.users u
set mobile_verified_at = a.phone_confirmed_at
from auth.users a
where a.id = u.id
  and u.mobile is not null
  and a.phone is not null
  and regexp_replace(u.mobile, '[^0-9]', '', 'g') <> ''
  and regexp_replace(u.mobile, '[^0-9]', '', 'g') = regexp_replace(a.phone, '[^0-9]', '', 'g')
  and a.phone_confirmed_at is not null
  and u.mobile_verified_at is null;

create table public.user_profiles (
  user_id uuid primary key references public.users(id) on delete cascade,
  name text not null,
  gender text,
  date_of_birth date,
  height_cm numeric,
  activity_level text,
  health_conditions text[] not null default '{}'::text[],
  other_health_condition text,
  unit_preferences jsonb not null default '{"weight":"kg","height":"cm","distance":"km","volume":"ml"}'::jsonb,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_profiles_gender_check
    check (gender is null or gender in ('male','female','other')),
  constraint user_profiles_height_positive
    check (height_cm is null or height_cm > 0),
  constraint user_profiles_activity_level_check
    check (activity_level is null or activity_level in ('sedentary','light','active','very_active','dynamic')),
  constraint user_profiles_health_conditions_check
    check (
      health_conditions <@ array['none','diabetes','hypertension','low_blood_pressure','other']::text[]
      and array_position(health_conditions, null) is null
      and not ('none' = any(health_conditions) and cardinality(health_conditions) > 1)
    ),
  constraint user_profiles_unit_preferences_check
    check (
      coalesce(
        jsonb_typeof(unit_preferences) = 'object'
        and unit_preferences ?& array['weight','height','distance','volume']
        and (unit_preferences ->> 'weight') in ('kg','lb')
        and (unit_preferences ->> 'height') in ('cm','ft_in')
        and (unit_preferences ->> 'distance') in ('km','mi')
        and (unit_preferences ->> 'volume') in ('ml','fl_oz'),
        false
      )
    )
);

comment on table public.user_profiles is
  'Canonical 1:1 common personal/profile baseline. Account/contact, Body, Wellness, Nutrition and Workout data belong to separate owners.';

create trigger trg_user_profiles_updated_at
before update on public.user_profiles
for each row execute function public.set_row_updated_at();

alter table public.user_profiles enable row level security;

grant select, insert, update on table public.user_profiles to authenticated;
grant select, insert, update, delete on table public.user_profiles to service_role;

create policy user_profiles_select_own
on public.user_profiles for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_profiles_insert_own
on public.user_profiles for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_profiles_update_own
on public.user_profiles for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

insert into public.user_profiles (
  user_id,
  name,
  gender,
  date_of_birth,
  height_cm,
  activity_level,
  health_conditions,
  other_health_condition,
  unit_preferences,
  created_at,
  updated_at
)
select
  id,
  name,
  gender,
  coalesce(date_of_birth, dob),
  height_cm,
  activity_level,
  health_conditions,
  other_health_condition,
  unit_preferences,
  created_at,
  updated_at
from public.users;

create table public.user_app_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  app_mode text,
  active_tabs text[],
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint user_app_preferences_mode_check
    check (app_mode is null or app_mode in ('workout','nutrition','hybrid')),
  constraint user_app_preferences_active_tabs_check
    check (
      active_tabs is null
      or (
        coalesce(array_ndims(active_tabs), 1) = 1
        and array_position(active_tabs, null) is null
      )
    )
);

comment on table public.user_app_preferences is
  'Canonical 1:1 account-level app experience preferences. app_mode is semantic mode; active_tabs is the effective ordered stable destination-id list.';

create trigger trg_user_app_preferences_updated_at
before update on public.user_app_preferences
for each row execute function public.set_row_updated_at();

alter table public.user_app_preferences enable row level security;

grant select, insert, update on table public.user_app_preferences to authenticated;
grant select, insert, update, delete on table public.user_app_preferences to service_role;

create policy user_app_preferences_select_own
on public.user_app_preferences for select to authenticated
using ((select auth.uid()) = user_id);

create policy user_app_preferences_insert_own
on public.user_app_preferences for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy user_app_preferences_update_own
on public.user_app_preferences for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
