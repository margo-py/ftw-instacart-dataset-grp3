

# 📝 Instacart Dataset Group 3

## 1. Project Overview

* **Dataset Used:**
  [Instacart Market Basket Analysis (Kaggle)](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis)
  The dataset contains anonymized customer orders, products, aisles, and departments from Instacart’s online grocery platform.

* **Goal of the Exercise:**
  Transform the normalized Instacart dataset (OLTP-style) into a **dimensional star schema** for analytics — applying dbt for data cleaning, modeling, and testing, and generating documentation for BI use.

* **Team Setup:**
  Group 3 — collaborative setup, with members **Mikay**, **Royce**, **Pau**, **Marj**, and **Bianca**.
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

  * **Fact Tables:**

    * `grp3_instacart_fact_orders`
    * `grp3_instacart_fact_order_products`
  * **Dimension Tables:**

    * `grp3_instacart_dim_users`
    * `grp3_instacart_dim_products`
    * `grp3_instacart_dim_aisles`
    * `grp3_instacart_dim_departments`
    * `grp3_instacart_dim_time`

* **Challenges / Tradeoffs:**

  * Handling missing `days_since_prior_order` values
  * Ensuring key consistency between `order_products_prior` and `order_products_train`
  * Creating correct primary/foreign key mappings in ClickHouse via dbt
  * Normalizing redundant user and order-level data for clean joins

---

## 4. Collaboration & Setup

* **Task Splitting:**

  * Mikay — Coordination, data cleaning, dbt documentation setup
  * Royce — Fact & dimension modeling, data testing integration
  * Pau — Data cleaning & validation
  * Marj — Schema review & Metabase visualization
  * Bianca — Table cleaning and joins for product dimension

* **Shared vs Local Work:**
  Each member worked on local dbt branches, pushed commits to GitHub, and merged updates after cleaning validation.
  Used Slack for async collaboration and meeting coordination.

* **Best Practices Learned:**

  * Commit frequently and pull before push to avoid conflicts
  * Use consistent naming conventions (`stg_`, `fact_`, `dim_`)
  * Define schema.yml and sources.yml for better lineage in dbt docs
  * Test and document every dbt model layer

---

## 5. Business Questions & Insights

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

## 6. Key Learnings

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

## 7. Future Improvements

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

