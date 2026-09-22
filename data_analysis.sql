-- Active: 1790015617336@@127.0.0.1@3306@zomato

-- *********************************************************************************************--

-- What's total and average revenue, and how does it trend month over month?

WITH CTE AS(
SELECT
MONTHNAME(order_date) AS month_name,
MONTH(order_date) AS month_num,
YEAR(order_date) AS `year`,
SUM(sales_amount) AS total_revenue,
AVG(sales_amount) AS avg_revenue
FROM orders
WHERE sales_amount IS NOT NULL
GROUP BY MONTHNAME(order_date), MONTH(order_date), YEAR(order_date)
ORDER BY `year`, month_num),
CTE_lags AS(
SELECT
month_name,
month_num,
`year`,
total_revenue,
LAG(total_revenue) OVER(ORDER BY `year`, month_num) AS prev_month_total,
avg_revenue,
LAG(avg_revenue) OVER(ORDER BY `year`, month_num) AS prev_month_avg
FROM CTE)
SELECT
month_name,
`year`,
total_revenue,
prev_month_total,
ROUND(((total_revenue - prev_month_total)/prev_month_total)*100, 2) AS total_revenue_mom,
avg_revenue,
prev_month_avg,
ROUND(((avg_revenue - prev_month_avg)/prev_month_avg)*100, 2) AS avg_revenue_mom
FROM CTE_lags
ORDER BY `year`, month_num;

-- FINDINGS -

-- Sharp fall in total revenue (34.29 to -10.04) and average revenue (4.64 to -0.65) from November -> December 2017
-- Sharp rebound in total revenue (-10.04 to 33.57%) and average revenue (-0.65 to 25.52%) from December 2017 -> January 2018;
-- the large jump in average order value suggests bulk/large orders drove this spike, not just more orders
-- Sharp drop in total and average revenue from August -> September 2018
-- Sharp increase in total (+38.45%) and average (+22.13%) revenue in July 2019 -- the single largest MoM jump in the dataset;
-- worth investigating whether a specific promotion or event drove this, since it isn't repeated in other years
-- Revenue grows through January-February 2020, then declines sharply every month from March through June 2020
-- (steepest drop: -36.83% in June 2020) -- timing coincides with India's COVID-19 lockdown period, though the dataset has no direct indicator to confirm causation

-- Verdict
--January tends to be a strong month (clearly in 2018, roughly tied with Feb in 2020), but this doesn't hold consistently across all three years (July 2019 was the year's actual peak). More years of data would be
-- needed to confirm a true seasonal pattern rather than one-off spikes.


--***********************************************************************************************--



-- Which restaurants generate the most revenue, and does that correlate with their rating?

SELECT t1.r_id, t2.name, t2.rating, t2.rating_count, SUM(sales_amount) AS total_revenue FROM orders t1
JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t1.sales_amount IS NOT NULL
GROUP BY t1.r_id, t2.name, t2.rating, t2.rating_count
ORDER BY total_revenue DESC
LIMIT 10;

SELECT SUM(total_revenue) FROM (SELECT t1.r_id, t2.name, t2.rating, t2.rating_count, SUM(sales_amount) AS total_revenue FROM orders t1
JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t1.sales_amount IS NOT NULL
GROUP BY t1.r_id, t2.name, t2.rating, t2.rating_count
ORDER BY total_revenue DESC
LIMIT 10) x; -- total_revenue by top 10 restaurants = 1,36,44,661.00

SELECT SUM(sales_amount) FROM orders; --98,65,65,018.00

WITH CTE AS (
  SELECT
    t1.*,
    t2.sales_amount,
    t2.r_id,
    CASE 
      WHEN t1.rating >= 4 THEN 'High-rated'
      WHEN t1.rating >= 3 THEN 'Average-rated'
      WHEN t1.rating < 3 THEN 'Low-rated'
      ELSE NULL 
    END AS rating_range
  FROM restaurant t1
  JOIN orders t2
    ON t1.id = t2.r_id
  WHERE t2.sales_amount IS NOT NULL
)
SELECT 
  rating_range, 
  SUM(sales_amount) AS total_revenue, 
  COUNT(DISTINCT r_id) AS total_restaurants
FROM CTE
GROUP BY rating_range
ORDER BY total_revenue DESC;

SELECT COUNT(*) FROM restaurant; -- 1,48,540 restaurants 


-- FINDINGS

-- Janta Snacks, Domino's Pizza, Happy Brew Cafe, Kouzina Kafe - The Food Court, Jaysika DDN Fast Food, Cafe Yummy, Krishna Food, Huber & Holly, ZAATAR SPICE, Blue Tokai Coffee Roasters are the restaurants that generate most revenue (combined ~1,36,44,661 across these 10 restaurants)
-- 5 of these top 10 restaurants have their rating as NULL
-- 2 of these top 10 restaurants fall under Highly-Rated restaurants
-- 3 of these top 10 restaurants fall under Moderately-Rated restaurants
-- according to the total revenue by rating-range report, restaurants with rating as NULL generate most revenue (53,83,83,400.00) and 
-- that is ~55% of total sales
-- ~86K out of ~147K restaurants have rating AS NULL

-- Verdict

-- 5 out of top 10 restaurants that generate most revenue have rating as NULL
-- ~86K out of ~148K restaurants have rating as NULL, dominating in count as compared to restaurants with ratings
-- because of that we can't inference whether restaurants with most sales high high rating or vice-versa


-- **********************************************************************************************--



-- What does the distribution of order value actually look like — is revenue driven by many small orders or a few huge ones?

SELECT COUNT(*) FROM orders
WHERE sales_amount IS NOT NULL; -- 148670 orders
SELECT SUM(sales_amount) FROM orders; -- 98,65,65,018

WITH CTE AS(
SELECT
*,
CASE 
    WHEN sales_amount < 500 THEN '<500'
    WHEN sales_amount < 1500 THEN '<1500'
    WHEN sales_amount < 2500 THEN '<2500' 
    ELSE '>2500'
END AS sales_range
FROM orders
WHERE sales_amount IS NOT NULL)
SELECT sales_range,
(COUNT(*)/(SELECT COUNT(*) FROM orders WHERE sales_amount IS NOT NULL))*100 AS total_orders_percent,
(SUM(sales_amount)/(SELECT SUM(sales_amount) FROM orders))*100 AS total_revenue_percent
FROM `CTE`
GROUP BY sales_range
ORDER BY total_revenue_percent DESC;


-- FINDINGS

-- Nearly half of all orders (49%) are under ₹500 -- this is the single largest group by count
-- But orders above ₹2500 make up only 27.4% of order volume yet generate 94.3% of total revenue
-- Average order value in the >2500 bucket is ₹22,808 -- over 100x the ₹203 average in the <500 bucket
-- Revenue is heavily concentrated: the bottom three buckets combined (72.6% of all orders) 
-- contribute only ~5.7% of total revenue

-- Verdict

-- Revenue is overwhelmingly driven by high-value orders, but "few" understates it -- over a quarter of all orders fall in the >2500 bracket. This is consistent with a platform that serves both everyday small orders and a substantial volume of bulk/catering-style orders, with the latter dominating revenue.
-- Worth a follow-up: segment the >2500 bucket further (e.g. 2500-5000 vs 5000+) to see whether revenue concentration is driven by a genuinely small number of very large outliers, or broadly across this whole group.


-- **********************************************************************************************--



-- Which cities have the most restaurants, and how does that compare to order volume from those cities?

SELECT t2.city, 
       COUNT(DISTINCT t2.id) AS total_restaurants,
       COUNT(t1.r_id) AS total_orders,
       ROUND(COUNT(t1.r_id) / COUNT(DISTINCT t2.id), 3) AS orders_per_restaurant
FROM restaurant t2
LEFT JOIN orders t1 ON t1.r_id = t2.id
GROUP BY t2.city
ORDER BY total_restaurants DESC
LIMIT 10;

-- FINDINGS

-- The top cities by restaurant count and by order count are identical, but this reflects the dataset's structure (~1 order per restaurant platform-wide) rather than a genuine demand signal — order volume here is not an independent measure from restaurant supply.



-- ********************************************************************************************--


-- Who are the top spenders, and how much of total revenue comes from them (customer concentration)?

SELECT SUM(sales_amount) FROM orders; -- total revenue = 98,65,65,018
SELECT t1.user_id, t2.name AS `name`, SUM(t1.sales_amount) AS total_amount FROM orders t1
JOIN users t2
ON t1.user_id=t2.user_id
GROUP BY t1.user_id, t2.name
ORDER BY total_amount DESC
LIMIT 10;

WITH CTE AS(SELECT t1.user_id, t2.name AS `name`, SUM(t1.sales_amount) AS total_amount FROM orders t1
JOIN users t2
ON t1.user_id=t2.user_id
GROUP BY t1.user_id, t2.name
ORDER BY total_amount DESC
LIMIT 10)
SELECT (SUM(total_amount)/(SELECT SUM(sales_amount) FROM orders))*100 AS total_revenue FROM CTE;


-- users Amanda Ballard, Gina Carpenter, Jonathan Vasquez, Lisa Aguirre, Richard Edwards, Elizabeth Martin, Brian White, Cassandra Benson, Elizabeth Rvan, Jeffrey Smith are the top spending users
-- The top 10 customers contribute approximately 1.39% of total revenue,
-- indicating relatively low revenue concentration among the highest-spending customers.

-- ********************************************************************************************--



-- Which customer segments generate the most revenue?

SELECT SUM(sales_amount) FROM orders; -- total revenue = 986565018
SELECT t1.age, t1.gender, t1.marital_status, t1.occupation, SUM(t2.sales_amount) AS total_revenue, (SUM(t2.sales_amount)/(SELECT SUM(sales_amount) FROM orders))*100 AS total_revenue_percent FROM users t1
JOIN orders t2
ON t1.user_id = t2.user_id
GROUP BY t1.age, t1.gender, t1.occupation, t1.marital_status
ORDER BY total_revenue DESC;

SELECT (SUM(total_revenue)/(SELECT SUM(sales_amount) FROM orders))*100 FROM (SELECT t1.age, t1.gender, t1.marital_status, t1.occupation, SUM(t2.sales_amount) AS total_revenue, (SUM(t2.sales_amount)/(SELECT SUM(sales_amount) FROM orders))*100 AS total_revenue_percent FROM users t1
JOIN orders t2
ON t1.user_id = t2.user_id
GROUP BY t1.age, t1.gender, t1.occupation, t1.marital_status
ORDER BY total_revenue DESC
LIMIT 3)x;


-- The top 3 customer demographic segments are concentrated among
-- 22–23-year-old students, with both male and female segments represented.
-- Together, these top 3 segments contribute approximately 23% of total revenue.



-- *******************************************************************************************--


-- Do repeat customers generate more revenue than one-time customers?

-- one-time customers
SELECT customer_return, COUNT(*) AS total_customers, SUM(sales_amount) AS total_revenue, (SUM(sales_amount)/(SELECT SUM(sales_amount) FROM orders))*100 AS percent_of_revenue FROM (SELECT
*,
CASE 
    WHEN user_id IN ((SELECT user_id FROM orders
    GROUP BY user_id
    HAVING COUNT(*) = 1)) THEN 'one-time'
    ELSE 'repeat'
END AS customer_return
FROM orders)x
GROUP BY customer_return
ORDER BY total_revenue DESC;

-- repeating customers generate more revenue than one-time customers
-- repeating customers contribute ~78% of total revenue
-- but, this is also because the count of repeating customers dominates count of one-time customer
-- repeating customers - 1,16,824
-- one-time - 33,457


-- *********************************************************************************************--


-- What percentage of total revenue comes from the top 1%, 5%, and 10% of customers?

WITH customer_revenue AS (
    SELECT
        user_id,
        SUM(sales_amount) AS total_revenue
    FROM orders
    GROUP BY user_id
),

customer_ranked AS (
    SELECT
        user_id,
        total_revenue,
        ROW_NUMBER() OVER (
            ORDER BY total_revenue DESC
        ) AS customer_rank,
        COUNT(*) OVER () AS total_customers
    FROM customer_revenue
)

SELECT
    'Top 1%' AS customer_group,
    ROUND(
        SUM(
            CASE
                WHEN customer_rank <= CEIL(total_customers * 0.01)
                THEN total_revenue
                ELSE 0
            END
        )
        / (SELECT SUM(sales_amount) FROM orders) * 100,
        2
    ) AS revenue_share

FROM customer_ranked

UNION ALL

SELECT
    'Top 5%',
    ROUND(
        SUM(
            CASE
                WHEN customer_rank <= CEIL(total_customers * 0.05)
                THEN total_revenue
                ELSE 0
            END
        )
        / (SELECT SUM(sales_amount) FROM orders) * 100,
        2
    )
FROM customer_ranked

UNION ALL

SELECT
    'Top 10%',
    ROUND(
        SUM(
            CASE
                WHEN customer_rank <= CEIL(total_customers * 0.10)
                THEN total_revenue
                ELSE 0
            END
        )
        / (SELECT SUM(sales_amount) FROM orders) * 100,
        2
    )
FROM customer_ranked;

-- top 1% -> 24.89% of total revenue
-- top 5% -> 53.76%
-- top 10% -> 69.38%