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

SELECT * FROM event_identifier

SELECT  
	visit_id,
	e.page_id,
	event_type
FROM
	events e 
	LEFT JOIN
	page_hierarchy ph
	ON
	ph.page_id = e.page_id
WHERE event_type NOT IN (4,5)
ORDER BY		
	visit_id

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


