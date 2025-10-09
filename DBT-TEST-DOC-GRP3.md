
# 🧭 How to Generate and View dbt Auto-Documentation for the Instacart Project

This guide shows how to **structure your dbt project**, define **models and sources**, and **generate browser-based documentation** automatically using `dbt docs`.

---

## 📂 1. Project Folder Structure

Your repo should look like this:

```
ftw-instacart-dataset-group3/
├── compose.yaml
├── dbt/
│   └── transforms/
│       └── instacart/
│           ├── dbt_project.yml
│           ├── models/
│           │   ├── sources/
│           │   │   └── sources.yml
│           │   ├── clean/
│           │   │   ├── stg_grp3_instacart_aisles.sql
│           │   │   ├── stg_grp3_instacart_departments.sql
│           │   │   ├── stg_grp3_instacart_order_products_prior.sql
│           │   │   ├── stg_grp3_instacart_order_products_train.sql
│           │   │   ├── stg_grp3_instacart_orders.sql
│           │   │   ├── stg_grp3_instacart_products.sql
│           │   │   └── schema.yml
│           │   └── mart/
│           │       ├── grp3_instacart_fact_orders.sql
│           │       ├── grp3_instacart_fact_order_products.sql
│           │       ├── grp3_instacart_dim_users.sql
│           │       ├── grp3_instacart_dim_products.sql
│           │       ├── grp3_instacart_dim_aisles.sql
│           │       ├── grp3_instacart_dim_departments.sql
│           │       ├── grp3_instacart_dim_time.sql
│           │       └── schema.yml
│           ├── macros/
│           └── target/ (auto-generated)
``` 
- This is to be edited since modifications in the schema is still ongoing.

---

## ⚙️ 2. dbt Project Configuration

`dbt_project.yml`

```yaml
name: "instacart"
version: "1.0"
config-version: 2

profile: clickhouse_ftw
model-paths: ["models"]
macro-paths: ["macros"]

models:
  instacart:
    clean:
      +schema: clean
      +materialized: table
    mart:
      +schema: mart
      +materialized: view
```

---

## 🧩 3. Define Your Sources (`models/sources/sources.yml`)

```yaml
version: 2

sources:
  - name: raw_instacart
    database: default
    schema: raw
    tables:
      - name: raw__insta_aisles
      - name: raw__insta_departments
      - name: raw__insta_products
      - name: raw__insta_orders
      - name: raw__insta_order_products_prior
      - name: raw__insta_order_products_train
```

Your staging models (`stg_`) will reference these like:

```sql
select * from {{ source('raw_instacart', 'raw__insta_orders') }}
```

---

## 🧱 4. Define Clean Models (`models/clean/schema.yml`)

```yaml
version: 2

models:
  - name: stg_grp3_instacart_orders
    columns:
      - name: order_id
        tests: [not_null, unique]
      - name: user_id
        tests: [not_null]

  - name: stg_grp3_instacart_products
    columns:
      - name: product_id
        tests: [not_null, unique]

  - name: stg_grp3_instacart_aisles
    columns:
      - name: aisle_id
        tests: [not_null, unique]

  - name: stg_grp3_instacart_departments
    columns:
      - name: department_id
        tests: [not_null, unique]

  - name: stg_grp3_instacart_order_products_prior
    columns:
      - name: order_id
        tests: [not_null]

  - name: stg_grp3_instacart_order_products_train
    columns:
      - name: order_id
        tests: [not_null]
```

---

## 🧮 5. Define Mart Models (`models/mart/schema.yml`)

```yaml
version: 2

models:
  - name: grp3_instacart_fact_orders
    columns:
      - name: order_id
        tests: [not_null, unique]

  - name: grp3_instacart_fact_order_products
    columns:
      - name: order_id
        tests: [not_null]

  - name: grp3_instacart_dim_users
    columns:
      - name: user_id
        tests: [not_null, unique]

  - name: grp3_instacart_dim_products
    columns:
      - name: product_id
        tests: [not_null, unique]

  - name: grp3_instacart_dim_aisles
    columns:
      - name: aisle_id
        tests: [not_null, unique]

  - name: grp3_instacart_dim_departments
    columns:
      - name: department_id
        tests: [not_null, unique]

  - name: grp3_instacart_dim_time
    columns:
      - name: order_dow
      - name: order_hour_of_day
```

---

## 🧠 6. Run & Build Models

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart \
  dbt run --profiles-dir /workdir/transforms/instacart
```

Optionally test:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart \
  dbt test --profiles-dir /workdir/transforms/instacart
```

---

## 📖 7. Generate Documentation

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart \
  dbt docs generate --profiles-dir /workdir/transforms/instacart --target local --static
```

Output:

```
dbt/transforms/instacart/target/static_index.html
```

---

## 🌐 8. View in Browser

**macOS**

```bash
open dbt/transforms/instacart/target/static_index.html
```

**Linux**

```bash
xdg-open dbt/transforms/instacart/target/static_index.html
```

---

## ✅ 9. Summary

| Step | Purpose           | Command                               |
| ---- | ----------------- | ------------------------------------- |
| 1    | Start environment | `docker compose --profile core up -d` |
| 2    | Build models      | `dbt run`                             |
| 3    | Test models       | `dbt test`                            |
| 4    | Generate docs     | `dbt docs generate`                   |
| 5    | Open docs         | `open target/static_index.html`       |

---
