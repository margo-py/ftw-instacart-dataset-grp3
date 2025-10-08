{{ config(materialized="table", schema="mart") }}

SELECT 
    aisle_id,
    aisle AS aisle_name
FROM {{ ref('stg_grp3_instacart_aisles') }}