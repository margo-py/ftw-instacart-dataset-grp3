Perfect 👌 — here’s your fully **updated and polished project documentation draft** that combines everything your group has done so far, includes your real dataset, tools, Slack collaboration story, and links.
You can copy this directly into your repo as `README.md` or `PROJECT-DOC-GRP3.md`.

---

# 📝 Instacart Dataset Group 3

## 1. Project Overview

* **Dataset Used:**
  [Instacart Market Basket Analysis (Kaggle)](https://www.kaggle.com/datasets/psparks/instacart-market-basket-analysis)
  The dataset contains anonymized customer orders, products, aisles, and departments from Instacart’s online grocery platform.

* **Goal of the Exercise:**
  Transform the normalized Instacart dataset (OLTP-style) into a **dimensional star schema** for analytics — applying dbt for data cleaning, modeling, and testing, and generating documentation for BI use.

* **Team Setup:**
  Group 3 — collaborative setup led by **@Mikay**, with members **Royce**, **Pau**, **Marj**, and **Bianca**.
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
  * Include data validation via Great Expectations or Soda
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

