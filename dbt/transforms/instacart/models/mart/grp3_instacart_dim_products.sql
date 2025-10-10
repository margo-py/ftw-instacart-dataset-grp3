-- {{ config(materialized="table", schema="mart") }}

-- SELECT 
--     CAST(p.product_id AS integer) AS product_id,
--     p.product_name,
--     CAST(p.aisle_id AS integer) AS aisle_id,
--     CAST(p.department_id AS integer) AS department_id
-- FROM {{ ref('stg_grp3_instacart_products') }} p
{{ config(materialized='table', schema='mart', engine='mergetree()', order_by='product_id') }}

select
    cast(p.product_id as integer) as product_id,
    trim(p.product_name) as product_name,
    cast(p.aisle_id as integer) as aisle_id,
    a.department_id as department_id
from {{ ref('stg_nrml_grp3_instacart_product_details') }} as p
left join {{ ref('grp3_instacart_dim_aisles') }} as a
    on p.aisle_id = a.aisle_id

