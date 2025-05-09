
-- DATA CLEANING
-- https://www.kaggle.com/datasets/saurabhbadole/zomato-delivery-operations-analytics-dataset/data

SELECT *
FROM zomato;

-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove columns

SELECT DISTINCT Delivery_person_ID
FROM zomato;

-- Creating staging data
CREATE TABLE zomato_staging
LIKE zomato;

-- Insert data into new table
INSERT zomato_staging
SELECT *
FROM zomato;

-- 1. Remove Duplicates
-- Using Unique identifier
SELECT ID, Delivery_person_ID, count(*)
FROM zomato_staging
GROUP BY ID,Delivery_person_ID
HAVING count(*) > 1;
-- No Duplicates

SELECT *
FROM zomato_staging;

-- Using ROW NUMBER
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ID, Delivery_person_ID,Type_of_vehicle) AS row_num
FROM zomato_staging;

#CTE
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY ID, Delivery_person_ID,Type_of_vehicle) AS row_num
FROM zomato_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num>1;
-- Zero duplicates

-- 2. Standardizing Data
-- Lookout for distinct values of categories
SELECT *
FROM zomato_staging;

-- Changing data type to date
-- STR_TO_DATE requires consistent string format in this case we had two formats 13-02-2022 and 12/3/2022
-- Using a case statement to convert to the same format 
SELECT ID, Order_Date,
    CASE 
        -- For 'dd-mm-yyyy' (e.g., '13-02-2022')
        WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%d-%m-%Y'), '%m/%d/%Y')
        
        -- For 'm/d/yyyy' or 'mm/dd/yyyy' (e.g., '12/3/2022')
        WHEN Order_Date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%m/%d/%Y'), '%m/%d/%Y')
        
        -- For 'yyyy-mm-dd' (e.g., '2022-04-03')
        WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%Y-%m-%d'), '%m/%d/%Y')
        
        ELSE NULL -- Handle unexpected formats
    END AS formatted_date
FROM zomato_staging;

UPDATE zomato_staging
SET Order_Date = 
CASE 
        -- For 'dd-mm-yyyy' (e.g., '13-02-2022')
        WHEN Order_Date REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%d-%m-%Y'), '%m/%d/%Y')
        
        -- For 'm/d/yyyy' or 'mm/dd/yyyy' (e.g., '12/3/2022')
        WHEN Order_Date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%m/%d/%Y'), '%m/%d/%Y')
        
        -- For 'yyyy-mm-dd' (e.g., '2022-04-03')
        WHEN Order_Date REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN 
            DATE_FORMAT(STR_TO_DATE(Order_Date, '%Y-%m-%d'), '%m/%d/%Y')
        
        ELSE NULL -- Handle unexpected formats
    END;
    
-- months & years
SELECT Order_Date,
SUBSTRING(Order_Date, 1, 2) AS month,
SUBSTRING(Order_Date, 7, 10) AS year
FROM zomato_staging ;


-- Convert order_date to correct data type
ALTER TABLE zomato_staging
MODIFY COLUMN Order_Date DATE;

UPDATE zomato_staging
SET Order_Date = STR_TO_DATE(Order_Date, '%m/%d/%Y');



-- CTE showing rows with time order picked in decimal format and in correct time format. Comparing to time ordered, the time order picked column does not make sense
-- Might be an error in recording of data,
WITH CTE_ST AS(
SELECT ID, Time_Orderd, Time_Order_picked
FROM zomato_staging
WHERE Time_Order_picked NOT LIKE '%_:__'
)
SELECT *, SEC_TO_TIME(Time_Order_picked * 3600) AS time_formatted 
FROM CTE_ST;

-- Deleting these rows
DELETE FROM zomato_staging
WHERE Time_Order_picked NOT LIKE '%_:__'
;

-- Some records have time more than 24:59 written as 24.00 which is wrong
SELECT ID, Time_Orderd, Time_Order_picked
FROM zomato_staging
WHERE Time_Order_picked LIKE '24:%'
;

-- CTE to select and correct these rows
WITH CTE_24 AS
(
SELECT ID, Time_Order_picked, REPLACE(Time_Order_picked, '24', '00') AS corrected_time
FROM zomato_staging
WHERE Time_Order_picked LIKE '24:%'
)
UPDATE zomato_staging t
JOIN CTE_24 tc ON t.ID = tc.ID
SET t.Time_Order_picked = tc.corrected_time;


-- UPDATE Time columns 
UPDATE zomato_staging
SET Time_Orderd = STR_TO_DATE(Time_Orderd, '%H:%i:%s'),
Time_Order_picked = STR_TO_DATE(Time_Order_picked, '%H:%i:%s') 
;
    
    
-- 3. Look at Null Values
SELECT *
FROM zomato_staging
WHERE Delivery_person_Ratings IS NULL
	OR Delivery_person_Age IS NULL
    OR Delivery_person_Ratings IS NULL
    OR Restaurant_latitude IS NULL
    OR Restaurant_longitude IS NULL
    OR Delivery_location_latitude IS NULL
    OR Delivery_location_longitude IS NULL
    OR Time_Orderd IS NULL
    OR Weather_conditions IS NULL
    OR Road_traffic_density IS NULL
    OR Festival IS NULL
    OR City IS NULL
    ;
    
DELETE FROM zomato_staging
WHERE Delivery_person_Ratings IS NULL
	OR Delivery_person_Age IS NULL
    OR Delivery_person_Ratings IS NULL
    OR Restaurant_latitude IS NULL
    OR Restaurant_longitude IS NULL
    OR Delivery_location_latitude IS NULL
    OR Delivery_location_longitude IS NULL
    OR Time_Orderd IS NULL
    OR Weather_conditions IS NULL
    OR Road_traffic_density IS NULL
    OR Festival IS NULL
    OR City IS NULL
    ;
    
-- Some of the restaurant and delivery locations were not properly recorded and have to be dropped

SELECT *
FROM zomato_staging;

SELECT ID, 
	Restaurant_latitude AS RLA, 
    Restaurant_longitude AS RLO, 
    Delivery_location_latitude AS DLLA, 
    Delivery_location_longitude AS DLLO
FROM zomato_staging
WHERE length(Restaurant_latitude) < 3
;

DELETE FROM zomato_staging
WHERE length(Restaurant_latitude) < 3
	OR length(Restaurant_longitude) < 3
    OR length(Delivery_location_latitude) < 4
    OR length(Delivery_location_longitude) < 4;
    
SELECT *
FROM zomato_staging
WHERE length(Restaurant_latitude) < 3
	OR length(Restaurant_longitude) < 3
    OR length(Delivery_location_latitude) < 4
    OR length(Delivery_location_longitude) < 4;
    

-- 4. Removing columns(No columns to remove)
-- Data is now clean for analysis










