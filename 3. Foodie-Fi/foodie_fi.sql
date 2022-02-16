------------
-- Tables --
------------

 SELECT * FROM plans;
 SELECT * FROM subscriptions;

----------------------
-- Customer Journey --
----------------------

SELECT 
	s.customer_id,
	count(plan_id)
	--(SELECT plan_name FROM plans p WHERE p.plan_id = s.plan_id) AS plan_name
FROM 
	subscriptions s 
WHERE 
	customer_id IN (5,50,500,6,60,600,7,70) 
GROUP BY 
	customer_id

-----------------------------
-- Data Analysis Questions --
-----------------------------

-- 1. How many customers has Foodie-Fi ever had?

SELECT 
	COUNT(DISTINCT customer_id) AS total_customers
FROM 
	subscriptions

-- 2. What is the monthly distribution of 
--    trial plan start_date values for our dataset 
--  - use the start of the month as the group by value

SELECT 
	MONTH(start_date) AS month_no, 
	DATENAME(month,start_date) AS month_name,
	COUNT(*) AS no_trial_plan 
FROM 
	subscriptions 
WHERE 
	plan_id = 0 
GROUP BY 
	DATENAME(month,start_date),
	MONTH(start_date) 
ORDER BY
	MONTH(start_date)
	

-- 3. What plan start_date values occur after the year 2020 for our dataset? 
--    Show the breakdown by count of events for each plan_name

SELECT 
	 p.plan_name,
	 COUNT(*) times_bought
FROM 
	subscriptions s
	JOIN
	plans p
	ON
	p.plan_id = s.plan_id
WHERE 
	start_date > '2020-01-01'
GROUP BY
	p.plan_name

-- 4. What is the customer count and percentage of customers
--    who have churned rounded to 1 decimal place?

SELECT
	count(*) AS chrun_customer,
	round(((convert(float,count(*))/convert(float,(SELECT count(distinct customer_id)  AS total_customer FROM subscriptions)))*100),2) AS chrun_percent
FROM 
	subscriptions 
WHERE 
	plan_id = 4 


-- 5. How many customers have churned straight after their initial free trial 
--  - what percentage is this rounded to the nearest whole number?

WITH cteTrialChurned AS
(
SELECT 
	customer_id,
	plan_id,
	DENSE_RANK() OVER(partition by customer_id order by plan_id ) AS rank 
FROM 
	subscriptions
)
SELECT 
	count(*)AS chruned_guys,
	ROUND(((convert(FLOAT,count(*)) / convert(FLOAT,(SELECT COUNT(DISTINCT customer_id) FROM cteTrialChurned)))*100),0) AS chruned_guys_percent
FROM
	cteTrialChurned
WHERE 
	rank = 2 AND plan_id = 4
      
-- 6. What is the number and percentage of customer plans after 
--    their initial free trial?


WITH cteCustomerPlanRank AS
(
SELECT 
	customer_id,
	plan_id,
	DENSE_RANK() OVER(partition by customer_id order by plan_id ) AS rank 
FROM 
	subscriptions
)
SELECT
	plan_id AS next_plan,
	count(*) no_customer,
	ROUND(((convert(FLOAT,count(*)) / convert(FLOAT,(SELECT COUNT(DISTINCT customer_id) FROM cteCustomerPlanRank)))*100),1) AS no_customer_percent

FROM	
	cteCustomerPlanRank
WHERE
	plan_id in(1,2,3,4)  AND rank = 2
GROUP BY 
	plan_id
ORDER BY
	plan_id

-- 7. What is the customer count and percentage breakdown of
--    all 5 plan_name values at 2020-12-31?

WITH next_date_cte AS (
    SELECT *,
            LEAD (start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_date
    FROM 
		subscriptions
),
customers_on_date_cte AS (
    SELECT 
		plan_id, 
		COUNT(DISTINCT customer_id) AS customers
    FROM 
		next_date_cte
    WHERE 
			(next_date IS NOT NULL AND ('2020-12-31'> start_date AND '2020-12-31' < next_date)) OR (next_date IS NULL AND '2020-12-31' > start_date)
    GROUP BY 
		plan_id
)
SELECT
	*,
	ROUND(((convert(FLOAT,customers) / convert(FLOAT,(SELECT COUNT(DISTINCT customer_id) FROM subscriptions)))*100),1) AS no_customer_percent
FROM
	customers_on_date_cte 


-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT
	count(DISTINCT customer_id) AS customer_count
FROM	
	subscriptions
WHERE 
	DATEPART(YEAR,start_date) = 2020 AND plan_id = 3

-- 9. How many days on average does it take for a customer 
--    to an annual plan from the day they join Foodie-Fi?
WITH cteTrialPlan AS
(SELECT 
	customer_id,
	start_date AS trial_date
FROM
	subscriptions
WHERE
	plan_id = 0
),
cteAnnualPlan AS
(SELECT 
	customer_id,
	start_date AS annual_date
FROM
	subscriptions
WHERE
	plan_id = 3
)
SELECT
	AVG(DATEDIFF(D,trial_date,annual_date)) AS avg_days_to_upgrade
FROM
	cteAnnualPlan ap
	JOIN
	cteTrialPlan tp
	ON
	ap.customer_id = tp.customer_id

-- 10. Can you further breakdown this average value into 30 day periods 
--     (i.e. 0-30 days, 31-60 days etc)
WITH tiral_to_annual_cte AS(
SELECT
	*
FROM
	(SELECT DISTINCT
	s1.customer_id,
	DATEDIFF(day,(SELECT start_date FROM subscriptions s2 WHERE s1.customer_id = s2.customer_id AND s2.plan_id = 0),(SELECT start_date FROM subscriptions s2 WHERE s1.customer_id = s2.customer_id AND s2.plan_id = 3)) AS tiral_to_annual
FROM 
	subscriptions s1) AS upgrade
WHERE
	tiral_to_annual IS NOT NULL
),
breakdown_cte AS(
SELECT
	'customer' AS breakdown,
	count(CASE WHEN tiral_to_annual>= 1 AND tiral_to_annual <= 30 THEN 1 END) AS [001 - 030],
	count(CASE WHEN tiral_to_annual>= 31 AND tiral_to_annual <= 60 THEN 1 END) AS [031 - 060],
	count(CASE WHEN tiral_to_annual>= 61 AND tiral_to_annual <= 90 THEN 1 END) AS [061 - 090],
	count(CASE WHEN tiral_to_annual>= 91 AND tiral_to_annual <= 120 THEN 1 END) AS [091 - 120],
	count(CASE WHEN tiral_to_annual>= 121 AND tiral_to_annual <= 150 THEN 1 END) AS [121 - 150],
	count(CASE WHEN tiral_to_annual>= 151 AND tiral_to_annual <= 180 THEN 1 END) AS [151 - 180],
	count(CASE WHEN tiral_to_annual>= 181 AND tiral_to_annual <= 210 THEN 1 END) AS [181 - 210],
	count(CASE WHEN tiral_to_annual>= 211 AND tiral_to_annual <= 240 THEN 1 END) AS [211 - 240],
	count(CASE WHEN tiral_to_annual>= 241 AND tiral_to_annual <= 270 THEN 1 END) AS [241 - 270],
	count(CASE WHEN tiral_to_annual>= 271 AND tiral_to_annual <= 300 THEN 1 END) AS [271 - 300],
	count(CASE WHEN tiral_to_annual>= 301 AND tiral_to_annual <= 330 THEN 1 END) AS [301 - 330],
	count(CASE WHEN tiral_to_annual>= 331 AND tiral_to_annual <= 360 THEN 1 END) AS [331 - 360]
FROM	
	tiral_to_annual_cte
),
pivot_cte AS(
SELECT * 
FROM breakdown_cte 
UNPIVOT(
	customers
	FOR bins IN ([001 - 030], [031 - 060], [061 - 090], [091 - 120], [121 - 150], [151 - 180], [181 - 210], [211 - 240], [241 - 270], [271 - 300], [301 - 330], [331 - 360])
)
AS unpvt
)
SELECT 
	bins AS day_range,
	customers AS customer_count
FROM pivot_cte

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

GO
WITH cteRankLead AS
(
SELECT
	customer_id,
	plan_id,
	start_date,
	LEAD(plan_id,1) OVER( PARTITION BY customer_id ORDER BY plan_id) AS next_plan
FROM
	subscriptions
)
SELECT 
	count(customer_id) AS downgraded_user
FROM
	cteRankLead
WHERE
plan_id = 3 AND next_plan = 1



