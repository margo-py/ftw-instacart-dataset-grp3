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
   
-- {{ config(materialized="table", schema="mart") }}

-- WITH order_items AS (
--     SELECT 
--         order_id,
--         COUNT(*) AS total_items
--     FROM {{ ref('stg_grp3_instacart_order_products_prior') }}
--     GROUP BY order_id
    
--     UNION ALL
    
--     SELECT 
--         order_id,
--         COUNT(*) AS total_items
--     FROM {{ ref('stg_grp3_instacart_order_products_train') }}
--     GROUP BY order_id
-- )

-- SELECT 
--     o.order_id,
--     o.user_id,
--     (o.order_dow * 100 + o.order_hour_of_day) AS time_id,
--     o.order_number,
--     o.days_since_prior_order,
--     COALESCE(oi.total_items, 0) AS total_items
-- FROM {{ ref('stg_grp3_instacart_orders') }} o
-- LEFT JOIN order_items oi ON o.order_id = oi.order_id