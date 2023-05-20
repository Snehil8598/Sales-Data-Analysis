select *
from [dbo].[sales_data_sample$]

--Analysis
--Grouping Sales by Productline
select PRODUCTLINE, SUM(SALES) as REVENUE
from [dbo].[sales_data_sample$]
group by PRODUCTLINE
order by 2 desc

--Grouping Sales by Years
select YEAR_ID, SUM(SALES) as REVENUE
from [dbo].[sales_data_sample$]
group by YEAR_ID
order by 2 desc

--Grouping Sales by Dealsize
select DEALSIZE, SUM(SALES) as REVENUE
from [dbo].[sales_data_sample$]
group by DEALSIZE
order by 2 desc

--Best month for sale and revenue from it
select MONTH_ID,YEAR_ID, SUM(SALES) as REVENUE, COUNT(ORDERNUMBER) as FREQUENCY
from [dbo].[sales_data_sample$]
group by MONTH_ID,YEAR_ID
order by 2,3 desc

--Best month seems november...So Productline in November is :
select PRODUCTLINE, SUM(SALES) as REVENUE, COUNT(ORDERNUMBER) as FREQUENCY
from [dbo].[sales_data_sample$]
where MONTH_ID=11 and YEAR_ID=2003
group by PRODUCTLINE
order by 1 desc

--Best customer determined by RFM Analysis
drop table if exists #rfm --creating a temp table
;with rfm as --creating CTEs
(
	select CUSTOMERNAME,
	SUM(SALES) as MonetoryValue,
	AVG(SALES) as AvgMonetoryValue,
	COUNT(ORDERNUMBER) as Frequency,
	MAX(ORDERDATE) as LastOrderDate,
	(select MAX(ORDERDATE) from [dbo].[sales_data_sample$]) MaxOrderDate,
	DATEDIFF(DD,MAX(ORDERDATE),(select MAX(ORDERDATE) from [dbo].[sales_data_sample$])) Recency
	from [dbo].[sales_data_sample$]
	group by CUSTOMERNAME
),
rfm_calc as
(
	select *,
	NTILE(4) over (order by Recency) rfm_recency,
	NTILE(4) over (order by Frequency) rfm_frequency,
	NTILE(4) over (order by MonetoryValue) rfm_monetory
	from rfm
)
select *,rfm_recency+rfm_frequency+rfm_monetory as rfm_cell,
cast(rfm_recency as varchar)+cast(rfm_frequency as varchar)+cast(rfm_monetory as varchar) as rfm_cell_string
into #rfm
from rfm_calc

select CUSTOMERNAME,rfm_recency,rfm_frequency,rfm_monetory,
	case
		when left(rfm_cell_string,1) = '1' then 'Lost Customers'
		when left(rfm_cell_string,1) = '2' then 'New Customers'
		when left(rfm_cell_string,1) = '3' then 'Potential Customers'
		when left(rfm_cell_string,1) = '4' then 'Loyal Customers'
	end rfm_segment
from #rfm


--What products are more often sold together?
select distinct ORDERNUMBER, stuff(		--to convert the created xml into string by removing the ',' from the 1st index in the xml
(select ','+ PRODUCTCODE
from [dbo].[sales_data_sample$] p
where ORDERNUMBER in
	(
	select ORDERNUMBER
	from
		(
		select ORDERNUMBER, COUNT(*) rn
		from [dbo].[sales_data_sample$]
		where STATUS='Shipped'
		group by ORDERNUMBER
		) m
		where rn=3
	)
	and p.ORDERNUMBER=s.ORDERNUMBER
	for xml path (''))
		,1,1,'') ProductCodes
from [dbo].[sales_data_sample$] s
order by 2 desc