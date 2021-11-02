/*
Project:	SQL Data Cleaning
Dataset:	Melbourne Housing Market | Kaggle
Link:		https://www.kaggle.com/anthonypino/melbourne-housing-market

Tools:		MS SQL Server 2019 Developer

*/

-- Get a feel of the data

-- Please note that LIMIT is not supported by MS SQL Server
-- Use TOP to limit the output

SELECT TOP (2000) *
FROM MelbHomeSales..melb_home_sales

-- Get the number of rows in the dataset

SELECT COUNT (*) AS rows_count
FROM MelbHomeSales..melb_home_sales			

-- Get column names in SQL Server
 
SELECT TOP(0) *
FROM MelbHomeSales..melb_home_sales

-- Initial observations

-- There are 21 Columns but none of them provides a Unique ID
-- There are quite a few fields containing NULL values
-- Date column has a 'Time' information that doesn't add any value

-- Insert a Unique ID for each sale

ALTER TABLE MelbHomeSales..melb_home_sales
ADD sale_id int IDENTITY (1,1) NOT NULL

SELECT TOP (10) *
FROM MelbHomeSales..melb_home_sales		-- Confirm column creation

/*	
	NULL fields
*/

-- ** Check for NULL in Address, Council and Region name ** 

SELECT COUNT(sale_id)
FROM MelbHomeSales..melb_home_sales
WHERE (Address is NULL) OR (CouncilArea IS NULL) OR (Regionname IS NULL)		-- 3 Addresses

-- Check what fields are NULL

SELECT * 
FROM MelbHomeSales..melb_home_sales
WHERE (Address is NULL) OR (CouncilArea IS NULL) OR (Regionname IS NULL)

-- Most of the information is NULL for these 3 properties
-- Drop these rows

DELETE
FROM MelbHomeSales..melb_home_sales
WHERE (Address is NULL) OR (CouncilArea IS NULL) OR (Regionname IS NULL)

-- Confirm the deletion

SELECT *
FROM MelbHomeSales..melb_home_sales
WHERE (Address is NULL) OR (CouncilArea IS NULL) OR (Regionname IS NULL)

-- Check Suburb and Postcode is available for all sales

SELECT COUNT(sale_id) AS suburb_null
FROM MelbHomeSales..melb_home_sales
WHERE (Suburb is NULL) OR (Postcode IS NULL)		-- No missing data

-- Check the Seller Group information is consistent

SELECT SellerG, COUNT(sale_id)
FROM MelbHomeSales..melb_home_sales
WHERE SellerG IS NOT NULL
GROUP BY SellerG
ORDER BY SellerG

-- SellerG seem to have multiple entries for similar looking sellers
-- No additional information available to confirm it

-- ** Check for NULL in Price **

SELECT COUNT(sale_id) AS sales_price_null
FROM MelbHomeSales..melb_home_sales
WHERE (Price is NULL)		-- 7610 rows

-- Drop these rows

DELETE 
FROM MelbHomeSales..melb_home_sales
WHERE (Price is NULL)

-- Confirm the deletion

SELECT *
FROM MelbHomeSales..melb_home_sales
WHERE (Price is NULL)

/* 
	Change Date column to only contain the 'Date' information 
*/

-- Create a new column sale_date and copy the 'Date' information across

ALTER TABLE MelbHomeSales..melb_home_sales
ADD sale_date date			-- Create column

SELECT TOP (10) *
FROM MelbHomeSales..melb_home_sales		-- Confirm column creation

UPDATE MelbHomeSales..melb_home_sales 
SET sale_date = CAST(melb_home_sales.Date AS date) 		-- Copy the 'Date' information

/* -- Can also be done as

UPDATE MelbHomeSales..melb_home_sales 
SET sale_date = CONVERT(date, melb_home_sales.Date) 	

*/

SELECT TOP (10) *
FROM MelbHomeSales..melb_home_sales		-- Confirm the creation and copy of datetime data

-- Remove any duplicates
-- Use Common Table Expression (CTE), PARTITION BY

WITH duplicate_cte AS ( 
	SELECT *, 
		ROW_NUMBER() OVER (
		PARTITION BY 
			Address,
			Suburb,
			CouncilArea,
			Type, 
			Price,
			sale_date
		ORDER BY
			sale_id
		) AS row_num
	FROM MelbHomeSales..melb_home_sales
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1
ORDER BY Address

-- Duplicate rows 3
-- sale_id 22779, 7819, 23093

-- Reconfirm that these sales are duplicate

SELECT *
FROM MelbHomeSales..melb_home_sales
WHERE Address LIKE '%Brickwood St%'		-- 22778 and 22779

SELECT *
FROM MelbHomeSales..melb_home_sales
WHERE Address LIKE '%Burns St%'			-- 7818 and 7819

SELECT *
FROM MelbHomeSales..melb_home_sales
WHERE Address LIKE '%Victoria St%'		-- 23092 and 23093

-- DELETE these duplicates

WITH duplicate_cte AS ( 
	SELECT *, 
		ROW_NUMBER() OVER (
		PARTITION BY 
			Address,
			Suburb,
			CouncilArea,
			Type, 
			Price,
			sale_date
		ORDER BY
			sale_id
		) AS row_num
	FROM MelbHomeSales..melb_home_sales
)
DELETE
FROM duplicate_cte
WHERE row_num > 1

-- Confirm the deletion

WITH duplicate_cte AS ( 
	SELECT *, 
		ROW_NUMBER() OVER (
		PARTITION BY 
			Address,
			Suburb,
			CouncilArea,
			Type, 
			Price,
			sale_date
		ORDER BY
			sale_id
		) AS row_num
	FROM MelbHomeSales..melb_home_sales
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1

-- Relook at the data

SELECT *
FROM MelbHomeSales..melb_home_sales
ORDER BY Address				

-- There are still many NULL values
-- Additional information is needed to handle any such missing data
-- Most of the important data is now cleaned and could be used for further Analysis
