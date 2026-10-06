create table if not exists public.pharmacy_sales (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('ADE-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id),
  payment_method text not null check (payment_method in ('cash', 'nhis')),
  client_name text,
  nhis_number text,
  total numeric(12, 2) not null default 0 check (total >= 0),
  check (payment_method <> 'nhis' or (nullif(trim(client_name), '') is not null and nullif(trim(nhis_number), '') is not null))
);

create table if not exists public.pharmacy_sale_items (
  id bigint generated always as identity primary key,
  sale_id uuid not null references public.pharmacy_sales(id) on delete cascade,
  medicine_id text not null references public.medicines(id),
  medicine_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  pricing_unit text not null,
  line_total numeric(12, 2) generated always as (quantity * unit_price) stored
);

create table if not exists public.pharmacy_sale_returns (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique default ('RET-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 12))),
  sale_id uuid not null references public.pharmacy_sales(id),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id),
  reason text not null,
  total numeric(12, 2) not null default 0 check (total >= 0)
);

create table if not exists public.pharmacy_sale_return_items (
  id bigint generated always as identity primary key,
  return_id uuid not null references public.pharmacy_sale_returns(id) on delete cascade,
  sale_item_id bigint not null references public.pharmacy_sale_items(id),
  medicine_id text not null references public.medicines(id),
  medicine_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  line_total numeric(12, 2) generated always as (quantity * unit_price) stored
);

create index if not exists pharmacy_sales_created_at_idx on public.pharmacy_sales (created_at desc);
create index if not exists pharmacy_sale_items_sale_id_idx on public.pharmacy_sale_items (sale_id);
create index if not exists pharmacy_sale_returns_sale_id_idx on public.pharmacy_sale_returns (sale_id);
create index if not exists pharmacy_sale_return_items_return_id_idx on public.pharmacy_sale_return_items (return_id);

alter table public.pharmacy_sales enable row level security;
alter table public.pharmacy_sale_items enable row level security;
alter table public.pharmacy_sale_returns enable row level security;
alter table public.pharmacy_sale_return_items enable row level security;

revoke all on public.pharmacy_sales, public.pharmacy_sale_items, public.pharmacy_sale_returns, public.pharmacy_sale_return_items from anon, authenticated;
grant select on public.pharmacy_sales, public.pharmacy_sale_items, public.pharmacy_sale_returns, public.pharmacy_sale_return_items to authenticated;

drop policy if exists "Only pharmacy owner can view sales" on public.pharmacy_sales;
create policy "Only pharmacy owner can view sales"
on public.pharmacy_sales for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') = 'admin');

drop policy if exists "Only pharmacy owner can view sale items" on public.pharmacy_sale_items;
create policy "Only pharmacy owner can view sale items"
on public.pharmacy_sale_items for select
to authenticated
using (
  exists (
    select 1 from public.pharmacy_sales sale
    where sale.id = pharmacy_sale_items.sale_id
      and (auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') = 'admin'
  )
);

drop policy if exists "Only pharmacy owner can view sale returns" on public.pharmacy_sale_returns;
create policy "Only pharmacy owner can view sale returns"
on public.pharmacy_sale_returns for select
to authenticated
using ((auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') = 'admin');

drop policy if exists "Only pharmacy owner can view sale return items" on public.pharmacy_sale_return_items;
create policy "Only pharmacy owner can view sale return items"
on public.pharmacy_sale_return_items for select
to authenticated
using (
  exists (
    select 1
    from public.pharmacy_sale_returns sale_return
    join public.pharmacy_sales sale on sale.id = sale_return.sale_id
    where sale_return.id = pharmacy_sale_return_items.return_id
      and (auth.jwt() -> 'app_metadata' ->> 'pharmacy_role') = 'admin'
  )
);

create or replace function public.record_pharmacy_sale(
  p_payment_method text,
  p_client_name text,
  p_nhis_number text,
  p_items jsonb
)
returns table (sale_reference text, sale_total numeric)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  role_name text := auth.jwt() -> 'app_metadata' ->> 'pharmacy_role';
  sale_id_value uuid;
  sale_reference_value text;
  total_value numeric(12, 2) := 0;
  requested_item record;
  selected_medicine public.medicines%rowtype;
begin
  if coalesce(role_name, '') not in ('admin', 'pharmacist', 'assistant') then
    raise exception 'Pharmacy staff access required.' using errcode = '42501';
  end if;
  if p_payment_method not in ('cash', 'nhis') then
    raise exception 'Unsupported payment method.' using errcode = '22023';
  end if;
  if p_payment_method = 'nhis' and (nullif(trim(p_client_name), '') is null or nullif(trim(p_nhis_number), '') is null) then
    raise exception 'Client name and NHIS number are required.' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Add at least one medicine to the sale.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) > 50 then
    raise exception 'A sale cannot contain more than 50 medicine lines.' using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_to_recordset(p_items) as requested(id text, quantity integer)
    where requested.id is null or requested.quantity is null or requested.quantity <= 0
  ) then
    raise exception 'Sale quantities must be positive whole numbers.' using errcode = '22023';
  end if;
  if exists (
    select requested.id
    from jsonb_to_recordset(p_items) as requested(id text, quantity integer)
    group by requested.id
    having count(*) > 1
  ) then
    raise exception 'Each medicine may appear only once in a sale.' using errcode = '22023';
  end if;

  perform medicine.id
  from public.medicines medicine
  join jsonb_to_recordset(p_items) as requested(id text, quantity integer) on requested.id = medicine.id
  order by medicine.id
  for update of medicine;

  insert into public.pharmacy_sales (created_by, payment_method, client_name, nhis_number)
  values (
    auth.uid(),
    p_payment_method,
    nullif(trim(p_client_name), ''),
    nullif(trim(p_nhis_number), '')
  ) returning id, reference into sale_id_value, sale_reference_value;

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

    insert into public.pharmacy_sale_items (sale_id, medicine_id, medicine_name, quantity, unit_price, pricing_unit)
    values (
      sale_id_value,
      selected_medicine.id,
      selected_medicine.name,
      requested_item.quantity,
      selected_medicine.price,
      selected_medicine.pricing_unit
    );
    total_value := total_value + selected_medicine.price * requested_item.quantity;
  end loop;

  update public.pharmacy_sales sale
  set total = total_value
  where sale.id = sale_id_value;

  return query select sale_reference_value, total_value;
end;
$$;

create or replace function public.record_pharmacy_sale_return(
  p_sale_reference text,
  p_reason text,
  p_items jsonb
)
returns table (return_reference text, return_total numeric)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  role_name text := auth.jwt() -> 'app_metadata' ->> 'pharmacy_role';
  selected_sale public.pharmacy_sales%rowtype;
  return_id_value uuid;
  return_reference_value text;
  total_value numeric(12, 2) := 0;
  requested_item record;
  selected_sale_item public.pharmacy_sale_items%rowtype;
  returned_so_far integer;
begin
  if coalesce(role_name, '') not in ('admin', 'pharmacist', 'assistant') then
    raise exception 'Pharmacy staff access required.' using errcode = '42501';
  end if;
  if nullif(trim(p_reason), '') is null then
    raise exception 'A return reason is required.' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Select at least one return quantity.' using errcode = '22023';
  end if;
  if exists (
    select 1
    from jsonb_to_recordset(p_items) as requested(sale_item_id bigint, quantity integer)
    where requested.sale_item_id is null or requested.quantity is null or requested.quantity <= 0
  ) then
    raise exception 'Return quantities must be positive whole numbers.' using errcode = '22023';
  end if;

  select * into selected_sale
  from public.pharmacy_sales sale
  where sale.reference = p_sale_reference
  for update;
  if not found then
    raise exception 'Receipt reference not found.' using errcode = 'P0002';
  end if;

  if exists (
    select requested.sale_item_id
    from jsonb_to_recordset(p_items) as requested(sale_item_id bigint, quantity integer)
    group by requested.sale_item_id
    having count(*) > 1
  ) then
    raise exception 'Each sold item may appear once in a return.' using errcode = '22023';
  end if;

  insert into public.pharmacy_sale_returns (sale_id, created_by, reason)
  values (selected_sale.id, auth.uid(), trim(p_reason))
  returning id, reference into return_id_value, return_reference_value;

  for requested_item in
    select requested.sale_item_id, requested.quantity
    from jsonb_to_recordset(p_items) as requested(sale_item_id bigint, quantity integer)
    order by requested.sale_item_id
  loop
    select * into selected_sale_item
    from public.pharmacy_sale_items item
    where item.id = requested_item.sale_item_id
      and item.sale_id = selected_sale.id
    for update;
    if not found then
      raise exception 'Return item does not belong to the supplied receipt.' using errcode = '22023';
    end if;

    select coalesce(sum(return_item.quantity), 0)::integer into returned_so_far
    from public.pharmacy_sale_return_items return_item
    join public.pharmacy_sale_returns sale_return on sale_return.id = return_item.return_id
    where sale_return.sale_id = selected_sale.id
      and return_item.sale_item_id = selected_sale_item.id;
    if returned_so_far + requested_item.quantity > selected_sale_item.quantity then
      raise exception 'Return quantity exceeds the quantity sold.' using errcode = '22023';
    end if;

    insert into public.pharmacy_sale_return_items (return_id, sale_item_id, medicine_id, medicine_name, quantity, unit_price)
    values (
      return_id_value,
      selected_sale_item.id,
      selected_sale_item.medicine_id,
      selected_sale_item.medicine_name,
      requested_item.quantity,
      selected_sale_item.unit_price
    );
    update public.medicines
    set stock = stock + requested_item.quantity,
        updated_at = now()
    where id = selected_sale_item.medicine_id;
    total_value := total_value + selected_sale_item.unit_price * requested_item.quantity;
  end loop;

  update public.pharmacy_sale_returns sale_return
  set total = total_value
  where sale_return.id = return_id_value;

  return query select return_reference_value, total_value;
end;
$$;

revoke all on function public.record_pharmacy_sale(text, text, text, jsonb) from public, anon;
revoke all on function public.record_pharmacy_sale_return(text, text, jsonb) from public, anon;
grant execute on function public.record_pharmacy_sale(text, text, text, jsonb) to authenticated;
grant execute on function public.record_pharmacy_sale_return(text, text, jsonb) to authenticated;
