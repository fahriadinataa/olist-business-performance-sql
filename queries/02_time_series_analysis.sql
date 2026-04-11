-- Date Range from the start to the end of the data
SELECT 
	MIN(order_purchase_timestamp) AS start_date,
	MAX(order_purchase_timestamp) AS end_date,
	DATEDIFF(MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)) AS count_days -- the number of days between the start date and the end date
FROM st_dim_order;


-- Create Dim Date Table
DROP TABLE IF EXISTS st_dim_date;

CREATE TABLE st_dim_date(
	datekey INT PRIMARY KEY,
	fulldate DATE,
	year INT,
	month INT,
	monthname VARCHAR(10),
	day INT,
	dayname VARCHAR(10),
	weekofyear INT,
	quarter INT,
	isweekend BOOLEAN,
	yearmonth VARCHAR(7)
);

INSERT INTO st_dim_date
(datekey, fulldate, year, month, monthname, day, dayname, weekofyear, quarter, isweekend, yearmonth)
WITH RECURSIVE date_series AS
(
SELECT '2016-09-04' AS date_value
UNION ALL
SELECT DATE_ADD(date_value, INTERVAL 1 DAY)
FROM date_series
WHERE date_value <= '2018-10-17'
)
SELECT
	DATE_FORMAT(date_value, '%Y%m%d'),
	date_value,
	YEAR(date_value),
	MONTH(date_value),
	MONTHNAME(date_value),
	DAY(date_value),
	DAYNAME(date_value),
	WEEKOFYEAR(date_value),
	QUARTER(date_value),
	CASE WHEN DAYOFWEEK(date_value) IN (1, 7) THEN TRUE ELSE FALSE END,
	DATE_FORMAT(date_value, '%Y-%m')
FROM date_series;

SELECT * 
FROM st_dim_date;


-- Merge 4 table (fact_payment, fact_item, dim_order, dim_customer) as new fact table.
-- I created a table containing all the IDs, calculations, and dates to make it easier to create relationships with other dim tables.
DROP TEMPORARY TABLE IF EXISTS payment_summary;

CREATE TEMPORARY TABLE payment_summary
SELECT 
	order_id,
	COUNT(DISTINCT payment_type) AS count_type,
	GROUP_CONCAT(DISTINCT payment_type ORDER BY payment_type) AS payment_type, 
	MAX(payment_installments) AS installment,
	ROUND(SUM(payment_value), 2) AS total_payment
FROM st_fact_payment
GROUP BY order_id;

SELECT *
FROM payment_summary;
-- Currently, 1 row in payment summary represents 1 transaction. (99438)

DROP TEMPORARY TABLE IF EXISTS item_summary;

CREATE TEMPORARY TABLE item_summary
SELECT 
	order_id,
	product_id,
	seller_id,
	COUNT(order_item_id) AS qty_sold,
	ROUND(SUM(price + freight_value), 2) AS actual_price
FROM st_fact_item
GROUP BY order_id, product_id, seller_id;

SELECT *
FROM item_summary;
-- Currently, 1 row in the item summary represents 1 order for 1 product from 1 seller. 
-- If a customer purchases different products or places orders with different sellers, the order ID will be duplicated. (102425)

DROP TEMPORARY TABLE IF EXISTS order_valid;

CREATE TEMPORARY TABLE order_valid
SELECT 
	order_id, 
	customer_id,
	order_status,
	order_purchase_timestamp AS purchase_date,
	order_delivered_customer_date AS delivered_date,
	order_estimated_delivery_date AS estimated_date
FROM st_dim_order
WHERE order_status NOT IN ('canceled', 'unavailable');
    
SELECT *
FROM order_valid;
-- I removed the rows with order status canceled and unavailable.
-- So the result is only successful orders and orders that are still in progress. (98207)

DROP TEMPORARY TABLE IF EXISTS order_valid_summary;

CREATE TEMPORARY TABLE order_valid_summary
SELECT 
	i.order_id,
	i.product_id,
	i.seller_id,
	o.customer_id,
	o.order_status,
	p.count_type,
	p.payment_type,
	p.installment,
	i.qty_sold,
	i.actual_price,
	p.total_payment,
	o.purchase_date,
	o.delivered_date,
	o.estimated_date
FROM item_summary i
LEFT JOIN order_valid o ON i.order_id = o.order_id
LEFT JOIN payment_summary p ON i.order_id = p.order_id
WHERE o.order_status IS NOT NULL;
-- LEFT JOIN digunakan karena item_summary (left table) bisa mengandung order canceled/unavailable. 
-- WHERE IS NOT NULL berfungsi memfilter failed order (cancel, unavail) yang tidak lolos dari valid_order. (101953)

SELECT * 
FROM order_valid_summary;

SET SQL_SAFE_UPDATES = 0;
ALTER TABLE order_valid_summary
MODIFY purchase_date DATE;
UPDATE order_valid_summary
SET purchase_date = DATE_FORMAT(purchase_date, '%Y-%m-%d');

ALTER TABLE order_valid_summary
MODIFY delivered_date DATE;
UPDATE order_valid_summary
SET delivered_date = DATE_FORMAT(delivered_date, '%Y-%m-%d');

ALTER TABLE order_valid_summary
MODIFY estimated_date DATE;
UPDATE order_valid_summary
SET estimated_date = DATE_FORMAT(estimated_date, '%Y-%m-%d');

SELECT *
FROM order_valid_summary
ORDER BY purchase_date ASC, order_id;
SET SQL_SAFE_UPDATES = 1;

DROP TEMPORARY TABLE IF EXISTS new_fact_order;

CREATE TEMPORARY TABLE new_fact_order
SELECT 
	o.order_id,
	o.product_id,
	o.seller_id,
	o.customer_id,
    c.customer_unique_id,
	o.order_status,
	o.count_type,
	o.payment_type,
	o.installment,
	o.qty_sold,
	o.actual_price,
	o.total_payment,
	o.purchase_date,
	o.delivered_date,
	o.estimated_date
FROM order_valid_summary o
LEFT JOIN st_dim_customer c ON o.customer_id = c.customer_id;

SELECT *
FROM new_fact_order;
-- The new fact table is now complete and ready to use.
-- Each row in this table represents one order from one customer who purchased one product from one seller.
-- Duplicates occur because a single order may include different products or different sellers.


-- Monthly Trend Analysis
SELECT 
	d.yearmonth,
	COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
    ROUND(
		(COUNT(DISTINCT o.customer_unique_id) - LAG(COUNT(DISTINCT o.customer_unique_id)) OVER(ORDER BY d.yearmonth)) * 100.0 /
		LAG(COUNT(DISTINCT o.customer_unique_id)) OVER(ORDER BY d.yearmonth), 2) AS growth_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
	ROUND(
		(SUM(o.qty_sold) - LAG(SUM(o.qty_sold)) OVER (ORDER BY d.yearmonth)) * 100.0 / 
		LAG(SUM(o.qty_sold)) OVER (ORDER BY d.yearmonth), 2) AS growth_qty,
	ROUND(AVG(o.qty_sold), 2) AS avg_qty,
	ROUND(SUM(total_payment), 2) AS total_gmv,
	ROUND(
		(SUM(o.total_payment) - LAG(SUM(o.total_payment)) OVER (ORDER BY d.yearmonth)) * 100.0 / 
		LAG(SUM(o.total_payment)) OVER (ORDER BY d.yearmonth), 2) AS growth_gmv,
	ROUND(AVG(total_payment), 2) AS avg_gmv
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.yearmonth
ORDER BY d.yearmonth;


-- Yearly Trend Analysis
SELECT 
	d.`year`,
	COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
	ROUND(
		(COUNT(DISTINCT o.customer_unique_id) - LAG(COUNT(DISTINCT o.customer_unique_id)) OVER(ORDER BY d.`year`)) * 100.0 /
		LAG(COUNT(DISTINCT o.customer_unique_id)) OVER(ORDER BY d.`year`), 2) AS growth_customer,
    ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
	ROUND(
		(SUM(o.qty_sold) - LAG(SUM(o.qty_sold)) OVER (ORDER BY d.`year`)) * 100.0 / 
		LAG(SUM(o.qty_sold)) OVER (ORDER BY d.`year`), 2) AS growth_qty,
	ROUND(AVG(o.qty_sold), 2) AS avg_qty,
	ROUND(SUM(total_payment), 2) AS total_gmv,
	ROUND(
		(SUM(o.total_payment) - LAG(SUM(o.total_payment)) OVER (ORDER BY d.`year`)) * 100.0 / 
		LAG(SUM(o.total_payment)) OVER (ORDER BY d.`year`), 2) AS growth_gmv,
	ROUND(AVG(total_payment), 2) AS avg_gmv
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.`year`
ORDER BY d.`year`;


-- Monthly Seasonality
SELECT 
	d.`month`,
	COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
    ROUND(SUM(o.qty_sold) / COUNT(DISTINCT o.order_id), 2) AS qty_sold_per_order,
	ROUND(SUM(o.qty_sold) * 100.0 / SUM(SUM(o.qty_sold)) OVER(), 2) AS qty_sold_pct_contribution,
	ROUND(SUM(o.total_payment), 2) AS total_gmv,
    ROUND(SUM(o.total_payment) / COUNT(DISTINCT o.order_id), 2) AS AOV,
	ROUND(SUM(o.total_payment) * 100.0 / SUM(SUM(o.total_payment)) OVER(), 2) AS gmv_pct_contribution
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.`month`
ORDER BY d.`month`;


-- Day of Week Pattern
SELECT 
	DISTINCT d.dayname,
	COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
    ROUND(SUM(o.qty_sold) / COUNT(DISTINCT o.order_id), 2) AS qty_sold_per_order,
	ROUND(SUM(o.qty_sold) * 100.0 / SUM(SUM(o.qty_sold)) OVER(), 2) AS qty_sold_pct_contribution,
	ROUND(SUM(o.total_payment), 2) AS total_gmv,
    ROUND(SUM(o.total_payment) / COUNT(DISTINCT o.order_id), 2) AS AOV,
	ROUND(SUM(o.total_payment) * 100.0 / SUM(SUM(o.total_payment)) OVER(), 2) AS gmv_pct_contribution
    FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.dayname
ORDER BY FIELD(d.dayname, 
    'Monday', 
    'Tuesday', 
    'Wednesday', 
    'Thursday', 
    'Friday', 
    'Saturday', 
    'Sunday'
);


-- Cumulative Metric Analysis
WITH running_metric AS
(
SELECT 
	d.yearmonth,
	COUNT(DISTINCT o.order_id) AS total_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
	ROUND(SUM(o.total_payment), 2) AS total_gmv
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.yearmonth
)
SELECT 
	yearmonth,
	SUM(total_order) OVER(ORDER BY yearmonth) AS cumulative_order,
    SUM(total_customer) OVER(ORDER BY yearmonth) AS cumulative_customer,
	ROUND(SUM(total_qty_sold) OVER(ORDER BY yearmonth), 2) AS cumulative_qty_sold,
	ROUND(SUM(total_gmv) OVER(ORDER BY yearmonth), 2) AS cumulative_gmv
FROM running_metric
GROUP BY yearmonth;


-- MoM Analysis
SELECT 
	DISTINCT d.yearmonth,
	COUNT(DISTINCT o.order_id) AS total_order,
	ROUND((COUNT(DISTINCT o.order_id) - 
		LAG(COUNT(DISTINCT o.order_id)) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(COUNT(DISTINCT o.order_id)) 
			OVER(ORDER BY d.yearmonth), 2) AS MoM_order,
    COUNT(DISTINCT o.customer_unique_id) AS total_customer,
    ROUND((COUNT(DISTINCT o.customer_unique_id) - 
		LAG(COUNT(DISTINCT o.customer_unique_id)) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(COUNT(DISTINCT o.customer_unique_id)) 
			OVER(ORDER BY d.yearmonth), 2) AS MoM_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
	ROUND((SUM(o.qty_sold) - 
		LAG(SUM(o.qty_sold)) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(SUM(o.qty_sold)) 
			OVER(ORDER BY d.yearmonth), 2) AS MoM_qty_sold,
	ROUND(SUM(o.total_payment), 2) AS total_gmv,
	ROUND((SUM(o.total_payment) - 
		LAG(SUM(o.total_payment)) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(SUM(o.total_payment)) 
			OVER(ORDER BY d.yearmonth), 2) AS MoM_gmv
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.yearmonth;


-- YoY Analysis
SELECT 
	DISTINCT d.yearmonth,
	COUNT(DISTINCT o.order_id) AS total_order,
	ROUND((COUNT(DISTINCT o.order_id) - 
		LAG(COUNT(DISTINCT o.order_id), 12) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(COUNT(DISTINCT o.order_id), 12) 
			OVER(ORDER BY d.yearmonth), 2) AS YoY_order,
	COUNT(DISTINCT o.customer_unique_id) AS total_customer,
	ROUND((COUNT(DISTINCT o.customer_unique_id) - 
		LAG(COUNT(DISTINCT o.customer_unique_id), 12) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(COUNT(DISTINCT o.customer_unique_id), 12) 
			OVER(ORDER BY d.yearmonth), 2) AS YoY_customer,
	ROUND(SUM(o.qty_sold), 2) AS total_qty_sold,
	ROUND((SUM(o.qty_sold) - 
		LAG(SUM(o.qty_sold), 12) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(SUM(o.qty_sold), 12) 
			OVER(ORDER BY d.yearmonth), 2) AS YoY_qty_sold,            
	ROUND(SUM(o.total_payment), 2) AS total_gmv,          
   	ROUND((SUM(o.total_payment) - 
		LAG(SUM(o.total_payment), 12) OVER(ORDER BY d.yearmonth)) * 100.0 / LAG(SUM(o.total_payment), 12) 
			OVER(ORDER BY d.yearmonth), 2) AS YoY_gmv    
FROM st_dim_date d
LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
GROUP BY d.yearmonth;


-- Moving Average 7 & Moving Average 30
WITH MA AS
(
	SELECT d.fulldate,
	COALESCE(ROUND(SUM(o.total_payment), 2), 0) AS total_gmv
	FROM st_dim_date d
	LEFT JOIN new_fact_order o ON d.fulldate = o.purchase_date
	GROUP BY d.fulldate
)
SELECT fulldate,
total_gmv,
ROUND(AVG(total_gmv) OVER(ORDER BY fulldate ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS MA7,
ROUND(AVG(total_gmv) OVER(ORDER BY fulldate ROWS BETWEEN 29 PRECEDING AND CURRENT ROW), 2) AS MA30
FROM MA;








