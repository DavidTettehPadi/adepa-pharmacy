create extension if not exists pgcrypto;

create table if not exists public.nhis_medicine_import (
  code text primary key,
  generic_name_dosage_form_strength text not null,
  unit_of_pricing text not null,
  price_ghc numeric(12, 2) not null check (price_ghc >= 0),
  level_of_prescribing text,
  source_page text
);

alter table public.nhis_medicine_import enable row level security;
revoke all on public.nhis_medicine_import from anon, authenticated;

create or replace function public.category_for_medicine(medicine_name text)
returns text
language sql
immutable
as $$
  select case
    when medicine_name ~* '\m(tablet|capsule|caplet)\M' then 'Oral solid'
    when medicine_name ~* '\m(injection|injectable)\M' then 'Injection'
    when medicine_name ~* '\m(syrup|suspension|oral solution|elixir)\M' then 'Oral liquid'
    when medicine_name ~* '\m(cream|ointment|gel|lotion)\M' then 'Topical'
    when medicine_name ~* '\m(drops|eye drop|ear drop)\M' then 'Drops'
    when medicine_name ~* '\m(inhaler|inhalation)\M' then 'Inhalation'
    when medicine_name ~* '\m(powder|granules)\M' then 'Powder'
    when medicine_name ~* '\msuppositor(y|ies)\M' then 'Suppository'
    else 'Other dosage form'
  end;
$$;

create or replace function public.seed_nhis_medicines()
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
  imported_count integer;
begin
  insert into public.medicines (
    id, name, price, pricing_unit, category, supplier, stock, restock_threshold, is_active
  )
  select
    imported.code,
    imported.generic_name_dosage_form_strength,
    imported.price_ghc,
    imported.unit_of_pricing,
    public.category_for_medicine(imported.generic_name_dosage_form_strength),
    'NHIS',
    case
      when public.category_for_medicine(imported.generic_name_dosage_form_strength) = 'Other dosage form' then 500
      else 1000
    end,
    100,
    true
  from public.nhis_medicine_import imported
  on conflict (id) do update set
    name = excluded.name,
    price = excluded.price,
    pricing_unit = excluded.pricing_unit,
    category = excluded.category,
    supplier = excluded.supplier,
    is_active = true,
    updated_at = now();

  get diagnostics imported_count = row_count;
  return imported_count;
end;
$$;

revoke all on function public.seed_nhis_medicines() from public, anon, authenticated;

create table if not exists public.medicines (
  id text primary key,
  name text not null,
  price numeric(12, 2) not null check (price >= 0),
  pricing_unit text not null,
  category text not null,
  supplier text not null default 'NHIS',
  stock integer not null default 0 check (stock >= 0),
  restock_threshold integer not null default 100 check (restock_threshold >= 0),
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_orders (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('ORD-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10))),
  customer_name text not null,
  phone text not null,
  delivery_address text not null,
  payment_method text not null default 'cash' check (payment_method in ('cash', 'nhis')),
  nhis_number text,
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'preparing', 'out_for_delivery', 'delivered', 'cancelled')),
  total numeric(12, 2) not null default 0 check (total >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (payment_method <> 'nhis' or nullif(trim(nhis_number), '') is not null)
);

create table if not exists public.customer_order_items (
  id bigint generated always as identity primary key,
  order_id uuid not null references public.customer_orders(id) on delete cascade,
  medicine_id text not null references public.medicines(id),
  medicine_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  pricing_unit text not null,
  line_total numeric(12, 2) generated always as (quantity * unit_price) stored
);

create index if not exists customer_orders_created_at_idx on public.customer_orders (created_at desc);
create index if not exists customer_orders_status_idx on public.customer_orders (status);
create index if not exists customer_order_items_order_id_idx on public.customer_order_items (order_id);

alter table public.medicines enable row level security;
alter table public.customer_orders enable row level security;
alter table public.customer_order_items enable row level security;

grant select on public.medicines to anon, authenticated;
grant insert, update, delete on public.medicines to authenticated;
grant select, update on public.customer_orders to authenticated;
grant select on public.customer_order_items to authenticated;

create policy "Public can view medicines in stock"
on public.medicines for select
to anon, authenticated
using (is_active and stock > 0);

create policy "Pharmacy staff can manage all medicines"
on public.medicines for all
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant'))
with check ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant'));

create policy "Pharmacy staff can view customer orders"
on public.customer_orders for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant'));

create policy "Pharmacy staff can update customer orders"
on public.customer_orders for update
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant'))
with check ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant'));

create policy "Pharmacy staff can view order items"
on public.customer_order_items for select
to authenticated
using (
  exists (
    select 1
    from public.customer_orders customer_order
    where customer_order.id = customer_order_items.order_id
      and (auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') in ('admin', 'pharmacist', 'assistant')
  )
);

create or replace function public.restore_cancelled_order_stock()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if old.status = 'cancelled' and new.status <> 'cancelled' then
    raise exception 'Cancelled orders cannot be reopened.' using errcode = '22023';
  end if;

  if old.status <> 'cancelled' and new.status = 'cancelled' then
    if old.status not in ('pending', 'confirmed', 'preparing') then
      raise exception 'Only orders not yet out for delivery can be cancelled.' using errcode = '22023';
    end if;
    update public.medicines medicine
    set stock = medicine.stock + order_item.quantity,
        updated_at = now()
    from public.customer_order_items order_item
    where order_item.order_id = new.id
      and medicine.id = order_item.medicine_id;
  end if;
  return new;
end;
$$;

drop trigger if exists customer_order_cancel_restores_stock on public.customer_orders;
create trigger customer_order_cancel_restores_stock
after update of status on public.customer_orders
for each row
execute function public.restore_cancelled_order_stock();

drop function if exists public.place_customer_order(text, text, text, jsonb, text, text);

create function public.place_customer_order(
  p_customer_name text,
  p_phone text,
  p_delivery_address text,
  p_items jsonb,
  p_payment_method text default 'cash',
  p_nhis_number text default null
)
returns table (order_reference text, order_total numeric, order_items jsonb)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  new_order_id uuid;
  new_order_reference text;
  order_total_amount numeric(12, 2) := 0;
  receipt_items jsonb;
  requested_item record;
  selected_medicine public.medicines%rowtype;
begin
  if nullif(trim(p_customer_name), '') is null then
    raise exception 'Customer name is required.' using errcode = '22023';
  end if;
  if nullif(trim(p_phone), '') is null then
    raise exception 'Contact number is required.' using errcode = '22023';
  end if;
  if nullif(trim(p_delivery_address), '') is null then
    raise exception 'Delivery address is required.' using errcode = '22023';
  end if;
  if p_payment_method not in ('cash', 'nhis') then
    raise exception 'Unsupported payment method.' using errcode = '22023';
  end if;
  if p_payment_method = 'nhis' and nullif(trim(p_nhis_number), '') is null then
    raise exception 'NHIS number is required for NHIS claims.' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' then
    raise exception 'Add at least one medicine to the order.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one medicine to the order.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) > 50 then
    raise exception 'Orders may contain no more than 50 medicine lines.' using errcode = '22023';
  end if;

  if exists (
    select 1
    from jsonb_to_recordset(p_items) as requested(id text, quantity integer)
    where requested.id is null or requested.quantity is null or requested.quantity <= 0
  ) then
    raise exception 'Order quantities must be positive whole numbers.' using errcode = '22023';
  end if;

  if exists (
    select requested.id
    from jsonb_to_recordset(p_items) as requested(id text, quantity integer)
    group by requested.id
    having count(*) > 1
  ) then
    raise exception 'Each medicine may appear only once in an order.' using errcode = '22023';
  end if;

  perform medicine.id
  from public.medicines medicine
  join jsonb_to_recordset(p_items) as requested(id text, quantity integer) on requested.id = medicine.id
  order by medicine.id
  for update of medicine;

  insert into public.customer_orders (
    customer_name,
    phone,
    delivery_address,
    payment_method,
    nhis_number
  ) values (
    trim(p_customer_name),
    trim(p_phone),
    trim(p_delivery_address),
    p_payment_method,
    nullif(trim(p_nhis_number), '')
  ) returning id, reference into new_order_id, new_order_reference;

  for requested_item in
    select requested.id, requested.quantity
    from jsonb_to_recordset(p_items) as requested(id text, quantity integer)
    order by requested.id
  loop
    select * into selected_medicine
    from public.medicines medicine
    where medicine.id = requested_item.id
      and medicine.is_active
      and medicine.stock >= requested_item.quantity
    for update;

    if not found then
      raise exception 'Medicine % is unavailable or has insufficient stock.', requested_item.id using errcode = 'P0001';
    end if;

    update public.medicines
    set stock = stock - requested_item.quantity,
        updated_at = now()
    where id = selected_medicine.id;

    insert into public.customer_order_items (
      order_id,
      medicine_id,
      medicine_name,
      quantity,
      unit_price,
      pricing_unit
    ) values (
      new_order_id,
      selected_medicine.id,
      selected_medicine.name,
      requested_item.quantity,
      selected_medicine.price,
      selected_medicine.pricing_unit
    );

    order_total_amount := order_total_amount + selected_medicine.price * requested_item.quantity;
  end loop;

  update public.customer_orders
  set total = order_total_amount,
      updated_at = now()
  where id = new_order_id;

  select jsonb_agg(jsonb_build_object(
    'medicine_name', item.medicine_name,
    'quantity', item.quantity,
    'unit_price', item.unit_price,
    'pricing_unit', item.pricing_unit,
    'line_total', item.line_total
  ) order by item.id)
  into receipt_items
  from public.customer_order_items item
  where item.order_id = new_order_id;

  return query select new_order_reference, order_total_amount, receipt_items;
end;
$$;

revoke all on function public.place_customer_order(text, text, text, jsonb, text, text) from public;
grant execute on function public.place_customer_order(text, text, text, jsonb, text, text) to anon, authenticated;
