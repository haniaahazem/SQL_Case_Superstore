#--Q1. List the top 10 customers by total sales amount. Show CustomerID, full name, and total sales.
SELECT Sum(S.Price) AS Totalsales,
       C.Id AS Id,
       Concat(C.Firstname, ' ', Lastname) AS Fullname
FROM Sales S
JOIN Customer C ON C.Id = S.Customerid
GROUP BY Id,
         Fullname
ORDER BY Totalsales DESC
LIMIT 10 ;


#--Q2. Show total sales per month for the year 2023, ordered by month.
SELECT Sum(Price) AS Totalsales,
       Date_format(Orderdate, '%Y-%m') AS MONTH
FROM Sales
WHERE Date_format(Orderdate, '%Y') = '2023'
GROUP BY MONTH
ORDER BY MONTH;

#--Q3. Find out the products that have never been sold
SELECT P.Productid AS Pid,
       P.Productname AS Name,
       P.Category AS Category
FROM Products P
LEFT JOIN Sales S ON S.Productid = P.Productid
WHERE S.Productid IS NULL ;

#--Q4. Find how many new customers were acquired in 2022
SELECT Count(*)
FROM (SELECT Min(Orderdate) AS Firstorder,
            Customerid
	   FROM Sales
	   GROUP BY Customerid
	   HAVING Year(Firstorder) = 2022) M;

#--Q5. Calculate the profit margin (Profit / Sales) percentage for each category.
SELECT 
    CAST((SUM(s.profit) / SUM(s.price)) * 100 AS DECIMAL (10 , 2 )) AS margin,
    p.category AS catname
FROM sales s
JOIN
    products p ON p.productid = s.productid
GROUP BY catname;


#--Q6. For each category, show date-wise sales and a running total of sales over time.
WITH Cte_dailysales AS (
	SELECT S.Orderdate AS date,
          P.Category AS Category,
          Sum(S.Price) AS Dailysales
   FROM Sales S
   JOIN Products P ON P.Productid=S.Productid
   GROUP BY date, Category)
SELECT *,
       Sum(Dailysales) OVER (PARTITION BY Category
                             ORDER BY DATE ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Runningtotal
FROM Cte_dailysales;

  
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
WHERE Rankrecentestorder =1;


/*--Q8. Classify customers based on their total sale. Show CustomerID, name, total sales: 
--Platinum – TotalSales ≥ 15,000
--Gold – 10,000 to < 15,000
--Silver – 5,000 to < 10,000
--Bronze – < 5,000*/

WITH Cte_totalsales AS
  (SELECT Sum(S.Price) AS Totalsales,
          C.Id AS Id,
          Concat(C.Firstname, ' ', C.Lastname) AS Fullname
   FROM Sales S
   JOIN Customer C ON C.Id=S.Customerid
   GROUP BY Id)
SELECT *,
       CASE
           WHEN Totalsales >= 15000 THEN 'platinum'
           WHEN Totalsales>= 10000 THEN 'gold'
           WHEN Totalsales >= 5000 THEN 'silver'
           ELSE 'bronze'
       END AS Customersclass
FROM Cte_totalsales;

#--Q9. For each category, find the product with the highest total sales. If ties exist, show all tied products.
WITH Cte_rankedailysales AS
  (SELECT *,
          Rank() OVER (PARTITION BY Cat
                       ORDER BY Totalsales DESC) AS Ranksales
   FROM
     (SELECT P.Category AS Cat,
             Sum(S.Price) AS Totalsales,
             S.Productid AS Id,
             P.Productname AS Pname
      FROM Sales S
      JOIN Products P ON P.Productid=S.Productid
      GROUP BY Id)m)
SELECT Pname,
       Cat,
       Totalsales
FROM Cte_rankedailysales
WHERE Ranksales =1;

#--Q10. Actual vs Target sales by category & year
WITH Cte_targetsales AS
  (SELECT Category,
          2020 AS YEAR,
          `2020_sales` AS Target
   FROM Targetsales
   UNION ALL SELECT Category,
                    2021 AS YEAR,
                    `2021_sales` AS Target
   FROM Targetsales
   UNION ALL SELECT Category,
                    2022 AS YEAR,
                    `2022_sales` AS Target
   FROM Targetsales
   UNION ALL SELECT Category,
                    2023 AS YEAR,
                    `2023_sales` AS Target
   FROM Targetsales),
	
Cte_actualsales AS
  (SELECT P.Category AS Cat,
          Sum(S.Price) AS Actualsales,
          Year(S.Orderdate) AS Yearr
   FROM Sales S
   JOIN Products P ON P.Productid=S.Productid
   GROUP BY Yearr,
            Cat)

SELECT Cas.Cat,
       Cas.Yearr,
       Ts.Target AS Targetsales,
       Cas.Actualsales,
       Cas.Actualsales - Ts.Target AS Difference,
       CASE
           WHEN Cas.Actualsales - Ts.Target >0 THEN 'achieved'
           ELSE 'not achieved'
       END AS 'status',
       Round(Cas.Actualsales*100 / Ts.Target, 2) AS Achievement_percentage
FROM Cte_actualsales Cas
JOIN Cte_targetsales Ts ON Ts.Year=Cas.Yearr
AND Cas.Cat=Ts.Category
;

#--Q11: Top 3 Products BY Total Profit Within EACH Category
WITH Cte_rankedproducts AS
  (SELECT *,
          Rank() OVER (PARTITION BY Cat
                       ORDER BY Totalprofit DESC) AS Rankedsales
   FROM
     (SELECT Sum(S.Profit) AS Totalprofit,
             P.Productname AS Pname,
             S.Productid AS Id,
             P.Category AS Cat
      FROM Sales S
      JOIN Products P ON P.Productid=S.Productid
      GROUP BY Id,
               Pname)m)
SELECT Cat,
       Id,
       Pname,
       Totalprofit
FROM Cte_rankedproducts
WHERE Rankedsales<=3;

#--Q12: YEAR-OVER-YEAR Sales Growth (%) FOR EACH Category 
WITH Cte_yearly AS
  (SELECT *,
          Lag(Yearlysales) OVER (PARTITION BY Cat
                                 ORDER BY YEAR) AS Lastyearsales
   FROM
     (SELECT Sum(S.Price) AS Yearlysales,
             Year(S.Orderdate) AS YEAR,
             P.Category AS Cat
      FROM Sales S
      JOIN Products P ON P.Productid=S.Productid
      GROUP BY YEAR,
               Cat)M)
SELECT *,
       Round((Yearlysales - Lastyearsales)*100/Lastyearsales, 2) AS Growth_percentage
FROM Cte_yearly ;

#--Q13: EACH Customer’S SHARE OF Their Region’S Total Sales
WITH Cte_cust AS
  (SELECT Sum(S.Price) AS Totalcust,
          S.Customerid,
          Concat(C.Firstname, ' ', C.Lastname) AS Fullname,
          C.Region AS Region
   FROM Sales S
   JOIN Customer C ON C.Id=S.Customerid
   GROUP BY Customerid,
            Fullname)
SELECT *,
       Sum(Totalcust) OVER (PARTITION BY Region) AS Totalregion,
       Round(Totalcust*100/Sum(Totalcust) OVER (PARTITION BY Region), 2) AS Customershare
FROM Cte_cust
ORDER BY Region,
         Customershare DESC;

#--Q14: Products Whose Total Sales ARE Above Their Category’S Average Product Sales
WITH Cte_above_avg AS
  (SELECT Totalsales,
          Cat,
          Id,
          Avg(Totalsales) OVER (PARTITION BY Cat) AS Avgg
   FROM
     (SELECT Sum(S.Price) AS Totalsales,
             P.Category AS Cat,
             P.Productid AS Id
      FROM Sales S
      JOIN Products P ON P.Productid=S.Productid
      GROUP BY Cat,
               Id)M)
SELECT *
FROM Cte_above_avg
WHERE Totalsales> Avgg
ORDER BY Cat,
         Totalsales DESC ;

#--Q15: Subcategories WITH Negative Total Profit
SELECT *
FROM
  (SELECT P.Subcategory AS Sub,
          Sum(S.Profit) AS Totalprofit
   FROM Sales S
   JOIN Products P ON P.Productid=S.Productid
   GROUP BY Sub)M
WHERE Totalprofit<0;

#--Q16: Rank regions by sales and by profit margin. 
SELECT *, 
		RANK() OVER (ORDER BY margin DESC) as Marginrank,
		RANK() OVER (ORDER BY totalsales DESC) as Salesrank
FROM (
	SELECT sum(s.price) AS Totalsales,
		   CAST((SUM(s.profit) / SUM(s.price)) * 100 AS DECIMAL (10 , 2 )) AS Margin,
		   c.region as Region
	FROM Sales s 
	JOIN Customer c 
	ON c.id=s.customerid
	GROUP BY Region)m;


#--Q17: Average ORDER Value, AND The 10 Largest Orders BY Total Value
WITH OrderSummary AS (
	SELECT *,
		   AVG(ordervalue) over() as AOV,
		   RANK() OVER (ORDER BY Ordervalue DESC) AS AOVrank
	FROM
	  (SELECT Orderid AS Id,
			  Round(sum(Price), 2) AS Ordervalue
	   FROM Sales
	   GROUP BY Orderid)M)
	
SELECT * 
FROM OrderSummary
WHERE AOVrank<=10
ORDER BY Ordervalue DESC;

#--Q18: SHARE OF Total Sales BY Customer TYPE: Frequent (7+ Orders), Occasional (2-6 Orders) AND One-TIME (1 ORDER)
WITH Cte_customer_status AS
  (SELECT *,
          Sum(Total) Over() AS Totalsales,
          Count(Customerid) OVER () AS Totalcustomers,
          CASE
              WHEN Countt >= 7 THEN 'frequent'
              WHEN Countt >= 2 THEN 'occasional'
              ELSE 'one-time'
          END AS Status
   FROM
     (SELECT Count(DISTINCT Orderid) AS Countt,
             Sum(Price) AS Total,
             Customerid
      FROM Sales
      GROUP BY Customerid) M)
	
SELECT Status,
       Round(Sum(Total)*100/Totalsales, 2) AS Saleshare,
       Round(Avg(Total), 2) AS Averagesales,
       Round(Count(Customerid)*100/Totalcustomers, 2) AS Customershare,
       Count(Customerid) AS Customercount
FROM Cte_customer_status
GROUP BY Status,
         Totalsales,
         Totalcustomers
ORDER BY Saleshare DESC ;

#--Q19: Does discounting hurt profit? Group sales into discount bands (none, low, medium, high) and compare the average profit margin of each
SELECT discountrange,
		round(sum(profit)*100/totalprofit,2) AS shareofprofit,
		round(sum(profit)*100/sum(price),2) AS averageprofitmargin,
        COUNT(*) AS linecount
 FROM (
	SELECT discount, 
		   profit,
           price,
           sum(profit) over() as totalprofit,
				   CASE WHEN discount= 0 THEN 'None'
						WHEN discount >= 0.5 THEN 'High'      
						WHEN discount >=0.4 THEN 'Medium'
						WHEN discount >= 0.1  THEN 'Low'
				   END AS 'DiscountRange'
	FROM sales
)m
GROUP BY discountrange, 
		  totalprofit
ORDER BY FIELD(discountrange, 'None', 'Low', 'Medium', 'High')
 ;

#--Q20: Pairs of products most often bought together in the same order 
SELECT 
    id,
    id1,
    pname,
    pname1,
    COUNT(DISTINCT oid) AS itemsboughtogether
FROM
    (SELECT 
			s.orderid AS oid,
            s.productid AS id,
            s1.productid AS id1,
            p1.ProductName AS pname1,
            p.ProductName AS pname
    FROM
        sales AS s
    JOIN sales AS s1 ON s1.orderid = s.orderid
    JOIN products p ON s.productid = p.productid
    JOIN products p1 ON s1.ProductID = p1.ProductID) m
WHERE
    id < id1
GROUP BY id , id1 , pname , pname1
HAVING itemsboughtogether > 1
ORDER BY itemsboughtogether DESC;
