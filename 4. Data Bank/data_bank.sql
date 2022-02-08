------------
-- Tables -- 
------------

SELECT * FROM regions 
SELECT * FROM customer_nodes
SELECT * FROM customer_transactions

--------------------------------
-- Customer Nodes Exploration --
--------------------------------

-- 1. How many unique nodes are there on the Data Bank system?

SELECT 
	COUNT(DISTINCT customer_id) AS total_unique_nodes
FROM
	customer_nodes

-- 2. How many unique nodes are there on the Data Bank system?
SELECT 
	region_name,
	count(DISTINCT node_id) AS node_count
FROM
customer_nodes cn
LEFT JOIN
regions r 
ON
r.region_id = cn.region_id
GROUP BY
	region_name

-- 3. How many customers are allocated to each region?
SELECT 
	region_name,
	count(DISTINCT customer_id) AS customer_count
FROM
customer_nodes cn
LEFT JOIN
regions r 
ON
r.region_id = cn.region_id
GROUP BY
	region_name

-- 4. How many days on average are customers reallocated to a different node?
GO
WITH next_date_cte AS (
SELECT 
	customer_id,
	node_id,
	start_date,
	LEAD(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date)  next_date
FROM
	customer_nodes
),
diff_date_cte AS (
	SELECT
		customer_id,
		node_id,
		DATEDIFF(DAY,start_date,next_date) diff_date
	FROM
		next_date_cte
	WHERE
		next_date IS NOT NULL
),
days_in_node_cte As(
	SELECT 
		customer_id,
		SUM(diff_date) days_one_node
	FROM
	 diff_date_cte
	GROUP BY
		customer_id,
		node_id
),
avg_days_relocate_cte AS
(
	SELECT
		customer_id,
		AVG(days_one_node) AS avg_days_relocate
	FROM
		days_in_node_cte
	GROUP BY
		customer_id
)
SELECT
	AVG(avg_days_relocate) AS avg_days_relocation
FROM
	avg_days_relocate_cte

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
-- undone
GO
WITH next_date_cte AS (
SELECT 
	customer_id,
	region_id,
	node_id,
	start_date,
	LEAD(start_date,1) OVER(PARTITION BY customer_id ORDER BY start_date)  next_date
FROM
	customer_nodes
)
	SELECT
		customer_id,
		region_id,
		node_id,
		SUM(DATEDIFF(DAY,start_date,next_date)) diff_date
	FROM
		next_date_cte
	WHERE
		next_date IS NOT NULL
	GROUP BY
		region_id,
		node_id,
		customer_id
	ORDER BY
		region_id,
		node_id

---------------------------
-- Customer Transactions --
---------------------------

-- 1. What is the unique count and total amount for each transaction type?

SELECT
	COUNT(DISTINCT customer_id) AS total_unique_txn
FROM
	customer_transactions

-- 2. What is the average total historical deposit counts and amounts for all customers?

SELECT 
	customer_id,
	COUNT(txn_type) AS no_deposit,
	AVG(txn_amount) AS amount
FROM
	customer_transactions
WHERE
	txn_type = 'deposit'
GROUP BY
	customer_id
ORDER BY 
	customer_id

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
GO
WITH txn_type_count_cte AS
(
SELECT
	DATEPART(MONTH,txn_date) AS txn_month,
	customer_id,
	SUM(CASE
			WHEN txn_type = 'deposit'
			THEN 1
			ELSE 0
		END) AS deposite,
	SUM(CASE
			WHEN txn_type = 'withdrawal'
			THEN 1
			ELSE 0
		END) AS withdrawal,
	SUM(CASE
			WHEN txn_type = 'purchase'
			THEN 1
			ELSE 0
		END) AS purchase
FROM
	customer_transactions
group BY
	customer_id,
	DATEPART(MONTH,txn_date)
)
SELECT
	txn_month,
	count(customer_id) as customers
FROM
	txn_type_count_cte
WHERE
	(deposite > 1) AND (withdrawal = 1 OR purchase = 1)
GROUP BY
	txn_month


GO

-- 4. What is the closing balance for each customer at the end of the month?
SELECT
	customer_id,
	txn_month,
	SUM(CASE	
		WHEN txn_type='deposit'
		THEN txn_amount
		ELSE (-txn_amount)
		END) AS balance
FROM(
	SELECT
		customer_id,
		DATEPART(MONTH,txn_date) AS txn_month,
		txn_type,
		txn_amount
	FROM
		customer_transactions
	) AS
	data_table
group by
	customer_id,
	txn_month
ORDER BY
	customer_id,
	txn_month
