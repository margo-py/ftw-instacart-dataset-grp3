{{ config(materialized="table", schema="clean") }}
with source as (
    select 
        cast(order_id as integer) as order_id,
        cast(product_id as integer) as product_id,
        cast(add_to_cart_order as integer) as add_to_cart_order,
        cast(reordered as integer) as reordered
    from {{ source('raw', 'raw___insta_order_products_prior') }}
),

cleaned as (
    select
        order_id,
        product_id,
        add_to_cart_order,
        reordered
    from source
    where order_id is not null
      and product_id is not null
)

select * from cleaned
