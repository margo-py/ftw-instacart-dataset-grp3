
# 🧭 Instacart Project — Auto-Documentation & Data Testing Guide

This guide explains how to **structure the dbt project**, **define models and sources**, **run tests**, and **generate browser-based documentation** (with DAG visualization).

---

## 📁 1. Project Folder Structure

Your project should follow this layout:

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
│           └── target/  (auto-generated)
```

> 💡 *You can adjust this structure if schema updates or model refinements are still in progress.*

---

## ⚙️ 2. Project Configuration (`dbt_project.yml`)

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

This configuration tells dbt where to look for models, and how to materialize each layer.

---

## 🧩 3. Source Definition (`models/sources/sources.yml`)

These define your **raw data inputs** — the “Bronze Layer” in the pipeline.

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

Used inside staging models as:

```sql
SELECT * FROM {{ source('raw_instacart', 'raw__insta_orders') }}
```

---

## 🧱 4. Clean Models (`models/clean/schema.yml`)

The **Silver Layer**, where data is cleaned and standardized.

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

Each column test checks for **data integrity** — no nulls, duplicates, or broken relationships.

---

## 🏗️ 5. Mart Models (`models/mart/schema.yml`)

The **Gold Layer**, where final business-ready datasets are stored.

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

These are **fact** and **dimension** tables that form the star schema for analytics and BI dashboards.

---

## 🧪 6. Data Testing

Run all data tests:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart \
  dbt test --profiles-dir /workdir/transforms/instacart
```

**Types of tests used:**

| Test              | Purpose                        |
| ----------------- | ------------------------------ |
| `not_null`        | Ensures no empty values        |
| `unique`          | Detects duplicate IDs          |
| `accepted_values` | Validates day/hour ranges      |
| `relationships`   | Confirms referential integrity |

All test results are saved under `target/` and visible inside **dbt Docs → Data Tests**.

---

## 📚 7. Generate Documentation

Build the documentation site:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart \
  dbt docs generate --profiles-dir /workdir/transforms/instacart --target local --static
```

Output file:

```
dbt/transforms/instacart/target/static_index.html
```

---

## 🌐 8. Serve and View Docs (Interactive DAG)

Serve interactive docs locally:

```bash
docker compose --profile jobs run --rm \
  -p 8080:8080 \
  -w /workdir/transforms/instacart \
  dbt docs serve --profiles-dir /workdir/transforms/instacart --target local --port 8080 --host 0.0.0.0
```

Then visit:
👉 **[http://localhost:8080](http://localhost:8080)**

### 🧩 Viewing the DAG

In the docs UI:

1. Click the **“Graph”** or **“Lineage”** icon in the top-right corner.
2. You’ll see the full model flow:

   ```
   raw__insta_* → stg_grp3_instacart_* → grp3_instacart_fact_* / dim_*
   ```
3. Each layer is color-coded:

   * 🟢 **Raw** — source tables
   * 🔵 **Clean** — staging models
   * 🟣 **Mart** — analytics models

This confirms your model dependencies and the full **data lineage**.

---

## ✅ 9. Workflow Summary

| Step | Purpose               | Command                               |
| ---- | --------------------- | ------------------------------------- |
| 1    | Start services        | `docker compose --profile core up -d` |
| 2    | Build models          | `dbt run`                             |
| 3    | Run tests             | `dbt test`                            |
| 4    | Generate docs         | `dbt docs generate`                   |
| 5    | Serve docs (view DAG) | `dbt docs serve --port 8080`          |
| 6    | Open in browser       | `http://localhost:8080`               |

---


