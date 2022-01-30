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
	event_type
	--COUNT(DISTINCT )
FROM 
	events

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

------------------------
-- CAMPAIGNS ANALYSIS --
------------------------
CREATE TABLE #campaign_data (campaign_id int, product_id INT, campaign_name varchar(33), start_date DATE, end_date DATE)
GO
DECLARE @start INT, @end INT;
DECLARE @count INT, @max INT ;

SET @count = 1;
SET @max = (SELECT count(*) FROM campaign_identifier)

WHILE @count <= @max
BEGIN
	SET @start = (SELECT LEFT(products,1) FROM campaign_identifier WHERE campaign_id = @count)
	SET @end = (SELECT RIGHT(products,1) FROM campaign_identifier WHERE	campaign_id = @count)

		WHILE @start <= @end
		BEGIN
			INSERT INTO #campaign_data
			SELECT campaign_id,@start,campaign_name,start_date,end_date  FROM campaign_identifier WHERE	campaign_id = @count
	
			SET @start = @start + 1;
	
		END
	SET @count = @count + 1;
END
GO
SELECT * FROM #campaign_data
----------------------------
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
),
campaign_cte AS (SELECT * FROM #campaign_data)
SELECT DISTINCT
	user_id, visit_id, visit_start_time, page_views, cart_adds, purchase,  
	CASE		
		WHEN visit_start_time BETWEEN start_date AND end_date
		THEN campaign_name
	END AS campaign_name,
	impression, click
FROM
	global_cte,campaign_cte
ORDER BY
	user_id




