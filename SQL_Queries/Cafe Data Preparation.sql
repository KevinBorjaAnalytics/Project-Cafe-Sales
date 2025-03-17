-- DATA CLEANING PROCESS

-- 1. REMOVE DUPLICATES
-- CHECK FOR DUPLICATES
WITH duplicate_cte AS (
	SELECT *, ROW_NUMBER() OVER (
    PARTITION BY `Transaction ID`, Item, Quantity, `Price Per Unit`, `Total Spent`, `Payment Method`, Location, `Transaction Date`
    ORDER BY `Transaction ID`) AS row_num
    FROM cafe_sales)
SELECT * FROM duplicate_cte
WHERE row_num > 1; -- There are no duplicates

-- 2. STANDARDIZE DATA
-- CHECK IF ALL UNIQUE IDs MATCH IN LENGTH
SELECT DISTINCT LENGTH(`Transaction ID`) AS ID_length
FROM cafe_sales; -- all match length: 11

-- STANDARDIZE ITEMS
UPDATE cafe_sales SET Item = NULL
WHERE Item IN ('ERROR', 'UNKNOWN', '');

-- STANDARDIZE QUANTITY
UPDATE cafe_sales SET Quantity = NULL
WHERE Quantity IN ('ERROR', 'UNKNOWN', '');

ALTER TABLE cafe_sales MODIFY Quantity INT;

-- STANDARDIZE PRICE PER UNIT
-- CORRECT FORMAT
UPDATE cafe_sales 
SET `Price Per Unit` =
	    CASE
			WHEN `Price Per Unit` = '1' THEN '1.00'
			WHEN `Price Per Unit` = '1.5' THEN '1.50'
			WHEN `Price Per Unit` = '2' THEN '2.00'
			WHEN `Price Per Unit` = '3' THEN '3.00'
			WHEN `Price Per Unit` = '4' THEN '4.00'
			WHEN `Price Per Unit` = '5' THEN '5.00'
			ELSE NULL
		END;
-- CORRECT DATATYPE
ALTER TABLE cafe_sales MODIFY `Price Per Unit` DECIMAL(10, 2);

-- STANDARDIZE TOTAL SPENT
-- CORRECT FORMAT
UPDATE cafe_sales 
SET `Total Spent` =
	    CASE
			WHEN `Total Spent` = '1' THEN '1.00'
			WHEN `Total Spent` = '1.5' THEN '1.50'
			WHEN `Total Spent` = '2' THEN '2.00'
			WHEN `Total Spent` = '3' THEN '3.00'
			WHEN `Total Spent` = '4' THEN '4.00'
            WHEN `Total Spent` = '4.5' THEN '4.50'
			WHEN `Total Spent` = '5' THEN '5.00'
            WHEN `Total Spent` = '6' THEN '6.00'
            WHEN `Total Spent` = '7.5' THEN '7.50'
            WHEN `Total Spent` = '8' THEN '8.00'
            WHEN `Total Spent` = '9' THEN '9.00'
            WHEN `Total Spent` = '10' THEN '10.00'
            WHEN `Total Spent` = '12' THEN '12.00'
            WHEN `Total Spent` = '15' THEN '15.00'
            WHEN `Total Spent` = '16' THEN '16.00'
            WHEN `Total Spent` = '20' THEN '20.00'
            WHEN `Total Spent` = '25' THEN '25.00'
			ELSE NULL
		END;
-- CORRECT DATATYPE
ALTER TABLE cafe_sales MODIFY `Total Spent` DECIMAL(10, 2);

-- STANDARDIZE PAYMENT METHOD
UPDATE cafe_sales SET `Payment Method`  = NULL
WHERE `Payment Method`  IN ('ERROR', 'UNKNOWN', '');

-- STANDARDIZE LOCATION
UPDATE cafe_sales SET Location = NULL
WHERE Location IN ('ERROR', 'UNKNOWN', '');

-- STANDARDIZE DATE
-- REMOVE TEXT VALUES FROM DATE
UPDATE cafe_sales SET `Transaction Date` = NULL
WHERE `Transaction Date` IN ('ERROR', 'UNKNOWN', '');
-- CORRECT FORMAT
UPDATE cafe_sales SET `Transaction Date` = STR_TO_DATE(`Transaction Date`, '%d/%m/%Y');
-- CORRECT DATATYPE
ALTER TABLE cafe_sales MODIFY `Transaction Date` DATE;

-- 3. HANDLE MISSING DATA
-- NULL VALUE OVERVIEW
SELECT 
    SUM(Item IS NULL) AS item,
    SUM(Quantity IS NULL) AS quantity,
    SUM(`Price Per Unit` IS NULL) AS price_per_unit,
    SUM(`Total Spent` IS NULL) AS total,
    SUM(`Payment Method` IS NULL) AS pay_method,
    SUM(Location IS NULL) AS location,
    SUM(`Transaction Date` IS NULL) AS `date`
FROM cafe_sales;

-- FILL IN MISSING VALUES FOR PRICE PER UNIT
UPDATE cafe_sales SET `Price Per Unit` = 3.00
WHERE `Price Per Unit` IS NULL AND Item = 'Cake';

UPDATE cafe_sales SET `Price Per Unit` = 2.00
WHERE `Price Per Unit` IS NULL AND Item = 'Coffee';

UPDATE cafe_sales SET `Price Per Unit` = 1.00
WHERE `Price Per Unit` IS NULL AND Item = 'Cookie';

UPDATE cafe_sales SET `Price Per Unit` = 3.00
WHERE `Price Per Unit` IS NULL AND Item = 'Juice';

UPDATE cafe_sales SET `Price Per Unit` = 5.00
WHERE `Price Per Unit` IS NULL AND Item = 'Salad';

UPDATE cafe_sales SET `Price Per Unit` = 4.00
WHERE `Price Per Unit` IS NULL AND Item = 'Sandwich';

UPDATE cafe_sales SET `Price Per Unit` = 4.00
WHERE `Price Per Unit` IS NULL AND Item = 'Smoothie';

UPDATE cafe_sales SET `Price Per Unit` = 1.50
WHERE `Price Per Unit` IS NULL AND Item = 'Tea';

UPDATE cafe_sales SET `Price Per Unit` = ROUND(`Total Spent` / Quantity, 2)
WHERE `Price Per Unit` IS NULL AND (Quantity IS NOT NULL AND `Total Spent` IS NOT NULL);

-- FILL IN MISSING VALUES FOR  TOTAL SPENT
UPDATE cafe_sales SET `Total Spent` = Quantity * `Price Per Unit`
WHERE `Total Spent` IS NULL AND Quantity IS NOT NULL;

-- FILL IN MISSING VALUES FOR QUANTITY
UPDATE cafe_sales SET Quantity = ROUND(`Total Spent` / `Price Per Unit`)
WHERE Quantity IS NULL AND `Total Spent` IS NOT NULL;

-- FILL IN MISSING VALUES FOR ITEMS
UPDATE cafe_sales SET Item = 'Cake/Juice'
WHERE Item IS NULL AND `Price Per Unit` = 3.00;

UPDATE cafe_sales SET Item = 'Coffee'
WHERE Item IS NULL AND `Price Per Unit` = 2.00;

UPDATE cafe_sales SET Item = 'Cookie'
WHERE Item IS NULL AND `Price Per Unit` = 1.00;

UPDATE cafe_sales SET Item = 'Salad'
WHERE Item IS NULL AND `Price Per Unit` = 5.00;

UPDATE cafe_sales SET Item = 'Sandwich/Smoothie'
WHERE Item IS NULL AND `Price Per Unit` = 4.00;

UPDATE cafe_sales SET Item = 'Tea'
WHERE Item IS NULL AND `Price Per Unit` = 1.50;

-- FILL IN MISSING VALUES FOR PAYMENT METHOD
UPDATE cafe_sales SET `Payment Method` = 'Unknown'
WHERE `Payment Method` IS NULL;

-- FILL IN MISSING VALUES FOR LOCATION
UPDATE cafe_sales SET Location = 'Unknown'
WHERE Location IS NULL;

-- FILL IN MISSING VALUES FOR TRANSACTION DATE
WITH date_fix AS (
SELECT 
	`Transaction ID`,
	COALESCE(`Transaction Date`, LAG(`Transaction Date`) OVER (ORDER BY `Transaction ID`)) AS filled_date
FROM cafe_sales
)
UPDATE cafe_sales t1
JOIN date_fix t2
	ON t1.`Transaction ID` = t2.`Transaction ID`
SET t1.`Transaction Date` = t2.filled_date;

-- NUMBER OF NULLS AT THIS POINT
SELECT 
    SUM(Item IS NULL) AS item,
    SUM(Quantity IS NULL) AS quantity,
    SUM(`Price Per Unit` IS NULL) AS price_per_unit,
    SUM(`Total Spent` IS NULL) AS total,
    SUM(`Payment Method` IS NULL) AS pay_method,
    SUM(Location IS NULL) AS location,
    SUM(`Transaction Date` IS NULL) AS `date`
FROM cafe_sales; -- 52 in total across Item, Quantity, Price Per Unit, Total Spent

SELECT * FROM cafe_sales
WHERE Item IS NULL OR
Quantity IS NULL OR
`Price Per Unit` IS NULL OR
`Total Spent` IS NULL; -- 26 rows containing the 52 NULL values

-- FIND THE MODE VALUES TO FILL THE NULLS WHEN PRICE PER UNIT IS KNOWN 
-- FIND THE MOST 'TOTAL SPENT' VALUE WHEN PRICE PER UNIT IS 5.00
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 5.00
GROUP BY `Total Spent`
ORDER BY 1 DESC
lIMIT 1; -- 25.00 is the most frequency total when unit price is 5.00

-- FIND THE MOST TOTAL SPENT VALUE WHEN PRICE PER UNIT IS 4.00
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 4.00
GROUP BY `Total Spent`
ORDER BY 1 DESC
LIMIT 1; -- 20.00 is the most frequency total when unit price is 4.00

-- FIND THE MOST TOTAL SPENT VALUE WHEN PRICE PER UNIT IS 3.00
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 3.00
GROUP BY `Total Spent`
ORDER BY 1 DESC
LIMIT 1; -- 15.00 is the most frequency total when unit price is 3.00

-- FIND THE MOST TOTAL SPENT VALUE WHEN PRICE PER UNIT IS 2.00
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 2.00
GROUP BY `Total Spent`
ORDER BY 1 DESC
LIMIT 1; -- 10.00 is the most frequency total when unit price is 2.00

-- FIND THE MOST TOTAL SPENT VALUE WHEN PRICE PER UNIT IS 1.50
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 1.50
GROUP BY `Total Spent`
ORDER BY 1 DESC
LIMIT 1; -- 7.50 is the most frequency total when unit price is 1.50

-- FIND THE MOST TOTAL SPENT VALUE WHEN PRICE PER UNIT IS 1.00
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`) AS frequency FROM cafe_sales
WHERE `Price Per Unit` = 1.00
GROUP BY `Total Spent`
ORDER BY 1 DESC
LIMIT 1; -- 5.00 is the most frequency total when unit price is 1.00
-- FILL IN THE NULL VALUES USING THE MODE
-- FILL IN WHERE PRICE PER UNIT IS 5.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 25.00,
    Quantity = 5
WHERE `Price Per Unit` = 5.00 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE PRICE PER UNIT IS 4.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 20.00,
    Quantity = 5
WHERE `Price Per Unit` = 4.00 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE PRICE PER UNIT IS 3.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 15.00,
    Quantity = 5
WHERE `Price Per Unit` = 3.00 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE PRICE PER UNIT IS 2.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 10.00,
    Quantity = 5
WHERE `Price Per Unit` = 2.00 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE PRICE PER UNIT IS 1.50 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 7.50,
    Quantity = 5
WHERE `Price Per Unit` = 1.50 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE PRICE PER UNIT IS 1.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET `Total Spent` = 5.00,
    Quantity = 5
WHERE `Price Per Unit` = 1.00 
AND (Quantity IS NULL AND `Total Spent` IS NULL);

-- FIND THE MODE VALUES TO FILL THE NULLS WHERE 'TOTAL SPENT' IS KNOWN
-- FIND THE MOST 'Price Per Unit' VALUE WHEN TOTAL SPENT IS 25.00
SELECT DISTINCT `Price Per Unit`, COUNT(`Price Per Unit`)
FROM cafe_sales
WHERE `Total Spent` = 25.00
GROUP BY `Price Per Unit`
ORDER BY 1 DESC
LIMIT 1; -- 5.00 is the most frequent 'Price Per Unit' when 'Total Spent' is 25.00

-- FIND THE MOST 'Price Per Unit' VALUE WHEN TOTAL SPENT IS 20.00
SELECT DISTINCT `Price Per Unit`, COUNT(`Price Per Unit`)
FROM cafe_sales
WHERE `Total Spent` = 20.00
GROUP BY `Price Per Unit`
ORDER BY 1 DESC
LIMIT 1; -- 5.00 is the most frequent 'Price Per Unit' when 'Total Spent' is 20.00

-- FIND THE MOST 'Price Per Unit' VALUE WHEN TOTAL SPENT IS 9.00
SELECT DISTINCT `Price Per Unit`, COUNT(`Price Per Unit`)
FROM cafe_sales
WHERE `Total Spent` = 9.00
GROUP BY `Price Per Unit`
ORDER BY 1 DESC
LIMIT 1; -- 3.00 is the most frequent 'Price Per Unit' when 'Total Spent' is 9.00
-- FILL IN THE NULL VALUES USING THE MODE
-- FILL IN WHERE TOTAL SPENT IS 25.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET Item = 'Salad',
	Quantity = 5,
    `Price Per Unit` = 5.00
WHERE `Total Spent` = 25.00
AND (Item IS NULL AND Quantity IS NULL AND `Price Per Unit` IS NULL);

-- FILL IN WHERE TOTAL SPENT IS 20.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET Item = 'Salad',
	Quantity = 4,
    `Price Per Unit` = 5.00
WHERE `Total Spent` = 20.00
AND (Item IS NULL AND Quantity IS NULL AND `Price Per Unit` IS NULL);

-- FILL IN WHERE TOTAL SPENT IS 9.00 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET Item = 'Cake/Juice',
	Quantity = 2,
    `Price Per Unit` = 3.00
WHERE `Total Spent` = 9.00
AND (Item IS NULL AND Quantity IS NULL AND `Price Per Unit` IS NULL);

-- FIND THE MODE VALUES TO FILL THE NULLS WHERE QUANTITY IS KNOWN
-- FIND THE MOST 'TOTAL SPENT' VALUE WHEN QUANTITY IS 4
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`)
FROM cafe_sales
WHERE Quantity = 4
GROUP BY `Total Spent`
ORDER BY 1 DESC LIMIT 1; -- 20.00 is the most frequency Total Spent When quantity is 4

-- FIND THE MOST 'TOTAL SPENT' VALUE WHEN QUANTITY IS 2
SELECT DISTINCT `Total Spent`, COUNT(`Total Spent`)
FROM cafe_sales
WHERE Quantity = 2
GROUP BY `Total Spent`
ORDER BY 1 DESC LIMIT 1; -- 10.00 is the most frequency Total Spent When quantity is 2
-- FILL IN THE NULL VALUES USING THE MODE
-- FILL IN WHERE QUANTITY IS 4 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET Item = 'Salad',
    `Price Per Unit` = 5.00,
	`Total Spent` = 20.00
WHERE Quantity = 4
AND (Item IS NULL AND `Price Per Unit` IS NULL AND `Total Spent` IS NULL);

-- FILL IN WHERE QUANTITY IS 2 AND OTHER COLUMNS ARE NULL
UPDATE cafe_sales
SET Item = 'Salad',
    `Price Per Unit` = 5.00,
	`Total Spent` = 10.00
WHERE Quantity = 2
AND (Item IS NULL AND `Price Per Unit` IS NULL AND `Total Spent` IS NULL);

-- FINAL SUMMARY
SELECT 
    SUM(Item IS NOT NULL) AS item,
    SUM(Quantity IS NOT NULL) AS quantity,
    SUM(`Price Per Unit` IS NOT NULL) AS price_per_unit,
    SUM(`Total Spent` IS NOT NULL) AS total,
    SUM(`Payment Method` IS NOT NULL) AS pay_method,
    SUM(Location IS NOT NULL) AS location,
    SUM(`Transaction Date` IS NOT NULL) AS `date`
FROM cafe_sales; -- all columns have no nulls