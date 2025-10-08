{{ config(materialized="table", schema="mart") }}

SELECT 
    department_id,
    department AS department_name
FROM {{ ref('stg_grp3_instacart_departments') }}