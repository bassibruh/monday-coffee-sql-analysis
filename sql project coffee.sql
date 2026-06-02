

--monday cofee data analysis
select * from city;
select * from products;
select * from customers;
select * from sales ;

-- analysis-- 
 --q1  coffee consumer count 
 -- how many people in each city are estimated to consume cofee given that 25 % of the population
select city_name,population, 
round((population *0.25)/1000000,2) as estimated_consumers_in_millions
from city 
order by population desc;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select 
c1.city_name,
sum(total) as total_revenue
from sales as s 
join customers as c
on s.customer_id=c.customer_id
join
city as c1
on c.city_id=c1.city_id
where

extract(YEAR from s.sale_date) = 2023
and
extract(quarter from s.sale_date) = 4
group by city_name
order by total_revenue desc;


-- Q3- sales count for each product
-- how many units of each coffe products have been sold?--

select p.product_name, count(s.sale_id) as total_orders
from products as p 
left join
sales as s
on s.product_id=p.product_id

group by p.product_name
order by total_orders desc;

-- Q-4 average sales amout per city
--what is the avg sale amount per customer in each city ?

select count(distinct c.customer_id)
as total_customer,c1.city_name,avg(s.total) as avg_sale from customers c 

join sales as s 
on c.customer_id=s.customer_id
join city as c1
on c.city_id=c1.city_id

group by c1.city_name
order by avg_sale desc;


--Q.5 City Population and Coffee Consumers (25%)

--Provide a list of cities along with their populations and estimated coffee consumers.

with city_table as(

select city_name,population,
round((population *0.25)/1000000,2) as coffee_consumers_in_millions
from city


),
customer_table as 
(
select ci.city_name,
count(distinct c.customer_id) as total_current_customer
from sales s 
join customers as c on c.customer_id=s.customer_id
JOIN city as ci ON ci.city_id = c.city_id
group by 1 


)
select
ct.city_name,
ct.population,
cust.total_current_customer,
ct.coffee_consumers_in_millions as estimated_coffee_consumers
from city_table as ct 
join customer_table as cust
on ct.city_name=cust.city_name


--6 Top 3 Selling Products by City

--What are the top 3 selling products in each city based on sales volume?


select * from (
select ci.city_name,p.product_name,count(s.sale_id) as total_orders,

dense_rank() over (partition by ci.city_name order by count(s.sale_id) desc) as rank 
from sales s 

JOIN products p ON s.product_id = p.product_id
JOIN customers c ON c.customer_id = s.customer_id
JOIN city ci ON ci.city_id = c.city_id
group by ci.city_name,p.product_name) as t1 

where rank<=3;



-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select ci.city_name 
,count(distinct c.customer_id) as unique_cx
from city as ci 


left join customers as c on ci.city_id=c.city_id
join sales as s on s.customer_id=c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by ci.city_name
order by unique_cx desc ;



-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer
with avg_sale as (

select ci.city_name,sum(s.total)as revenue,
count(distinct s.customer_id) as total_cx,
ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2)

from sales s

join customers as c on s.customer_id=c.customer_id
join city ci on ci.city_id=c.city_id
group by ci.city_name
),

avg_rent as 
(select city_name,estimated_rent from city)

select ar.city_name,
ar.estimated_rent,
av.total_cx,
ROUND(ar.estimated_rent::numeric / av.total_cx::numeric, 2) as avg_rent_per_cx
from avg_rent ar
join avg_sale av 
on ar.city_name=av.city_name
ORDER BY av.avg_sale_per_cx DESC


Q9: Monthly Sales Growth

Calculate the percentage growth (or decline) in sales over different months 
for each city.

with monthly_sales as (

select ci.city_name,
extract(month from s.sale_date) as month,
extract (year from s.sale_date) as year,
sum(s.total) as total_sale
from sales as s 
join  customers c ON s.customer_id = c.customer_id
join city ci ON ci.city_id = c.city_id
group by ci.city_name,extract (year from s.sale_date),extract(month from s.sale_date)
)
,

growth_ratio as (
select city_name
, year,month,total_Sale as cr_monthly_sale ,
lag(total_sale,1) over (partition by city_name order by  year,month) as last_month_sale
from monthly_sales
)
select city_name,year,month,cr_monthly_sale,last_month_sale,

ROUND((cr_monthly_sale - last_month_sale)::numeric / last_month_sale::numeric * 100, 2)
from growth_ratio
where last_month_sale is not null
order by city_name,year,month;



--Q10: Market Potential Analysis

--Identify the top 3 cities by total sales revenue. 

--Return: city_name, total_revenue, total_rent, total_cx (unique customers), 
--estimated_coffee_consumers (25% of population in millions), avg_sale_pr_cx, avg_rent_per_cx

--Order by total_revenue DESC and limit to top 3 cities.

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT c.customer_id) AS total_cx,
        ROUND(SUM(s.total)::numeric / COUNT(DISTINCT c.customer_id)::numeric, 2) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 2) AS estimated_coffee_consumers
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumers,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent::numeric / ct.total_cx::numeric, 2) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct ON cr.city_name = ct.city_name
ORDER BY total_revenue DESC
LIMIT 3;












