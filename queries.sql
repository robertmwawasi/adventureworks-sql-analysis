-- AdventureWorks internet sales: analysis queries (PostgreSQL)
-- Run ONE query at a time: select it, then press F5 in pgAdmin's Query Tool.
-- Every result was reconciled to the Excel analysis (60,398 lines, $29,358,677 revenue).


-- ============================================================
-- 00  CHECKS
-- ============================================================

-- The six tables should exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- Totals that tie to the Excel workbook
SELECT COUNT(*)                            AS lines,
       COUNT(DISTINCT sales_order_number)  AS orders,
       COUNT(DISTINCT customer_key)        AS customers,
       SUM(sales_amount)                   AS revenue
FROM sales;
-- expected: 60398 | 27659 | 18484 | 29358677.2207

SELECT SUM(sales_amount - total_product_cost) AS profit,
       ROUND(100 * SUM(sales_amount - total_product_cost) / SUM(sales_amount), 1) AS margin_pct
FROM sales;
-- expected: 12080883.6450 | 41.1


-- ============================================================
-- 01  SALES OVER TIME
-- ============================================================

-- By calendar year
SELECT EXTRACT(YEAR FROM order_date)       AS year,
       COUNT(DISTINCT sales_order_number)  AS orders,
       ROUND(SUM(sales_amount), 0)         AS revenue,
       ROUND(SUM(sales_amount - total_product_cost), 0) AS profit,
       ROUND(100 * SUM(sales_amount - total_product_cost) / SUM(sales_amount), 1) AS margin_pct
FROM sales
GROUP BY year
ORDER BY year;

-- By month (37 rows)
SELECT TO_CHAR(order_date, 'YYYY-MM') AS month,
       ROUND(SUM(sales_amount), 0)    AS revenue
FROM sales
GROUP BY month
ORDER BY month;

-- By fiscal year (the fiscal year starts in July)
SELECT c.fiscal_year,
       ROUND(SUM(s.sales_amount), 0) AS revenue,
       ROUND(SUM(s.sales_amount - s.total_product_cost), 0) AS profit,
       ROUND(100 * SUM(s.sales_amount - s.total_product_cost) / SUM(s.sales_amount), 1) AS margin_pct
FROM sales s
JOIN calendar c ON s.order_date_key = c.date_key
GROUP BY c.fiscal_year
ORDER BY c.fiscal_year;


-- ============================================================
-- 02  PRODUCTS
-- ============================================================

-- Top 10 products by revenue
SELECT p.product_name,
       ROUND(SUM(s.sales_amount), 0) AS revenue,
       ROUND(SUM(s.sales_amount - s.total_product_cost), 0) AS profit
FROM sales s
JOIN product p ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue DESC
LIMIT 10;

-- Bottom 5 products by revenue
SELECT p.product_name,
       ROUND(SUM(s.sales_amount), 0) AS revenue,
       ROUND(SUM(s.sales_amount - s.total_product_cost), 0) AS profit
FROM sales s
JOIN product p ON s.product_key = p.product_key
GROUP BY p.product_name
ORDER BY revenue ASC
LIMIT 5;

-- Items under $100 versus $100 and up, by year
SELECT EXTRACT(YEAR FROM order_date) AS year,
       CASE WHEN unit_price < 100 THEN '1 Under $100'
            ELSE '2 $100 and up' END AS price_tier,
       COUNT(*)                      AS items,
       ROUND(SUM(sales_amount), 0)   AS revenue
FROM sales
GROUP BY year, price_tier
ORDER BY year, price_tier;

-- Share of items and of revenue that are under $100
SELECT EXTRACT(YEAR FROM order_date) AS year,
       ROUND(100.0 * SUM(CASE WHEN unit_price < 100 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_items_under_100,
       ROUND(100.0 * SUM(CASE WHEN unit_price < 100 THEN sales_amount ELSE 0 END) / SUM(sales_amount), 1) AS pct_revenue_under_100
FROM sales
GROUP BY year
ORDER BY year;

-- Revenue per order
SELECT EXTRACT(YEAR FROM order_date) AS year,
       COUNT(DISTINCT sales_order_number) AS orders,
       ROUND(SUM(sales_amount) / COUNT(DISTINCT sales_order_number), 0) AS revenue_per_order
FROM sales
GROUP BY year
ORDER BY year;


-- ============================================================
-- 03  GEOGRAPHY
-- ============================================================

-- Revenue, share and margin by country and region
SELECT t.country, t.region,
       ROUND(SUM(s.sales_amount), 0) AS revenue,
       ROUND(100.0 * SUM(s.sales_amount) / (SELECT SUM(sales_amount) FROM sales), 1) AS share_pct,
       ROUND(100.0 * SUM(s.sales_amount - s.total_product_cost) / SUM(s.sales_amount), 1) AS margin_pct
FROM sales s
JOIN sales_territory t ON s.sales_territory_key = t.sales_territory_key
GROUP BY t.country, t.region
ORDER BY revenue DESC;


-- ============================================================
-- 04  CUSTOMERS
-- ============================================================

-- Customer totals: average and median spend
WITH customer_spend AS (
    SELECT customer_key,
           SUM(sales_amount) AS total_spend
    FROM sales
    GROUP BY customer_key
)
SELECT COUNT(*)                          AS customers,
       ROUND(SUM(total_spend), 0)        AS revenue,
       ROUND(AVG(total_spend), 0)        AS avg_spend,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY total_spend))::numeric, 0) AS median_spend
FROM customer_spend;

-- Two kinds of customer: big-ticket buyers and accessories-only
WITH customer_spend AS (
    SELECT customer_key,
           SUM(sales_amount) AS total_spend,
           MAX(unit_price)   AS max_price
    FROM sales
    GROUP BY customer_key
)
SELECT CASE WHEN max_price >= 100 THEN 'Big-ticket' ELSE 'Accessories only' END AS segment,
       COUNT(*)                   AS customers,
       ROUND(SUM(total_spend), 0) AS revenue,
       ROUND(AVG(total_spend), 0) AS avg_spend
FROM customer_spend
GROUP BY segment
ORDER BY segment;

-- Spend and big-ticket share by occupation
WITH customer_spend AS (
    SELECT customer_key,
           SUM(sales_amount) AS total_spend,
           MAX(unit_price)   AS max_price
    FROM sales
    GROUP BY customer_key
)
SELECT c.occupation,
       COUNT(*)                      AS customers,
       ROUND(AVG(cs.total_spend), 0) AS avg_spend,
       ROUND(100.0 * AVG(CASE WHEN cs.max_price >= 100 THEN 1 ELSE 0 END), 1) AS pct_big_ticket
FROM customer c
JOIN customer_spend cs ON c.customer_key = cs.customer_key
GROUP BY c.occupation
ORDER BY pct_big_ticket DESC;


-- ============================================================
-- 05  SEASONALITY
-- ============================================================

-- Revenue by weekday
SELECT c.day_name,
       ROUND(SUM(s.sales_amount), 0) AS revenue,
       ROUND(100.0 * SUM(s.sales_amount) / (SELECT SUM(sales_amount) FROM sales), 1) AS share_pct
FROM sales s
JOIN calendar c ON s.order_date_key = c.date_key
GROUP BY c.day_name, c.day_number_of_week
ORDER BY c.day_number_of_week;

-- Fiscal-year change (window function LAG)
WITH fy AS (
    SELECT c.fiscal_year,
           SUM(s.sales_amount) AS revenue
    FROM sales s
    JOIN calendar c ON s.order_date_key = c.date_key
    GROUP BY c.fiscal_year
)
SELECT fiscal_year,
       ROUND(revenue, 0) AS revenue,
       ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY fiscal_year))
             / LAG(revenue) OVER (ORDER BY fiscal_year), 1) AS pct_change
FROM fy
ORDER BY fiscal_year;

-- Each month's share of its fiscal year (window function SUM ... OVER)
WITH monthly AS (
    SELECT c.fiscal_year,
           c.month_number_of_year AS month,
           SUM(s.sales_amount)    AS revenue
    FROM sales s
    JOIN calendar c ON s.order_date_key = c.date_key
    WHERE c.fiscal_year BETWEEN 2006 AND 2008
    GROUP BY c.fiscal_year, c.month_number_of_year
)
SELECT fiscal_year,
       month,
       ROUND(revenue, 0) AS revenue,
       ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY fiscal_year), 1) AS pct_of_year
FROM monthly
ORDER BY fiscal_year, month;


-- ============================================================
-- 06  CUSTOMER GROUPS (RFM)
-- Snapshot date: 2008-08-01 (the day after the last order)
-- ============================================================

WITH customer_rfm AS (
    SELECT customer_key,
           DATE '2008-08-01' - MAX(order_date) AS recency,
           COUNT(DISTINCT sales_order_number)  AS frequency,
           SUM(sales_amount)                   AS monetary
    FROM sales
    GROUP BY customer_key
),
scored AS (
    SELECT *,
           CASE WHEN recency >= 265 THEN 1
                WHEN recency >= 170 THEN 2
                WHEN recency >= 88  THEN 3
                ELSE 4 END                AS r_score,
           LEAST(frequency, 3)            AS f_score,
           CASE WHEN monetary >= 2500 THEN 4
                WHEN monetary >= 300  THEN 3
                WHEN monetary >= 50   THEN 2
                ELSE 1 END                AS m_score
    FROM customer_rfm
),
segmented AS (
    SELECT *,
           CASE WHEN r_score >= 3 AND m_score = 4 THEN '1 Champions'
                WHEN r_score <= 2 AND m_score = 4 AND recency <= 411 THEN '2 Due for reorder'
                WHEN r_score <= 2 AND m_score = 4 THEN '3 Overdue big spenders'
                WHEN f_score >= 2 AND m_score <= 3 THEN '4 Repeat small buyers'
                WHEN r_score >= 3 THEN '5 Recent one-off'
                ELSE '6 Lapsed low value' END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*)                                            AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)  AS pct_customers,
       ROUND(SUM(monetary), 0)                             AS revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
       ROUND(AVG(recency), 0)                              AS avg_days_since_order,
       ROUND(AVG(monetary), 0)                             AS avg_spend
FROM segmented
GROUP BY segment
ORDER BY segment;


-- ============================================================
-- 07  REPEAT BUYING (COHORTS)
-- ============================================================

-- Order gaps: how long between a customer's orders
WITH orders AS (
    SELECT customer_key,
           sales_order_number,
           MIN(order_date) AS order_date
    FROM sales
    GROUP BY customer_key, sales_order_number
),
numbered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_key
                              ORDER BY order_date, sales_order_number) AS order_no,
           order_date - LAG(order_date) OVER (PARTITION BY customer_key
                              ORDER BY order_date, sales_order_number) AS gap_days
    FROM orders
)
SELECT COUNT(*)                                  AS orders,
       COUNT(*) FILTER (WHERE order_no = 1)      AS first_orders,
       COUNT(gap_days)                           AS gaps,
       ROUND(AVG(gap_days), 0)                   AS avg_gap,
       ROUND((percentile_cont(0.5) WITHIN GROUP (ORDER BY gap_days))::numeric, 0) AS median_gap
FROM numbered;

-- Cohorts by fiscal year of first order (LEFT JOIN keeps customers who never reordered)
WITH orders AS (
    SELECT customer_key,
           sales_order_number,
           MIN(order_date) AS order_date
    FROM sales
    GROUP BY customer_key, sales_order_number
),
numbered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_key
                              ORDER BY order_date, sales_order_number) AS order_no,
           order_date - LAG(order_date) OVER (PARTITION BY customer_key
                              ORDER BY order_date, sales_order_number) AS gap_days
    FROM orders
),
cohorts AS (
    SELECT n.customer_key,
           c.fiscal_year AS cohort,
           n.order_date  AS first_order
    FROM numbered n
    JOIN calendar c ON c.full_date = n.order_date
    WHERE n.order_no = 1
),
second_orders AS (
    SELECT customer_key, order_date AS second_order, gap_days
    FROM numbered
    WHERE order_no = 2
)
SELECT co.cohort,
       COUNT(*)                                   AS customers,
       COUNT(s.customer_key)                      AS reordered,
       ROUND(100.0 * COUNT(s.customer_key) / COUNT(*), 1) AS reorder_pct,
       COUNT(*) FILTER (WHERE s.gap_days <= 365)  AS within_365
FROM cohorts co
LEFT JOIN second_orders s ON s.customer_key = co.customer_key
GROUP BY co.cohort
ORDER BY co.cohort;

-- Fair comparison: everyone's clock starts at the later of their first order
-- or 1 July 2007 (when repeat orders begin), and only customers watched
-- for at least 180 days are counted.
WITH orders AS (
    SELECT customer_key,
           sales_order_number,
           MIN(order_date) AS order_date
    FROM sales
    GROUP BY customer_key, sales_order_number
),
numbered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_key
                              ORDER BY order_date, sales_order_number) AS order_no
    FROM orders
),
cohorts AS (
    SELECT n.customer_key,
           c.fiscal_year AS cohort,
           n.order_date  AS first_order
    FROM numbered n
    JOIN calendar c ON c.full_date = n.order_date
    WHERE n.order_no = 1
),
second_orders AS (
    SELECT customer_key, order_date AS second_order
    FROM numbered
    WHERE order_no = 2
),
base AS (
    SELECT co.cohort,
           GREATEST(co.first_order, DATE '2007-07-01') AS start_point,
           s.second_order
    FROM cohorts co
    LEFT JOIN second_orders s ON s.customer_key = co.customer_key
)
SELECT cohort,
       COUNT(*) AS eligible,
       COUNT(*) FILTER (WHERE second_order >= start_point
                          AND second_order - start_point <= 180) AS reordered_180,
       ROUND(100.0 * COUNT(*) FILTER (WHERE second_order >= start_point
                          AND second_order - start_point <= 180) / COUNT(*), 1) AS rate_pct
FROM base
WHERE DATE '2008-08-01' - start_point >= 180
GROUP BY cohort
ORDER BY cohort;
-- expected: 2006 | 2206 | 1002 | 45.4   2007 | 3222 | 1165 | 36.2   2008 | 7114 | 1139 | 16.0
