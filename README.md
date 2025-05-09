# Zomato Delivery Operations Analysis (2022)

## Project Overview
This project analyzes food delivery operations for Zomato, a leading food delivery company in India, based on a dataset of over 31,000 deliveries in 2022. The dataset, sourced from an Excel sheet, was cleaned and analyzed using SQL, and the results were visualized in a Tableau dashboard titled **"Food Delivery Analysis: Motorcycle, Scooter, or Electric Scooter"**. The analysis focuses on delivery performance, particularly late deliveries, across various dimensions such as weather conditions, road traffic, order types, urbanization levels, time of day, and geographic regions. The Tableau dashboard provides interactive visualizations with a filter for vehicle type (motorcycle, scooter, electric scooter) to compare their performance.

The dataset is available on Kaggle: [Zomato Delivery Operations Analytics Dataset](https://www.kaggle.com/datasets/saurabhbadole/zomato-delivery-operations-analytics-dataset/data).

## Repository Contents
- **SQL Scripts**:
  - `data_cleaning.sql`: SQL queries for cleaning the Zomato dataset, including removing duplicates, standardizing data, handling null values, and correcting invalid entries.
  - `data_analysis.sql`: SQL queries for analyzing delivery performance, defining late deliveries, and generating insights for visualizations.
- **Tableau Dashboard**: 
  - A Tableau workbook containing the interactive visualizations : https://public.tableau.com/views/ZomatoDeliveryAnalysis_17467906312420/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link
- **README.md**: This file, providing an overview of the project, setup instructions, and analysis details.

## Dataset Description
The dataset contains over 31,000 delivery records from Zomato in India for 2022, with the following key columns:
- `ID`: Unique delivery identifier.
- `Delivery_person_ID`: Unique identifier for the delivery person.
- `Type_of_vehicle`: Vehicle used (Motorcycle, Scooter, Electric Scooter).
- `Order_Date`: Date of the order (in multiple formats initially).
- `Time_Orderd`: Time the order was placed.
- `Time_Order_picked`: Time the order was picked up by the delivery person.
- `Time_taken`: Delivery time in minutes.
- `Weather_conditions`: Weather during delivery (Cloudy, Fog, Windy, Sandstorms, Stormy, Sandy).
- `Road_traffic_density`: Traffic conditions (Jam, High, Medium, Low).
- `Type_of_order`: Order type (Meal, Snack, Drinks, Buffet).
- `City`: City of delivery (with urbanization levels: Metropolitan, Urban, Semiurban).
- `Restaurant_latitude`, `Restaurant_longitude`: Coordinates of the restaurant.
- `Delivery_location_latitude`, `Delivery_location_longitude`: Coordinates of the delivery location.
- `Festival`: Indicator of festival days (Yes/No).
- `Delivery_person_Age`, `Delivery_person_Ratings`: Age and ratings of the delivery person.

## Data Cleaning
The `data_cleaning.sql` script performs the following steps to prepare the dataset for analysis:
1. **Duplicate Removal**:
   - Checked for duplicates using `Delivery_person_ID` and `ID` with `GROUP BY` and `ROW_NUMBER()`. No duplicates were found.
2. **Data Standardization**:
   - Standardized `Order_Date` from multiple formats (e.g., `13-02-2022`, `12/3/2022`) to a consistent `mm/dd/yyyy` format using `CASE` statements and `STR_TO_DATE`.
   - Converted `Order_Date` to the `DATE` data type.
   - Corrected invalid `Time_Order_picked` entries:
     - Removed rows with decimal time formats (e.g., `0.5` instead of `HH:MM`).
     - Fixed entries with `24:XX` times by converting to `00:XX`.
     - Converted `Time_Orderd` and `Time_Order_picked` to the `TIME` data type using `STR_TO_DATE`.
3. **Null and Invalid Value Handling**:
   - Deleted rows with `NULL` values in critical columns (e.g., `Delivery_person_Age`, `Weather_conditions`, `City`).
   - Removed rows with invalid geographic coordinates (e.g., latitude/longitude values with insufficient digits).
4. **Column Retention**:
   - No columns were removed, as all were relevant for analysis.

The cleaned data was stored in a staging table (`zomato_staging`) to preserve the original dataset.

## Data Analysis
The `data_analysis.sql` script includes queries to derive insights for the Tableau dashboard. Key analyses include:
1. **Defining Late Deliveries**:
   - Added a `Hotspot_flag` column to classify deliveries as `Late` or `Ontime`.
   - A delivery is considered late if `Time_taken` exceeds the city-specific threshold: `AVG(Time_taken) + STDDEV(Time_taken)`.
2. **Delivery Performance by Dimensions**:
   - **Type of Order**: Calculated average delivery time and late delivery percentage for Meal, Snack, Drinks, and Buffet, grouped by vehicle type.
   - **Weather Conditions**: Analyzed average delivery time and late percentage for Cloudy, Fog, Windy, Sandstorms, Stormy, and Sandy conditions, grouped by vehicle type.
   - **Road Traffic Density**: Evaluated average delivery time and late percentage for Jam, High, Medium, and Low traffic, grouped by vehicle type.
3. **Time-Based Analysis**:
   - Added `Order_Day` (e.g., Monday, Tuesday) using `TO_CHAR` on `Order_Date`.
   - Added `time_of_day` (Morning, Mid-Morning, Afternoon, Evening, Night) based on `Time_Orderd` ranges.
   - Calculated average delivery time for each day and time of day, grouped by vehicle type.
4. **Geographic Analysis**:
   - Used PostGIS to create geometry columns (`restaurant_geom`, `delivery_geom`) for restaurant and delivery locations.
   - Calculated delivery distances in kilometers using `ST_DISTANCE` with SRID 3857, adjusted for latitude distortion.
   - Grouped deliveries into distance zones (0–5 km, 5–10 km, 10–15 km, 15–20 km, Over 20 km) and computed late delivery percentages per zone, grouped by vehicle type.
   - Joined delivery locations with an `indian_states` table to calculate late delivery density per state, grouped by vehicle type.
5. **Urbanization Analysis**:
   - Analyzed late delivery percentages for Metropolitan, Urban, and Semiurban cities, grouped by vehicle type.

## Tableau Dashboard
The Tableau dashboard, **"Food Delivery Analysis: Motorcycle, Scooter, or Electric Scooter"**, visualizes the analysis results with the following components, all linked to an interactive filter for `Type_of_vehicle` (All, Motorcycle, Scooter, Electric Scooter):
1. **Bar Charts**:
   - **Percentage of Late Deliveries by Weather Conditions**: Shows late delivery percentages for Cloudy, Fog, Windy, Sandstorms, Stormy, and Sandy conditions.
   - **Percentage of Late Deliveries by Road Traffic Density**: Displays late percentages for Jam, High, Medium, and Low traffic.
   - **Percentage of Late Deliveries by Type of Order**: Illustrates late percentages for Meal, Snack, Drinks, and Buffet.
2. **Heat Map**:
   - Displays average delivery time across days of the week (Monday–Sunday) and times of day (Morning, Mid-Morning, Afternoon, Evening, Night).
3. **Pie Charts**:
   - Shows the percentage of late deliveries for Metropolitan, Urban, and Semiurban cities.
4. **Map**:
   - Visualizes late delivery percentages per Indian state, with color intensity indicating density.
5. **Text Table**:
   - Lists late delivery percentages for each distance zone (0–5 km, 5–10 km, 10–15 km, 15–20 km, Over 20 km).

The vehicle type filter allows users to compare performance across Motorcycle, Scooter, and Electric Scooter, revealing how each vehicle type handles different conditions.

## Insights

- Weather Impact: Cloudy and Fog conditions generally have more than 20% late deliveries across all vehicles while Sunny conditions have the least at less than 6%.
For cloudy conditions a scooter would be the best option while for fog conditions, the electric scooter is the preffered vehicle

- Traffic Conditions: Generally Jam attracts higher percentage of late deliveries. Intrestingly, medium traffic density is second to Jam. 
The electric scooter has low late percentage rates 24% during Jams compared to scooters and motorcycles with 25% and 39% respectively.

- Order Types: For a motorcycle, the percentages are almost at a flat rate with all orders having approximately 20% late percentages.
Scooter had the highest and lowest rates for meals(13%) and snacks(11%) respectively while Electric Scooter had the highest and lowest rates as snacks(13%) and buffet(11%)

- Time Patterns: Morning deliveries had the lowest delivery times which increased gradually peaking at evening and reducing at night. Friday evenings were the busiest for all three types of vehicles.

- Urbanization: Metropolitan cities have higher late delivery rates due to traffic and distance, with Electric Scooters and scooters showing better performance in Semi Urban areas with 100% ontime delivery.

- Geographic Trends: States with dense urban centers (e.g., Maharashtra, Gujarat) show lower late delivery density, with Scooters and electric scooters outperforming motorcycle in urban states.
Uttarakhand, a rural state, consistenty shows high late deliveries across all types of vehicles probably due to poor road network.

- Distance Zones: Deliveries over 20 km have the highest late percentages, with Scooters perfoming better than other vehicles.



## Usage
- **SQL Scripts**: Execute the scripts in a SQL client (e.g., pgAdmin, DBeaver) to clean and analyze the data.
- **Tableau Dashboard**: Open the Tableau workbook to explore the interactive visualizations. Use the vehicle type filter to compare Motorcycle, Scooter, and Electric Scooter performance.
- **GitHub**: Clone this repository to access the SQL scripts and adapt them for your own analysis.

## Contact
- Email: wambwahilary@gmail.com
- LinkedIn: https://www.linkedin.com/in/hilary-wambwa-288610355/

Here is a snapshot of the dashboard:https://public.tableau.com/views/ZomatoDeliveryAnalysis_17467906312420/Dashboard1?:language=en-US&publish=yes&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link


![image](https://github.com/user-attachments/assets/6828078f-bafc-4bb2-828f-2fe4180fef6b)

