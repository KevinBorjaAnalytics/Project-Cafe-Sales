-- CAFE EXPLORATORY DATA ANALYSIS
-- 1. WHAT IS THE MOST SOLD ITEM?
SELECT 
	DISTINCT Item,
    `Price Per Unit`,
    SUM(Quantity) AS Total_Quantity
FROM cafe_sales
GROUP BY 1, 2
ORDER BY 3 DESC; -- Coffee is the most sold item with 3,929

-- 2. WHAT IS THE MOST SOLD ITEM CATEGORY
SELECT 
	CASE
		WHEN Item = 'Coffee' THEN 'Warm Beverages'
        WHEN Item = 'Salad' THEN 'Healthy Snacks'
        WHEN Item = 'Tea' THEN 'Warm Beverages'
        WHEN Item = 'Cookie' THEN 'Snacks'
        WHEN Item = 'Juice' THEN 'Cold Beverages'
        WHEN Item = 'Cake' THEN 'Snacks'
        WHEN Item = 'Sandwich' THEN 'Healthy Snacks'
        WHEN Item = 'Smoothie' THEN 'Cold Beverages'
		ELSE 'Unknown'
    END AS Category,
    SUM(Quantity) AS Total_Quantity
FROM cafe_sales
GROUP BY category
ORDER BY 2 DESC; -- Warm Beverages is the most sold category with 7,584

-- 3. AVERAGE TRANSACTION VALUE?
SELECT 
    ROUND(SUM(Quantity * `Price Per Unit`) / COUNT(DISTINCT `Transaction ID`), 2) AS average_transaction_value,
    MIN(`Total Spent`) AS least_spent, 
    MAX(`Total Spent`) AS most_spent
FROM cafe_sales; -- average value per transaction is 8.94

-- 4. CUSTOMERS' SPENDING HABITS?
SELECT 
	DISTINCT `Total Spent`,
    COUNT(`Total Spent`) AS frequency
FROM cafe_sales
GROUP BY `Total Spent`
ORDER BY frequency DESC; -- 6.00 is the most frequent transaction

WITH frequency_table AS (
SELECT 
    CASE 
        WHEN `Total Spent` BETWEEN 1.00 AND 5.00 THEN '1.00 - 5.00'
        WHEN `Total Spent` BETWEEN 5.00 AND 10.00 THEN '5.00 - 10.00'
        WHEN `Total Spent` BETWEEN 10.00 AND 15.00 THEN '10.00 - 15.00'
        WHEN `Total Spent` BETWEEN 15.00 AND 20.00 THEN '15.00 - 20.00'
        ELSE '20+' 
    END AS total_spent_range,
    COUNT(*) AS Frequency
FROM cafe_sales
GROUP BY total_spent_range
ORDER BY Frequency DESC
)
SELECT
	total_spent_range,
    Frequency,
	ROUND((SUM(Frequency) * 100.0 / (SELECT SUM(Frequency) FROM frequency_table)), 2) AS Relative_Frequency
FROM frequency_table
GROUP BY total_spent_range
ORDER BY Frequency DESC; -- frequency table for histogram

-- 5. WHAT ITEM GENERATES THE MOST REVENUE?
SELECT 
	DISTINCT Item,
    `Price Per Unit`,
    SUM(`Total Spent`) AS Total_revenue,
    ROUND((SUM(`Total Spent`) * 100.0 / (SELECT SUM(`Total Spent`) FROM cafe_sales)), 2) AS Revenue_Percentage
FROM cafe_sales
GROUP BY 1,2
ORDER BY 3 DESC; -- Salad generates the most revenue with 19,240

-- 6. SALES REVENUE BY PAYMENT METHOD
SELECT 
	`Payment Method`,
    SUM(`Total Spent`) AS Total_revenue,
    ROUND((SUM(`Total Spent`) * 100.0 / (SELECT SUM(`Total Spent`) FROM cafe_sales)), 2) AS Revenue_Percentage
FROM cafe_sales
GROUP BY `Payment Method`
ORDER BY Total_revenue DESC; -- Credit Card is the known payment method that generates the most revenue

-- 7. SALES REVENUE BY LOCATION
SELECT 
	Location,
    SUM(`Total Spent`) AS Total_revenue,
    ROUND((SUM(`Total Spent`) * 100.0 / (SELECT SUM(`Total Spent`) FROM cafe_sales)), 2) AS Revenue_Percentage
FROM cafe_sales
GROUP BY Location
ORDER BY Total_revenue DESC; -- In-store is the known location that generates the most revenue

-- Time Series Analysis
-- SALES REVENUE PERFORMANCE BY MONTH
SELECT 
	MONTHNAME(`Transaction Date`) AS `month`,
    SUM(`Total Spent`) AS Total_revenue
FROM cafe_sales
GROUP BY `month`
ORDER BY Total_revenue DESC; -- January generates the most revenue with 7,808.50 but pretty even across the board

-- SALES REVENUE PERFORMANCE BY SEASON
SELECT
	DISTINCT CASE
		WHEN MONTHNAME(`Transaction Date`) = 'January' THEN 'Winter'
		WHEN MONTHNAME(`Transaction Date`) = 'February' THEN 'Winter'
		WHEN MONTHNAME(`Transaction Date`) = 'March' THEN 'Spring'
		WHEN MONTHNAME(`Transaction Date`) = 'April' THEN 'Spring'
		WHEN MONTHNAME(`Transaction Date`) = 'May' THEN 'Spring'
		WHEN MONTHNAME(`Transaction Date`) = 'June' THEN 'Summer'
		WHEN MONTHNAME(`Transaction Date`) = 'July' THEN 'Summer'
		WHEN MONTHNAME(`Transaction Date`) = 'August' THEN 'Summer'
		WHEN MONTHNAME(`Transaction Date`) = 'September' THEN 'Autumn'
		WHEN MONTHNAME(`Transaction Date`) = 'October' THEN 'Autumn'
		WHEN MONTHNAME(`Transaction Date`) = 'November' THEN 'Autumn'
		WHEN MONTHNAME(`Transaction Date`) = 'December' THEN 'Winter'
	END AS season,
    SUM(`Total Spent`) AS Total_Revenue,
    ROUND((SUM(`Total Spent`) * 100.0 / (SELECT SUM(`Total Spent`) FROM cafe_sales)), 2) AS Revenue_Percentage
FROM cafe_sales
GROUP BY 1
ORDER BY 2 DESC; -- even results

-- SALES REVENUE PERFORMANCE BY DAY
SELECT 
	DAYNAME(`Transaction Date`) AS `Day of week`,
    SUM(`Total Spent`) AS Total_revenue
FROM cafe_sales
GROUP BY `Day of week`
ORDER BY Total_revenue DESC; -- Thursday generates the most revenue with 13,062.50