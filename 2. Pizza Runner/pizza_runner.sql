CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  "runner_id" INTEGER,
  "registration_date" DATE
);
INSERT INTO runners
  ("runner_id", "registration_date")
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  "order_id" INTEGER,
  "customer_id" INTEGER,
  "pizza_id" INTEGER,
  "exclusions" VARCHAR(4),
  "extras" VARCHAR(4),
  "order_time" DATETIME
);

INSERT INTO customer_orders
  ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  "order_id" INTEGER,
  "runner_id" INTEGER,
  "pickup_time" VARCHAR(19),
  "distance" VARCHAR(7),
  "duration" VARCHAR(10),
  "cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
  ("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  "topping_id" INTEGER,
  "topping_name" TEXT
);
INSERT INTO pizza_toppings
  ("topping_id", "topping_name")
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

SELECT * FROM runners;
SELECT * FROM customer_orders;
SELECT * FROM runner_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROm pizza_toppings;

--DATA CLEANING
--pizza_recipe
ALTER TABLE pizza_recipes ALTER COLUMN toppings VARCHAR(60);
--customer_order

UPDATE
	customer_orders
SET exclusions = ''
WHERE exclusions = NULL OR exclusions = 'null';


UPDATE
	customer_orders
SET extras = ''
WHERE extras IS NULL OR extras = 'null';


SELECT * FROM customer_orders;

SELECT	
	CONVERT(DATE,order_time) AS order_date,
	CONVERT(TIME(0), order_time) AS order_time
FROM
	customer_orders;

--Cleaning runner_orders
SELECT * FROM runner_orders;

ALTER TABLE runner_orders ALTER COLUMN pickup_time DATETIME;
ALTER TABLE runner_orders ALTER COLUMN distance_km FLOAT;
ALTER TABLE runner_orders ALTER COLUMN duration_min INT;

UPDATE
	runner_orders
SET cancellation = NULL
WHERE cancellation = '' OR cancellation = 'null';

UPDATE
	runner_orders
SET distance = NULL
WHERE distance = '' OR distance = 'null';

UPDATE
	runner_orders
SET duration = NULL
WHERE duration = '' OR duration = 'null';

UPDATE
	runner_orders
SET pickup_time = NULL
WHERE pickup_time = '' OR pickup_time = 'null';


UPDATE
	runner_orders
SET
	duration = TRIM('minutes'FROM duration)

UPDATE
	runner_orders
SET
	distance = TRIM('km'FROM distance)



EXEC sp_rename 'dbo.runner_orders.distance', 'distance_km', 'COLUMN';

EXEC sp_rename 'dbo.runner_orders.duration', 'duration_min', 'COLUMN';

ALTER VIEW vwPizzaRecipe
AS
(
SELECT
	r.pizza_id,
	pt.topping_id,
	pt.topping_name
FROM
	(
		SELECT 
			pizza_id,
			cast(value AS int) toppings 
		FROM
			pizza_recipes
			cross apply
			string_split(toppings, ',')
	) AS 
	r
	JOIN
	pizza_toppings pt
	ON 
	pt.topping_id = r.toppings
)



--pizza_names
ALTER TABLE pizza_names ALTER COLUMN pizza_name VARCHAR(20);
UPDATE
	pizza_names
SET
	pizza_name = convert(VARCHAR(20),pizza_name)

--pizza_toppings
ALTER TABLE pizza_toppings ALTER COLUMN topping_name VARCHAR(20);
UPDATE
	pizza_toppings
SET
	topping_name = convert(VARCHAR(20),topping_name)


-- A) Pizza Metrics

-- 1.How many pizzas were ordered?
SELECT 
	COUNT(*) AS Total_Pizza_Sell
FROM 
	customer_orders

--2.How many unique customer orders were made?
SELECT 
	count(DISTINCT order_id)  AS total_unique_orders
FROM 
	customer_orders

--3.How many successful orders were delivered by each runner?
SELECT
	runner_id,
	COUNT(order_id) As successful_delivery
FROM
	runner_orders
WHERE
	cancellation iS NULL
GROUP BY
	runner_id
ORDER BY
	runner_id

--4. How many of each type of pizza was delivered?
SELECT 
	pn.pizza_name,
	COUNT(r.order_id) AS total_deliveries 
FROM
	customer_orders o
	RIGHT JOIN
	runner_orders r
	ON
	r.order_id = o.order_id
	JOIN 
	pizza_names pn
	ON
	pn.pizza_id = o.pizza_id
WHERE
	cancellation iS NULL
GROUP BY
	pn.pizza_name

--5.How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	o.customer_id,
	SUM( CASE
			WHEN pn.pizza_name = 'Meatlovers'
			THEN 1
			ELSE 0	
		END) AS Meatlover,
	SUM( CASE
			WHEN pn.pizza_name = 'Vegetarian'
			THEN 1
			ELSE 0	
		END) AS Vegetarian
FROM
	customer_orders o
	JOIN 
	pizza_names pn
	ON
	pn.pizza_id = o.pizza_id
GROUP BY
	o.customer_id

--6. What was the maximum number of pizzas delivered in a single order?
SELECT TOP 1
	r.order_id,
	COUNT(o.order_id) pizza_deliver
FROM
	customer_orders o
	RIGHT JOIN
	runner_orders r
	ON
	r.order_id = o.order_id
WHERE
	cancellation IS NULL
GROUP BY
	r.order_id
ORDER BY
	COUNT(o.order_id) DESC

--7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT	
	customer_id,
	SUM(CASE
			WHEN o.exclusions IS NOT NULL OR o.extras IS NOT NULL 
			THEN 1
			ELSE 0
		END) AS aleast_one_change,
	SUM(CASE
			WHEN o.exclusions IS NULL OR o.extras IS NULL 
			THEN 1
			ELSE 0
		END) AS no_changes
FROM
	customer_orders o
	JOIN
	runner_orders r
	ON
	r.order_id = o.order_id
WHERE
	 r.cancellation IS NULL
GROUP BY
	customer_id

--8. How many pizzas were delivered that had both exclusions and extras
SELECT	
	SUM(CASE
			WHEN o.exclusions IS NOT NULL AND o.extras IS NOT NULL 
			THEN 1
			ELSE 0
		END) AS both_exclusion_extras
FROM
	customer_orders o
	JOIN
	runner_orders r
	ON
	r.order_id = o.order_id
WHERE
	 r.cancellation IS NULL

--9. What was the total volume of pizzas ordered for each hour of the day?
SELECT 
	DATEPART(HOUR,order_time) AS hour_of_day,
	COUNT(order_id) AS volume_of_pizza
FROM customer_orders
GROUP BY DATEPART(HOUR,order_time);

--10. What was the volume of orders for each day of the week?

SELECT 
	DATENAME(WEEKDAY,order_time) AS hour_of_day,
	COUNT(order_id) AS volume_of_pizza
FROM customer_orders
GROUP BY DATENAME(WEEKDAY,order_time)
ORDER BY 2 DESC,1 DESC;

--B. Runner And Customer Experience
--1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT DATEPART(WEEK, registration_date) AS registration_week,
 COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY DATEPART(WEEK, registration_date);

--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT DISTINCT
	r.runner_id,
	CONVERT(VARCHAR(5),AVG(DATEDIFF(MINUTE,c.order_time,pickup_time ))) + ' minutes' AS avg_pickup_time
FROM 
	runner_orders r
	JOIN 
	customer_orders c
	ON
	c.order_id = r.order_id
WHERE 
	pickup_time IS NOT NULL
GROUP BY 
	runner_id
--3). Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT 
	no_pizza,
	avg(avg_prep.prepare_time) AS prep_time
FROM(
	SELECT
		count(*) AS no_pizza,
		AVG(DATEDIFF(MINUTE,c.order_time,pickup_time )) AS prepare_time
	FROM 
		runner_orders r
		JOIN 
		customer_orders c
		ON
		c.order_id = r.order_id
	WHERE 
		cancellation IS NULL
	GROUP BY
		c.order_id
	) AS avg_prep

GROUP BY
	no_pizza
	
--4). What was the average distance travelled for each customer

SELECT 
	customer_id,
	ROUND(AVG(r.distance_km),1)
FROM
	customer_orders c
	JOIN
	runner_orders r
	ON
	r.order_id = c.order_id
GROUP BY 
	customer_id

--5).What was the difference between the longest and shortest delivery times for all orders?

SELECT 
	MAX(duration_min) - MIN(duration_min) AS dilvery_time_difference
FROM 
	runner_orders

--6). What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT
	runner_id,
	order_id,
	distance_km ,
	ROUND((convert(FLOAT,duration_min)/60),1) AS duration_hr,
	ROUND((distance_km / ROUND((convert(FLOAT,duration_min)/60),1)),1) AS speed
FROM
	runner_orders
WHERE 
	cancellation IS NULL
ORDER BY
	runner_id,
	order_id;

-- AVG Speed of each runner
SELECT
	runner_id,
	ROUND(AVG(ROUND((distance_km / ROUND((convert(FLOAT,duration_min)/60),1)),1)),1) AS avg_speed
FROM	
	runner_orders 
GROUP BY
	runner_id

--7). What is the successful delivery percentage for each runner?
SELECT 
	runner_id,
	(CAST(successful_delivery AS float)/CAST(total_orders AS FLOAT))*100 AS sucess_rate
FROM
(SELECT
	runner_id,
	SUM(CASE
			WHEN cancellation IS NULL
			THEN 1
			ELSE 0
		END) AS successful_delivery,
	COUNT(*) AS total_orders
FROM runner_orders
GROUP BY runner_id) AS d


--C. Ingredient Optimization

--1). What are the standard ingredients for each pizza?

SELECT  
	pn.pizza_name,
	STRING_AGG(topping_name, ', ') AS toppings
FROM 
	vwPizzaRecipe vw
	JOIN 
	pizza_names	pn
	ON
	pn.pizza_id = vw.pizza_id

GROUP BY
	pizza_name


--2). What was the most commonly added extra?

SELECT TOP 1
	pt.topping_name,
	count
FROM
(
SELECT
	CAST(VALUE AS INT) extras,
	COUNT(CAST(VALUE AS INT)) AS count
FROM
	customer_orders 
	CROSS APPLY
	STRING_SPLIT( extras, ',')
WHERE
	extras IS NOT NULL
GROUP BY
	CAST(VALUE AS INT)
) AS d
JOIN
pizza_toppings pt
ON
pt.topping_id = d.extras

--3). What was the most common exclusion?


SELECT TOP 1
	pt.topping_name,
	count AS most_excluded
FROM
(
SELECT
	CAST(VALUE AS INT) exclusions,
	COUNT(CAST(VALUE AS INT)) AS count
FROM
	customer_orders 
	CROSS APPLY
	STRING_SPLIT( exclusions, ',')
WHERE
	exclusions IS NOT NULL
GROUP BY
	CAST(VALUE AS INT)
	
) AS d
JOIN
pizza_toppings pt
ON
pt.topping_id = d.exclusions
ORDER BY
	count DESC;

--4). Generate an order item for each record in the customers_orders table in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

--view--
GO
ALTER VIEW vwExcludeAndExtra AS 
SELECT 
	c.order_id,
	c.pizza_id,
	pn.pizza_name,
	STUFF(
			( 
				SELECT ', ' + 
					topping_name
				FROM
					pizza_toppings pt
				WHERE
					topping_id in(SELECT value FROM STRING_SPLIT(c.exclusions,','))
				FOR XML PATH('')
			),1,1,''
		) AS exclude,
		(SELECT count(value) FROM string_split(c.exclusions,',') WHERE c.exclusions <> '') AS exclude_count,
		c.exclusions AS exclude_id,
	STUFF(
			( 
				SELECT ', ' + 
					topping_name
				FROM
					pizza_toppings pt
				WHERE
					topping_id in(SELECT value FROM STRING_SPLIT(c.extras,','))
				FOR XML PATH('')
			),1,1,''
		) AS extra,
		(SELECT count(value) FROM string_split(c.extras,',') WHERE c.extras <> '') AS extras_count,
		c.extras as extras_id
FROM
	customer_orders c
	JOIN
	pizza_names pn
	ON
	pn.pizza_id = c.pizza_id 

GO
--------QUERY-----------------

SELECT 
	order_id,
	CASE
		WHEN ee.exclude IS NULL AND ee.extra IS NULL
		THEN pizza_name
		ELSE	CASE
				WHEN ee.exclude IS NOT NULL AND ee.extra IS NULL
				THEN pizza_name + ' - Exclude : ' + ee.exclude
				ELSE	CASE
						WHEN ee.extra IS NOT NULL AND ee.exclude IS NULL
						THEN pizza_name + ' - Extra : ' + ee.extra
						ELSE	CASE	
									WHEN ee.extra IS NOT NULL AND ee.exclude IS NOT NULL
									THEN pizza_name + ' - Exclude :  ' + ee.exclude +'   - Extra : ' + ee.extra
								END
						END
				END
	END AS orders
FROM
	vwExcludeAndExtra ee
	
--5)Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

SELECT 
	ee.order_id,
	ee.pizza_name,
	(SELECT		
		STRING_AGG(topp,',') 
	FROM 
		(SELECT 
			case 
				WHEN  ee.extras_id = ''
				THEN ' '+topping_name
				WHEN  topping_id IN (SELECT VALUE FROM STRING_SPLIT(ee.extras_id,','))
				THEN ' 2x'+topping_name
				ELSE ' '+topping_name
			END AS topp
		FROM
		vwPizzaRecipe
		WHERE 
		vwPizzaRecipe.pizza_id = ee.pizza_id
		)AS pr
	) AS ingredient
FROM
	vwExcludeAndExtra ee
ORDER BY
	order_id

--6).What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
SELECT
	co.order_id,
	pizza_name,
	count(co.pizza_id) as pizza_count,
	SUM(CASE
		WHEN co.extras <> ''
		THEN 1
		ELSE 0
	END )AS exclusions
FROM
	customer_orders co
	join
	runner_orders ro
	ON
	ro.order_id = co.order_id
	join
	pizza_names pn
	ON
	pn.pizza_id = co.pizza_id
WHERE 
	ro.cancellation IS NULL
GROUP BY
	co.order_id,
	pizza_name

SELECT order_id, (SELECT count(value) FROM string_split(exclusions,',') WHERE exclusions <> '')
FROM customer_orders
--D). Pricing and Ratings
--1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
	pn.pizza_name,
	SUM(
		CASE
			WHEN co.pizza_id = 1
			THEN 12
			ELSE 10
		END) AS total_income
FROM	
	customer_orders co
	JOIN
	runner_orders ro
	ON
	ro.order_id = co.order_id
	JOIN 
	pizza_names pn
	ON
	pn.pizza_id = co.pizza_id
WHERE 
	ro.cancellation IS NULL
group by
	pn.pizza_name

--2).What if there was an additional $1 charge for any pizza extras?
--->Add cheese is $1 extr

SELECT 
	pn.pizza_name,
	SUM(
		CASE
			WHEN vw.pizza_id = 1 AND vw.extras_count = 0
			THEN 12
			WHEN vw.pizza_id = 2 AND vw.extras_count = 0
			THEN 10
			WHEN vw.pizza_id = 1 AND vw.extras_count <> 0
			THEN 12 + vw.extras_count 
			WHEN vw.pizza_id = 2 AND vw.extras_count <> 0
			THEN 10 + vw.extras_count
		END) AS total_income
FROM	
	vwExcludeAndExtra vw
	JOIN
	runner_orders ro
	ON
	ro.order_id = vw.order_id
	JOIN 
	pizza_names pn
	ON
	pn.pizza_id = vw.pizza_id
WHERE 
	ro.cancellation IS NULL
group by
	pn.pizza_name

-- 3). The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
--     how would you design an additional table for this new dataset - generate a schema for this new table and insert 
--     your own data for ratings for each successful customer order between 1 to 5.
DROP TABLE IF EXISTS ratings;
CREATE TABLE ratings (
    order_id INTEGER,
    rating INTEGER CONSTRAINT check1to5_rating CHECK (rating between 1 and 5),
    comment VARCHAR(150)
);
INSERT INTO ratings (order_id, rating, comment)
VALUES	('1', '3', 'Tasty'),
		('2', '4', ''),
		('3', '4', ''),
		('4', '2', 'The pizza arrived cold, really bad service'),
		('5', '2', ''),
		('6', NULL, ''),
		('7', '5', ''),
		('8', '5', 'Great service'),
		('9', NULL, ''),
		('10', '1', 'The pizza arrived upside down, really disappointed');

SELECT * FROM ratings;

-- 4) Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--  - customer_id
--  - order_id
--  - runner_id
--  - rating
--  - order_time
--  - pickup_time
--  - Time between order and pickup
--  - Delivery duration
--  - Average speed 
--  - Total number of pizzas
GO
DROP TABLE IF EXISTS #global_table
SELECT 
	g1.order_id,
	g1.customer_id,
	g1.total_pizza,
	g1.runner_id,
	g1.order_time,
	g1.pickup_time,
	convert(varchar,(g1.avg_pickup_time + r1.duration_min )) + ' min'  AS delivery_duration,
	convert(varchar,g1.avg_pickup_time) + ' min' AS avg_pickup_time,
	convert(varchar,FLOOR(g1.avg_speed)) + ' Km/H' AS avg_speed,
	g1.rating
INTO #global_table
FROM(
	SELECT 
		co.order_id,
		customer_id,
		runner_id,
		r.rating,
		count(pizza_id) AS total_pizza,
		order_time,
		pickup_time,
		CONVERT(VARCHAR(5),AVG(DATEDIFF(MINUTE,co.order_time,ro.pickup_time )))AS avg_pickup_time,
		ROUND(AVG(ROUND((ro.distance_km / ROUND((convert(FLOAT,ro.duration_min)/60),1)),1)),1) AS avg_speed
	FROM
		customer_orders co
		JOIN
		runner_orders ro
		ON
		ro.order_id = co.order_id
		JOIN
		ratings r 
		ON
		r.order_id = co.order_id
	WHERE 
		ro.cancellation IS NULL
	GROUP BY
		customer_id,
		co.order_id,
		runner_id,
		r.rating,
		order_time,
		pickup_time
	)AS 
	g1
	join 
	runner_orders r1
	ON 
	r1.order_id = g1.order_id
WHERE 
	r1.cancellation IS NULL
ORDER BY
	g1.order_id
GO
SELECT * FROM #global_table
GO

--5). If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras 
--    and each runner is paid $0.30 per kilometre traveled 
--    how much money does Pizza Runner have left over after these deliveries?
GO
WITH cte_Income AS
(
SELECT 
	SUM(
		CASE
			WHEN co.pizza_id = 1
			THEN 12
			ELSE 10
		END
		) AS total_income,
	 (SELECT sum(distance_km)*0.30 FROM runner_orders WHERE cancellation IS NULL) AS runner_salary

FROM	
	customer_orders co
	JOIN
	runner_orders ro
	ON
	ro.order_id = co.order_id
WHERE 
	ro.cancellation IS NULL
)
SELECT 
	(total_income-runner_salary) AS final_income
FROM 
	cte_Income
GO