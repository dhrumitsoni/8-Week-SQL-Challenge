------------
-- Tables --
------------

SELECT * FROM interest_metrics
SELECT * FROM interest_map

---------------------------
-- Let's deal with NULLs --
---------------------------
GO
UPDATE interest_metrics
SET month_year = NULL
WHERE month_year ='NULL'

GO
UPDATE interest_metrics
SET _month = NULL
WHERE _month ='NULL'

GO
UPDATE interest_metrics
SET _year = NULL
WHERE _year ='NULL'

GO
UPDATE interest_metrics
SET interest_id = NULL
WHERE interest_id ='NULL'
GO

-----------------------------------
-- Data Exploraing and cleansing --
-----------------------------------

-- 1. Update the interest_metrics table by modifying the month_year column 
--    to be a date data type with the start of the month

ALTER TABLE interest_metrics ALTER COLUMN month_year VARCHAR(10)

GO
UPDATE interest_metrics
SET month_year = STUFF(month_year,1,0,'01-')
WHERE month_year IS NOT NULL

GO
UPDATE interest_metrics
SET month_year = CONVERT(varchar(10),convert(DATE,month_year,105),120)
WHERE month_year IS NOT NULL

GO
ALTER TABLE interest_metrics ALTER COLUMN month_year DATE

GO
SELECT * FROM interest_metrics

-- 2. What is count of records in the interest_metrics for each month_year value sorted in chronological order 
--    (earliest to latest) with the null values appearing first?

SELECT 
	month_year,
	COUNT(*) AS total_record
FROM	
	interest_metrics
GROUP BY
	month_year 
ORDER BY
	1 ASC;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- Ans.
------> NULL vales is present in '_month', '_year', 'month_year' and 'intrest_id', here 'intrest_id' is important so before dopping null we have to check its effact on whole dataset
------> Let's calculate total percet on 'NULL' in intrest_id
SELECT 
  CAST(((SUM(CASE WHEN interest_id IS NULL THEN 1 END) * 1.0 / COUNT(*))*100) AS DECIMAL(4,2)) AS null_perc
FROM 
	interest_metrics

-- > ~ 8.4 % of total entiries of intrest_id contains NULL which will not make any big impact on further analysis so its safe to drop them

DELETE FROM 
	interest_metrics
WHERE 
	interest_id IS NULL;

--> lets again check for NULLs in intrest_id
SELECT 
  CAST(((SUM(CASE WHEN interest_id IS NULL THEN 1 END) * 1.0 / COUNT(*))*100) AS DECIMAL(4,2)) AS null_perc
FROM 
	interest_metrics

-- 4. How many interest_id values exist in the interest_metrics table but not in the interest_map table?
--    What about the other way around?

SELECT 
  COUNT(DISTINCT map.id) AS map_id_count,
  COUNT(DISTINCT metrics.interest_id) AS metrics_id_count,
  SUM(CASE WHEN map.id is NULL THEN 1 END) AS not_in_metric,
  SUM(CASE WHEN metrics.interest_id is NULL THEN 1 END) AS not_in_map
FROM 
	interest_map map
	FULL OUTER JOIN 
	interest_metrics metrics
	ON 
	metrics.interest_id = map.id;

-- 5. Summarise the id values in the interest_map by its total record count in this table

SELECT 
  id, 
  interest_name, 
  COUNT(*) AS count
FROM 
	interest_map map
	JOIN 
	interest_metrics metrics
	ON 
	map.id = metrics.interest_id
GROUP BY 
	id, interest_name
ORDER BY 
	3 DESC, id;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking 
--    the rows where interest_id = 21246 in your joined output and include all columns from interest_metrics 
--    and all columns from interest_map except from the id column.

SELECT 
	month_year,
	interest_id,
	interest_name,
	interest_summary,
	created_at,
	last_modified,
	composition,
	index_value,
	ranking,
	percentile_ranking
FROM 
	interest_map map
	INNER JOIN 
	interest_metrics metrics
	ON	
	map.id = metrics.interest_id
WHERE 
	metrics.interest_id = 21246 AND metrics._month IS NOT NULL;

-- 7. Are there any records in your joined table where the month_year value is before the created_at value 
--    from the interest_map table? Do you think these values are valid and why?

SELECT 
  COUNT(*) AS count
FROM
	interest_map map
	INNER JOIN 
	interest_metrics metrics
	ON 
	map.id = metrics.interest_id
WHERE 
	metrics.month_year < map.created_at

--> There are 188 records where the month_year date is before the created_at date
--> these records are created in the same month as month_year
--> Seems like all the records' dates are in the same month, hence we will consider the records as valid.

-----------------------
-- Interest Analysis --
-----------------------

-- 1. Which interests have been present in all month_year dates in our dataset?

SELECT 
  COUNT(DISTINCT month_year) AS unique_month_year_count, 
  COUNT(DISTINCT interest_id) AS unique_interest_id_count
FROM 
	interest_metrics
GO

WITH interest_cte AS (
	SELECT 
		interest_id, 
		COUNT(DISTINCT month_year) AS total_months
	FROM 
		interest_metrics
	WHERE 
		month_year IS NOT NULL
	GROUP BY 
		interest_id
)
SELECT 
  c.total_months,
  COUNT(DISTINCT c.interest_id) AS count
FROM 
	interest_cte c
WHERE 
	total_months = 14
GROUP BY 
	c.total_months
ORDER BY count DESC;

-- 3. Using this same total_months measure 
-- - calculate the cumulative percentage of all records starting at 14 months
-- - which total_months value passes the 90% cumulative percentage value?

WITH cte_interest_months AS (
	SELECT
		interest_id,
		MAX(DISTINCT month_year) AS total_months
	FROM 
		interest_metrics
	WHERE 
		interest_id IS NOT NULL
	GROUP BY 
		interest_id
),
cte_interest_counts AS (
	SELECT
		total_months,
		COUNT(DISTINCT interest_id) AS interest_count
	FROM 
		cte_interest_months
	GROUP BY 
		total_months
)
SELECT
	total_months,
	interest_count,
	ROUND(100 * SUM(interest_count) OVER (ORDER BY total_months DESC),
	(SUM(INTEREST_COUNT) OVER ()),2) AS cumulative_percentage
FROM 
	cte_interest_counts;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question
-- - how many total data points would we be removing?

SELECT DISTINCT
	_month
	
FROM
	interest_metrics

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example 
--    where there are all 14 months present to a removed interest example for your arguments
--  - think about what it means to have less months present from a segment perspective.



-- 5. After removing these interests - how many unique interests are there for each month?

----------------------
-- Segment Analysis --
----------------------

-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, 
--    which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year



-- 2. Which 5 interests had the lowest average ranking value?



-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value



-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values 
--   for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
--   For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values 
--   for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?



-- 5. How would you describe our customers in this segment based off their composition and ranking values? 
--    What sort of products or services should we show to these customers and what should we avoid?



--------------------
-- Index Analysis --
--------------------

--The index_value is a measure which can be used to reverse calculate the average composition for Fresh Segments’ clients.
--Average composition can be calculated by dividing the composition column by the index_value column rounded to 2 decimal places.

-- 1. What is the top 10 interests by the average composition for each month?


-- 2. For all of these top 10 interests - which interest appears the most often?


-- 3. What is the average of the average composition for the top 10 interests for each month?


-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 
--    and include the previous top ranking interests in the same output shown below.


-- 5. Provide a possible reason why the max average composition might change from month to month? 
--    Could it signal something is not quite right with the overall business model for Fresh Segments?