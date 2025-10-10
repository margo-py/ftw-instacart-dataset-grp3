-- {{ config(materialized="table", schema="mart") }}

-- SELECT 
--     aisle_id,
--     aisle AS aisle_name
-- FROM {{ ref('stg_grp3_instacart_aisles') }}
{{ config(materialized='table', schema='mart', order_by='aisle_id') }}

select
    cast(a.aisle_id as integer) as aisle_id,
    trim(a.aisle) as aisle_name,
    cast(ad.department_id as integer) as department_id
from {{ ref('stg_grp3_instacart_aisles') }} as a
left join {{ ref('stg_nrml_grp3_instacart_aisle_dept_map') }} as ad
    on a.aisle_id = ad.aisle_id