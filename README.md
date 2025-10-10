# 📝 Instacart Dataset ELT Pipeline Documentation Group 3

## 1. Project Overview

* **Dataset Used:**
  [Instacart Market Basket Analysis (Kaggle)](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis)
  The dataset contains anonymized customer orders, products, aisles, and departments from Instacart’s online grocery platform.

* **Goal of the Exercise:**
  Transform the normalized Instacart dataset (OLTP-style) into a **dimensional star schema** for analytics — applying dbt for data cleaning, modeling, and testing, and generating documentation for BI use.

* **Team Setup:**
  Group 3 — collaborative setup, with members  **Royce**, **Pau**, **Marj**, **Bianca**, and **Mikay**,.
  Work was done both individually and collaboratively with async updates via Slack and GitHub.

* **Environment Setup:**

  * Development and testing on **Dockerized local environments**
  * Shared **ClickHouse** database
  * dbt project stored and versioned in **GitHub**
  * Visualization in **Metabase**

---

## 2. Architecture & Workflow

* **Pipeline Flow:**

  ```
  Raw (Bronze) -> Clean (Silver) -> Mart (Gold) -> Metabase Dashboards
  ```

* **Tools Used:**

  * Ingestion: `dlt`
  * Modeling: `dbt`
  * Visualization: `Metabase`
  * Database: `ClickHouse`
  * Documentation & Testing: `dbt docs`, `dbt tests`, `DBeaver`, `dbdiagram`

* **Medallion Architecture Application:**

  * **Bronze (Raw):** Data loaded directly from Kaggle CSVs into ClickHouse (`raw__insta_*` tables)
  * **Silver (Clean):** Data cleaned and standardized via dbt staging models (`stg_grp3_instacart_*`)
  * **Gold (Mart):** Star-schema models for analysis (`fact_` and `dim_` tables)

* **Data Dictionary**


  | **Table**                           | **Column**        | **Description**                                      | **Notes / Keys**             |
  | ----------------------------------- | ----------------- | ---------------------------------------------------- | ---------------------------- |
  | **orders** (3.4M rows, 206K users)  | order_id          | Order identifier                                     | **Primary key**              |
  |                                     | user_id           | Customer identifier                                  | Foreign key → users          |
  |                                     | eval_set          | Evaluation set this order belongs to                 | Values: prior / train / test |
  |                                     | order_number      | Order sequence number for user (1 = first, n = nth)  |                              |
  |                                     | order_dow         | Day of the week the order was placed (0–6)           |                              |
  |                                     | order_hour_of_day | Hour of the day the order was placed (0–23)          |                              |
  |                                     | days_since_prior  | Days since last order (NA for first order)           | Capped at 30                 |
  | **products** (50K rows)             | product_id        | Product identifier                                   | **Primary key**              |
  |                                     | product_name      | Name of product                                      |                              |
  |                                     | aisle_id          | Aisle foreign key                                    | FK → aisles                  |
  |                                     | department_id     | Department foreign key                               | FK → departments             |
  | **aisles** (134 rows)               | aisle_id          | Aisle identifier                                     | **Primary key**              |
  |                                     | aisle             | Name of aisle                                        |                              |
  | **departments** (21 rows)           | department_id     | Department identifier                                | **Primary key**              |
  |                                     | department        | Name of department                                   |                              |
  | **order_products__SET** (30M+ rows) | order_id          | Order foreign key                                    | FK → orders                  |
  |                                     | product_id        | Product foreign key                                  | FK → products                |
  |                                     | add_to_cart_order | Order in which product added to cart                 |                              |
  |                                     | reordered         | 1 = product reordered by user before, 0 = first time |                              |

**SET values (eval_set in `orders`):**

* **prior** → all previous orders (~3.2M)
* **train** → training data (~131K)
* **test** → test data (~75K)



* **🧹 Cleaning:**
  - Raw tables were cleaned and followed a naming convention `stg_grp3_instacart_tablename.sql`

    1. `stg_grp3_instacart_aisles.sql`
    2. `stg_grp3_instacart_departments.sql`
    3. `stg_grp3_instacart_order_products_prior.sql`
    4. `stg_grp3_instacart_order_ products_train.sql`
    5. `stg_grp3_instacart_orders.sql`
    6. `stg_grp3_instacart_products.sql`
    7. `stg_nrml_grp3_instacart_aisle_dept_map.sql`
    8. `stg_nrml_grp3_instacart_order_details.sql`
    9. `stg_nrml_grp3_instacart_order_number.sql`
    10. `stg_nrml_grp3_instacart_product_details.sql`

    -----

    1. `stg_grp3_instacart_aisles.sql` -> aisles table cleaning
      - Configure output {{ config(...) }} (dbt setup, not SQL yet)
      - Create CTE source to read & pull data from raw
      - Clean & cast fields inside source
      - Filter invalid rows inside cleaned CTE
      - Select final result select * from cleaned
    ```sql
    {{ config(materialized="table", schema="clean") }}

    with source as (
        select 
            cast(aisle_id as integer) as aisle_id,
            cast(aisle as varchar) as aisle
        from {{ source('raw', 'raw___insta_aisles') }}
    ),

    cleaned as (
        select
            aisle_id,
            aisle
        from source
        where aisle_id is not null
          and aisle is not null
    )

    select * from cleaned
    ```



    2. `stg_grp3_instacart_departments.sql` -> departments cleaning
      - Create CTE source to read & pull data from raw
      - Clean and cast fields inside source
      - Create CTE cleaned
      - Select columns and alias correctly
      - Filter out null department_id since these act as key
    ```sql
    {{ config(materialized="table", schema="clean") }}

    with source as (
        select 
            cast(department_id as integer) as department_id,
            cast(department as varchar) as department
        from {{ source('raw', 'raw___insta_departments') }}
    ),

    cleaned as (
        select
            department_id,
            trim(lower(department)) as department
        from source
        where department_id is not null
          and department is not null
    )

    select * from cleaned
    ```



    3. `stg_grp3_instacart_order_products_prior.sql` -> order_products_prior cleaning
      - Create CTE source to read & pull data from raw
      - Clean and cast fields, and alias correctly
      - Create CTE cleaned
      - Filter out null order_id and product_id since these act as keys
    ```sql
    {{ config(materialized="table", schema="clean") }}
    with source as (
        select 
            cast(order_id as integer) as order_id,
            cast(product_id as integer) as product_id,
            cast(add_to_cart_order as integer) as add_to_cart_order,
            cast(reordered as integer) as reordered
        from {{ source('raw', 'raw___insta_order_products_prior') }}
    ),

    cleaned as (
        select
            order_id,
            product_id,
            add_to_cart_order,
            reordered
        from source
        where order_id is not null
          and product_id is not null
    )

    select * from cleaned
    ```



    4. `stg_grp3_instacart_order_ products_train.sql` -> order_products_train cleaning (Same as prior, but source is from order_products_train)
      - Create CTE source to read & pull data from raw
      - Clean and cast fields, and alias correctly
      - Create CTE cleaned
      - Filter out null order_id and product_id since these act as keys
    ```sql
    {{ config(materialized="table", schema="clean") }}
    with source as (
        select 
            cast(order_id as integer) as order_id,
            cast(product_id as integer) as product_id,
            cast(add_to_cart_order as integer) as add_to_cart_order,
            cast(reordered as integer) as reordered
        from {{ source('raw', 'raw___insta_order_products_train') }}
    ),

    cleaned as (
        select
            order_id,
            product_id,
            add_to_cart_order,
            reordered
        from source
        where order_id is not null
          and product_id is not null
    )

    select * from cleaned
    ```



    5. `stg_grp3_instacart_orders.sql` ->  orders cleaning
    🧐 Challenge encountered: Null values in days_since_prior_order
    - Create CTE source to read and pull data from raw
    - Cast and clean fields, trim, lowercase text
    - Handle invalid `days_since_prior_order` field, replace Nan, null, empty, or 0 with NULL to make them safe for query
    - Create CTE cleaned
    - Mapped numeric order_dow to weekday string names
    - Filter out null order_id and user_id and keep eval_set values
    ```sql
    {{ config(materialized = "table", schema = "clean") }}

    with source as (
        select
            toInt32OrNull(order_id)           as order_id,
            toInt32OrNull(user_id)            as user_id,
            lower(trim(toString(eval_set)))   as eval_set,
            toInt32OrNull(order_number)       as order_number,
            toInt32OrNull(order_dow)          as order_dow,
            toInt32OrNull(order_hour_of_day)  as order_hour_of_day,


            -- Clean and normalize days_since_prior_order
            case
                when lower(trim(toString(days_since_prior_order))) in ('nan', 'null', '') then null
                when isNaN(toFloat64OrNull(days_since_prior_order)) then null
                when toFloat64OrNull(days_since_prior_order) = 0 then null
                else toFloat64OrNull(days_since_prior_order)
            end as days_since_prior_order


        from {{ source('raw', 'raw___insta_orders') }}
    ),


    cleaned as (
        select
            order_id,
            user_id,
            eval_set,
            order_number,


            -- Map numeric DOW to readable weekday
            case toInt32(order_dow)
                when 0 then 'Sunday'
                when 1 then 'Monday'
                when 2 then 'Tuesday'
                when 3 then 'Wednesday'
                when 4 then 'Thursday'
                when 5 then 'Friday'
                when 6 then 'Saturday'
                else null
            end as order_dow_name,


            order_dow,
            order_hour_of_day,
            days_since_prior_order
        from source
        where order_id is not null
          and user_id is not null
          and eval_set in ('prior', 'train', 'test')
    )


    select *
    from cleaned
    ```



    6. `stg_grp3_instacart_products.sql` ->  products cleaning
    - Create CTE source to pull data from raw
    - Create CTE clean
    - Trim to remove extra spaces on product name string
    - Filter null values on product_id and product_name
    ```sql
    {{ config(materialized="table", schema="clean") }}
    with source as (
        select 
            cast(product_id as integer) as product_id,
            cast(aisle_id as integer) as aisle_id,
            cast(department_id as integer) as department_id,
            cast(product_name as varchar(64)) as product_name
        from {{ source('raw', 'raw___insta_products') }}
    ),

    cleaned as (
        select
            product_id,
            lower(trim(product_name)) as product_name, --Easier to query if all lowercase
            aisle_id,
            department_id,

        from source
        where product_id is not null
          and product_name is not null
          and trim(product_name) != ''
    )


    select * from cleaned
    ```



    7. stg_nrml_grp3_instacart_aisle_dept_map.sql
    - Create CTe aisle_dept_map and cast data type
    - Group to get unique aisle-department pairs
    - Create CTE to check aisles linked to multiple departments
    - Filter aisles with more than 1 department
    ```sql
    {{ config(materialized="table", schema="clean") }}

    with aisle_dept_map as (
        select
            cast(aisle_id as Int32) as aisle_id,
            cast(department_id as Int32) as department_id
        from {{ ref('stg_grp3_instacart_products') }}
        group by
            aisle_id,
            department_id
    ),

    aisles_with_multiple_departments as (
        select
            aisle_id,
            count(distinct department_id) as dept_count
        from {{ ref('stg_grp3_instacart_products') }}
        group by aisle_id
        having count(distinct department_id) > 1
    )

    select *
    from aisle_dept_map
    ```



    8. stg_nrml_grp3_instacart_order_details.sql
    - Simple select of fields from instacart_orders
    ```sql
    {{ config(materialized="table", schema="clean") }}

    select
        order_id,
        user_id,
        eval_set,
        order_dow,
        order_hour_of_day,
        days_since_prior_order
    from {{ ref('stg_grp3_instacart_orders') }}
    ```


    9. stg_nrml_grp3_instacart_order_number.sql
    - Simple select of fields from instacart_orders
    ```sql
    {{ config(materialized="table", schema="clean") }}

    select distinct
        user_id,
        order_id,
        order_number
    from {{ ref('stg_grp3_instacart_orders') }}

    ```


    10. stg_nrml_grp3_instacart_product_details.sql
    - Simple select and casting of product details fields
    ```sql
    {{ config(materialized="table", schema="clean") }}

    select
        cast(product_id as Int32) as product_id,
        product_name,
        cast(aisle_id as Int32) as aisle_id
    from {{ ref('stg_grp3_instacart_products') }}

    ```

  After cleaning we ran this code:
  ```bash
  docker compose --profile jobs run --rm \
  -w /workdir/transforms/instacart  \
  dbt build --profiles-dir . --target remote
  ```

---

## 3. Modeling Process

* **Source Structure (Normalized):**
  The raw Instacart dataset consists of multiple related tables (orders, order_products, products, aisles, departments) with primary/foreign keys following 3NF design.

* **Star Schema Design:**

  ![ERD](https://github.com/margo-py/ftw-instacart-dataset-grp3/blob/main/dbt/transforms/instacart/Instacart%20Star%20Schema.png?raw=true)

  * **A. Dimension Tables (5):**

    1. `grp3_instacart_dim_aisles`
    2. `grp3_instacart_dim_departments`
    3. `grp3_instacart_dim_products`
    4. `grp3_instacart_dim_time`
    5. `grp3_instacart_dim_users`

  * **B. Fact Tables (2):**

    1. `grp3_instacart_fact_order_products`
    2. `grp3_instacart_fact_orders`
    

  ### Breakdown of Dimensional modeling tables
  #### A. Dimension Tables

  1. `grp3_instacart_dim_aisles.sql` -> aisles dimension

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='aisle_id') }}

    select
        cast(a.aisle_id as integer) as aisle_id,
        trim(a.aisle) as aisle_name,
        cast(ad.department_id as integer) as department_id
    from {{ ref('stg_grp3_instacart_aisles') }} as a
    left join {{ ref('stg_nrml_grp3_instacart_aisle_dept_map') }} as ad
        on a.aisle_id = ad.aisle_id
    ```


  2. `grp3_instacart_dim_departments.sql` -> departments dimension

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='department_id') }}

    select
        cast(department_id as integer) as department_id,
        trim(department) as department_name
    from {{ ref('stg_grp3_instacart_departments') }}
    ```


  3. `grp3_instacart_dim_products.sql` -> products dimension

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='product_id') }}

    select
        cast(p.product_id as integer) as product_id,
        trim(p.product_name) as product_name,
        cast(p.aisle_id as integer) as aisle_id,
        a.department_id as department_id
    from {{ ref('stg_nrml_grp3_instacart_product_details') }} as p
    left join {{ ref('grp3_instacart_dim_aisles') }} as a
        on p.aisle_id = a.aisle_id
    ```

  4. `grp3_instacart_dim_time.sql` -> time dimension

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='tuple()') }}

    select 
        cast(row_number() over () as integer) as time_id,
        cast(order_dow as integer) as order_dow,
        case 
            when order_dow = 0 then 'sunday'
            when order_dow = 1 then 'monday'
            when order_dow = 2 then 'tuesday'
            when order_dow = 3 then 'wednesday'
            when order_dow = 4 then 'thursday'
            when order_dow = 5 then 'friday'
            when order_dow = 6 then 'saturday'
            else 'unknown'
        end as day_name,
        cast(order_hour_of_day as integer) as order_hour_of_day,
        case 
            when order_hour_of_day between 0 and 5 then 'late night'
            when order_hour_of_day between 6 and 11 then 'morning'
            when order_hour_of_day between 12 and 17 then 'afternoon'
            when order_hour_of_day between 18 and 21 then 'evening'
            else 'late night'
        end as time_of_day,
        case when order_dow in (0, 6) then 1 else 0 end as is_weekend
    from (
        select distinct
            order_dow,
            order_hour_of_day
        from {{ ref('stg_nrml_grp3_instacart_order_details') }}
        where order_dow is not null
    )
    ```

  5. `grp3_instacart_dim_users.sql` -> users dimension

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='tuple()') }}

    with user_metrics as (
        select 
            user_id,
            count(distinct order_id) as total_orders,
            round(avg(days_since_prior_order), 2) as avg_days_between_orders
        from {{ ref('stg_nrml_grp3_instacart_order_details') }}
        where eval_set = 'prior'
        group by user_id
    ),
    user_products as (
        select 
            o.user_id,
            count(*) as total_products_ordered,
            count(distinct op.product_id) as unique_products_ordered,
            sum(op.reordered) as total_reorders
        from {{ ref('stg_nrml_grp3_instacart_order_details') }} as o
        inner join {{ ref('stg_grp3_instacart_order_products_prior') }} as op
            on o.order_id = op.order_id
        group by o.user_id
    )
    select 
        um.user_id,
        um.total_orders,
        um.avg_days_between_orders,
        coalesce(up.total_products_ordered, 0) as total_products_ordered,
        coalesce(up.unique_products_ordered, 0) as unique_products_ordered,
        round(
            coalesce(up.total_products_ordered, 0) * 1.0 / nullif(um.total_orders, 0),
            2
        ) as avg_basket_size,
        case 
            when um.total_orders >= 50 then 'high frequency'
            when um.total_orders >= 20 then 'medium frequency'
            when um.total_orders >= 10 then 'regular'
            else 'low frequency'
        end as customer_segment,
        case 
            when coalesce(up.total_reorders, 0) * 1.0 / nullif(up.total_products_ordered, 0) >= 0.7 then 'very loyal'
            when coalesce(up.total_reorders, 0) * 1.0 / nullif(up.total_products_ordered, 0) >= 0.5 then 'loyal'
            when coalesce(up.total_reorders, 0) * 1.0 / nullif(up.total_products_ordered, 0) >= 0.3 then 'moderate'
            else 'exploratory'
        end as loyalty_tier
    from user_metrics as um
    left join user_products as up
        on um.user_id = up.user_id
    ```
  ---
  #### B. Fact Tables
  1. `grp3_instacart_fact_order_products.sql` -> fact order products

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='order_id') }}

    select
        cast(op.order_id as integer) as order_id,
        p.product_id as product_id,
        p.aisle_id as aisle_id,
        p.department_id as department_id,
        u.user_id as user_id,
        t.time_id as time_id,
        cast(op.add_to_cart_order as integer) as add_to_cart_order,
        cast(op.reordered as integer) as reordered
    from (
        select * from {{ ref('stg_grp3_instacart_order_products_prior') }}
        union all
        select * from {{ ref('stg_grp3_instacart_order_products_train') }}
    ) as op
    left join {{ ref('grp3_instacart_dim_products') }} as p
        on op.product_id = p.product_id
    left join {{ ref('stg_nrml_grp3_instacart_order_details') }} as od
        on op.order_id = od.order_id
    left join {{ ref('grp3_instacart_dim_users') }} as u
        on od.user_id = u.user_id
    left join {{ ref('grp3_instacart_dim_time') }} as t
        on od.order_dow = t.order_dow
      and od.order_hour_of_day = t.order_hour_of_day
    ```


  2. `grp3_instacart_fact_orders.sql` -> fact orders

    ```sql
    {{ config(materialized='table', schema='mart', engine='mergetree()', order_by='order_id') }}

    select
        cast(o.order_id as integer) as order_id,
        u.user_id as user_id,
        t.time_id as time_id,
        cast(n.order_number as integer) as order_number,
        trim(o.eval_set) as eval_set,
        o.days_since_prior_order as days_since_prior_order
    from {{ ref('stg_nrml_grp3_instacart_order_details') }} as o
    left join {{ ref('stg_nrml_grp3_instacart_order_number') }} as n
        on o.order_id = n.order_id
    left join {{ ref('grp3_instacart_dim_users') }} as u
        on o.user_id = u.user_id
    left join {{ ref('grp3_instacart_dim_time') }} as t
        on o.order_dow = t.order_dow
      and o.order_hour_of_day = t.order_hour_of_day
    ```


* **Challenges / Tradeoffs:**

  * Handling missing `days_since_prior_order` values
  * Ensuring key consistency between `order_products_prior` and `order_products_train`
  * Creating correct primary/foreign key mappings in ClickHouse via dbt
  * Normalizing redundant user and order-level data for clean joins



## 4. Data Quality Checking

In our group, we implemented **two types of data quality checks**:

1. **`schema.yml` tests** — *automated dbt-native checks*

   * Focused on **constraints** like:

     * `not_null`
     * `unique`
     * `relationships`
   * Great for enforcing model-level data integrity.

2. **`_data_sanity_check.sql` files** — *manual analytical checks*

   * SQL models that summarize DQ metrics in a table
   * Provide **counts**, **descriptions**, and **PASS/FAIL** statuses
   * Ideal for **Metabase dashboards** and ongoing DQ monitoring.

---

### 1. Schema YAML Quality Check

- 📂 [Clean Schema YML - Group Github Repository](https://github.com/margo-py/ftw-instacart-dataset-grp3/blob/main/dbt/transforms/instacart/models/clean/schema.yml)
- 📂 [Mart Schema YML - Group Github Repository](https://github.com/margo-py/ftw-instacart-dataset-grp3/blob/main/dbt/transforms/instacart/models/mart/schema.yml)



### 2. SQL Manual Sanity Check

#### **1️⃣ RAW Layer – `stg_grp3_data_sanity_check.sql`**

* **Purpose:** Verify raw source files are complete and correctly loaded.
* **Checks done:**

  * Row count per source table
  * Null or blank key fields (IDs, names)
  * Duplicate row detection
  * Uniqueness of primary keys (`aisle_id`, `product_id`, etc.)

---

#### **2️⃣ CLEAN Layer – Staging & Normalized Models**

* **Purpose:** Ensure transformation consistency before loading to mart.
* **Checks done:**

  * Data type conversions are valid
  * Foreign key mappings (aisle → department, orders → users)
  * Removed invalid or duplicate records
  * Structural and referential integrity validation

---

#### **3️⃣ MART Layer – `grp3_instacart_data_sanity_check.sql`**

* **Purpose:** Validate final analytical tables for accuracy and relationships.
* **Checks done:**

  * `not_null`, `unique`, and `relationship` tests for all dims/facts
  * Domain validation (`reordered` only 0 or 1)
  * PASS/FAIL summary for quick monitoring
  * Referential integrity verification across all dimensions




---

## 5. Collaboration & Setup

* **Task Splitting:**

  All team members were collaboratively in charge of supporting each other across all tasks — from data cleaning and modeling to documentation and visualization. 
  
  Coordination was done through two scheduled meetings every Tuesday and Thursday on Slack, along with follow-up huddles, chat sessions, and continuous updates in the shared repository and Google Docs. Communication and progress tracking were maintained through the main Slack channel to ensure alignment and transparency.

* **Shared vs Local Work:**
  Each member worked on local dbt branches, pushed commits to GitHub, and merged updates after cleaning validation.
  Used Slack for async collaboration and meeting coordination.

* **Best Practices Learned:**

  * Commit frequently and pull before push to avoid conflicts
  * Use consistent naming conventions (`stg_`, `fact_`, `dim_`)
  * Define schema.yml and sources.yml for better lineage in dbt docs
  * Test and document every dbt model layer

---

## 6. Business Questions & Insights

* **Business Questions Explored:**

  1. What are the most frequently reordered products?
  2. Which departments or aisles have the highest reorder ratio?
  3. What is the average reorder frequency per customer?
  4. What time of day and day of week are most orders placed?

* **Dashboards / Queries:**

  * Built interactive dashboards in **Metabase** connected to the ClickHouse mart layer
  * Aggregated data from fact tables to show purchase trends by time, product, and user behavior

* **Key Insights:**

  * Majority of orders occur during weekdays, peaking in late afternoons
  * Specific aisles (produce, dairy) show high reorder ratios
  * Repeat customers represent a large share of total orders

---

## 7. Key Learnings

* **Technical Learnings:**

  * dbt project structure and schema testing
  * YAML-driven documentation and tests
  * Basic ClickHouse–dbt integration setup
  * Use of `dbt docs generate` for automated documentation

* **Team Learnings:**

  * Effective collaboration using GitHub and Slack
  * Version control and multi-environment workflow management
  * Clarity gained from consistent model naming and modular SQL

* **Real-World Connection:**
  Mirrors how real data teams maintain layered data warehouses with CI/CD and documentation standards using dbt, Airflow, and BI tools.

---

## 8. Future Improvements

* **Next Steps with More Time:**

  * Add orchestration using Airflow or Prefect
  * Include data validation via `Great Expectations` -> This is something we discovered where we can check here more advanced data validations (ranges, thresholds, null ratios, value patterns).
  * Automate nightly ETL runs
  * Expand dashboards to include product affinity and retention analytics

* **Generalization:**

  * The same workflow can be applied to e-commerce, retail, or supply chain datasets following the medallion (raw-clean-mart) architecture.

---

## 📚 Reference Links

* 📊 **Datasource:** [Kaggle – Instacart Market Basket Analysis](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis)
* 📖 **Data Dictionary:** [RPubs – Instacart8](https://rpubs.com/yongks/instacart8)
* 🧱 **DBT Documentation Guide:** [DBT-TEST-DOC-GRP3.md](https://github.com/margo-py/ftw-instacart-dataset-grp3/blob/main/DBT-TEST-DOC-GRP3.md)
* 🧰 **Tools Used:** `dbt`, `dlt`, `DBeaver`, `dbdiagram`, `Metabase`, `Docker`, `GitHub`

