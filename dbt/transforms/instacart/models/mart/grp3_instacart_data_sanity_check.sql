{{ config(
    materialized='table',
    schema='mart',
    order_by=['table_name', 'check_name']
) }}

-- =======================================================
--  MART DATA SANITY CHECK
--  Mirrors schema.yml tests + adds PASS/FAIL column
-- =======================================================

-- ========== DIM USERS ==========
with dq_dim_users as (
    select 'grp3_instacart_dim_users' as table_name, 'user_id_not_null' as check_name, 1 as is_critical,
           toFloat64(countIf(user_id is null)) as metric_value,
           'Detects null user_id values' as description
    from {{ ref('grp3_instacart_dim_users') }}
    union all
    select 'grp3_instacart_dim_users', 'user_id_unique', 1,
           toFloat64(count(distinct user_id)) as metric_value,
           'Ensures unique user_id values'
    from {{ ref('grp3_instacart_dim_users') }}
),

-- ========== DIM PRODUCTS ==========
dq_dim_products as (
    select 'grp3_instacart_dim_products' as table_name, 'product_id_not_null', 1,
           toFloat64(countIf(product_id is null)), 'Detects null product_id values'
    from {{ ref('grp3_instacart_dim_products') }}
    union all
    select 'grp3_instacart_dim_products', 'product_id_unique', 1,
           toFloat64(count(distinct product_id)), 'Ensures unique product_id values'
    from {{ ref('grp3_instacart_dim_products') }}
    union all
    select 'grp3_instacart_dim_products', 'aisle_id_not_null', 1,
           toFloat64(countIf(aisle_id is null)), 'Detects missing aisle_id references'
    from {{ ref('grp3_instacart_dim_products') }}
    union all
    select 'grp3_instacart_dim_products', 'department_id_not_null', 1,
           toFloat64(countIf(department_id is null)), 'Detects missing department_id references'
    from {{ ref('grp3_instacart_dim_products') }}
),

-- ========== DIM AISLES ==========
dq_dim_aisles as (
    select 'grp3_instacart_dim_aisles' as table_name, 'aisle_id_not_null', 1,
           toFloat64(countIf(aisle_id is null)), 'Detects null aisle_id values'
    from {{ ref('grp3_instacart_dim_aisles') }}
    union all
    select 'grp3_instacart_dim_aisles', 'aisle_id_unique', 1,
           toFloat64(count(distinct aisle_id)), 'Ensures unique aisle_id values'
    from {{ ref('grp3_instacart_dim_aisles') }}
),

-- ========== DIM DEPARTMENTS ==========
dq_dim_departments as (
    select 'grp3_instacart_dim_departments' as table_name, 'department_id_not_null', 1,
           toFloat64(countIf(department_id is null)), 'Detects null department_id values'
    from {{ ref('grp3_instacart_dim_departments') }}
    union all
    select 'grp3_instacart_dim_departments', 'department_id_unique', 1,
           toFloat64(count(distinct department_id)), 'Ensures unique department_id values'
    from {{ ref('grp3_instacart_dim_departments') }}
),

-- ========== DIM TIME ==========
dq_dim_time as (
    select 'grp3_instacart_dim_time' as table_name, 'time_id_not_null', 1,
           toFloat64(countIf(time_id is null)), 'Detects null time_id values'
    from {{ ref('grp3_instacart_dim_time') }}
    union all
    select 'grp3_instacart_dim_time', 'time_id_unique', 1,
           toFloat64(count(distinct time_id)), 'Ensures unique time_id values'
    from {{ ref('grp3_instacart_dim_time') }}
    union all
    select 'grp3_instacart_dim_time', 'order_hour_of_day_not_null', 1,
           toFloat64(countIf(order_hour_of_day is null)), 'Detects null order_hour_of_day values'
    from {{ ref('grp3_instacart_dim_time') }}
    union all
    select 'grp3_instacart_dim_time', 'order_dow_not_null', 1,
           toFloat64(countIf(order_dow is null)), 'Detects null order_dow values'
    from {{ ref('grp3_instacart_dim_time') }}
),

-- ========== FACT ORDERS ==========
dq_fact_orders as (
    select 'grp3_instacart_fact_orders' as table_name, 'order_id_not_null', 1,
           toFloat64(countIf(order_id is null)), 'Detects null order_id values'
    from {{ ref('grp3_instacart_fact_orders') }}
    union all
    select 'grp3_instacart_fact_orders', 'order_id_unique', 1,
           toFloat64(count(distinct order_id)), 'Ensures unique order_id values'
    from {{ ref('grp3_instacart_fact_orders') }}
    union all
    select 'grp3_instacart_fact_orders', 'user_id_not_null', 1,
           toFloat64(countIf(user_id is null)), 'Detects null user_id values'
    from {{ ref('grp3_instacart_fact_orders') }}
    union all
    select 'grp3_instacart_fact_orders', 'time_id_not_null', 1,
           toFloat64(countIf(time_id is null)), 'Detects null time_id values'
    from {{ ref('grp3_instacart_fact_orders') }}
),

-- ========== FACT ORDER PRODUCTS ==========
dq_fact_order_products as (
    select 'grp3_instacart_fact_order_products' as table_name, 'order_id_not_null', 1,
           toFloat64(countIf(order_id is null)), 'Detects null order_id values'
    from {{ ref('grp3_instacart_fact_order_products') }}
    union all
    select 'grp3_instacart_fact_order_products', 'product_id_not_null', 1,
           toFloat64(countIf(product_id is null)), 'Detects null product_id values'
    from {{ ref('grp3_instacart_fact_order_products') }}
    union all
    select 'grp3_instacart_fact_order_products', 'reordered_domain_check', 1,
           toFloat64(countIf(reordered not in (0,1))), 'Ensures reordered values only 0 or 1'
    from {{ ref('grp3_instacart_fact_order_products') }}
)

-- ========== COMBINE & ADD STATUS ==========
select
    table_name,
    check_name,
    is_critical,
    metric_value,
    description,
    case
        when check_name like '%unique%' and metric_value > 0 then 'PASS'
        when check_name like '%not_null%' and metric_value = 0 then 'PASS'
        when check_name like '%domain_check%' and metric_value = 0 then 'PASS'
        else 'FAIL'
    end as status
from (
    select * from dq_dim_users
    union all select * from dq_dim_products
    union all select * from dq_dim_aisles
    union all select * from dq_dim_departments
    union all select * from dq_dim_time
    union all select * from dq_fact_orders
    union all select * from dq_fact_order_products
)
