alter table public.users
  add column weight_unit text not null default 'kg',
  add column height_unit text not null default 'cm',
  add column distance_unit text not null default 'km',
  add column volume_unit text not null default 'ml';

alter table public.users
  add constraint users_weight_unit_check
    check (weight_unit in ('kg', 'lb')),
  add constraint users_height_unit_check
    check (height_unit in ('cm', 'ft_in')),
  add constraint users_distance_unit_check
    check (distance_unit in ('km', 'mi')),
  add constraint users_volume_unit_check
    check (volume_unit in ('ml', 'fl_oz'));

comment on column public.users.weight_unit is
  'Preferred weight display/input unit; canonical stored weights remain kilograms.';
comment on column public.users.height_unit is
  'Preferred height display/input unit; canonical stored height remains centimeters.';
comment on column public.users.distance_unit is
  'Preferred distance display/input unit; canonical domain distances remain metric.';
comment on column public.users.volume_unit is
  'Preferred volume display/input unit; canonical stored volume remains millilitres.';
