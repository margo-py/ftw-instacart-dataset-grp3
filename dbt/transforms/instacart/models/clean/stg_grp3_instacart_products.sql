{{ config(materialized="table", schema="clean") }}

WITH source_data AS (
    SELECT 
        product_id,
        product_name,
        aisle_id,
        department_id
    FROM {{ source('raw', 'raw___insta_products') }}
),

cleaned AS (
    SELECT 

        TRIM(product_id) AS product_id,
        
        TRIM(product_name) AS product_name,
        
        TRIM(aisle_id) AS aisle_id,
        TRIM(department_id) AS department_id,
        
        now() AS cleaned_at
        
    FROM source_data
    WHERE 

        product_id IS NOT NULL 
        AND TRIM(product_id) != ''
        AND product_name IS NOT NULL
        AND TRIM(product_name) != ''
)

SELECT * FROM cleaned