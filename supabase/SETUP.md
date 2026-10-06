# Supabase setup for Adepa Pharmacy

`schema.sql` creates the shared medicine catalogue, staff-only order access, and a public order-submission function. `owner-sales.sql` adds a private pharmacy sales ledger. Database row-level security is the access boundary; hiding controls in the browser is not relied on as security.

## Create and initialize the project

1. Create a Supabase project and keep its database password private.
2. Open the project's SQL Editor and run all of `schema.sql`.
3. Run all of `owner-sales.sql` in the SQL Editor. It creates the sales/returns ledger, allows staff to submit transactions through checked database functions, and restricts ledger reads to accounts whose protected `pharmacy_role` is `admin`.
4. In Table Editor, import `../nhis_2025_medicines.csv` into `public.nhis_medicine_import`. Map the CSV columns to the staging table's matching columns: `code`, `generic_name_dosage_form_strength`, `unit_of_pricing`, `price_ghc`, `level_of_prescribing`, and `source_page`.
5. In SQL Editor, run `select public.seed_nhis_medicines();`. The import maps dosage forms to categories and initializes 1,000 pieces per medicine, or 500 for `Other dosage form`. Running it again updates catalogue descriptions and prices without resetting stock.
6. Invite each worker as a Supabase Auth user. In SQL Editor, assign `admin` only to the pharmacy owner and use `pharmacist` or `assistant` for staff. Assign roles in protected JWT app metadata. Replace the example email and role:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('pharmacy_role', 'admin')
where email = 'owner@example.com';
```

Use `admin`, `pharmacist`, or `assistant` for the role. Sign the user out and back in after changing app metadata so the refreshed access token contains the role. Do not put a Supabase service-role key in website code.

## Website connection still required

The website is configured for this project's Supabase URL and browser-safe publishable key. Staff sign-in is required to open checkout; new sales and returns use database functions, and only the authenticated `admin` owner role can load sales history. This works only after both SQL files above have been applied and staff roles are assigned. Never use the service-role key in website code.

Stock balances are loaded from Supabase at staff sign-in and sale/return movements update shared stock. The existing manual `Receive` stock adjustment still uses browser-local storage and must be migrated to a database-protected operation before relying on it for shared stock. Any sales history created by an older version of the site remains in that browser's `localStorage`; it is not automatically migrated. Do not clear the old browser data until those records have been reconciled or separately archived.

The SQL exposes `public.medicines` to anonymous visitors only when `is_active` is true and stock is greater than zero. Customer orders must be submitted through `public.place_customer_order(...)`; the function validates customer contact/address and each requested quantity, takes stock using database prices, and returns an order reference and total. Order and buyer details are readable only by authenticated pharmacy staff. Cancelling an order before it is out for delivery restores its reserved stock. Pharmacy sales and returns use `public.record_pharmacy_sale(...)` and `public.record_pharmacy_sale_return(...)`; only the owner `admin` role can query their history and customer details.
