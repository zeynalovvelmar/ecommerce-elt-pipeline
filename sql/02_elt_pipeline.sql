/*
=========================================================
PROJECT: E-Commerce Data Warehouse (ELT)
FILE: 02_elt_pipeline.sql
AUTHOR: Elmar
DESCRIPTION: 
    This script executes the ELT process.
    1. Extracts distinct data from Staging.
    2. Transforms data types (Strings -> Numbers/Dates).
    3. Loads data into Dimensions and Fact tables.
=========================================================
*/

-- ======================================================
-- 1. LOAD DIMENSIONS (Transform & Deduplicate)
-- ======================================================

-- Loading Customers
INSERT INTO dim_customer (customer_id, customer_name, customer_city, customer_country, segment)
SELECT DISTINCT 
    customer_id, customer_name, customer_city, customer_country, segment 
FROM staging_orders 
WHERE customer_id IS NOT NULL;

-- Loading Products
INSERT INTO dim_product (product_id, sku, brand, category_code)
SELECT DISTINCT 
    product_id, sku, brand, category_code 
FROM staging_orders 
WHERE product_id IS NOT NULL;

-- Loading Shipments (Converting String to Timestamp)
INSERT INTO dim_shipment (shipment_id, carrier, delivery_instructions, shipped_ts, delivered_ts)
SELECT DISTINCT 
    shipment_id, 
    carrier, 
    delivery_instructions, 
    TO_TIMESTAMP(shipped_ts, 'YYYY-MM-DD HH24:MI:SS'), 
    TO_TIMESTAMP(delivered_ts, 'YYYY-MM-DD HH24:MI:SS') 
FROM staging_orders 
WHERE shipment_id IS NOT NULL;

-- Loading Junk Dimension (All unique combinations of flags)
INSERT INTO dim_junk (sales_channel, payment_method, device_type, is_gift, gift_wrap, requires_id_check, promo_stackable)
SELECT DISTINCT 
    sales_channel, payment_method, device_type, is_gift, gift_wrap, requires_id_check, promo_stackable 
FROM staging_orders;

-- Loading Date Dimension (Parsing Order Date)
INSERT INTO dim_date (date_sk, full_date, year, month, day_name)
SELECT DISTINCT 
    TO_NUMBER(REPLACE(order_date, '-', '')),          -- 2025-01-05 -> 20250105
    TO_DATE(order_date, 'YYYY-MM-DD'), 
    EXTRACT(YEAR FROM TO_DATE(order_date, 'YYYY-MM-DD')), 
    EXTRACT(MONTH FROM TO_DATE(order_date, 'YYYY-MM-DD')), 
    TO_CHAR(TO_DATE(order_date, 'YYYY-MM-DD'), 'Day') 
FROM staging_orders 
WHERE order_date IS NOT NULL;

-- ======================================================
-- 2. LOAD FACT TABLE (Key Lookups & Measure Casting)
-- ======================================================

INSERT INTO fact_sales (
    order_id, line_nbr, customer_sk, product_sk, shipment_sk, junk_sk, date_sk, 
    quantity, unit_price, discount_rate, line_net_amount, line_vat_amount
)
SELECT 
    s.order_id,
    TO_NUMBER(s.line_nbr),
    
    -- Dimension Key Lookups
    c.customer_sk,
    p.product_sk,
    sh.shipment_sk,
    j.junk_sk,
    TO_NUMBER(REPLACE(s.order_date, '-', '')), -- Date Key
    
    -- Measure Conversions (String -> Number)
    TO_NUMBER(s.quantity),
    TO_NUMBER(s.unit_price),
    TO_NUMBER(s.discount_rate),
    TO_NUMBER(s.line_net_amount),
    TO_NUMBER(s.line_vat_amount)

FROM staging_orders s
-- JOINs to retrieve Surrogate Keys
JOIN dim_customer c ON s.customer_id = c.customer_id
JOIN dim_product p  ON s.product_id = p.product_id
LEFT JOIN dim_shipment sh ON s.shipment_id = sh.shipment_id
JOIN dim_junk j ON 
    NVL(s.sales_channel, 'X')     = NVL(j.sales_channel, 'X') AND
    NVL(s.payment_method, 'X')    = NVL(j.payment_method, 'X') AND
    NVL(s.device_type, 'X')       = NVL(j.device_type, 'X') AND
    NVL(s.is_gift, 'X')           = NVL(j.is_gift, 'X') AND
    NVL(s.gift_wrap, 'X')         = NVL(j.gift_wrap, 'X') AND
    NVL(s.requires_id_check, 'X') = NVL(j.requires_id_check, 'X') AND
    NVL(s.promo_stackable, 'X')   = NVL(j.promo_stackable, 'X');

-- Final Commit to persist changes
COMMIT;