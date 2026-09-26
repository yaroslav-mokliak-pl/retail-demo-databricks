# Brazilian E-Commerce Dataset (Olist) — Schema & Semantics

Source: [Brazilian E-Commerce Public Dataset by Olist — Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

## 1. Business context

Olist is a Brazilian marketplace connector: small and medium merchants sign up
with Olist and their products get listed across multiple large Brazilian
marketplaces (like Mercado Livre, Americanas, etc.) under one unified
back-office. Olist handles the multi-channel logistics, catalog and payment
side, and the merchant just ships the order once Olist routes it to them.

The dataset is real, anonymized commercial data covering **2016–2018**,
donated by Olist. It spans the full order lifecycle: a customer places an
order → order is split into items handled by (possibly multiple) sellers →
payment is collected → item is shipped → customer receives it → customer
leaves a review. Real customer/seller identities are anonymized.

## 2. High-level data model

The data sits in two layers under [data/](data/):

- **Transactional (event-dated) data** — orders, their line items, their
  payments, and their reviews. Each row is tied to a point in time, so
  these were split into one file per calendar year (2016/2017/2018,
  filename suffixed with the year) to keep files manageable and
  queryable by period.
- **Lookup / dimension data** — customers, sellers, products, zip-code
  geolocation, and the product-category translation table. These have no
  event date of their own and were left as single files.

An order is the center of the model. It belongs to one customer, contains
one or more line items, is settled by one or more payment rows, and
(usually) gets one review. Each line item points to a product and to the
seller who fulfills it. Both customers and sellers carry a Brazilian zip
code prefix that can be joined against the geolocation table to get
coordinates, e.g. to compute buyer↔seller distance.

Two identity subtleties worth knowing: the customer id on an order is
minted fresh per order, while a separate "unique id" field identifies the
actual repeat customer across orders — the schema distinguishes an order's
customer record from the person. Similarly, an order can have several
payment rows (installments, split methods) and several line items from
different sellers, so it is not a strict one-row-per-order structure once
you join outward.

## 3. Schema

### `olist_orders_dataset_<year>.csv` — order header

| Column | Type | Description |
|---|---|---|
| `order_id` | string (PK) | Unique order identifier. |
| `customer_id` | string (FK → customers) | One-per-order customer key. |
| `order_status` | enum | `created`, `approved`, `invoiced`, `processing`, `shipped`, `delivered`, `unavailable`, `canceled`. |
| `order_purchase_timestamp` | datetime | When the order was placed. Split key for this file. |
| `order_approved_at` | datetime, nullable | When payment was approved. |
| `order_delivered_carrier_date` | datetime, nullable | Handed to the logistics carrier. |
| `order_delivered_customer_date` | datetime, nullable | Actually received by the customer. |
| `order_estimated_delivery_date` | datetime | Delivery estimate shown at purchase time. |

### `olist_order_items_dataset_<year>.csv` — line items

| Column | Type | Description |
|---|---|---|
| `order_id` | string (FK → orders) | Parent order. |
| `order_item_id` | int | Sequence number within the order. |
| `product_id` | string (FK → products) | Product sold. |
| `seller_id` | string (FK → sellers) | Seller fulfilling this item. |
| `shipping_limit_date` | datetime | Seller's deadline to ship. Split key for this file. |
| `price` | decimal | Item price, excludes freight. |
| `freight_value` | decimal | Shipping cost for this item. |

### `olist_order_payments_dataset_<year>.csv` — payments

| Column | Type | Description |
|---|---|---|
| `order_id` | string (FK → orders) | Parent order. |
| `payment_sequential` | int | Sequence when paid with multiple methods/attempts. |
| `payment_type` | enum | `credit_card`, `boleto`, `debit_card`, `voucher`, `not_defined`. |
| `payment_installments` | int | Installment count for card payments. |
| `payment_value` | decimal | Amount charged in this row. |

No date of its own — year split derived by joining `order_id` back to `orders.order_purchase_timestamp`.

### `olist_order_reviews_dataset_<year>.csv` — reviews

| Column | Type | Description |
|---|---|---|
| `review_id` | string | Review identifier. |
| `order_id` | string (FK → orders) | Order being reviewed. |
| `review_score` | int 1–5 | Star rating, 1 worst – 5 best. |
| `review_comment_title` | string, mostly empty | Optional title, Portuguese. |
| `review_comment_message` | string, mostly empty | Optional comment, Portuguese. |
| `review_creation_date` | date | Survey sent date. Split key for this file. |
| `review_answer_timestamp` | datetime | When the customer answered. |

### `olist_customers_dataset.csv` — lookup

| Column | Type | Description |
|---|---|---|
| `customer_id` | string (PK) | Per-order key, joins `orders.customer_id`. |
| `customer_unique_id` | string | Stable id of the actual person across orders. |
| `customer_zip_code_prefix` | string | Join key into `geolocation`. |
| `customer_city` | string | City name. |
| `customer_state` | string | 2-letter state code. |

### `olist_sellers_dataset.csv` — lookup

| Column | Type | Description |
|---|---|---|
| `seller_id` | string (PK) | Joins `order_items.seller_id`. |
| `seller_zip_code_prefix` | string | Join key into `geolocation`. |
| `seller_city` | string | City name. |
| `seller_state` | string | 2-letter state code. |

### `olist_products_dataset.csv` — lookup

| Column | Type | Description |
|---|---|---|
| `product_id` | string (PK) | Joins `order_items.product_id`. |
| `product_category_name` | string, Portuguese | Joins `product_category_name_translation`. |
| `product_name_lenght` | int | Product title character length (upstream's own spelling, kept for join compatibility). |
| `product_description_lenght` | int | Description character length. |
| `product_photos_qty` | int | Number of listing photos. |
| `product_weight_g` | int | Weight in grams. |
| `product_length_cm`, `product_height_cm`, `product_width_cm` | int | Package dimensions in cm. |

### `olist_geolocation_dataset.csv` — lookup

| Column | Type | Description |
|---|---|---|
| `geolocation_zip_code_prefix` | string | Not unique — many lat/lng samples per prefix. |
| `geolocation_lat` | float | Latitude. |
| `geolocation_lng` | float | Longitude. |
| `geolocation_city` | string | City name. |
| `geolocation_state` | string | 2-letter state code. |

### `product_category_name_translation.csv` — lookup

| Column | Type | Description |
|---|---|---|
| `product_category_name` | string, Portuguese (PK) | Matches `products.product_category_name`. |
| `product_category_name_english` | string | English translation. |

## 4. Injected dirty data (deliberate, for testing)

The following is **not real Olist data quality** — it was deliberately
injected into this copy of the dataset to exercise validation/parsing
code paths. Every row/change below is intentional and documented here so
it isn't mistaken for a real upstream data issue.

### Reviews: simulated schema drift
- [olist_order_reviews_dataset_2016.json](data/olist_order_reviews_dataset_2016.json) has the `review_comment_title`
  field **removed from every record**, simulating that the column was
  introduced later.
- [olist_order_reviews_dataset_2017.json](data/olist_order_reviews_dataset_2017.json) and
  [olist_order_reviews_dataset_2018.json](data/olist_order_reviews_dataset_2018.json) keep `review_comment_title` on
  every record, simulating the column being added starting 2017.
- Reviews were also converted from CSV to JSON (array of objects,
  `review_score` cast to int); the original review CSVs were deleted.

### Payments: dirty/corrupted rows
One bad row was inserted as the first data row in each year's payments
file (right after the header):

| File | Row inserted | What's wrong with it |
|---|---|---|
| [olist_order_payments_dataset_2016.csv](data/olist_order_payments_dataset_2016.csv) | `bad_id_123,abc,unknown_type,three,N/A,extra_col` | non-numeric `payment_sequential`, invalid `payment_type` enum, non-numeric `payment_installments`, non-numeric `payment_value`, and an extra 6th field (5 columns expected) |
| [olist_order_payments_dataset_2017.csv](data/olist_order_payments_dataset_2017.csv) | `,1,credit_card,1,89.90` | empty `order_id` — breaks the FK join to `orders` |
| [olist_order_payments_dataset_2018.csv](data/olist_order_payments_dataset_2018.csv) | `9a736b248f67d166d2fbb006bcb877c3,1,boleto,1,-42.50` | negative `payment_value` — violates the business rule that payments are non-negative |

### Orders: inconsistent date formats
In [olist_orders_dataset_2018.csv](data/olist_orders_dataset_2018.csv), `order_purchase_timestamp` was reformatted
on 3 rows (same underlying instant, different string format) to simulate
a source that isn't consistent about date formatting:

| order_id | Value | Format |
|---|---|---|
| `53cdb2fc8bc7dce0b6741e2150273451` | `07/24/2018 20:41:37` | MM/DD/YYYY HH:MM:SS |
| `47770eb9100c2d0c44946d9cf07ec65d` | `2018-08-08T08:38:49Z` | ISO 8601 with `T`/`Z` |
| `ad21c59c0840e6cb83a9ceb5573f8159` | `13-02-2018 21:18:39` | DD-MM-YYYY HH:MM:SS |

Every other date column, in every other row, is still the original
`YYYY-MM-DD HH:MM:SS` format.

## 5. Known data quirks

- Order-level customer id is not the same as the person — a repeat buyer
  gets a new customer id on every order.
- One order can involve multiple sellers (one per line item) and multiple
  payment rows — never assume 1:1 when joining out from orders.
- Review text is optional, mostly empty, and in Portuguese.
- Delivery timestamps are nullable for orders that never reached that
  stage (canceled, still in transit, etc).
- The payments file has no date of its own; its year split was derived by
  joining back to the parent order's purchase date.
- A handful of line items land in a 2020 slice — their shipping deadline
  rolled past year-end even though the order itself was placed in 2018.
