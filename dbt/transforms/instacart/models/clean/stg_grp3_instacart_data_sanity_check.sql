{{ config(
    materialized='table',
    schema='clean',
    order_by=['table_name', 'check_name']
) }}

with dq_aisles as (
    select 'raw___insta_aisles' as table_name, 'aisles_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in aisles' as description
    from {{ source('raw', 'raw___insta_aisles') }}
    union all
    select 'raw___insta_aisles', 'aisle_id_uniqueness', 1, toFloat64(count(distinct toInt64OrNull(aisle_id))),
           'Ensures each aisle_id is unique'
    from {{ source('raw', 'raw___insta_aisles') }}
    union all
    select 'raw___insta_aisles', 'aisle_name_missing', 1, toFloat64(count(*)), 'Detects missing or blank aisle names'
    from {{ source('raw', 'raw___insta_aisles') }} where aisle is null or trim(aisle)=''
    union all
    select 'raw___insta_aisles', 'aisle_row_duplicates', 1, toFloat64(count(*) - count(distinct (aisle_id, aisle))),
           'Checks for duplicate rows'
    from {{ source('raw', 'raw___insta_aisles') }}
),

dq_products as (
    select 'raw___insta_products' as table_name, 'products_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in products' as description
    from {{ source('raw', 'raw___insta_products') }}
    union all
    select 'raw___insta_products', 'product_id_uniqueness', 1, toFloat64(count(distinct toInt64OrNull(product_id))),
           'Ensures each product_id is unique'
    from {{ source('raw', 'raw___insta_products') }}
    union all
    select 'raw___insta_products', 'critical_field_completeness', 1, toFloat64(count(*)),
           'Missing product_name, aisle_id, or department_id'
    from {{ source('raw', 'raw___insta_products') }}
    where product_name is null or trim(product_name)='' or aisle_id is null or department_id is null
),

dq_orders as (
    select 'raw___insta_orders' as table_name, 'orders_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in orders' as description
    from {{ source('raw', 'raw___insta_orders') }}
    union all
    select 'raw___insta_orders', 'order_id_uniqueness', 1, toFloat64(count(distinct toInt64OrNull(order_id))),
           'Ensures order_id values are unique'
    from {{ source('raw', 'raw___insta_orders') }}
),

dq_departments as (
    select 'raw___insta_departments' as table_name, 'departments_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in departments' as description
    from {{ source('raw', 'raw___insta_departments') }}
    union all
    select 'raw___insta_departments', 'department_id_uniqueness', 1,
           toFloat64(count(distinct toInt64OrNull(department_id))), 'Ensures each department_id is unique'
    from {{ source('raw', 'raw___insta_departments') }}
),

dq_order_products_prior as (
    select 'raw___insta_order_products_prior' as table_name, 'order_products_prior_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in prior order_products' as description
    from {{ source('raw', 'raw___insta_order_products_prior') }}
),

dq_order_products_train as (
    select 'raw___insta_order_products_train' as table_name, 'order_products_train_volume_check' as check_name, 0 as is_critical,
           toFloat64(count(*)) as metric_value, 'Total row count in train order_products' as description
    from {{ source('raw', 'raw___insta_order_products_train') }}
)

select * from dq_aisles
union all select * from dq_products
union all select * from dq_orders
union all select * from dq_departments
union all select * from dq_order_products_prior
union all select * from dq_order_products_train
