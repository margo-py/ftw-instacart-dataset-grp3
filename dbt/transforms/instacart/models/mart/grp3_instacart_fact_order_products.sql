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


-- {{ config(materialized="table", schema="mart") }}

-- WITH combined_order_products AS (
--     SELECT 
--         order_id,
--         product_id,
--         add_to_cart_order,
--         reordered
--     FROM {{ ref('stg_grp3_instacart_order_products_prior') }}
    
--     UNION ALL
    
--     SELECT 
--         order_id,
--         product_id,
--         add_to_cart_order,
--         reordered
--     FROM {{ ref('stg_grp3_instacart_order_products_train') }}
-- )

-- SELECT 
--     concat(toString(op.order_id), '_', toString(op.product_id)) AS order_product_id,
--     op.order_id,
--     op.product_id,
--     op.add_to_cart_order,
--     op.reordered AS is_reordered,
--     1 AS quantity
-- FROM combined_order_products op