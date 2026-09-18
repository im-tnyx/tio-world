alter table public.user_profiles
  add column country_code text;

alter table public.user_profiles
  add constraint user_profiles_country_code_check
    check (
      country_code is null
      or country_code ~ '^[A-Z]{2}$'
    );

comment on column public.user_profiles.country_code is
  'Canonical user-selected/saved ISO 3166-1 alpha-2 country code. NULL means unknown/unset; do not infer from phone, timezone, language, IP, or device location.';
