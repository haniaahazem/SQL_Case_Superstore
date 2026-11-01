#--Q1. List the top 10 customers by total sales amount. Show CustomerID, full name, and total sales.
SELECT 
    SUM(s.Price) AS totalsales,
    c.id AS id,
    CONCAT(c.firstname, ' ', lastname) AS fullname
FROM sales s
JOIN customer c
	ON c.id = s.CustomerID
GROUP BY id , fullname
ORDER BY totalsales DESC
LIMIT 10
;

#--Q2. Show total sales per month for the year 2023, ordered by month.
SELECT SUM(price), 
	   DATE_FORMAT(orderdate, '%Y-%m') AS month
FROM sales
WHERE DATE_FORMAT(orderdate, '%Y') = '2023'
GROUP BY month;

#--Q3. Find out the products that have never been sold
SELECT 
    p.productid AS pid,
    p.productname AS name,
    p.category AS category
FROM products p
LEFT JOIN sales s 
	ON s.ProductID = p.productid
WHERE s.productid IS NULL
;

#-Q4. Find how many new customers were acquired in 2022
SELECT COUNT(*)
FROM (SELECT MIN(orderdate) AS firstorder,
			 customerid
	  FROM sales
      GROUP BY CustomerID
      HAVING YEAR(firstorder) = 2022
      ) m;

#--Q5. Calculate the profit margin (Profit / Sales) percentage for each category.
SELECT 
    CAST((SUM(s.profit) / SUM(s.price)) * 100 AS DECIMAL (10 , 2 )) AS margin,
    p.category AS catname
FROM sales s
JOIN
    products p ON p.productid = s.productid
GROUP BY catname;


#--Q6. For each category, show date-wise sales and a running total of sales over time.
WITH cte_dailysales AS (
	SELECT s.orderdate AS date, 
           p.category AS category,
           sum(s.price) AS dailysales
	FROM sales s 
    JOIN products p 
		ON p.ProductID=s.ProductID
    GROUP BY date, category )

SELECT *,
		SUM(dailysales) OVER (PARTITION BY category 
							  ORDER BY DATE
						      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                              AS Runningtotal
FROM cte_dailysales;
  
#--Q7. GET The Most Recent ORDER (BY Orderdate) FOR EVERY Customer. 
WITH Recentorder AS
  (SELECT DISTINCT Rank() OVER (PARTITION BY C.Id
                                ORDER BY S.Orderdate DESC) AS Rankrecentestorder,
                   S.Customerid AS Id,
                   Concat(C.Firstname, ' ', C.Lastname) AS Fullname,
                   S.Orderid AS Orderid,
                   Orderdate AS date
   FROM Sales S
   JOIN Customer C ON C.Id=S.Customerid)
SELECT Id,
       Fullname, date
FROM Recentorder
WHERE Rankrecentestorder =1
