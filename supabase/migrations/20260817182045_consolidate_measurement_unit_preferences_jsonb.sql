alter table public.users
  add column unit_preferences jsonb not null
  default '{"weight":"kg","height":"cm","distance":"km","volume":"ml"}'::jsonb;

update public.users
set unit_preferences = jsonb_build_object(
  'weight', weight_unit,
  'height', height_unit,
  'distance', distance_unit,
  'volume', volume_unit
);

alter table public.users
  add constraint users_unit_preferences_check
  check (
    coalesce(
      jsonb_typeof(unit_preferences) = 'object'
      and unit_preferences ?& array['weight', 'height', 'distance', 'volume']
      and (unit_preferences ->> 'weight') in ('kg', 'lb')
      and (unit_preferences ->> 'height') in ('cm', 'ft_in')
      and (unit_preferences ->> 'distance') in ('km', 'mi')
      and (unit_preferences ->> 'volume') in ('ml', 'fl_oz'),
      false
    )
  );

comment on column public.users.unit_preferences is
  'Measurement display/input preferences. Required keys: weight, height, distance, volume. Canonical physical values remain metric.';

alter table public.users
  drop constraint if exists users_weight_unit_check,
  drop constraint if exists users_height_unit_check,
  drop constraint if exists users_distance_unit_check,
  drop constraint if exists users_volume_unit_check,
  drop column weight_unit,
  drop column height_unit,
  drop column distance_unit,
  drop column volume_unit;
