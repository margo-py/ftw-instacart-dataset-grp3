{{ config(materialized="table", schema="clean") }}

with aisle_dept_map as (
    select
        cast(aisle_id as Int32) as aisle_id,
        cast(department_id as Int32) as department_id
    from {{ ref('stg_grp3_instacart_products') }}
    group by
        aisle_id,
        department_id
),

aisles_with_multiple_departments as (
    select
        aisle_id,
        count(distinct department_id) as dept_count
    from {{ ref('stg_grp3_instacart_products') }}
    group by aisle_id
    having count(distinct department_id) > 1
)

select *
from aisle_dept_map
