-- {{ config(materialized="table", schema="mart") }}

-- SELECT 
--     department_id,
--     department AS department_name
-- FROM {{ ref('stg_grp3_instacart_departments') }}
{{ config(materialized='table', schema='mart', engine='mergetree()', order_by='department_id') }}

select
    cast(department_id as integer) as department_id,
    trim(department) as department_name
from {{ ref('stg_grp3_instacart_departments') }}