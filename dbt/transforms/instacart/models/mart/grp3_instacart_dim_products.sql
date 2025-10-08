{{ config(materialized="table", schema="mart") }}

SELECT 
    CAST(p.product_id AS integer) AS product_id,
    p.product_name,
    CAST(p.aisle_id AS integer) AS aisle_id,
    CAST(p.department_id AS integer) AS department_id
FROM {{ ref('stg_grp3_instacart_products') }} p