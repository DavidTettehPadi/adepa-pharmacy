# Supabase setup for Adepa Pharmacy

`schema.sql` creates the shared medicine catalogue, staff-only order access, and a public order-submission function. Database row-level security is the access boundary; hiding controls in the browser is not relied on as security.

## Create and initialize the project

1. Create a Supabase project and keep its database password private.
2. Open the project's SQL Editor and run all of `schema.sql`.
3. In Table Editor, import `../nhis_2025_medicines.csv` into `public.nhis_medicine_import`. Map the CSV columns to the staging table's matching columns: `code`, `generic_name_dosage_form_strength`, `unit_of_pricing`, `price_ghc`, `level_of_prescribing`, and `source_page`.
4. In SQL Editor, run `select public.seed_nhis_medicines();`. The import maps dosage forms to categories and initializes 1,000 pieces per medicine, or 500 for `Other dosage form`. Running it again updates catalogue descriptions and prices without resetting stock.
5. Invite each worker as a Supabase Auth user. In SQL Editor, assign `admin` only to the pharmacy owner and use `pharmacist` or `assistant` for staff. Assign roles in protected JWT app metadata. Replace the example email and role:

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
  || jsonb_build_object('pharmacy_role', 'admin')
where email = 'owner@example.com';
```

Use `admin`, `pharmacist`, or `assistant` for the role. Sign the user out and back in after changing app metadata so the refreshed access token contains the role. Do not put a Supabase service-role key in website code.

## Sales backend

The static website uses `supabase/config.js` for the Supabase project URL and public anon key. Set both values there after running `schema.sql`. The anon key is intended for browser use; never put a service-role key in this file or any other website asset. The site submits orders through `public.place_customer_order(...)`, displays the returned database-priced receipt, and lets signed-in pharmacy staff review recent order history and print receipts.

The SQL exposes `public.medicines` to anonymous visitors only when `is_active` is true and stock is greater than zero. The order function validates customer contact/address and requested quantities, reserves stock using database prices, and returns the order reference, total, and exact stored line items for the receipt. Order and buyer details are readable only by authenticated pharmacy staff. Cancelling an order before it is out for delivery restores its reserved stock. The sales-history screen displays the 100 most recent customer orders; it does not expose anonymous access to customer details.
