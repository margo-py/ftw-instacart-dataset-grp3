{{ config(materialized="table", schema="clean") }}
with source as (
    select 
        cast(product_id as integer) as product_id,
        cast(aisle_id as integer) as aisle_id,
        cast(department_id as integer) as department_id,
        cast(product_name as varchar(64)) as product_name
    from {{ source('raw', 'raw___insta_products') }}
),

cleaned as (
    select
        product_id,
        lower(trim(product_name)) as product_name, --Easier to query if all lowercase
        aisle_id,
        department_id,

    from source
    where product_id is not null
      and product_name is not null
      and trim(product_name) != ''
)


select * from cleaned
