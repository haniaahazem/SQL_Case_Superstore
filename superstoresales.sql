#Q1. List the top 10 customers by total sales amount. Show CustomerID, full name, and total sales.
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
select p.productid as pid,
	   p.productname as name,
       p.category as category
from products p
left join sales s on s.ProductID=p.productid
where s.productid is null
;

#-Q4. Find how many new customers were acquired in 2022
select count(*) 
from (
	select min(orderdate) as firstorder,
		   customerid
	from sales 
    group by CustomerID
    having year(firstorder)=2022
    )m;

select * from products;
#VQ5. Calculate the profit margin (Profit / Sales) percentage for each category.
select cast((sum(s.profit)/sum(s.price))*100 
		as decimal(10,2)) 
        as margin,
	   p.category as catname
from sales s
join products p on p.productid=s.productid
group by catname;


#--Q6. For each category, show date-wise sales and a running total of sales over time.
select 	p.category,
		sum(s.price) over (partition by p.category),
	    date_format(s.orderdate, '%Y-%m') as month
from sales s
join products p on p.productid=s.productid
