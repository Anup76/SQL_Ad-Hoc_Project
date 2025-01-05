
-- 1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region.

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';
        
-- 2.  What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
-- unique_products_2020 
-- unique_products_2021 
-- percentage_chg         

WITH unique_product_2020 AS (
SELECT COUNT(DISTINCT PRODUCT_CODE) AS unique_products_2020 FROM FACT_SALES_MONTHLY
WHERE FISCAL_YEAR = 2020
),
unique_product_2021 AS (
SELECT COUNT(DISTINCT PRODUCT_CODE) AS unique_products_2021 FROM FACT_SALES_MONTHLY
WHERE FISCAL_YEAR = 2021)
SELECT unique_products_2020, unique_products_2021,
CONCAT(ROUND(((unique_products_2021-unique_products_2020)/unique_products_2020)*100,2), "%") AS PCT_CHG
FROM unique_product_2020, unique_product_2021;

-- 3.  Provide a report with all the unique product counts for each  segment  and 
-- sort them in descending order of product counts. The final output contains 2 fields, 
-- segment 
-- product_count 

SELECT 
    segment, COUNT(DISTINCT product_code) AS Product_cnt
FROM
    dim_product
GROUP BY segment
ORDER BY Product_cnt DESC;

-- 4.  Follow-up: Which segment had the most increase in unique products in 
-- 2021 vs 2020? The final output contains these fields, 
-- segment 
-- product_count_2020 
-- product_count_2021 
-- difference

WITH cte1 AS (SELECT segment, count(distinct p.product_code) as Product_cnt_2020
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE fiscal_year = 2020
GROUP BY segment),
cte2 AS ( SELECT segment, count(distinct p.product_code) as Product_cnt_2021
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE fiscal_year = 2021
GROUP BY segment)
SELECT cte1.segment, Product_cnt_2020, Product_cnt_2021, (Product_cnt_2021 - Product_cnt_2020) AS DIFF
FROM cte1 JOIN cte2 ON cte1.segment = cte2.segment ORDER BY DIFF desc; 

-- 5. Get the products that have the highest and lowest manufacturing costs. 
-- The final output should contain these fields, 
-- product_code 
-- product 
-- manufacturing_cost

WITH cte AS (
    SELECT 
        MAX(manufacturing_cost) AS max_cost, 
        MIN(manufacturing_cost) AS min_cost
    FROM 
        fact_manufacturing_cost
)
SELECT 
    
    p.product_code,
    p.product,p.category,
    m.manufacturing_cost
FROM  
    dim_product p
JOIN  
    fact_manufacturing_cost m 
    ON p.product_code = m.product_code
CROSS JOIN 
    cte
WHERE 
    m.manufacturing_cost IN (cte.max_cost, cte.min_cost)
    ORDER BY manufacturing_cost desc;
    
-- 6.  Generate a report which contains the top 5 customers who received an 
-- average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
-- Indian  market. The final output contains these fields, 
-- customer_code 
-- customer 
-- average_discount_percentage    

SELECT c.customer, c.customer_code, CONCAT(ROUND(AVG(pre.pre_invoice_discount_pct*100),2),"%") AS average_discount_percentage
FROM fact_pre_invoice_deductions pre
JOIN dim_customer c ON
pre.customer_code = c.customer_code
WHERE c.market = "INDIA" AND pre.fiscal_year = 2021
GROUP BY c.customer, c.customer_code
ORDER BY AVG(pre.pre_invoice_discount_pct*100) DESC
LIMIT 5 ;

-- 7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
-- Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
-- high-performing months and take strategic decisions. 
-- The final report contains these columns: 
-- Month 
-- Year 
-- Gross sales Amount

SELECT 
    MONTHNAME(s.date) AS Month,
    s.fiscal_year,
    CONCAT(ROUND(SUM((s.sold_quantity * g.gross_price)) / 1000000,
                    2),
            ' mln') AS Gross_sales_Amount
FROM
    dim_customer c
        JOIN
    fact_sales_monthly s ON c.customer_code = s.customer_code
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
WHERE
    c.customer = 'ATLIQ EXCLUSIVE'
GROUP BY MONTHNAME(s.date) , s.fiscal_year
ORDER BY s.fiscal_year;

-- 8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
-- output contains these fields sorted by the total_sold_quantity, Quarter, total_sold_quantity

SELECT 
    CASE
        WHEN MONTH(DATE) IN (9 , 10, 11) THEN 'Q1'
        WHEN MONTH(DATE) IN (12 , 01, 02) THEN 'Q2'
        WHEN MONTH(DATE) IN (03 , 04, 05) THEN 'Q3'
        WHEN MONTH(DATE) IN (06 , 07, 08) THEN 'Q4'
    END AS QUARTERS,
    CONCAT(ROUND(SUM(SOLD_QUANTITY) / 1000000, 2),
            ' mln') AS TOTAL_SOLD_QUANTITY
FROM
    FACT_SALES_MONTHLY
WHERE
    FISCAL_YEAR = 2020
GROUP BY QUARTERS
ORDER BY TOTAL_SOLD_QUANTITY DESC;
 
-- 9.  Which channel helped to bring more gross sales in the fiscal year 2021 
-- and the percentage of contribution?  The final output  contains these fields, 
-- channel 
-- gross_sales_mln 
-- percentage 

WITH cte AS (SELECT c.channel,
ROUND(SUM(g.gross_price*s.sold_quantity)/100000,2) AS Gross_sales_mln
FROM fact_sales_monthly s
JOIN dim_customer c USING(customer_code)
JOIN fact_gross_price g USING(product_code)
WHERE s.fiscal_year = 2021
GROUP BY c.channel)
SELECT Channel, Gross_Sales_mln,
ROUND((Gross_Sales_mln/(SELECT SUM(Gross_Sales_mln) FROM cte))*100,2)
 AS Percentage FROM cte
ORDER BY Gross_Sales_mln DESC;

-- 10.  Get the Top 3 products in each division that have a high 
-- total_sold_quantity in the fiscal_year 2021? The final output contains these 
-- fields, 
-- division 
-- product_code
-- product 
-- total_sold_quantity 
-- rank_order

WITH cte AS
(
SELECT p.division, s.product_code, p.product, CONCAT(ROUND(SUM(s.sold_quantity)/1000000,2), " mln") AS total_sold_quantity,
DENSE_RANK() OVER(PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS 'rank_order'
FROM dim_product p  JOIN fact_sales_monthly s
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.division, s.product_code, p.product)
 SELECT * FROM cte
WHERE rank_order <= 3
ORDER BY division, rank_order;

