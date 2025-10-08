{{ config(materialized="table", schema="mart") }}

WITH combined_order_products AS (
    SELECT 
        order_id,
        product_id,
        add_to_cart_order,
        reordered
    FROM {{ ref('stg_grp3_instacart_order_products_prior') }}
    
    UNION ALL
    
    SELECT 
        order_id,
        product_id,
        add_to_cart_order,
        reordered
    FROM {{ ref('stg_grp3_instacart_order_products_train') }}
)

SELECT 
    concat(toString(op.order_id), '_', toString(op.product_id)) AS order_product_id,
    op.order_id,
    op.product_id,
    op.add_to_cart_order,
    op.reordered AS is_reordered,
    1 AS quantity
FROM combined_order_products op