/* ----------------------------------------------------------------------
   STAGE 1 — STAGING TABLE
------------------------------------------------------------------------- */

DROP TABLE IF EXISTS staging_ecommerce_sales;
CREATE TABLE staging_ecommerce_sales(
    customer_id TEXT,
	gender TEXT,
	region TEXT,
	age TEXT,
	product_name TEXT,
	category TEXT,
	unit_price TEXT,
	quantity TEXT,
	total_price TEXT,
	shipping_fee TEXT,
	shipping_status TEXT,
	order_date TEXT
);

SELECT * FROM staging_ecommerce_sales;

SELECT COUNT(*) AS rows_loaded FROM staging_ecommerce_sales;

/* ----------------------------------------------------------------------
   STAGE 2 — DATA QUALITY CHECKS IN THE UNCLEANED TABLE
------------------------------------------------------------------------- */

-- 2.1 Null Counts Per Column
SELECT
    COUNT(*) FILTER(WHERE customer_id IS NULL OR customer_id = '') AS null_customer_id,
	COUNT(*) FILTER(WHERE gender IS NULL OR gender = '') AS null_gender,
	COUNT(*) FILTER(WHERE region IS NULL OR region = '') AS null_region,
	COUNT(*) FILTER(WHERE age IS NULL OR age = '') AS null_age,
	COUNT(*) FILTER(WHERE shipping_status IS NULL OR shipping_status = '') AS null_shipping_status
FROM
    staging_ecommerce_sales

-- 2.2 Distinct Values In Categorical Columns
SELECT DISTINCT region FROM staging_ecommerce_sales ORDER BY 1;
SELECT DISTINCT gender FROM staging_ecommerce_sales ORDER BY 1;
SELECT DISTINCT shipping_status FROM staging_ecommerce_sales ORDER BY 1;
SELECT DISTINCT category FROM staging_ecommerce_sales ORDER BY 1;

-- 2.3 Rows Where Total Price != Unit Price * Quantity
SELECT
    customer_id,
	unit_price,
	quantity,
	total_price,
	ROUND(unit_price::NUMERIC * quantity::INTEGER, 2) AS expected_total
FROM
    staging_ecommerce_sales
WHERE
	ROUND(unit_price::NUMERIC * quantity::INTEGER, 2) != ROUND(total_price::NUMERIC, 2);

-- 2.4 Order date format check — flags anything NOT in YYYY-MM-DD form
SELECT
    order_date
FROM staging_ecommerce_sales
WHERE order_date !~ '^\d{4}-\d{2}-\d{2}$';

-- 2.5 Extract Duplicate Rows
SELECT
    customer_id,
	order_date,
	product_name,
	unit_price,
	quantity,
	COUNT(*)
FROM
    staging_ecommerce_sales
GROUP BY customer_id, order_date, product_name, unit_price, quantity
HAVING COUNT(*) > 1;


/* ----------------------------------------------------------------------
   STAGE 3 — NOW CREATE A CLEANED TABLE
------------------------------------------------------------------------- */

DROP TABLE IF EXISTS cleaned_ecommerce_sales;
CREATE TABLE cleaned_ecommerce_sales(
    row_id SERIAL PRIMARY KEY,
	customer_id TEXT NOT NULL,
	gender TEXT NOT NULL,
	region TEXT NOT NULL,
	age INTEGER,
	age_band TEXT NOT NULL,
	product_name TEXT NOT NULL,
	category TEXT NOT NULL,
	unit_price NUMERIC(10,2) NOT NULL,
	quantity INTEGER NOT NULL,
	total_price NUMERIC(10,2) NOT NULL,
	total_price_flagged BOOLEAN NOT NULL,
	shipping_fee NUMERIC(10,2) NOT NULL,
	shipping_status TEXT NOT NULL,
	order_date DATE NOT NULL
);

INSERT INTO cleaned_ecommerce_sales(
    customer_id, gender, region, age, age_band, product_name, category,
    unit_price, quantity, total_price, total_price_flagged, shipping_fee, shipping_status,
    order_date
) SELECT
    TRIM(customer_id),
	TRIM(gender),
	COALESCE(NULLIF(TRIM(region), ''), 'Unknown'),
	ROUND(age::NUMERIC)::INTEGER,
	CASE
	    WHEN age IS NULL OR age = '' THEN 'Unknown'
		WHEN age::NUMERIC < 26 THEN '18-25'
		WHEN age::NUMERIC < 36 THEN '26-35'
		WHEN age::NUMERIC < 46 THEN '36-45'
		WHEN age::NUMERIC < 56 THEN '46-55'
		WHEN age::NUMERIC < 66 THEN '56-65'
		ELSE '66+'
	END,
	TRIM(product_name),
	TRIM(category),
	ROUND(unit_price::NUMERIC, 2),
	quantity::INTEGER,
	ROUND(unit_price::NUMERIC * quantity::INTEGER, 2),
	(ROUND(unit_price::NUMERIC * quantity::INTEGER, 2) != ROUND(total_price::NUMERIC, 2)),
	ROUND(shipping_fee::NUMERIC, 2),
	COALESCE(NULLIF(TRIM(shipping_status), ''), 'Unknown'),
	order_date::DATE
FROM staging_ecommerce_sales;

SELECT COUNT(*) AS total_rows FROM cleaned_ecommerce_sales;
SELECT COUNT(*) AS flagged_price_mismatches FROM cleaned_ecommerce_sales WHERE total_price_flagged = true;

SELECT * FROM cleaned_ecommerce_sales;

/* ----------------------------------------------------------------------
   STAGE 4 — CREATE CUSTOMER SUMMARY TABLE
-------------------------------------------------------------------------*/

DROP TABLE IF EXISTS customer_summary;
CREATE TABLE customer_summary AS
SELECT
    customer_id,
	MIN(gender) AS gender,
	MODE() WITHIN GROUP (ORDER BY region) AS most_common_region,
	MIN(age) AS age,
	MIN(age_band) AS age_band,
	COUNT(*) AS total_orders,
	SUM(total_price) AS lifetime_spend,
	ROUND(AVG(total_price), 2) AS avg_order_value,
	MIN(order_date) AS first_order_date,
	MAX(order_date) AS last_order_date,
	(MAX(order_date) - MIN(order_date)) AS customer_tenure_days,
	SUM(CASE WHEN shipping_status = 'Returned' THEN 1 ELSE 0 END) AS return_count,
	(SUM(CASE WHEN shipping_status = 'Returned' THEN 1 ELSE 0 END) > 0) AS has_return_flag
FROM cleaned_ecommerce_sales
GROUP BY customer_id;

SELECT COUNT(*) AS total_customers FROM customer_summary;
SELECT COUNT(*) AS repeat_customers FROM customer_summary WHERE total_orders > 1;

SELECT *
FROM customer_summary
ORDER BY lifetime_spend DESC
LIMIT 10;

SELECT * FROM customer_summary;