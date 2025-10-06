{{ config(materialized="table", schema="clean") }}

with source as (
    select 
        cast(aisle_id as integer) as aisle_id,
        cast(aisle as varchar) as aisle
    from {{ source('raw', 'raw___insta_aisles') }}
),

cleaned as (
    select
        aisle_id,
        aisle
    from source
    where aisle_id is not null
      and aisle is not null
)

select * from cleaned
