-- DATA ANALYSIS

SELECT *
FROM zomato;


-- First let's define late deliveries: Time_taken > AVG(time_taken)+STDDEV(Time_taken)
-- Different cities have different definitions of late
-- Add it to a column Hotspot_flag

-- Create a column 'Hotspot_flag'
ALTER TABLE zomato
ADD COLUMN Hotspot_flag TEXT;

SELECT *
FROM zomato;

WITH city_threshold AS
(
SELECT city,
	AVG(time_taken) + STDDEV(time_taken) AS threshold
FROM zomato
GROUP BY city
)
UPDATE zomato z
SET Hotspot_flag =
(SELECT
	CASE
		WHEN z.time_taken > ct.threshold THEN 'Late'
		ELSE 'Ontime'
	END AS Hotspot_flag
FROM city_threshold ct 
WHERE z.city = ct.city)
FROM city_threshold ct 
WHERE z.city = ct.city
;


-- 1. Delivery by type of order
SELECT type_of_order,
	   type_of_vehicle,
       ROUND(AVG(time_taken), 2)AS Average_time_taken,
	   (COUNT(*) FILTER(WHERE hotspot_flag = 'Late')::FLOAT/COUNT(*) * 100) AS late_percentage
FROM zomato
GROUP BY type_of_order,type_of_vehicle
ORDER BY Average_time_taken ASC;

SELECT *
FROM zomato;

-- 2. Delivery by weather conditions
SELECT weather_conditions,
	   type_of_vehicle,
 	   ROUND(AVG(time_taken), 2)AS Average_time_taken,
	   (COUNT(*) FILTER (WHERE hotspot_flag = 'Late')::FLOAT / COUNT(*) * 100) AS late_percentage
FROM zomato
GROUP BY weather_conditions,type_of_vehicle
ORDER BY Average_time_taken ASC;

-- 3. Delivery by Road traffic density
SELECT road_traffic_density,
	   type_of_vehicle,
 	   ROUND(AVG(time_taken), 2)AS Average_time_taken,
       (COUNT(*) FILTER (WHERE hotspot_flag = 'Late')::FLOAT / COUNT(*) * 100) AS late_percentage
FROM zomato
GROUP BY road_traffic_density,type_of_vehicle
ORDER BY Average_time_taken ASC;



-- 4. Percentage deivered on time(Above average)
SELECT 
	city,
	type_of_vehicle,
	(COUNT(*) FILTER(WHERE hotspot_flag = 'Ontime')::FLOAT/COUNT(*)* 100) AS Percentage_Ontime,
	(COUNT(*) FILTER(WHERE hotspot_flag = 'Late')::FLOAT/COUNT(*)* 100) AS Percentage_Late
FROM zomato
GROUP BY city, type_of_vehicle;



-- 5. Delivery by day of the week and time of the day
-- Update table to include day of week
ALTER TABLE zomato
ADD COLUMN Order_Day TEXT;

UPDATE zomato
SET Order_Day = 
TO_CHAR(order_date, 'Day');

-- Average time taken at different times of the day
-- Add column for time of day
ALTER TABLE zomato ADD COLUMN time_of_day VARCHAR(20);

UPDATE zomato
SET time_of_day = CASE
	WHEN time_ordered BETWEEN TIME '05:00:00' AND TIME '08:59:59' THEN 'Morning'
	WHEN time_ordered BETWEEN TIME '09:00:00' AND TIME '11:59:59' THEN 'Mid-Morning'
	WHEN time_ordered BETWEEN TIME '12:00:00' AND TIME '16:59:59' THEN 'Afternoon'
	WHEN time_ordered BETWEEN TIME '17:00:00' AND TIME '20:59:59' THEN 'Evening'
	ELSE 'Night' 
END;


SELECT 
    order_day,
    time_of_day,
	type_of_vehicle,
    AVG(time_taken) AS avg_time_taken
FROM zomato
GROUP BY time_of_day,order_day,type_of_vehicle
ORDER BY order_day,
  CASE 
    WHEN time_of_day = 'Morning' THEN 1
	WHEN time_of_day = 'Mid-Morning' THEN 2
    WHEN time_of_day = 'Afternoon' THEN 3
    WHEN time_of_day = 'Evening' THEN 4
    ELSE 5
  END;

-- GIS ANALYSIS
SELECT *
FROM zomato;

CREATE EXTENSION postgis;

-- Defining geometry
ALTER TABLE zomato ADD COLUMN restaurant_geom GEOMETRY;
UPDATE zomato
SET restaurant_geom = ST_SetSRID(ST_MakePoint(restaurant_longitude, restaurant_latitude), 4326);

ALTER TABLE zomato ADD COLUMN delivery_geom GEOMETRY;
UPDATE zomato
SET delivery_geom = ST_SetSRID(ST_MakePoint(delivery_location_longitude, delivery_location_latitude), 4326);

-- Calculating distances
-- units in planar degrees 4326 is WGS 84 long lat
SELECT ID,
	ST_DISTANCE(restaurant_geom::geometry, delivery_geom::geometry) AS Distance_in_planar_degrees
FROM zomato;

-- Units in meters, we use SRID 3857;projected coordinate system used for rendering maps.
-- corrected by cos(lat) to account for distortion
SELECT ID,
	ST_DISTANCE(
	ST_TRANSFORM(restaurant_geom::geometry,3857),
	ST_TRANSFORM(delivery_geom::geometry,3857))* cosd(restaurant_latitude)/1000 
	-- AS Distance_in_meters
FROM zomato;

ALTER TABLE zomato ADD COLUMN Distance_km FLOAT
UPDATE zomato
SET Distance_km = 
	ST_DISTANCE(
	ST_TRANSFORM(restaurant_geom::geometry,3857),
	ST_TRANSFORM(delivery_geom::geometry,3857))* cosd(restaurant_latitude) /1000
;


-- 6. Deliveries by Distances
SELECT distance_km
FROM zomato
ORDER BY distance_km DESC;
-- Percentage of restaurants late deliveries in different zones grouped by type_of vehicle
-- CTE that defines the zones and calculates percentages
WITH zones AS
(
SELECT distance_km,
		type_of_vehicle,
		hotspot_flag,
		CASE
		WHEN distance_km BETWEEN 0.0 AND 5.0 THEN '0-5 km'
		WHEN distance_km BETWEEN 5.1 AND 10.0 THEN '5-10 km'
		WHEN distance_km BETWEEN 10.1 AND 15.0 THEN '10-15 km'
		WHEN distance_km BETWEEN 15.1 AND 20.0 THEN '15-20 km'
		ELSE 'Over 20 km'
		END AS zone
FROM zomato
)
SELECT zone,
	   type_of_vehicle,
	   (COUNT(*) FILTER (WHERE hotspot_flag = 'Late')::FLOAT / COUNT(*) * 100) AS late_percentage
FROM zones
GROUP BY zone,type_of_vehicle
ORDER BY type_of_vehicle;

-- 7. Map out Indian regions showing density of late deliveries based on type of vehicle
-- Check Map projection
SELECT ST_SRID(geom) FROM indian_states; 
SELECT ST_SRID(delivery_geom) FROM zomato; 

-- Transform map projection
ALTER TABLE indian_states ALTER COLUMN geom TYPE geometry(MULTIPOLYGON, 3857) USING ST_SetSRID(geom, 3857);
ALTER TABLE zomato ALTER COLUMN delivery_geom TYPE geometry(POINT, 3857) USING ST_SetSRID(delivery_geom, 3857);


SELECT st_nm,
	   type_of_vehicle,
	   COUNT(*) AS delivery_count,
	   COUNT(*) FILTER (WHERE hotspot_flag = 'Late')::FLOAT/COUNT(*) * 100 AS Late_Delivery_Density
FROM indian_states rc
JOIN zomato z ON ST_Within(z.delivery_geom,rc.geom)
GROUP BY rc.st_nm,type_of_vehicle
;







