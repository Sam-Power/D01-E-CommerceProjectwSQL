/*E-Commerce Data and Customer Retention Analysis with SQL
_________________________________________________________
An e-commerce organization demands some analysis of sales and delivery processes.
Thus, the organization hopes to be able to predict more easily the opportunities and
threats for the future.
You are asked to make the following analyzes for this scenario by following the
instructions given.
Introduction
- You can benefit from the ERD diagram given to you during your work.
- You have to create a database and import into the given csv files.
- During the import process, you will need to adjust the date columns. You need
to carefully observe the data types and how they should be.In our database, a
star model will be created with one fact table and four dimention tables.
- The data are not very clean and fully normalized. However, they don't prevent
you from performing the given tasks. In some cases you may need to use the
string, window, system or date functions.
- There may be situations where you need to update the tables.
- Manually verify the accuracy of your analysis.
OPTIONAL: You can clean and normalize the data, change the data types of some
columns, clear the id columns, and assign them as keys. Then you can create the data
model.*/

/*Analyze the data by finding the answers to the questions below:
1. Join all the tables and create a new table with all of the columns, called
combined_table. (market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)*/

-- SELECT * INTO combined_table FROM
-- (
--     SELECT  c.Cust_id, c.Customer_Name, c.Province, c.Region, c.Customer_Segment, m.Ord_id, 
--             m.Prod_id, m.Sales, m.Discount, m.Order_Quantity, m.Profit, m.Shipping_Cost, m.Product_Base_Margin,
--             o.Order_Date, o.Order_Priority,
--             p.Product_Category, p.Product_Sub_Category,
--             s.Ship_id, s.Ship_Mode, s.Ship_Date
--     FROM [dbo].[market_fact] m
--     INNER JOIN cust_dimen c ON m.Cust_id = c.Cust_id
--     INNER JOIN orders_dimen o ON m.Ord_id = o.Ord_id
--     INNER JOIN prod_dimen p ON m.Prod_id = p.Prod_id
--     INNER JOIN shipping_dimen s ON m.Ship_id = s.Ship_id
-- ) split

/*Lets have a look on our tables*/
-- select * from [dbo].[cust_dimen];
-- select * from [dbo].[shipping_dimen];
-- select * from [dbo].[orders_dimen];
-- select * from [dbo].[prod_dimen]
/*We may update*/ 
-- update  [dbo].[prod_dimen]
-- set prod_id='Prod_16' where Prod_id= ' RULERS AND TRIMMERS,Prod_16'

--2. Find the top 3 customers who have the maximum count of orders.

-- SELECT TOP 3 Cust_id,count(distinct  Ord_id ) as num
-- FROM [dbo].[combined_table]
-- GROUP BY Cust_id
-- ORDER BY 2 DESC

/*3. Create a new column at combined_table as DaysTakenForDelivery that
contains the date difference of Order_Date and Ship_Date*/
-- ALTER TABLE combined_table
-- ADD DaysTakenForDelivery int 

-- UPDATE combined_table
-- SET DaysTakenForDelivery =  DATEDIFF(D,[Order_Date] ,[Ship_Date]) 
                                 
-- SELECT *
-- FROM
-- combined_table


/*4. Find the customer whose order took the maximum time to get delivered.*/

-- SELECT [Cust_id], Customer_Name, Order_Date, Ship_Date, DaysTakenForDelivery 
-- FROM combined_table
-- WHERE DaysTakenForDelivery = (
--     SELECT MAX(DaysTakenForDelivery) FROM combined_table
-- ) 

/*5. Retrieve total sales made by each product from the data (use Window function)*/

-- SELECT DISTINCT PROD_ID, SUM(SALES) OVER (PARTITION BY PROD_ID ORDER BY PROD_ID) SUM_PRODS
-- FROM [dbo].[combined_table]
-- ORDER BY PROD_ID

/*6. Retrieve total profit made from each product from the data (use windows function)*/

-- SELECT DISTINCT PROD_ID, SUM([Profit]) OVER (PARTITION BY PROD_ID ORDER BY PROD_ID) TOTAL_PROFIT
-- FROM [dbo].[combined_table]
-- ORDER BY 2 DESC

/*7. Count the total number of unique customers in January and how many of them 
came back every month over the entire year in 2011*/
-- SELECT  COUNT(DISTINCT Cust_id )
-- FROM [dbo].[combined_table]
-- WHERE  MONTH([Order_Date]) = 1 AND YEAR([Order_Date]) = 2011


-- SELECT DISTINCT  MONTH([Order_Date]) MONTH ,COUNT(Cust_id) OVER(PARTITION BY MONTH([Order_Date]) ORDER BY MONTH([Order_Date])) COUNT
-- FROM [dbo].[combined_table]
-- WHERE  YEAR([Order_Date]) = 2011 AND Cust_id IN ( 
--     SELECT  DISTINCT Cust_id
--     FROM [dbo].[combined_table]
--     WHERE  MONTH([Order_Date]) = 1 AND YEAR([Order_Date]) = 2011
-- )
-- ORDER BY 1


/*Find month-by-month customer retention rate since the start of the business (using views).
1. Create a view where each user’s visits are logged by month, allowing for the
possibility that these will have occurred over multiple years since whenever
business started operations.*/
-- CREATE VIEW user_visit AS 
-- select Cust_id , convert(date, MY+'-01') 'DATE' , CountInMonth from
-- (
-- SELECT Cust_id,  CAST(YEAR(Order_Date) AS VARCHAR)+ '-' + CAST(MONTH(Order_Date) AS VARCHAR) AS MY,COUNT(*) CountInMonth
-- FROM [dbo].[combined_table]
-- GROUP BY Cust_id,CAST(YEAR(Order_Date) AS VARCHAR)+ '-' + CAST(MONTH(Order_Date) AS VARCHAR)
-- ) a

/*2. Identify the time lapse between each visit. So, for each person and for each
month, we see when the next visit is.*/

create view Time_lapse_vw as 
SELECT *, LEAD([DATE]) over(PARTITION by Cust_id order by [DATE]) Next_month_Visit
FROM user_visit

/*3. Calculate the time gaps between visits.*/
 create view  time_gap_vw as 
 select *,datediff(month,[DATE], Next_month_Visit ) as Time_Gap
 from Time_lapse_vw

--drop view [dbo].[Time_lapse_vw]

/*4. Categorise the customer with time gap 1 as retained, >1 as irregular and NULL as churned.*/

create view Customer_value_vw as 

select distinct cust_id, Average_time_gap,
case 
	when Average_time_gap<=1 then 'Retained'
    when Average_time_gap>1 then 'Irregular'
    when Average_time_gap is null then 'Churned'
    else 'Unknown data'
end  as  Customer_Value
from 
(
select cust_id, avg(Time_Gap) over(partition by cust_id) as Average_time_gap
from time_gap_vw
) a

select * from customer_value_vw

select * from time_gap_vw
where
cust_id='Cust_1288'

select * from time_gap_vw

/*5. Calculate the retention month wise.*/

create view retention_vw as 
select distinct next_month_visit as Retention_month,
sum(time_gap) over (partition by next_month_visit) as Retention_Sum_monthly
from time_gap_vw 
where time_gap<=1



