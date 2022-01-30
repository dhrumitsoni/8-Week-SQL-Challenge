SELECT * FROM interest_metrics
SELECT * FROM interest_map

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

ALTER TABLE interest_metrics ALTER COLUMN month_year VARCHAR(10)

UPDATE interest_metrics
SET month_year = STUFF(month_year,1,0,'01-')
WHERE month_year IS NOT NULL

ALTER TABLE interest_metrics ALTER COLUMN month_year DATE

-- 2.
SELECT 
	month_year,
	COUNT(*)
FROM	
	interest_metrics
GROUP BY
	month_year 
ORDER BY
	1 ASC;

-- 4.
SELECT DISTINCT  interest_id FROM interest_metrics WHERE interest_id NOT IN (SELECT  id FROM interest_map);
SELECT * FROM interest_map WHERE id NOT IN (SELECT  interest_id FROM interest_metrics);



-----------------------
-- Interest Analysis --
-----------------------

-- 1. Which interests have been present in all month_year dates in our dataset?

