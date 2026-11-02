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
       Fullname,
	   date
FROM Recentorder
WHERE Rankrecentestorder =1;

/*--Q8. Classify customers based on their total sale. Show CustomerID, name, total sales: 
--Platinum – TotalSales ≥ 15,000
--Gold – 10,000 to < 15,000
--Silver – 5,000 to < 10,000
--Bronze – < 5,000*/

with cte_totalsales as (
	select sum(s.price) as totalsales,
		   c.id as id,
		   concat(c.firstname,' ',c.lastname) as fullname
	from sales s
    join customer c
    on c.id=s.customerid
	group by id)
    
select * ,
		CASE WHEN totalsales >= 15000 then 'platinum'
		when totalsales>= 10000 then 'gold'
		when totalsales >= 5000 then 'silver'
        else 'bronze'
        end as customersclass
from cte_totalsales;
;

#--Q9. For each category, find the product with the highest total sales. If ties exist, show all tied products.
with cte_rankedailysales as (
select *,
	  rank() over (partition by cat order by totalsales desc) as ranksales
from (select p.category as cat,
		   sum(s.price) as totalsales,
		   s.productid as id,
           p.productname as pname
	from sales s
	join products p
	on p.ProductID=s.productid
	group by id)m)
    
select pname, 
	   cat, 
	   totalsales 
from cte_rankedailysales
where ranksales =1;

#--Q10. Actual vs Target sales by category & year
with cte_targetsales as (
	SELECT category, 2020 AS year, `2020_Sales` AS target
	FROM targetsales
    
	union all
    
	SELECT category, 2021 AS year, `2021_Sales` AS target
	FROM targetsales
	
    union all 
	
    SELECT category, 2022 AS year, `2022_Sales` AS target
	FROM targetsales
	
    union all
    
	SELECT category, 2023 AS year, `2023_Sales` AS target
	FROM targetsales) ,
    
cte_actualsales as ( 
select  p.Category as cat,
        sum(s.price) as actualsales,
	    year(s.orderdate) as yearr
from sales s
join products p
on p.ProductID=s.productid
group by yearr, cat
)
select  cas.cat,
	    cas.yearr,
        ts.target as targetsales,
        cas.actualsales,
        cas.actualsales - ts.target  as differance,
        case when cas.actualsales - ts.target >0 then 'achieved'
			 else 'not achieved'
		end as 'status',
        round(cas.actualsales*100 / ts.target, 2) as achievement_percentage
        
from cte_actualsales cas
join cte_targetsales ts 
	on ts.year=cas.yearr
	and cas.cat=ts.category
group by yearr, cat,targetsales
; 
