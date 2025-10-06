{{ config(materialized="view", schema="mart") }}

-- Inputs:
--   raw table:   raw.autompg___cars           (as loaded by dlt)
--   clean model: {{ ref('mpg_standardized') }} (typed/trimmed)

with src as (
  select * from {{ source('raw','autompg___cars') }}
),
cln as (
  select * from {{ ref('mpg_standardized') }}
),

counts as (
  select
    (select count() from src)  as row_count_raw,
    (select count() from cln)  as row_count_clean
),
nulls as (
  select
    round(100.0 * countIf(horsepower is null) / nullif(count(),0), 2) as pct_null_horsepower
  from cln
),
domains as (
  select
    -- cylinders domain: {3,4,5,6,8}
    countIf(cylinders not in (3,4,5,6,8)) as invalid_cylinders,
    -- origin domain: {"usa","europe","japan"} (case-insensitive trim assumed in clean)
    countIf(lower(origin) not in ('usa','europe','japan')) as invalid_origin
  from cln
),
bounds as (
  select
    countIf(mpg <= 0)           as nonpositive_mpg,
    countIf(displacement <= 0)  as nonpositive_displacement,
    countIf(weight <= 0)        as nonpositive_weight,
    countIf(acceleration <= 0)  as nonpositive_acceleration,
    -- UCI Auto MPG years are 70..82 (1970..1982) in this dataset
    countIf(model_year < 70 or model_year > 82) as out_of_range_model_year
  from cln
),
joined as (
  select
    counts.row_count_raw,
    counts.row_count_clean,
    (counts.row_count_raw - counts.row_count_clean) as dropped_rows,

    nulls.pct_null_horsepower,

    domains.invalid_cylinders,
    domains.invalid_origin,

    bounds.nonpositive_mpg,
    bounds.nonpositive_displacement,
    bounds.nonpositive_weight,
    bounds.nonpositive_acceleration,
    bounds.out_of_range_model_year
  from counts
  cross join nulls
  cross join domains
  cross join bounds
)

select * from joined
