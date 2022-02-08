------------
-- Tables --
------------

SELECT * FROM runners;
SELECT * FROM customer_orders;
SELECT * FROM runner_orders;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;

-------------------
-- DATA CLEANING --
-------------------

-- pizza_recipe
ALTER TABLE pizza_recipes ALTER COLUMN toppings VARCHAR(60);

-- customer_order
UPDATE
	customer_orders
SET exclusions = ''
WHERE exclusions = NULL OR exclusions = 'null';


UPDATE
	customer_orders
SET extras = ''
WHERE extras IS NULL OR extras = 'null';


-- runner_orders
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

ALTER TABLE runner_orders ALTER COLUMN pickup_time DATETIME;

ALTER TABLE runner_orders ALTER COLUMN distance_km FLOAT;

ALTER TABLE runner_orders ALTER COLUMN duration_min INT;


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

-- view 
GO
CREATE VIEW vwPizzaRecipe
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

SELECT * FROM vwPizzaRecipe

-------------------
-- Pizza Metrics --
-------------------

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
	DATEPART(HH,order_time) AS hour_of_day,
	COUNT(order_id) AS volume_of_pizza
FROM 
	customer_orders
GROUP BY 
	DATEPART(HH,order_time);

--10. What was the volume of orders for each day of the week?
SELECT 
	DATENAME(WEEKDAY,order_time) AS week_day,
	COUNT(order_id) AS volume_of_pizza
FROM customer_orders
GROUP BY DATENAME(WEEKDAY,order_time)
ORDER BY 2 DESC,1 DESC;

------------------------------------
-- Runner And Customer Experience --
------------------------------------

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
	ROUND(AVG(r.distance_km),1) AS avg_distance_km
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

----------------------------
-- Ingredient Optimization --
-----------------------------

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
CREATE VIEW vwExcludeAndExtra AS 
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

-------------------------
-- Pricing and Ratings --
-------------------------

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

-- 2. What if there was an additional $1 charge for any pizza extras?
--    Add cheese is $1 extr
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