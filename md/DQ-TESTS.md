# 🚀 FTW Data Engineering Bootcamp – Auto MPG Pipeline (dbt)

This module demonstrates an end-to-end mini data pipeline using **dlt**, **ClickHouse**, and **dbt** with the [Auto MPG dataset](https://archive.ics.uci.edu/dataset/9/auto+mpg).

It includes:

* A `clean` layer (typed, standardized)
* A `mart` layer (aggregated cylinders by origin)
* dbt **tests** (structural + semantic)
* dbt **docs** (static HTML site)

---

## 📂 Folder Structure

```
ftw-de-bootcamp/
└── dbt/
    └── transforms/
        └── 01_mpg/
            ├── models/
            │   ├── clean/
            │   │   └── schema.yml
            │   └── mart/
            │       └── schema.yml
            ├── target/              # dbt docs output (after generation)
            └── ...
```

---

## 🧪 Running dbt Tests

### Clean (structural tests)

* Validate not-null constraints, accepted values, and row count consistency.
* Defined in: `models/clean/schema.yml`

### Mart (semantic tests)

* Validate aggregated results are within expected ranges.
* Defined in: `models/mart/schema.yml`

**Run tests:**

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt test --profiles-dir . --target local
```

---

## ⚙️ Execute Models & Run Pipeline

Build all models (`staging` → `clean` → `mart`) in this module:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt build --profiles-dir . --target local
```

---

## 📖 Generate Documentation

Generate static HTML documentation for this dbt project:

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt docs generate --profiles-dir . --target local --static
```

Open the docs locally:

```
ftw-de-bootcamp/dbt/transforms/01_mpg/target/static_index.html
```

---

## ✅ Summary

* **Tests:** run `dbt test` for data quality checks
* **Build:** run `dbt build` to execute models
* **Docs:** run `dbt docs generate` and open `target/index.html`

# Let's create a DQ Dashboard 

Two lightweight dbt views:

1. **`mart.dq_mpg_summary`** – one-row KPI snapshot with:

   * `row_count_raw`, `row_count_clean`, `dropped_rows`
   * null rates (e.g., `pct_null_horsepower`)
   * invalid domain counts (e.g., cylinders not in {3,4,5,6,8})
   * simple numeric bounds checks (negative or zero values)

2. **`mart.dq_mpg_anomalies`** – row-level drilldown for any records violating simple rules
   (great for a Metabase table card).

You’ll then create 3–4 Metabase cards:

* KPI tiles from `dq_mpg_summary`
* A bar showing invalids by rule
* A table listing `dq_mpg_anomalies` (limit 50)
* (Optional) a trend if you re-run regularly and add a run timestamp (kept out for simplicity)

---

## 1) Add dbt models (mart layer)

Create a new folder:

```
ftw-de-bootcamp/dbt/transforms/01_mpg/models/mart/dq/
```

### A) `dq_mpg_summary.sql`

**Path:** `ftw-de-bootcamp/dbt/transforms/01_mpg/models/mart/dq/dq_mpg_summary.sql`

```sql
{{ config(materialized="view", schema="mart") }}

-- Inputs:
--   raw table:   raw.autompg___cars           (as loaded by dlt)
--   clean model: {{ ref('mpg_standardized') }} (typed/trimmed)

with src as (
  select * from {{ source('raw','autompg___cars') }}
),
cln as (
  select * from {{ ref('mpg_standardized') }}
),

counts as (
  select
    (select count() from src)  as row_count_raw,
    (select count() from cln)  as row_count_clean
),
nulls as (
  select
    round(100.0 * countIf(horsepower is null) / nullif(count(),0), 2) as pct_null_horsepower
  from cln
),
domains as (
  select
    -- cylinders domain: {3,4,5,6,8}
    countIf(cylinders not in (3,4,5,6,8)) as invalid_cylinders,
    -- origin domain: {"usa","europe","japan"} (case-insensitive trim assumed in clean)
    countIf(lower(origin) not in ('usa','europe','japan')) as invalid_origin
  from cln
),
bounds as (
  select
    countIf(mpg <= 0)           as nonpositive_mpg,
    countIf(displacement <= 0)  as nonpositive_displacement,
    countIf(weight <= 0)        as nonpositive_weight,
    countIf(acceleration <= 0)  as nonpositive_acceleration,
    -- UCI Auto MPG years are 70..82 (1970..1982) in this dataset
    countIf(model_year < 70 or model_year > 82) as out_of_range_model_year
  from cln
),
joined as (
  select
    counts.row_count_raw,
    counts.row_count_clean,
    (counts.row_count_raw - counts.row_count_clean) as dropped_rows,

    nulls.pct_null_horsepower,

    domains.invalid_cylinders,
    domains.invalid_origin,

    bounds.nonpositive_mpg,
    bounds.nonpositive_displacement,
    bounds.nonpositive_weight,
    bounds.nonpositive_acceleration,
    bounds.out_of_range_model_year
  from counts
  cross join nulls
  cross join domains
  cross join bounds
)

select * from joined
```

### B) `dq_mpg_anomalies.sql`

**Path:** `ftw-de-bootcamp/dbt/transforms/01_mpg/models/mart/dq/dq_mpg_anomalies.sql`

```sql
{{ config(materialized="view", schema="mart") }}

-- Row-level drilldown of “obviously wrong” records based on simple rules.
-- LIMIT for demo-friendliness; remove in real pipelines.

with cln as (
  select * from {{ ref('mpg_standardized') }}
),
violations as (
  select
    -- NOTE: this dataset has no native PK; include a synthetic row_number if needed.
    -- ClickHouse: use monotonicallyIncreasingId() isn't stable; we’ll show columns directly.
    mpg, cylinders, displacement, horsepower, weight, acceleration, model_year, origin, make,

    multiIf(
      mpg <= 0,                      'nonpositive_mpg',
      displacement <= 0,             'nonpositive_displacement',
      weight <= 0,                   'nonpositive_weight',
      acceleration <= 0,             'nonpositive_acceleration',
      cylinders not in (3,4,5,6,8),  'invalid_cylinders',
      lower(origin) not in ('usa','europe','japan'), 'invalid_origin',
      model_year < 70 or model_year > 82, 'out_of_range_model_year',
      horsepower is null,            'null_horsepower',
      'ok'
    ) as dq_issue
  from cln
)
select *
from violations
where dq_issue != 'ok'
limit 50
```

### C) Add a small `schema.yml` for docs

**Path:** `ftw-de-bootcamp/dbt/transforms/01_mpg/models/mart/dq/schema.yml`

```yaml
version: 2

models:
  - name: dq_mpg_summary
    description: "DQ KPIs derived from clean MPG model vs raw source (demo-friendly)."
    columns:
      - name: row_count_raw
        description: "Total rows in raw source table"
      - name: row_count_clean
        description: "Total rows in clean model"
      - name: dropped_rows
        description: "raw minus clean (proxy for filtered rows)"
      - name: pct_null_horsepower
        description: "% of rows with NULL horsepower in clean"
      - name: invalid_cylinders
        description: "Rows where cylinders not in {3,4,5,6,8}"
      - name: invalid_origin
        description: "Rows where origin not in {usa,europe,japan}"
      - name: nonpositive_mpg
        description: "Rows where mpg <= 0"
      - name: nonpositive_displacement
        description: "Rows where displacement <= 0"
      - name: nonpositive_weight
        description: "Rows where weight <= 0"
      - name: nonpositive_acceleration
        description: "Rows where acceleration <= 0"
      - name: out_of_range_model_year
        description: "Rows where model_year not in [70..82]"

  - name: dq_mpg_anomalies
    description: "Row-level drilldown of records violating simple DQ rules."
```

---

## 2) Build the models

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt build --profiles-dir . --target local
```

(You’ll see `mart.dq_mpg_summary` and `mart.dq_mpg_anomalies` created as views.)

Generate/update docs (optional, nice for students):

```bash
docker compose --profile jobs run --rm \
  -w /workdir/transforms/01_mpg \
  dbt docs generate --profiles-dir . --target local --static
```

Open: `ftw-de-bootcamp/dbt/transforms/01_mpg/target/index.html`

---

## 3) Create the Metabase dashboard (manual, 2 minutes)

In Metabase, connect to your ClickHouse “raw” database (already done for your stack).
Then create a dashboard called **“Data Quality – Auto MPG (Demo)”** with these cards:

1. **KPI: Dropped rows**

   * Native query (SQL) against `mart.dq_mpg_summary`:

   ```sql
   select dropped_rows from mart.dq_mpg_summary
   ```

   * Visualization: Single Value.

2. **KPI: % NULL horsepower**

   ```sql
   select pct_null_horsepower from mart.dq_mpg_summary
   ```

   * Single Value, show “%”.

3. **Bar: Invalid counts by rule**
   Use this SQL to pivot the summary into a long list:

   ```sql
   select 'invalid_cylinders' as rule, invalid_cylinders as count from mart.dq_mpg_summary
   union all
   select 'invalid_origin', invalid_origin from mart.dq_mpg_summary
   union all
   select 'nonpositive_mpg', nonpositive_mpg from mart.dq_mpg_summary
   union all
   select 'nonpositive_displacement', nonpositive_displacement from mart.dq_mpg_summary
   union all
   select 'nonpositive_weight', nonpositive_weight from mart.dq_mpg_summary
   union all
   select 'nonpositive_acceleration', nonpositive_acceleration from mart.dq_mpg_summary
   union all
   select 'out_of_range_model_year', out_of_range_model_year from mart.dq_mpg_summary
   ```

   * Visualization: Bar (Rule vs Count).

4. **Table: Anomalies (sample)**

   ```sql
   select * from mart.dq_mpg_anomalies
   ```

   * Table; keep default columns; this will show up to 50 rows as configured.

Arrange the dashboard: KPI tiles on top, bar chart in the middle, table at the bottom.

---

## 4) Talking points for class (why this is “simple but right”)

* **Close to the data**: Metrics are computed from `clean` tables (typed & trimmed), but published as **mart** views intended for consumption.
* **Clear, demo-friendly rules**: Domain checks, numeric bounds, and null rates are intuitive to explain.
* **Extensible**: If you later want historical trends, add a `run_ts` to these views (parameter/variable or a small logging table) and chart over time.
* **Complementary to dbt tests**: These **don’t replace** dbt’s pass/fail tests; they **summarize** data conditions for stakeholders.

---

## 5) Optional enhancements (next steps)

* Add a `dq_run_ts` column with `now()` in both views to create a time series.
* Parameterize allowed domains via a small YAML seed table (e.g., `cylinders_domain`, `origin_domain`) and `ref()` it for maintainability.
* Add a **freshness** check: compare `max(model_year)` to an expected threshold or a load timestamp if you have one.
* Wire dbt tests + run_results parsing later if you want a “test-centric” DQ dashboard.

