{{ config(materialized='table', schema='mart', order_by='tuple()') }}

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

-- {{ config(materialized="table", schema="mart") }}

-- WITH user_metrics AS (
--     SELECT 
--         user_id,
--         COUNT(DISTINCT order_id) AS total_orders,
--         AVG(days_since_prior_order) AS avg_days_between_orders
--     FROM {{ ref('stg_grp3_instacart_orders') }}
--     WHERE eval_set = 'prior'
--     GROUP BY user_id
-- ),

-- user_products AS (
--     SELECT 
--         o.user_id,
--         COUNT(*) AS total_products,
--         COUNT(DISTINCT op.product_id) AS unique_products,
--         SUM(op.reordered) AS total_reorders
--     FROM {{ ref('stg_grp3_instacart_orders') }} o
--     INNER JOIN {{ ref('stg_grp3_instacart_order_products_prior') }} op
--         ON o.order_id = op.order_id
--     GROUP BY o.user_id
-- )

-- SELECT 
--     um.user_id,
--     um.total_orders,
--     ROUND(um.avg_days_between_orders, 2) AS avg_days_between_orders,
--     COALESCE(up.total_products, 0) AS total_products_ordered,
--     COALESCE(up.unique_products, 0) AS unique_products_ordered,
--     ROUND(COALESCE(up.total_products, 0) * 1.0 / NULLIF(um.total_orders, 0), 2) AS avg_basket_size,
    
--     -- Customer segment
--     CASE 
--         WHEN um.total_orders >= 50 THEN 'High Frequency'
--         WHEN um.total_orders >= 20 THEN 'Medium Frequency'
--         WHEN um.total_orders >= 10 THEN 'Regular'
--         ELSE 'Low Frequency'
--     END AS customer_segment,
    
--     -- Loyalty tier
--     CASE 
--         WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.7 THEN 'Very Loyal'
--         WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.5 THEN 'Loyal'
--         WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.3 THEN 'Moderate'
--         ELSE 'Exploratory'
--     END AS loyalty_tier
    
-- FROM user_metrics um
-- LEFT JOIN user_products up ON um.user_id = up.user_id