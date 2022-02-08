------------
-- Tables --
------------

SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

--------------------------
-- Case Study Questions --
--------------------------

--1). What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id,
	sum(price) as total_spent
FROM
	sales s 
	LEFT JOIN
	menu m
	ON 
	m.product_id = s.product_id
GROUP BY
	customer_id
ORDER BY
	customer_id;

--2). How many days has each customer visited the restaurant?

SELECT 
	customer_id,
	count(DISTINCT order_date) as no_visites
FROM
	sales
GROUP BY
	customer_id;

--3). What was the first item from the menu purchased by each customer?
WITH date_rank_cte As
(
SELECT 
	customer_id,
	product_name,
	order_date,
	DENSE_RANK()OVER(PARTITION BY customer_id ORDER BY order_date) AS rank
FROM
	sales s 
	JOIN	
	menu m
	ON
	m.product_id = s.product_id
)
SELECT DISTINCT	
	customer_id,
	product_name
FROM	
	date_rank_cte
WHERE
	rank = 1; 


--4) What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
	m.product_name,
	count(s.product_id) AS times_purchesed
FROM
	sales s
	JOIN 
	menu m
	ON
	m.product_id = s.product_id
group by
	m.product_name
ORDER BY
	count(s.product_id) DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROW ONLY

--5). Which item was the most popular for each customer?
WITH cte_food_ranking 
AS (
SELECT
	s.customer_id,
	m.product_name,
	COUNT(s.product_id) AS times_purchesed,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY count(customer_id) DESC) AS rank
FROM
	sales s
	JOIN 
	menu m
	ON
	m.product_id = s.product_id
GROUP BY
	s.customer_id,
	m.product_name
)
SELECT 
	customer_id,
	product_name,
	times_purchesed
FROM
	cte_food_ranking
WHERE
	rank = 1;

--6) Which item was purchased first by the customer after they became a member?

WITH cte_after_member
AS(
SELECT 
	s.customer_id,
	s.order_date,
	me.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id  ORDER BY order_date) AS rank
FROM 
	sales s
	RIGHT JOIN
	members m
	ON
	m.customer_id = s.customer_id
	JOIN
	menu me
	ON
	me.product_id = s.product_id
WHERE 
	s.order_date > m.join_date
)
SELECT
	customer_id,
	order_date,
	product_name
FROM
	cte_after_member
WHERE 
	rank = 1;

--7) Which item was purchased just before the customer became a member?
WITH cte_before_member
AS(
SELECT 
	s.customer_id,
	s.order_date,
	me.product_name,
	DENSE_RANK() OVER(PARTITION BY s.customer_id  ORDER BY order_date DESC) AS rank
FROM 
	sales s
	RIGHT JOIN
	members m
	ON
	m.customer_id = s.customer_id
	JOIN
	menu me
	ON
	me.product_id = s.product_id
WHERE 
	s.order_date < m.join_date
)
SELECT
	customer_id,
	order_date,
	product_name
FROM
	cte_before_member
WHERE 
	rank = 1;

--8) What is the total items and amount spent for each member before they became a member?

SELECT 
	s.customer_id,
	count(DISTINCT me.product_name) AS total_time,
	sum(me.price) AS total_spent
FROM
	sales s
	JOIN
	menu me
	ON
	me.product_id = s.product_id
	LEFT JOIN
	members m
	ON
	m.customer_id = s.customer_id
WHERE 
	s.order_date < m.join_date
GROUP BY
	s.customer_id

--9).If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
	s.customer_id,
	SUM(CASE
			WHEN me.product_id = 1
			THEN me.price * 20
			ELSE me.price *10
		END) AS points
FROM
	sales s
	JOIN
	menu me
	ON
	me.product_id = s.product_id
GROUP BY
	s.customer_id;


--10).In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT
	s.customer_id,
	SUM(CASE
			WHEN s.order_date  BETWEEN m.join_date AND DATEADD(day,6,m.join_date)
			THEN me.price *20
			ELSE	CASE
						WHEN me.product_id = 1 AND s.order_date < m.join_date
						THEN me.price * 20
						ELSE me.price *10
					END
		END) AS points
FROM
	sales s
	JOIN
	menu me
	ON
	me.product_id = s.product_id
	JOIN
	members m
	ON
	m.customer_id = s.customer_id
WHERE 
	s.order_date <'2021-02-01'
GROUP BY
	s.customer_id


--Bonus Questions--

SELECT 
	s.customer_id,
	order_date,
	product_name,
	price,
	CASE
		WHEN order_date >= join_date and s.customer_id IN (SELECT customer_id FROM members)
		THEN 'Y'
		ELSE 'N'
	END AS member
FROM
	sales s
	LEFT JOIN
	menu m
	ON
	m.product_id = s.product_id
	LEFT JOIN
	members mb
	ON
	mb.customer_id = s.customer_id
ORDER BY
	1,2,3;
------------------------------
WITH global_cte As (
SELECT 
	s.customer_id,
	order_date,
	product_name,
	price,
	CASE
		WHEN order_date >= join_date and s.customer_id IN (SELECT customer_id FROM members)
		THEN 'Y'
		ELSE 'N'
	END AS member
FROM
	sales s
	LEFT JOIN
	menu m
	ON
	m.product_id = s.product_id
	LEFT JOIN
	members mb
	ON
	mb.customer_id = s.customer_id
),
ranking_cte AS (
SELECT
	s.customer_id,
	order_date,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY order_date) AS  ranking 
FROM
	sales s
	JOIN
	members mb
	ON
	mb.customer_id = s.customer_id
WHERE
	order_date >= join_date
)
SELECT 
	gc.customer_id,
	gc.order_date,
	product_name,
	price,
	member,
	ranking
FROM	
	global_cte gc
	LEFT JOIN
	ranking_cte rc
	ON
	rc.order_date = gc.order_date
	AND
	rc.customer_id = gc.customer_id
ORDER BY
customer_id,ranking