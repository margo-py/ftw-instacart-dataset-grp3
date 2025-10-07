{{ config(materialized="table", schema="clean") }}

with source as (
    select 
        cast(department_id as integer) as department_id,
        cast(department as varchar) as department
    from {{ source('raw', 'raw___insta_departments') }}
),

cleaned as (
    select
        department_id,
        trim(lower(department)) as department
    from source
    where department_id is not null
      and department is not null
)

select * from cleaned
