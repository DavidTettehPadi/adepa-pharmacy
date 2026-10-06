# Supabase setup for Adepa Pharmacy

`schema.sql` creates the shared medicine catalogue, staff-only order access, and a public order-submission function. Database row-level security is the access boundary; hiding controls in the browser is not relied on as security.

## Create and initialize the project

1. Create a Supabase project and keep its database password private.
2. Open the project's SQL Editor and run all of `schema.sql`.
3. In Table Editor, import `../nhis_2025_medicines.csv` into `public.nhis_medicine_import`. Map the CSV columns to the staging table's matching columns: `code`, `generic_name_dosage_form_strength`, `unit_of_pricing`, `price_ghc`, `level_of_prescribing`, and `source_page`.
4. In SQL Editor, run `select public.seed_nhis_medicines();`. The import maps dosage forms to categories and initializes 1,000 pieces per medicine, or 500 for `Other dosage form`. Running it again updates catalogue descriptions and prices without resetting stock.
5. Invite each worker as a Supabase Auth user. In SQL Editor, assign the appropriate role in the protected JWT app metadata. Replace the example email and role:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('pharmacy_role', 'admin')
where email = 'owner@example.com';
```

Use `admin`, `pharmacist`, or `assistant` for the role. Sign the worker out and back in after changing app metadata so the refreshed access token contains the role. Do not put a Supabase service-role key in website code.

## Website connection still required

The current website is a static GitHub Pages site and still uses browser-local inventory and sales. The SQL schema is the secure shared-data foundation; it does not by itself switch the existing page to Supabase. To complete that integration, configure the project's Supabase project URL and **publishable/anon client key** in the site. These client values are intended for browser use when RLS is enabled. Never use the service-role key in the browser.

The SQL exposes `public.medicines` to anonymous visitors only when `is_active` is true and stock is greater than zero. Customer orders must be submitted through `public.place_customer_order(...)`; the function validates customer contact/address and each requested quantity, takes stock using database prices, and returns an order reference and total. Order and buyer details are readable only by authenticated pharmacy staff. Cancelling an order before it is out for delivery restores its reserved stock.
