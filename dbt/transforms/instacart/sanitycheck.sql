DROP TABLE IF EXISTS raw.grp3_dq_sanity_checks;
CREATE TABLE raw.grp3_dq_sanity_checks 
(
    table_name String,
    check_name String,
    is_critical UInt8,
    metric_value Float64,
    description String
)
ENGINE = MergeTree
ORDER BY (table_name, check_name);
-- Aisles
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_aisles','aisles_volume_check',0,toFloat64(COUNT(*)),'Total row count in aisles'
FROM raw.raw___insta_aisles
UNION ALL
SELECT 'raw___insta_aisles','aisle_id_uniqueness',1,toFloat64(COUNT(DISTINCT toInt64OrNull(aisle_id))),'Ensures each aisle_id is unique'
FROM raw.raw___insta_aisles
UNION ALL
SELECT 'raw___insta_aisles','aisle_name_missing',1,toFloat64(COUNT(*)),'Detects missing or blank aisle names'
FROM raw.raw___insta_aisles WHERE aisle IS NULL OR TRIM(aisle)=''
UNION ALL
SELECT 'raw___insta_aisles','aisle_row_duplicates',1,toFloat64(COUNT(*) - COUNT(DISTINCT (aisle_id, aisle))),'Checks for duplicate rows'
FROM raw.raw___insta_aisles
UNION ALL
SELECT 'raw___insta_aisles','aisle_blank_string_names',0,toFloat64(COUNT(*)),'Counts blank string aisle names'
FROM raw.raw___insta_aisles WHERE TRIM(aisle)='';
-- Products
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_products','products_volume_check',0,toFloat64(COUNT(*)),'Total row count in products'
FROM raw.raw___insta_products
UNION ALL
SELECT 'raw___insta_products','product_id_uniqueness',1,toFloat64(COUNT(DISTINCT toInt64OrNull(product_id))),'Ensures each product_id is unique'
FROM raw.raw___insta_products
UNION ALL
SELECT 'raw___insta_products','critical_field_completeness',1,toFloat64(COUNT(*)),'Missing product_name, aisle_id, or department_id'
FROM raw.raw___insta_products WHERE product_name IS NULL OR TRIM(product_name)='' OR aisle_id IS NULL OR department_id IS NULL
UNION ALL
SELECT 'raw___insta_products','product_id_duplicates',1,toFloat64(COUNT(product_id) - COUNT(DISTINCT product_id)),'Detects duplicate product_id values'
FROM raw.raw___insta_products
UNION ALL
SELECT 'raw___insta_products','product_name_length_excess',1,toFloat64(COUNT(*)),'Product names longer than 512 characters'
FROM raw.raw___insta_products WHERE length(product_name) > 512
UNION ALL
SELECT 'raw___insta_products','missing_aisle_reference',1,toFloat64(COUNT(*)),'Products with aisle_id not present in aisles'
FROM raw.raw___insta_products p
LEFT JOIN raw.raw___insta_aisles a ON toInt64OrNull(p.aisle_id) = toInt64OrNull(a.aisle_id)
WHERE a.aisle_id IS NULL
UNION ALL
SELECT 'raw___insta_products','missing_department_reference',1,toFloat64(COUNT(*)),'Products with department_id not present in departments'
FROM raw.raw___insta_products p
LEFT JOIN raw.raw___insta_departments d ON toInt64OrNull(p.department_id) = toInt64OrNull(d.department_id)
WHERE d.department_id IS NULL
UNION ALL
SELECT 'raw___insta_products','null_percentage_product_name',1,
       (countIf(product_name IS NULL OR TRIM(product_name)='') * 100.0 / COUNT()), 
       'Percentage of null or blank product names'
FROM raw.raw___insta_products
UNION ALL
SELECT 'raw___insta_products','duplicate_product_names_multi_ids',0,toFloat64(COUNT(*)),'Product names assigned to multiple IDs'
FROM (
  SELECT product_name
  FROM raw.raw___insta_products
  GROUP BY product_name
  HAVING COUNT(DISTINCT product_id) > 1
);
-- Orders
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_orders','orders_volume_check',0,toFloat64(COUNT(*)),'Total row count in orders'
FROM raw.raw___insta_orders
UNION ALL
SELECT 'raw___insta_orders','order_id_uniqueness',1,toFloat64(COUNT(DISTINCT toInt64OrNull(order_id))),'Ensures order_id values are unique'
FROM raw.raw___insta_orders
UNION ALL
SELECT 'raw___insta_orders','order_number_threshold_check',1,toFloat64(MAX(toInt32OrNull(order_number))),'Validates max order_number within limit'
FROM raw.raw___insta_orders
UNION ALL
SELECT 'raw___insta_orders','dow_value_range',1,toFloat64(COUNT(*)),'Invalid day-of-week values outside 0–6'
FROM raw.raw___insta_orders WHERE toInt32OrNull(order_dow) NOT BETWEEN 0 AND 6
UNION ALL
SELECT 'raw___insta_orders','hour_value_range',1,toFloat64(COUNT(*)),'Invalid order hours outside 0–23'
FROM raw.raw___insta_orders WHERE toInt32OrNull(order_hour_of_day) NOT BETWEEN 0 AND 23
UNION ALL
SELECT 'raw___insta_orders','days_since_prior_nulls',1,toFloat64(COUNT(*)),'Null days_since_prior_order values'
FROM raw.raw___insta_orders WHERE days_since_prior_order IS NULL
UNION ALL
SELECT 'raw___insta_orders','user_id_reference_check',1,toFloat64(COUNT(*)),'Orders with missing or blank user_id'
FROM raw.raw___insta_orders WHERE user_id IS NULL OR TRIM(user_id)=''
UNION ALL
SELECT 'raw___insta_orders','null_percentage_order_dow',1,
       (countIf(order_dow IS NULL OR TRIM(order_dow)='') * 100.0 / COUNT()),
       'Percentage of null or blank order_dow values'
FROM raw.raw___insta_orders
UNION ALL
SELECT 'raw___insta_orders','duplicate_order_per_user',1,toFloat64(COUNT(*)),'Duplicate order_id detected for same user'
FROM (
  SELECT user_id, order_id
  FROM raw.raw___insta_orders
  GROUP BY user_id, order_id
  HAVING COUNT(*) > 1
);
-- Departments
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_departments','departments_volume_check',0,toFloat64(COUNT(*)),'Total row count in departments'
FROM raw.raw___insta_departments
UNION ALL
SELECT 'raw___insta_departments','department_id_uniqueness',1,toFloat64(COUNT(DISTINCT toInt64OrNull(department_id))),'Ensures each department_id is unique'
FROM raw.raw___insta_departments
UNION ALL
SELECT 'raw___insta_departments','department_name_missing',1,toFloat64(COUNT(*)),'Detects missing or blank department names'
FROM raw.raw___insta_departments WHERE department IS NULL OR TRIM(department)=''
UNION ALL
SELECT 'raw___insta_departments','department_row_duplicates',1,toFloat64(COUNT(*) - COUNT(DISTINCT (department_id, department))),'Checks for duplicate rows'
FROM raw.raw___insta_departments
UNION ALL
SELECT 'raw___insta_departments','department_blank_string_names',0,toFloat64(COUNT(*)),'Counts blank string department names'
FROM raw.raw___insta_departments WHERE TRIM(department)='';
-- Order Products (Prior)
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_order_products_prior','order_products_prior_volume_check',0,toFloat64(COUNT(*)),'Total row count in prior order_products'
FROM raw.raw___insta_order_products_prior
UNION ALL
SELECT 'raw___insta_order_products_prior','order_fk_validity',1,toFloat64(COUNT(*)),'Order IDs not found in orders'
FROM raw.raw___insta_order_products_prior op
LEFT JOIN raw.raw___insta_orders o ON toInt64OrNull(op.order_id) = toInt64OrNull(o.order_id)
WHERE o.order_id IS NULL
UNION ALL
SELECT 'raw___insta_order_products_prior','product_fk_validity',1,toFloat64(COUNT(*)),'Product IDs not found in products'
FROM raw.raw___insta_order_products_prior op
LEFT JOIN raw.raw___insta_products p ON toInt64OrNull(op.product_id) = toInt64OrNull(p.product_id)
WHERE p.product_id IS NULL
UNION ALL
SELECT 'raw___insta_order_products_prior','reordered_domain_check',1,toFloat64(COUNT(*)),'Invalid reordered values not in {0,1}'
FROM raw.raw___insta_order_products_prior WHERE reordered NOT IN ('0','1')
UNION ALL
SELECT 'raw___insta_order_products_prior','add_to_cart_min_check',1,toFloat64(MIN(toInt32OrNull(add_to_cart_order))),'Ensures add_to_cart_order starts at 1 or above'
FROM raw.raw___insta_order_products_prior
UNION ALL
SELECT 'raw___insta_order_products_prior','null_pct_reordered',1,(countIf(reordered IS NULL) * 100.0 / COUNT()),'Percentage of null reordered values'
FROM raw.raw___insta_order_products_prior;
-- Order Products (Train)
INSERT INTO raw.grp3_dq_sanity_checks
SELECT 'raw___insta_order_products_train','order_products_train_volume_check',0,toFloat64(COUNT(*)),'Total row count in train order_products'
FROM raw.raw___insta_order_products_train
UNION ALL
SELECT 'raw___insta_order_products_train','order_fk_validity',1,toFloat64(COUNT(*)),'Order IDs not found in orders'
FROM raw.raw___insta_order_products_train op
LEFT JOIN raw.raw___insta_orders o ON toInt64OrNull(op.order_id) = toInt64OrNull(o.order_id)
WHERE o.order_id IS NULL
UNION ALL
SELECT 'raw___insta_order_products_train','product_fk_validity',1,toFloat64(COUNT(*)),'Product IDs not found in products'
FROM raw.raw___insta_order_products_train op
LEFT JOIN raw.raw___insta_products p ON toInt64OrNull(op.product_id) = toInt64OrNull(p.product_id)
WHERE p.product_id IS NULL
UNION ALL
SELECT 'raw___insta_order_products_train','reordered_domain_check',1,toFloat64(COUNT(*)),'Invalid reordered values not in {0,1}'
FROM raw.raw___insta_order_products_train WHERE reordered NOT IN ('0','1')
UNION ALL
SELECT 'raw___insta_order_products_train','add_to_cart_min_check',1,toFloat64(MIN(toInt32OrNull(add_to_cart_order))),'Ensures add_to_cart_order starts at 1 or above'
FROM raw.raw___insta_order_products_train
UNION ALL
SELECT 'raw___insta_order_products_train','null_pct_reordered',1,(countIf(reordered IS NULL) * 100.0 / COUNT()),'Percentage of null reordered values'
FROM raw.raw___insta_order_products_train;