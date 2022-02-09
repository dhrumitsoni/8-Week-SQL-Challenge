------------
-- Tables --
------------

SELECT * FROM event_identifier;
SELECT * FROM campaign_identifier;
SELECT * FROM page_hierarchy;
SELECT * FROM users;
SELECT * FROM events;

----------------------
-- DIGITAL ANALYSIS --
----------------------

-- 1. How many users are there?
SELECT
	COUNT(DISTINCT user_id) AS total_users
FROM
	users

-- 2. How many cookies does each user have on average?
SELECT
	AVG(no_cookie) as avg_cookie_per_user
FROM
	(SELECT
		user_id,
		count(cookie_id) AS no_cookie
	 FROM
		users
	 GROUP BY
		user_id
	) AS
	cookie_count

-- 3. What is the unique number of visits by all users per month?
SELECT
	DATENAME(MONTH,event_time) AS month,
	COUNT(DISTINCT visit_id) AS total_visits
FROM
	events
GROUP BY
	DATENAME(MONTH,event_time)
ORDER BY
	total_visits DESC;

-- 4. What is the number of events for each event type?
SELECT 
	event_type,
	COUNT(event_type) no_event
FROM 
	events
GROUP BY
	event_type
ORDER BY
	1;

-- 5. What is the percentage of visits which have a purchase event?
DECLARE @total_visit INT, @purchase_event INT;
SET @total_visit = (SELECT COUNT(visit_id) FROM events)
SET @purchase_event = (SELECT COUNT(visit_id) FROM events WHERE event_type = 3)
SELECT
	ROUND((CONVERT(FLOAT,@purchase_event)/CONVERT(FLOAT,@total_visit)),2) AS purchase_event_percent

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
GO
DECLARE @total_visit INT, @chekout_no_purchase_event INT;
SET @total_visit = (SELECT COUNT(visit_id) FROM events)
SET @chekout_no_purchase_event = (SELECT COUNT(visit_id) FROM events WHERE page_id = 12 AND event_type <> 3)
SELECT
	ROUND((CONVERT(FLOAT,@chekout_no_purchase_event)/CONVERT(FLOAT,@total_visit)),2) AS chekout_no_purchase_event_percent

-- 7. What are the top 3 pages by number of views?
SELECT TOP 3
	page_id,
	COUNT(*) AS no_count
FROM 
	events
WHERE
	event_type = 1
GROUP BY
	page_id
ORDER BY
	no_count

-- 8. What is the number of views and cart adds for each product category?

SELECT
	product_category,
	SUM(CASE
			WHEN event_type = 1
			THEN 1
			ELSE 0
		END )AS views,
	SUM(CASE
			WHEN event_type = 2
			THEN 1	
			ELSE 0
		END )As added_to_carts
FROM	
	events e
	LEFT JOIN
	page_hierarchy ph
	ON
	ph.page_id = e.page_id
WHERE
	product_category IS NOT NULL
GROUP BY
	product_category

--9. What are the top 3 products by purchases?
GO
WITH purchase_cte AS
(
SELECT
	page_name
FROM	
	events e
	JOIN 
	page_hierarchy ph
	ON
	ph.page_id = e.page_id
WHERE
	visit_id IN (SELECT visit_id FROM events WHERE event_type = 3) AND e.page_id NOT IN (1,2,12,13) AND event_type = 2
)
SELECT TOP 3
	page_name,
	COUNT(*) times_purchase
FROM
	purchase_cte
GROUP BY
	page_name
ORDER BY
	times_purchase DESC

-----------------------------
-- Product Funnel Analysis --
-----------------------------

--Using a single SQL query - create a new output table which has the following details:

--How many times was each product viewed?
--How many times was each product added to cart?
--How many times was each product added to a cart but not purchased (abandoned)?
--How many times was each product purchased?

WITH product_page_events AS ( -- Note 1
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM events AS e
  JOIN page_hierarchy AS ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
purchase_events AS ( -- Note 2
  SELECT 
    DISTINCT visit_id
  FROM events
  WHERE event_type = 3 -- 3 for Purchase
),
combined_table AS ( -- Note 3
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM product_page_events AS ppe
  LEFT JOIN purchase_events AS pe
    ON ppe.visit_id = pe.visit_id
),
product_info AS (
  SELECT 
	product_id,
    product_name, 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_id, product_name, product_category)

SELECT *
INTO #product_info
FROM product_info
ORDER BY product_id
GO
SELECT * FROM #product_info

-- Table which further aggregates the data for the above points but 
-- this time for each product category instead of individual products.
GO
WITH product_page_events AS ( -- Note 1
  SELECT 
    e.visit_id,
    ph.product_id,
    ph.page_name AS product_name,
    ph.product_category,
    SUM(CASE WHEN e.event_type = 1 THEN 1 ELSE 0 END) AS page_view, -- 1 for Page View
    SUM(CASE WHEN e.event_type = 2 THEN 1 ELSE 0 END) AS cart_add -- 2 for Add Cart
  FROM events AS e
  JOIN page_hierarchy AS ph
    ON e.page_id = ph.page_id
  WHERE product_id IS NOT NULL
  GROUP BY e.visit_id, ph.product_id, ph.page_name, ph.product_category
),
purchase_events AS ( -- Note 2
  SELECT 
    DISTINCT visit_id
  FROM events
  WHERE event_type = 3 -- 3 for Purchase
),
combined_table AS ( -- Note 3
  SELECT 
    ppe.visit_id, 
    ppe.product_id, 
    ppe.product_name, 
    ppe.product_category, 
    ppe.page_view, 
    ppe.cart_add,
    CASE WHEN pe.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
  FROM product_page_events AS ppe
  LEFT JOIN purchase_events AS pe
    ON ppe.visit_id = pe.visit_id
),
product_category AS (
  SELECT 
    product_category, 
    SUM(page_view) AS views,
    SUM(cart_add) AS cart_adds, 
    SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
  FROM combined_table
  GROUP BY product_category)

SELECT *
INTO #product_category
FROM product_category
GO

SELECT * FROM #product_category

-----------------------------------------
-- 1. Which product had the most views, cart adds and purchases?
SELECT TOP 1
	product_name,
	views
FROM
	#product_info
ORDER BY 
	views DESC;

-- cart adds
SELECT TOP 1
	product_name,
	cart_adds
FROM
	#product_info
ORDER BY 
	cart_adds DESC;

-- most purchases
SELECT TOP 1
	product_name,
	purchases
FROM
	#product_info
ORDER BY 
	purchases DESC;

-- 2. Which product was most likely to be abandoned?
SELECT TOP 1
	product_name,
	abandoned
FROM
	#product_info
ORDER BY 
	abandoned DESC;

-- 3. Which product had the highest view to purchase percentage?
SELECT
	product_name, 
	product_category, 
	ROUND(100 * purchases/views,2) AS purchase_per_view_percentage
FROM 
	#product_info
ORDER BY 
	purchase_per_view_percentage DESC

-- 4. What is the average conversion rate from view to cart add?
SELECT
	ROUND(100*AVG(cast(cart_adds as float)/cast(views as float)),2) AS avg_view_to_cart_add_conversion
FROM	
	#product_info

-- 5. What is the average conversion rate from cart add to purchase?
SELECT 
	ROUND(100*AVG(cast(purchases as float)/cast(cart_adds as float)),2) AS avg_cart_add_to_purchases_conversion_rate
FROM 
	#product_info

------------------------
-- CAMPAIGNS ANALYSIS --
------------------------
GO
WITH global_cte AS (
SELECT 
	user_id,
	visit_id,
	MIN(event_time) AS visit_start_time,  
	COUNT(e.page_id) AS page_views,
	(SELECT COUNT(event_type) FROM events e1 WHERE event_type = 2 AND e1.visit_id = e.visit_id) AS cart_adds,
	SUM(CASE
		WHEN event_type = 3
		THEN 1
		ELSE 0
	END) AS purchase,
	(SELECT campaign_name FROM campaign_identifier WHERE MIN(event_time) BETWEEN start_date AND end_date) campaign_name,
	(SELECT COUNT(event_type) FROM events e1 WHERE event_type = 4 AND e1.visit_id = e.visit_id) AS impression,
	(SELECT COUNT(event_type) FROM events e1 WHERE event_type = 5 AND e1.visit_id = e.visit_id) AS click
FROM
	events e
	JOIN
	users u 
	ON
	u.cookie_id = e.cookie_id
	LEFT JOIN 
	page_hierarchy ph 
	ON 
	ph.page_id = e.page_id	
GROUP BY
	user_id,
	visit_id
)
SELECT DISTINCT 
	user_id, visit_id, visit_start_time, page_views, cart_adds, purchase,global_cte.campaign_name,impression,click
FROM
	global_cte
ORDER BY
	user_id
GO


