------------------------------
-- Data Cleansing Steps --
------------------------------

ALTER TABLE weekly_sales ALTER column week_date VARCHAR(10)

UPDATE weekly_sales
SET week_date = STUFF(week_date,6,0,'20')
WHERE LEN(week_date) = 7

UPDATE weekly_sales
SET week_date = STUFF(week_date,5,0,'20')
WHERE LEN(week_date) = 6

UPDATE weekly_sales
SET week_date = STUFF(week_date,4,0,'0')
WHERE LEN(week_date) = 9

UPDATE weekly_sales
SET week_date = STUFF(week_date,3,0,'0')
WHERE LEN(week_date) = 8

UPDATE weekly_sales
SET week_date = STUFF(week_date,1,0,'0')
WHERE LEN(week_date) = 9

UPDATE weekly_sales
SET week_date= CONVERT(VARCHAR(10), CONVERT(DATE, week_date, 103), 120)

ALTER TABLE weekly_sales ALTER column week_date DATE

SELECT week_date FROM weekly_sales;

------------------------------
-- [Add new Column] --
------------------------------

ALTER TABLE weekly_sales
ADD week_number INT

ALTER TABLE weekly_sales
ADD month_number INT

ALTER TABLE weekly_sales
ADD calendar_year INT

UPDATE weekly_sales
SET week_number = DATEPART(WEEK,week_date)

UPDATE weekly_sales
SET month_number = DATEPART(MONTH,week_date)

UPDATE weekly_sales
SET calendar_year = DATEPART(YEAR,week_date)

ALTER TABLE weekly_sales
ADD age_band VARCHAR(20)

ALTER TABLE weekly_sales
ADD demographic  VARCHAR(9)

ALTER TABLE weekly_sales ALTER column segment VARCHAR(7)

UPDATE weekly_sales
SET demographic = CASE
						WHEN LEFT(segment,1) = 'C'
						THEN 'Couples'
						WHEN LEFT(segment,1) = 'F'
						THEN 'Families'
						WHEN segment = 'null'
						THEN  'unknown'
				 END

UPDATE weekly_sales
SET age_band = CASE
					WHEN RIGHT(segment,1) = '1'
					THEN 'Young Adults'
					WHEN RIGHT(segment,1) = '2'
					THEN 'Middle Aged'
					WHEN RIGHT(segment,1) = '3' OR RIGHT(segment,1) = '4'
					THEN 'Retirees'
					WHEN segment = 'null'
					THEN  'unknown'
			  END

UPDATE weekly_sales
SET segment = 'unknown'
WHERE segment = 'null' 

ALTER TABLE weekly_sales
ADD avg_transaction FLOAT

UPDATE weekly_sales
SET avg_transaction = ROUND( ( CONVERT(FLOAT,sales) / CONVERT(FLOAT,transactions) ),2)

ALTER TABLE weekly_sales ALTER COLUMN sales BIGINT

----------------------
-- Data Exploration --
----------------------

-- 1. What day of the week is used for each week_date value?
SELECT 
	DATENAME(WEEKDAY,week_date) AS week_day
FROM	
	weekly_sales
GROUP BY
	DATENAME(WEEKDAY,week_date)

-- 2. What range of week numbers are missing from the dataset?
CREATE TABLE #weeknumber (week_number INT);
GO
DECLARE @weeknumber INT 
SET @weeknumber = 1;
WHILE @weeknumber <= 52
BEGIN 
	INSERT INTO #weeknumber(week_number)
	VALUES(@weeknumber)
	SET @weeknumber =@weeknumber +1;
END
GO
SELECT week_number FROM #weeknumber WHERE week_number NOT IN (SELECT DISTINCT week_number FROM weekly_sales)

-- 3. How many total transactions were there for each year in the dataset?
SELECT  
	calendar_year,
	COUNT(transactions) AS no_transactions
FROM
	weekly_sales
GROUP BY
	calendar_year

-- 4. What is the total sales for each region for each month?
SELECT 
	region,
	month_number,
	SUM(sales) AS total_sale 
FROM	
	weekly_sales
GROUP BY
	region,
	month_number 
ORDER BY
	region,
	month_number 

-- 5. What is the total count of transactions for each platform
SELECT 
	platform,
	COUNT(transactions) AS total_transactions
FROM	
	weekly_sales
GROUP BY
	platform

-- 6. What is the percentage of sales for Retail vs Shopify for each month?

SELECT
	platform,
	ROUND( (( CONVERT(FLOAT, SUM(sales) ) / CONVERT( FLOAT, (SELECT SUM(sales) FROM weekly_sales) ) ) * 100), 2) AS sales_percent
FROM
	weekly_sales
GROUP BY
	platform

-- 7. What is the percentage of sales by demographic for each year in the dataset?
SELECT
	ws2.calendar_year,
	ws2.demographic,
	ROUND( (( CONVERT(FLOAT, SUM(sales) ) / CONVERT( FLOAT, (SELECT SUM(sales) FROM weekly_sales ws1 WHERE ws1.calendar_year = ws2.calendar_year) ) ) * 100), 2) AS sales_percent
FROM	
	weekly_sales ws2
GROUP BY
	ws2.calendar_year,
	ws2.demographic
ORDER BY
	2,1

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT TOP 1
	age_band,
	demographic,
	ROUND( (( CONVERT(FLOAT, SUM(sales) ) / CONVERT( FLOAT, (SELECT SUM(sales) FROM weekly_sales WHERE platform = 'Retail') ) ) * 100), 2) AS sales_percent
FROM	
	weekly_sales
GROUP BY
	age_band,
	demographic
ORDER BY 
	sales_percent DESC;

-- 9.find the average transaction size for each year for Retail vs Shopify? 
SELECT	
	calendar_year,
	platform,
	AVG(transactions)
FROM
	weekly_sales
GROUP BY
	calendar_year,
	platform
ORDER BY
	2,1;

------------------------------
-- [Before & After] --
------------------------------

-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales? 
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-4,'2020-06-15')) AND '2020-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2020-06-15' AND CONVERT(date,DATEADD(week,4,'2020-06-15')))

SELECT
'2020' as year,
'4 weeks' AS analysis_period,
@before_sales AS sales_before_2020_06_15,
@after_sales AS sales_after_2020_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate




-- 2. What about the entire 12 weeks before and after?
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-12,'2020-06-15')) AND '2020-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2020-06-15' AND CONVERT(date,DATEADD(week,12,'2020-06-15')))

SELECT
'2020' as year,
'12 weeks' AS analysis_period,
@before_sales AS sales_before_2020_06_15,
@after_sales AS sales_after_2020_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate


-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-4,'2018-06-15')) AND '2018-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2018-06-15' AND CONVERT(date,DATEADD(week,4,'2018-06-15')))

SELECT
'2018' as year,
'4 weeks' AS analysis_period,
@before_sales AS sales_before_2018_06_15,
@after_sales AS sales_after_2018_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate
-------------
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-4,'2019-06-15')) AND '2019-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2019-06-15' AND CONVERT(date,DATEADD(week,4,'2019-06-15')))

SELECT
'2019' as year,
'4 weeks' AS analysis_period,
@before_sales AS sales_before_2019_06_15,
@after_sales AS sales_after_2019_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate
------------------
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-4,'2020-06-15')) AND '2020-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2020-06-15' AND CONVERT(date,DATEADD(week,4,'2020-06-15')))

SELECT
'2020' as year,
'4 weeks' AS analysis_period,
@before_sales AS sales_before_2020_06_15,
@after_sales AS sales_after_2020_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate

---------------
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-12,'2018-06-15')) AND '2018-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2018-06-15' AND CONVERT(date,DATEADD(week,12,'2018-06-15')))

SELECT
'2018' as year,
'12 weeks' AS analysis_period,
@before_sales AS sales_before_2018_06_15,
@after_sales AS sales_after_2018_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate
-------------
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-12,'2019-06-15')) AND '2019-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2019-06-15' AND CONVERT(date,DATEADD(week,12,'2019-06-15')))

SELECT
'2019' as year,
'12 weeks' AS analysis_period,
@before_sales AS sales_before_2019_06_15,
@after_sales AS sales_after_2019_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate
----------------
GO
DECLARE @before_sales BIGINT;
SET @before_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN CONVERT(date,DATEADD(week,-12,'2020-06-15')) AND '2020-06-15')
DECLARE @after_sales BIGINT;
SET @after_sales = (SELECT SUM(sales) FROM weekly_sales WHERE week_date BETWEEN '2020-06-15' AND CONVERT(date,DATEADD(week,12,'2020-06-15')))

SELECT
'2020' as year,
'12 weeks' AS analysis_period,
@before_sales AS sales_before_2020_06_15,
@after_sales AS sales_after_2020_06_15,
@after_sales-@before_sales AS reduction_growth_amount,
ROUND(((ABS((CAST( @after_sales AS FLOAT) -CAST( @before_sales AS FLOAT)))/CAST( @before_sales AS FLOAT))*100), 2) as reduction_growth_rate