SELECT * FROM sales
SELECT * FROM product_details

-------------------------------
-- High level Sales Analysis --
-------------------------------

-- 1. What was the total quantity sold for all products?
SELECT 
	product_name,
	SUM(qty) AS qty_sold
FROM	
	sales s
	LEFT JOIN
	product_details pd
	ON
	pd.product_id = s.prod_id
GROUP BY
	product_name

-- 2. What is the total generated revenue for all products before discounts?
GO
WITH sold_product_cte AS
(SELECT 
	prod_id,
	SUM(qty) AS qty_sold
FROM	
	sales s
GROUP BY
	prod_id
),
sales_cte AS (SELECT DISTINCT prod_id, price FROM sales )
SELECT
	SUM(price*qty_sold) AS total_revenue
FROM
	sold_product_cte sp
	JOIN
	sales_cte s
	ON
	s.prod_id = sp.prod_id

-- 3. What was the total discount amount for all products
SELECT 
	SUM(CAST(price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT)) As total_discounted_amount
FROM	
	sales

--------------------------
-- Transaction Analysis --
--------------------------

-- 1. How many unique transactions were there
SELECT 
	COUNT(DISTINCT txn_id) AS total_unique_transacions
FROM
	sales

-- 2. What is the average unique products purchased in each transaction?
SELECT 
	AVG(product_count) AS avg_product_count
FROM
	(SELECT
		txn_id,
		count(DISTINCT prod_id) AS product_count
	FROM 
		sales
	GROUP BY
		txn_id
	)as txn_details

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
--GO
--WITH gross_revenue_cte AS
--(
--SELECT
--	txn_id,
--	SUM(price - (CAST(price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT))) as gross_revenue
--FROM	
--	sales
--GROUP BY
--	txn_id
--),
--percent_rank_cte AS (
--SELECT
--	gross_revenue,
--	CAST(PERCENT_RANK() OVER(order by gross_revenue ) AS decimal(3,2))as percent_rank
--FROM
--	gross_revenue_cte
--)
--SELECT
--	AVG(gross_revenue) AS 
--FROM	
--	gross_revenue_cte

-- 4. What is the average discount value per transaction 
SELECT
	AVG(total_discounted_amount) AS avg_discount_per_transaction
FROM
	(SELECT
		txn_id,
		SUM(CAST(price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT)) As total_discounted_amount
	FROM	
		sales
	GROUP BY
		txn_id
	) AS txn_discount

-- 5. What is the percentage split of all transactions for members vs non-members?
DECLARE @member INT, @nonmember INT, @txnno INT;
SET @member = (SELECT COUNT(DISTINCT txn_id) FROM sales WHERE member = 't')
SET @nonmember = (SELECT COUNT(DISTINCT txn_id) FROM sales WHERE member = 'f')
SET @txnno = (SELECT COUNT(DISTINCT txn_id) FROM sales)
SELECT 	
	(CONVERT(FLOAT,CONVERT(FLOAT,@member)/CONVERT(FLOAT,@txnno)))*100 AS members,
	(CONVERT(FLOAT,CONVERT(FLOAT,@nonmember)/CONVERT(FLOAT,@txnno)))*100 AS non_members

-- 6. What is the average revenue for member transactions and non-member transactions?
GO
CREATE VIEW txn_detail_view AS
(
	SELECT	
		txn_id,
		member,
		SUM(price) AS txn_amount,
		SUM(CAST(price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT)) As discount
	FROM	
		sales
	GROUP BY
		txn_id,
		member
)
GO
DECLARE @member INT, @nonmember INT, @totalrevenue INT;
SET @member = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view WHERE member = 't' );
SET @nonmember = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view WHERE member = 'f' );
SET @totalrevenue = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view);
SELECT 
	@totalrevenue AS gross_revenue,
	@member AS members_revenue,
	@nonmember AS non_members_revenue

----------------------
-- Product Analysis --
----------------------

-- 1. What are the top 3 products by total revenue before discount?
GO
WITH sold_product_cte AS
(SELECT 
	 product_name,
	 s.prod_id,
	SUM(qty) AS qty_sold
FROM	
	sales s
	JOIN
	product_details d
	ON
	d.product_id =  s.prod_id
GROUP BY
	product_name,
	s.prod_id
),
sales_cte AS (SELECT DISTINCT prod_id, price FROM sales )
SELECT TOP 3
	product_name,
	price*qty_sold AS total_revenue
FROM
	sold_product_cte sp
	JOIN
	sales_cte s
	ON
	s.prod_id = sp.prod_id

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT 
	segment_name,
	SUM(qty) qty_sold,
	SUM(s.price) total_revenue,
	ROUND(SUM(CAST(s.price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT)),2) As discounted_amount,
	ROUND(SUM(s.price-s.price*(CAST((CAST(discount AS FLOAT)/100) AS FLOAT))),2) AS gross_revenue
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	segment_name
ORDER BY 
	segment_name

-- 3. What is the top selling product for each segment?
WITH product_seg_rank_cte AS
(
SELECT 
	segment_name,
	d.product_name,
	SUM(qty) qty_sold,
	DENSE_RANK() OVER(PARTITION BY segment_name ORDER BY SUM(qty) DESC) AS ranking
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	segment_name,
	d.product_name
)
SELECT
	segment_name,
	product_name,
	qty_sold
FROM	
	product_seg_rank_cte
WHERE
	ranking = 1

-- 4. What is the total quantity, revenue and discount for each category?
SELECT 
	category_name,
	SUM(qty) qty_sold,
	SUM(s.price) total_revenue,
	ROUND(SUM(CAST(s.price*CAST((CAST(discount AS FLOAT)/100) AS FLOAT)AS FLOAT)),2) As discounted_amount,
	ROUND(SUM(s.price-s.price*(CAST((CAST(discount AS FLOAT)/100) AS FLOAT))),2) AS gross_revenue
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	category_name
ORDER BY 
	category_name

-- 5. What is the top selling product for each category?

WITH product_cat_rank_cte AS
(
SELECT 
	category_name,
	d.product_name,
	SUM(qty) qty_sold,
	DENSE_RANK() OVER(PARTITION BY category_name ORDER BY SUM(qty) DESC) AS ranking
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	category_name,
	d.product_name
)
SELECT
	category_name,
	product_name,
	qty_sold
FROM	
	product_cat_rank_cte
WHERE
	ranking = 1

-- 6. What is the percentage split of revenue by product for each segment?
DECLARE @totalrevenue INT;
SET @totalrevenue = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view);
SELECT 
	segment_name,
	d.product_name,
	CAST(((SUM(s.price-s.price*(CAST((CAST(discount AS FLOAT)/100) AS FLOAT)))/CAST(@totalrevenue AS FLOAT))*100) AS DECIMAL(4,2)) AS revenue_percent
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	segment_name,
	d.product_name
ORDER BY 
	1,3 DESC;

-- 7. What is the percentage split of revenue by segment for each category?
GO
DECLARE @totalrevenue INT;
SET @totalrevenue = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view);
SELECT 
	category_name,
	d.segment_name,
	CAST(((SUM(s.price-s.price*(CAST((CAST(discount AS FLOAT)/100) AS FLOAT)))/CAST(@totalrevenue AS FLOAT))*100) AS DECIMAL(4,2)) AS revenue_percent
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	category_name,
	d.segment_name
ORDER BY 
	1,3 DESC;

-- 8. What is the percentage split of total revenue by category

GO
DECLARE @totalrevenue INT;
SET @totalrevenue = (SELECT SUM((txn_amount-discount)) FROM txn_detail_view);
SELECT 
	category_name,
	CAST(((SUM(s.price-s.price*(CAST((CAST(discount AS FLOAT)/100) AS FLOAT)))/CAST(@totalrevenue AS FLOAT))*100) AS DECIMAL(4,2)) AS revenue_percent
FROM 
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	category_name
ORDER BY 
	1,2 DESC;

-- 9. What is the total transaction “penetration” for each product? 
--   (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
DECLARE @total_txn INT;
SET @total_txn = (SELECT COUNT(DISTINCT txn_id) FROM sales)
SELECT 
	product_name,
	CONVERT(DECIMAL(5,4),CONVERT(float,COUNT(txn_id))/CONVERT(float,@total_txn)) AS txn_penetration
FROM
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	product_name

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction
GO
WITH txn_product_cte As
(
SELECT 
	txn_id,
	product_name
FROM
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
GROUP BY
	txn_id,
	product_name

),
product_count_cte AS
(
SELECT
	product_name,
	count(*) as count
FROM
	sales s
	LEFT JOIN
	product_details d
	ON
	d.product_id = s.prod_id
	
GROUP BY
	product_name,
	txn_id
)
SELECT
	txn_id,
	tp.product_name,
	count,
	DENSE_RANK() OVER(PARTITION BY txn_id ORDER BY count DESC) AS ranking,
	SUM(count) OVER(PARTITION BY txn_id ORDER BY count DESC) AS running_count
FROM
	txn_product_cte tp
	LEFT JOIN
	product_count_cte pc
	ON
	pc.product_name = tp.product_name

	--select prod_id,count(prod_id) from sales group by prod_id

	select count(txn_id) from sales group by (prod_id) 
	select count(prod_id) from sales group by (prod_id) 