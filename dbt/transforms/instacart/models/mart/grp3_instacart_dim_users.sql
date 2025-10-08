{{ config(materialized="table", schema="mart") }}

WITH user_metrics AS (
    SELECT 
        user_id,
        COUNT(DISTINCT order_id) AS total_orders,
        AVG(days_since_prior_order) AS avg_days_between_orders
    FROM {{ ref('stg_grp3_instacart_orders') }}
    WHERE eval_set = 'prior'
    GROUP BY user_id
),

user_products AS (
    SELECT 
        o.user_id,
        COUNT(*) AS total_products,
        COUNT(DISTINCT op.product_id) AS unique_products,
        SUM(op.reordered) AS total_reorders
    FROM {{ ref('stg_grp3_instacart_orders') }} o
    INNER JOIN {{ ref('stg_grp3_instacart_order_products_prior') }} op
        ON o.order_id = op.order_id
    GROUP BY o.user_id
)

SELECT 
    um.user_id,
    um.total_orders,
    ROUND(um.avg_days_between_orders, 2) AS avg_days_between_orders,
    COALESCE(up.total_products, 0) AS total_products_ordered,
    COALESCE(up.unique_products, 0) AS unique_products_ordered,
    ROUND(COALESCE(up.total_products, 0) * 1.0 / NULLIF(um.total_orders, 0), 2) AS avg_basket_size,
    
    -- Customer segment
    CASE 
        WHEN um.total_orders >= 50 THEN 'High Frequency'
        WHEN um.total_orders >= 20 THEN 'Medium Frequency'
        WHEN um.total_orders >= 10 THEN 'Regular'
        ELSE 'Low Frequency'
    END AS customer_segment,
    
    -- Loyalty tier
    CASE 
        WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.7 THEN 'Very Loyal'
        WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.5 THEN 'Loyal'
        WHEN COALESCE(up.total_reorders, 0) * 1.0 / NULLIF(up.total_products, 0) >= 0.3 THEN 'Moderate'
        ELSE 'Exploratory'
    END AS loyalty_tier
    
FROM user_metrics um
LEFT JOIN user_products up ON um.user_id = up.user_id