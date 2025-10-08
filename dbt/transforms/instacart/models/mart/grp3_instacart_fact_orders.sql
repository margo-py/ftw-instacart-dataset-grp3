{{ config(materialized="table", schema="mart") }}

WITH order_items AS (
    SELECT 
        order_id,
        COUNT(*) AS total_items
    FROM {{ ref('stg_grp3_instacart_order_products_prior') }}
    GROUP BY order_id
    
    UNION ALL
    
    SELECT 
        order_id,
        COUNT(*) AS total_items
    FROM {{ ref('stg_grp3_instacart_order_products_train') }}
    GROUP BY order_id
)

SELECT 
    o.order_id,
    o.user_id,
    (o.order_dow * 100 + o.order_hour_of_day) AS time_id,
    o.order_number,
    o.days_since_prior_order,
    COALESCE(oi.total_items, 0) AS total_items
FROM {{ ref('stg_grp3_instacart_orders') }} o
LEFT JOIN order_items oi ON o.order_id = oi.order_id