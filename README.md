# Sales Analysis (MySQL)

SQL analysis of a retail sales database covering customers, products, orders, and shipping. The 20 queries answer business questions on customer value, sales trends, product performance, target achievement, discounting, and cross-selling.

**Dataset at a glance:** 8,027 sales rows · 4,104 orders · 783 customers · 1,810 products

## Highlights

| Query | What it shows |
|---|---|
| Q10 | Actual vs target sales by category and year. The wide target table is unpivoted with `UNION ALL`, then joined to actuals. |
| Q12 | Year-over-year sales growth per category using `LAG()`. |
| Q18 | Customers segmented by order count (frequent, occasional, one-time), with each segment's share of sales and of customers. |
| Q19 | Profit margin by discount band, to test whether heavy discounting hurts profit. |
| Q20 | Product pairs bought together in the same order, using a self-join with deduplicated pairs. |

## Database Schema

![ERD](database_diagram.png)

| Table | Description |
|---|---|
| `Sales` (fact) | One row per order line: customer, product, quantity, price, discount, profit, order date, shipping |
| `Customer` | Name, email, city, state, country, region |
| `Products` | Category, subcategory, product name, manufacturer, price |
| `Shipping` | Ship mode, shipping cost, carrier |
| `TargetSales` | Sales targets by category for 2020-2023 (standalone table, not linked by a key) |

## Tools

- MySQL 8
- MySQL Workbench

## Definitions

- **Total sales:** `SUM(Price)` from `Sales`
- **Profit margin:** `SUM(Profit) / SUM(Price) * 100`
- **Order value:** `SUM(Price)` per `OrderID`. An order can span several rows in `Sales`.
- **Customer acquisition date:** the date of the customer's first order
- **Customer types (Q18):** frequent = 7+ orders, occasional = 2-6 orders, one-time = 1 order. Cutoffs were chosen from the distribution of orders per customer.

## Questions Answered

### Aggregation and joins

| # | Question | Key Techniques |
|---|---|---|
| 1 | Top 10 customers by total sales | Joins, `SUM`, `ORDER BY`, `LIMIT` |
| 2 | Total sales per month for 2023 | `DATE_FORMAT`, date filtering |
| 3 | Products that have never been sold | `LEFT JOIN` anti-join (`IS NULL`) |
| 4 | New customers acquired in 2022 | Subquery, `MIN()`, `HAVING` |
| 5 | Profit margin % by category | Aggregation, `CAST` |

### CTEs and window functions

| # | Question | Key Techniques |
|---|---|---|
| 6 | Daily sales per category with a running total | CTE, windowed `SUM` with frame |
| 7 | Most recent order for every customer | Window ranking with tie-break |
| 8 | Customer tiers by total sales (Platinum, Gold, Silver, Bronze) | CTE, `CASE` |
| 9 | Top product per category, including ties | `RANK()`, `PARTITION BY` |
| 10 | Actual vs target sales by category and year | Unpivot with `UNION ALL`, joins, `CASE` |
| 11 | Top 3 products by profit within each category | `RANK()`, `PARTITION BY` |
| 12 | Year-over-year sales growth by category | `LAG()`, growth formula |
| 13 | Each customer's share of their region's sales | `SUM() OVER (PARTITION BY)` |
| 14 | Products with sales above their category average | Window `AVG`, filter in an outer layer |

### Business metrics

| # | Question | Key Techniques |
|---|---|---|
| 15 | Subcategories with negative total profit | Aggregation, filtering on aggregates |
| 16 | Regions ranked by sales and by profit margin | Multiple `RANK()` windows |
| 17 | Average order value and the 10 largest orders | Two-level aggregation, window `AVG`, `RANK()` |

### Customer and discount analysis

| # | Question | Key Techniques |
|---|---|---|
| 18 | Share of sales by customer type | CTE, `CASE`, window totals |
| 19 | Profit margin by discount band | `CASE` bands, margin, `ORDER BY FIELD()` |
| 20 | Product pairs most often bought together | Self-join, `id < id1` to dedupe, `COUNT(DISTINCT)` |

## Selected Findings

- **Customer value (Q18):** the 200 customers with 7+ orders are 25.5% of customers but bring in 38.8% of sales, averaging about 4,524 each versus about 2,530 for occasional customers (2-6 orders). The 26 one-time customers account for 0.7% of sales.
- **Technology (Q10):** missed its sales target every year from 2020 to 2023 (69-74% of target), even though actual sales roughly doubled over that period, because the targets doubled too.
- **Office Supplies (Q10):** beat its target in 2020-2022, then reached 84.6% in 2023 when its target doubled to 300,000.
- **Furniture (Q10):** the 2023 result (197.5% of target) is largely due to a lower target, which was cut from 160,000 to 100,000. Actual sales grew 18.6%.
- **Cross-selling (Q20):** 31 product pairs were bought together in at least 2 different orders.

## SQL Concepts Practiced

- Joins across a fact table and dimension tables, including self-joins and anti-joins
- CTEs and subqueries
- Window functions: `RANK`, `LAG`, running totals, partitioned totals and averages
- Unpivoting a wide table with `UNION ALL`
- `CASE` for segmentation and banding
- Percentage-of-total, growth, and margin calculations
- Date functions: `DATE_FORMAT`, `YEAR`

## Repository Structure

```
├── README.md
├── erd.png
└── sales_analysis_queries.sql
```

## How to Run

1. Create the database and load the source tables.
2. Run the queries in `sales_analysis_queries.sql`.


