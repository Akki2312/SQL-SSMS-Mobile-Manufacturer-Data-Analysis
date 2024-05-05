--SQL Advance Case Study
use db_SQLCaseStudies

--Q1--BEGIN 

select distinct L.State
from DIM_LOCATION as L
join FACT_TRANSACTIONS as T
on L.IDLocation = T.IDLocation
where T.Date between '2005-01-01' and GETDATE();

--Q1--END

--Q2--BEGIN

select top 1 State , SUM(Quantity) Quantity from DIM_LOCATION as L
join FACT_TRANSACTIONS as T
on L.IDLocation = T.IDLocation
join DIM_MODEL as M
on M.IDModel = T.IDModel
join DIM_MANUFACTURER  as MANUFACTURER
on MANUFACTURER.IDManufacturer = M.IDManufacturer
where Country = 'US' and Manufacturer_Name = 'Samsung'
group by State
order by Quantity DESC

--Q2--END

--Q3--BEGIN      
	
select  distinct Model_Name ,  ZipCode , State,  COUNT(*) as transactions_Number from DIM_MODEL as M
join FACT_TRANSACTIONS as T
on M.IDModel = T.IDModel
join DIM_LOCATION as L
on L.IDLocation = T.IDLocation
group by Model_Name , state , ZipCode

--Q3--END

--Q4--BEGIN

select top 1 Model_Name, MIN(Unit_price) as Price from DIM_MODEL 
group by Model_Name
order by Price

--Q4--END

--Q5--BEGIN

select model_name ,Manufacturer_Name, AVG(Unit_price) as Avg_Unit_price from DIM_MODEL as MODEL
inner join DIM_MANUFACTURER as MAN
on MODEL.IDManufacturer = MAN.IDManufacturer
where Manufacturer_Name   in (
select Top 5 Manufacturer_name  from FACT_TRANSACTIONS as T
join DIM_MODEL as MO
on MO.IDModel = T.IDModel  
join DIM_MANUFACTURER as MAN
on MO.IDManufacturer = MAN.IDManufacturer
group by  Manufacturer_Name
order by SUM(quantity) desc
)
group by Model_Name , Manufacturer_Name
order by Avg_Unit_price desc

--Q5--END

--Q6--BEGIN

select customer_name , AVG(TotalPrice) as Average from DIM_CUSTOMER as C
join FACT_TRANSACTIONS as T
on T.IDCustomer = C.IDCustomer
join DIM_DATE as D
on D.DATE = T.Date
where YEAR(T.Date) = 2009 
group by Customer_Name 
having AVG(totalprice) >500

--Q6--END
	
--Q7--BEGIN  
	
select * from
(select top 5 Model_name , SUM(quantity) as Quantity from DIM_MODEL as Model
join FACT_TRANSACTIONS as T
on Model.IDModel = T.IDModel
join DIM_DATE as D
on D.DATE = T.Date
where YEAR = 2008
group by Model_Name
order by Quantity desc
intersect
select top 5 Model_name , SUM(quantity) as Quantity from DIM_MODEL as Model
join FACT_TRANSACTIONS as T
on Model.IDModel = T.IDModel
join DIM_DATE as D
on D.DATE = T.Date
where YEAR = 2009
group by Model_Name
order by Quantity desc
intersect
select top 5 Model_name , SUM(quantity) as Quantity from DIM_MODEL as Model
join FACT_TRANSACTIONS as T  
on Model.IDModel = T.IDModel
join DIM_DATE as D
on D.DATE = T.Date
where YEAR = 2010
group by Model_Name
order by Quantity desc
) as A	
--there exist no such model that's why no data is showing in the table

--Q7--END	

--Q8--BEGIN

SELECT * 
FROM 
(
SELECT *
FROM
(
SELECT Manufacturer_Name,totalSales,YEAR,
ROW_NUMBER() OVER(ORDER BY totalSales DESC) AS _rank
FROM
(
SELECT MF.Manufacturer_Name,D.YEAR,
SUM(T.TotalPrice) AS totalSales
FROM DIM_MANUFACTURER AS MF
JOIN DIM_MODEL AS MDL
ON MF.IDManufacturer = MDL.IDManufacturer
JOIN FACT_TRANSACTIONS AS T
ON MDL.IDModel = T.IDModel
JOIN DIM_DATE AS D
ON T.Date = D.DATE
WHERE D.YEAR = 2009
GROUP BY MF.Manufacturer_Name,D.YEAR) AS table1 ) AS table2
WHERE _rank = 2

UNION

SELECT *
FROM
(
SELECT Manufacturer_Name,totalSales,YEAR,
ROW_NUMBER() OVER(ORDER BY totalSales DESC) AS _rank
FROM
(
SELECT MF.Manufacturer_Name,D.YEAR,
SUM(T.TotalPrice) AS totalSales
FROM DIM_MANUFACTURER AS MF
JOIN DIM_MODEL AS MDL
ON MF.IDManufacturer = MDL.IDManufacturer
JOIN FACT_TRANSACTIONS AS T
ON MDL.IDModel = T.IDModel
JOIN DIM_DATE AS D
ON T.Date = D.DATE
WHERE D.YEAR = 2010
GROUP BY MF.Manufacturer_Name,D.YEAR) AS table3 ) AS table4
WHERE _rank = 2
)
AS mainTable;

--Q8--END

--Q9--BEGIN
	
select Distinct  Manufacturer_name  from DIM_MANUFACTURER as MAN
join DIM_MODEL as MO
on MAN.IDManufacturer = MO.IDManufacturer
join FACT_TRANSACTIONS as T
on MO.IDModel = T.IDModel
join DIM_DATE as D
on D.DATE = T.Date
where YEAR(T.Date) = 2010
except
select Distinct  Manufacturer_name as _sum   from DIM_MANUFACTURER as MAN
join DIM_MODEL as MO
on MAN.IDManufacturer = MO.IDManufacturer
join FACT_TRANSACTIONS as T
on MO.IDModel = T.IDModel
join DIM_DATE as D
on D.DATE = T.Date
where YEAR(T.Date) = 2009

--Q9--END

--Q10--BEGIN
	
with CustomerYearlyStats as(
select C.Customer_Name as CustomerName, year(T.Date) as Order_Year, avg(T.TotalPrice) as Avg_Spend, avg(T.Quantity) as Avg_Quantity
from DIM_CUSTOMER as C
join FACT_TRANSACTIONS as T
on C.IDCustomer = T.IDCustomer
group by C.Customer_Name,year(T.Date)
)
select top 100
CustomerName, Order_Year, Avg_spend, Avg_Quantity,
lag(Avg_Spend) over (partition by CustomerName order by Order_Year) as Prev_Avg_Spend,
((Avg_Spend - lag(avg_spend) over (partition by CustomerName order by Order_Year)) / lag(Avg_Spend) over (partition by CustomerName order by Order_Year)) * 100 as Change_Spend_Percentage
from CustomerYearlyStats
order by Avg_Spend DESC;

--Q10--END
	