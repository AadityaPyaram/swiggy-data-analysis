-- Active: 1790015617336@@127.0.0.1@3306@zomato

-- food table

SELECT * FROM food
LIMIT 10;

-- 1 row = 1 food item, so f_id should be unique

SELECT COUNT(*) FROM food; -- 371560 rows


-- f_id

-- validating f_id
SELECT COUNT(*) FROM food
WHERE f_id NOT REGEXP '^fd[0-9]+$';
-- 8 rows where f_id is not in fd[0-9] format
-- let's verify those columns

SELECT f_id FROM food
WHERE f_id NOT REGEXP '^fd[0-9]+$';
-- all the rows where f_id is not in fd[0-9] format are 'empty strings' (NULLs)
-- f_id column validated

-- checking for NULLs
SELECT COUNT(*) FROM food
WHERE TRIM(f_id) = '';
-- 8 NULLs

SELECT COUNT(DISTINCT f_id) FROM food; -- all values are unique if not for those 8 NULLs

-- updating f_id column
UPDATE food
SET f_id = NULLIF(TRIM(f_id), '');

SELECT COUNT(*) FROM food
WHERE f_id IS NULL; -- confirming 8 NULL values

-- we can fill the NULLs with forward fill
-- this column can be primary key after handling NULL values

SELECT * FROM food
LIMIT 10;


-- item

SELECT COUNT(*) FROM food
WHERE TRIM(item) = '';
-- 8 NULL values

-- let's check if those NULL values are the rows where f_id is NULL

SELECT * FROM food
WHERE TRIM(item) = '';
-- yes, the 8 NULL values are where f_id is NULL

-- let's check if that's the same case for veg or non veg column
SELECT COUNT(*) FROM food
WHERE TRIM(veg_or_non_veg) = ''; -- it shows 8!

SELECT DISTINCT veg_or_non_veg FROM food; -- shows Veg, Non-veg, empty cell

-- this confirms that all the rows where f_id is NULL are NULL, so we have to remove the entire rows, no point of filling
-- and now the f_id column should be unique and can be used as primary key

DELETE FROM food
WHERE f_id IS NULL; -- 8 rows now removed

SELECT COUNT(*) FROM food
WHERE f_id IS NULL OR TRIM(item) = '' OR TRIM(veg_or_non_veg) = ''; -- all NULLs removed

SELECT COUNT(*) AS total_rows, COUNT(DISTINCT f_id) AS f_id FROM food;
-- our table now has 371552 rows, with 1 row = 1 food item
-- 371552 distinct f_id (PRIMARY KEY)
-- no cols contain NULLs now

-- let's update our table
ALTER TABLE food
MODIFY f_id VARCHAR(255) PRIMARY KEY,
MODIFY item VARCHAR(255) NOT NULL,
MODIFY veg_or_non_veg VARCHAR(50) NOT NULL;

SELECT * FROM food
LIMIT 10;

DESC food;
-- food table is now cleaned and ready for analysis.


-- menu

SELECT * FROM menu
LIMIT 10;

-- 1 row = 1 food item from the menu
-- 1 menu has many food items
-- there can be many menus containing same food item
-- so, no unique row for this table
-- we can create index on menu_id col
-- f_id is a foreign key here from food table

SELECT COUNT(*) FROM menu; -- 1048575 rows

-- menu_id

-- validating
SELECT COUNT(*) FROM menu
WHERE menu_id NOT REGEXP '^mn[0-9]+$';
-- no anomalies

-- NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(menu_id) = '';
-- no NULLs

-- updating the column
ALTER TABLE menu
MODIFY menu_id VARCHAR(255) NOT NULL;

SELECT COUNT(DISTINCT menu_id) FROM menu;

DESC menu;


-- r_id
SELECT * FROM menu
LIMIT 10;
-- needs change in datatype

-- validating
SELECT COUNT(*) FROM menu
WHERE r_id NOT REGEXP '^[0-9]+$';
-- no anomalies
-- we're gonna leave this column as VARCHAR as this references r_id in restaurant table

-- NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(r_id) = '';
-- no NULLs found

ALTER TABLE menu
MODIFY r_id VARCHAR(100) NOT NULL;

-- validation
-- checking if r_id refrences id not present in restauraant table
SELECT COUNT(*) FROM menu t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t2.id IS NULL;
-- 273 rows where r_id is referencing id's in restaurant table that don't exist
-- we'll come back to this after dealing with the restaurant table


DESC menu;

-- f_id

SELECT * FROM menu
LIMIT 10;

-- NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(f_id) = '';
-- no NULLs

-- validate

SELECT COUNT(*) FROM menu
WHERE f_id NOT REGEXP '^fd[0-9]+$';
-- no anomalies

-- let's check if there's any f_id in this table that's not referencing f_id of food table

SELECT COUNT(*) FROM menu t1
LEFT JOIN food t2
ON t1.f_id = t2.f_id
WHERE t2.f_id IS NULL;
-- 1205 f_ids in menu table that are referencing to f_id that don't exist in food table

SELECT COUNT(DISTINCT t1.f_id) FROM menu t1
LEFT JOIN food t2
ON t1.f_id = t2.f_id
WHERE t2.f_id IS NULL;
-- 8 f_ids are referencing to f_ids that don't exist in food table
-- maybe these are the same 8 f_ids that were missing from food table
-- but deleting those 8 rows was the right call, because if we were to insert these 8 f_ids in food table, we'd have to invent/add random value in item and also flagging veg/non-veg wouldv'e been invalid

-- we'll store these orphaned f_id's in a seperate table for now and drop those rows from our menu table

CREATE TABLE menu_orphans AS
SELECT t1.*
FROM menu t1
LEFT JOIN food t2
ON t1.f_id = t2.f_id
WHERE t2.f_id IS NULL;

-- dropping orphans from menu table
DELETE t1 FROM menu t1
LEFT JOIN food t2
ON t1.f_id = t2.f_id
WHERE t2.f_id IS NULL;

SELECT COUNT(*) FROM menu; -- our table now has 1047370 rows

-- checking for NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(f_id) = '';
-- no NULLs

-- adding foreign key
ALTER TABLE menu
MODIFY f_id VARCHAR(255) NOT NULL,
ADD CONSTRAINT fk_f_id FOREIGN KEY (f_id) REFERENCES food (f_id);

DESC food;
DESC menu;


-- now that we removed 1205 rows, let's see how the r_id referencing id in restaurant table is affected
SELECT COUNT(*) FROM menu t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t2.id IS NULL;
-- no anomalies
-- we'll come back here to create FK after dealing with restaurant table, and making id column PK
-- restaurant table is dealt with, let's make this as FK

ALTER TABLE menu
MODIFY r_id VARCHAR(255) NOT NULL,
ADD CONSTRAINT fk_r_id FOREIGN KEY (r_id) REFERENCES restaurant(`id`);

DESC restaurant;
DESC menu;


-- cuisine
SELECT * FROM menu
LIMIT 10;

-- distinct cuisines
SELECT COUNT(DISTINCT LOWER(cuisine)) FROM menu; -- 857
SELECT COUNT(DISTINCT cuisine) FROM menu; -- 857
-- so no case sensitive anomalies

-- NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(cuisine) = '';
-- no NULLs

ALTER TABLE menu
MODIFY cuisine VARCHAR(255) NOT NULL;

DESC menu;

-- price
SELECT * FROM menu
LIMIT 10;
-- dtype -> DECIMAL(10,2)

SELECT COUNT(*) FROM menu
WHERE price NOT REGEXP '^[0-9]+\\.[0-9]+$';
-- no anomalies

-- NULLs
SELECT COUNT(*) FROM menu
WHERE TRIM(price) = '';
-- no NULLs


ALTER TABLE menu
MODIFY price DECIMAL(10,2);

-- vaidation 
SELECT COUNT(*) FROM menu
WHERE price <= 0;
-- 59 rows where price is <= 0

SELECT DISTINCT price FROM menu
WHERE price <= 0;
-- 59 rows where price = 0
-- these could be placeholders, so replacing them with NULL
UPDATE menu
SET price = NULL
WHERE price = 0;

SELECT COUNT(*) FROM menu
WHERE price <= 0; -- no more anomalies

DESC menu;


-- orders

SELECT * FROM orders
LIMIT 10;

-- order_date

-- NULLs
SELECT COUNT(*) FROM orders
WHERE TRIM(order_date) = '';
-- no NULLs

-- validate
SELECT COUNT(*) FROM orders
WHERE order_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';
-- no anomalies

SELECT COUNT(*) FROM orders
WHERE STR_TO_DATE(order_date, '%Y-%m-%d') IS NULL;
-- no anomalies

UPDATE orders
SET order_date = STR_TO_DATE(order_date, '%Y-%m-%d');

ALTER TABLE orders
MODIFY order_date DATE NOT NULL;
CREATE INDEX idx_order_date ON orders(order_date);

DESC orders;

-- sales_qty
SELECT * FROM orders
LIMIT 10;

-- validation
SELECT COUNT(*) FROM orders
WHERE sales_qty NOT REGEXP '^[0-9]+$';
-- no anomalies

-- NULLs
SELECT COUNT(*) FROM orders
WHERE TRIM(sales_qty) = '';
-- no NULLs

ALTER TABLE orders
MODIFY sales_qty INT;


-- validation
SELECT COUNT(*) FROM orders
WHERE sales_qty <= 0;
-- no anomalies

ALTER TABLE orders
MODIFY sales_qty INT NOT NULL;

DESC orders;

-- sales_amount
SELECT * FROM orders
LIMIT 10;

SELECT COUNT(*) FROM orders
WHERE TRIM(sales_amount) = '';
-- no NULLs

-- validation
SELECT * FROM orders
WHERE sales_amount NOT REGEXP '^[0-9]+$';
-- 2 sales_amount where values are -1, these could be placeholders

ALTER TABLE orders
MODIFY sales_amount DECIMAL(10,2);

-- validation
SELECT COUNT(*) FROM orders
WHERE sales_amount <= 0; -- 1611 rows where sales_amount is <=0

SELECT DISTINCT sales_amount FROM orders
WHERE sales_amount <= 0; -- -1.00 and 0.00

-- let's set these to NULL
UPDATE orders
SET sales_amount = NULL
WHERE sales_amount = -1.00;

UPDATE orders
SET sales_amount = NULL
WHERE sales_amount = 0.00;

DESC orders;

-- currency
SELECT DISTINCT currency FROM orders;
-- only one distinct value - INR

SELECT COUNT(*) FROM orders
WHERE TRIM(currency) = '';
-- no NULLs

-- no need of validation as we confirmed there is only 1 distinct value

ALTER TABLE orders
MODIFY currency CHAR(3) NOT NULL;

DESC orders;

-- user_id

SELECT * FROM orders
LIMIT 10;

-- this column references user_id column in users table

-- validation
-- user_id that are referencing to user_ids not present in users table

SELECT COUNT(*) FROM orders t1
LEFT JOIN users t2
ON t1.user_id = t2.user_id
WHERE t2.user_id IS NULL;
-- no anomalies

-- NULLs
SELECT COUNT(*) FROM orders
WHERE TRIM(user_id) = ''; -- no NULLs

-- let's come back to create FK after dealing with users table
-- users table is now dealt with, let's make this FK

ALTER TABLE orders
MODIFY user_id VARCHAR(255) NOT NULL,
ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);

DESC orders;

-- r_id

-- NULLs
SELECT COUNT(*) FROM orders
WHERE TRIM(r_id) = '';  -- 1617 NULLs

SELECT * FROM orders
LIMIT 10;
-- this column references r_id column in restaurants table

-- validation
SELECT COUNT(*) FROM orders t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t2.id IS NULL; -- 1,50,281 rows referencing id not present in restaurant table
-- inspecting

SELECT * FROM orders t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t2.id IS NULL
LIMIT 10;

SELECT * FROM restaurant
LIMIT 10; -- because the r_id column is of VARCHAR dtype bu the values have a decimal value, so first have to validate and change to INT then again to VARCHAR

SELECT COUNT(DISTINCT r_id) FROM orders
WHERE r_id NOT REGEXP '^[0-9]+\\.0$';

SELECT DISTINCT r_id FROM orders
WHERE r_id NOT REGEXP '^[0-9]+\\.0$'; -- shows empty STRING

SELECT COUNT(*) FROM orders
WHERE r_id NOT REGEXP '^[0-9]+\\.0$'; -- 1617, the exact count we caught while checking for NULLs

-- let's convert them to NULL
UPDATE orders
SET r_id = NULL
WHERE TRIM(r_id) = '';

SELECT COUNT(DISTINCT r_id) FROM orders
WHERE r_id NOT REGEXP '^[0-9]+\\.0$'; -- now, ready to convert to INT

-- now, first dtype -> INT
ALTER TABLE orders
MODIFY r_id INT;

SELECT * FROM orders
LIMIT 10;

-- now, again to VARCHAR
ALTER TABLE orders
MODIFY r_id VARCHAR(255);

SELECT * FROM orders
LIMIT 10;

-- now let's check for reference errors
SELECT COUNT(*) FROM orders t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t1.r_id IS NOT NULL AND t2.id IS NULL; -- only 1 row where r_id references to id that does not exist in restaurant table

-- let's verify that row
SELECT * FROM orders t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t1.r_id IS NOT NULL AND t2.id IS NULL; -- r_id = 427891

SELECT * FROM restaurant
WHERE `id` = '427891'; -- id is not in the restaurant table

-- let's make this r_id as NULL too
UPDATE orders
SET r_id = NULL
WHERE r_id = '427891';

SELECT COUNT(*) FROM orders t1
LEFT JOIN restaurant t2
ON t1.r_id = t2.id
WHERE t1.r_id IS NOT NULL AND t2.id IS NULL; -- now all r_id's references ids that exist in restaurant table, except that 1 value which we just made NULL

-- let's come back to this to make r_id as FK after dealing with restaurant table
-- restaurant table is dealt with, now let's make this r_id FK

ALTER TABLE orders
ADD CONSTRAINT fk_orders_r_id FOREIGN KEY (r_id) REFERENCES restaurant(`id`);


-- orders_type table

SELECT * FROM orders_type
LIMIT 10;

-- 1 row = 1 order_id
-- so, order_id column should be unique and we can use it as PRIMARY KEY
-- type tells the type of order placed in that order_id

-- order_id
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT Order_id) AS order_id FROM orders_type;
-- yes, this is a unique column

-- checking for NULLs
SELECT COUNT(*) FROM orders_type
WHERE TRIM(`Order_Id`) = '';
-- no NULLs

ALTER TABLE orders_type
MODIFY Order_Id VARCHAR(255) PRIMARY KEY;

DESC orders_type;

-- type

SELECT COUNT(DISTINCT `type`) FROM orders_type;
-- 3 different types of orders

SELECT DISTINCT `type` FROM orders_type; -- Veg, Non-Veg, Other

-- NULLs
SELECT COUNT(*) FROM orders_type
WHERE TRIM(`type`) = '';
-- no NULLs

-- validate
SELECT COUNT(*) FROM orders_type
WHERE TRIM(`Type`) NOT IN ('Veg', 'Non-Veg', 'Other'); -- no anomalies

ALTER TABLE orders_type
MODIFY `Type` VARCHAR(100) NOT NULL CHECK(`Type` IN ('Veg', 'Non-Veg', 'Other'));

DESC orders_type;
--orders_type table cleaned and ready for analysis


-- restaurant

SELECT * FROM restaurant
LIMIT 10;

-- id

-- validation
SELECT COUNT(*) FROM restaurant
WHERE `id` NOT REGEXP '^[0-9]+$';
-- no anomalies
-- since it's going to used as FK in other tables, we're keeping it's data type as VARCHAR

-- NULLs
SELECT COUNT(*) FROM restaurant
WHERE TRIM(`id`) = '';
-- no NULLs

SELECT COUNT(*) AS total_rows, COUNT(DISTINCT `id`) AS id_count FROM restaurant;
-- yes, this is a unique column with no NULLs/inconsistencies
-- can be used as PRMARY KEY

ALTER TABLE restaurant
MODIFY `id` VARCHAR(255) PRIMARY KEY;

DESC restaurant;

-- name

-- name of the restaurant, may not be unique
SELECT * FROM restaurant
LIMIT 10;

SELECT COUNT(*) FROM restaurant
WHERE TRIM(`name`) = '';
-- 86 NULLs
-- let's verify those columns

SELECT * FROM restaurant
WHERE TRIM(`name`) = '';

-- let's convert them to NULL
UPDATE restaurant
SET `name` = NULL
WHERE TRIM(`name`) = '';

SELECT COUNT(*) FROM restaurant
WHERE TRIM(`name`) = ''; -- no more empty strings
-- no more changes required

DESC restaurant;

-- Country

SELECT DISTINCT Country FROM restaurant;
-- 1 distinct value - India

-- NULLs
SELECT COUNT(*)  FROM restaurant
WHERE TRIM(`Country`) = '';
-- no NULLs

ALTER TABLE restaurant
MODIFY Country CHAR(5) NOT NULL CHECK(Country = 'India');

DESC restaurant;

-- city

SELECT * FROM restaurant
LIMIT 10;

SELECT COUNT(*) FROM restaurant
WHERE TRIM(city) = '';
-- no NULLs

SELECT COUNT(*) FROM restaurant
WHERE city NOT REGEXP '^[a-zA-Z ]+|[a-zA-Z]+, [a-zA-Z]+$';
-- no anomalies

ALTER TABLE restaurant
MODIFY city VARCHAR(255) NOT NULL;

DESC restaurant;

-- rating
SELECT * FROM restaurant
LIMIT 10;

-- validation
SELECT COUNT(*) FROM restaurant
WHERE rating NOT REGEXP '^[0-9]{1}\\.[0-9]{1}$';
-- 94772 anomalies
-- let's verify them

SELECT COUNT(DISTINCT rating) FROM restaurant
WHERE rating NOT REGEXP '^[0-9]{1}\\.[0-9]{1}$';
-- 7 distinct values

SELECT DISTINCT rating FROM restaurant
WHERE rating NOT REGEXP '^[0-9]{1}\\.[0-9]{1}$';
-- we have placeholder '--' which should be replaced by NULL, empty string which should also be replaced by NULL and INT numbers which should be DECIMAL

-- NULLs
SELECT COUNT(*) FROM restaurant
WHERE TRIM(rating) = '' OR rating = '--'; -- 87,099 NULLs

UPDATE restaurant
SET rating = NULLIF(NULLIF(TRIM(rating), ''), '--');

SELECT COUNT(*) FROM restaurant
WHERE TRIM(rating) = '' OR rating = '--'; -- now 0

ALTER TABLE restaurant
MODIFY rating DECIMAL(4,2);

DESC restaurant;

-- rating_count

SELECT * FROM restaurant
LIMIT 10;

SELECT COUNT(*) FROM restaurant
WHERE TRIM(rating_count) = ''; -- 86 NULLs

SELECT DISTINCT rating_count FROM restaurant; -- 8 distinct types of rating counts with one of them as empty string, so no plaxeholders

UPDATE restaurant
SET rating_count = NULLIF(TRIM(rating_count), '');

SELECT COUNT(*) FROM restaurant
WHERE TRIM(rating_count) = ''; -- now 0

-- cuisine
SELECT * FROM restaurant
LIMIT 10;

SELECT COUNT(*) FROM restaurant
WHERE TRIM(cuisine) = '';
-- 99 NULLs

UPDATE restaurant
SET cuisine = NULLIF(TRIM(cuisine), '');

SELECT COUNT(DISTINCT cuisine) FROM restaurant; -- 2131 different cuisines


-- link

SELECT COUNT(*) FROM restaurant
WHERE TRIM(`link`) = '';
-- no NULLs

-- validation
SELECT COUNT(*) FROM restaurant
WHERE `link` NOT LIKE 'https://www.swiggy.com/%';
-- no anomalies
-- no change in dtype

ALTER TABLE restaurant
MODIFY `link` TEXT NOT NULL;

DESC restaurant;

-- address

SELECT COUNT(*) FROM restaurant
WHERE TRIM(`address`) = ''; -- 86 NULLs

UPDATE restaurant
SET `address` = NULLIF(TRIM(`address`), '');
-- no change in dtype

DESC restaurant;

-- users

SELECT * FROM users
LIMIT 10;

-- user_id
SELECT COUNT(DISTINCT user_id) AS user_id, COUNT(*) AS total_rows FROM users;
-- unique column, can be used as PRIMARY KEY

-- NULLs
SELECT COUNT(*) FROM users
WHERE TRIM(user_id) = '';
-- mo NULLs
-- since this column is going to be used as FK in other tables, I'm keeping it's dtype as it is VARCHAR

ALTER TABLE users
MODIFY user_id VARCHAR(100) PRIMARY KEY;

DESC users;

-- name

SELECT * FROM users
LIMIT 10;

SELECT COUNT(*) FROM users
WHERE TRIM(`name`) = '';
-- no NULLs
-- no change in dtype required

ALTER TABLE users
MODIFY `name` VARCHAR(255) NOT NULL;

-- age

SELECT COUNT(*) FROM users
WHERE TRIM(age) = '';
-- no NULLs

SELECT COUNT(*) FROM users
WHERE age NOT REGEXP '^[0-9]{2}$';
-- no anomalies

ALTER TABLE users
MODIFY age INT NOT NULL;

-- validation
SELECT MIN(age) FROM users; --18
SELECT MAX(age) FROM users; -- 33 
-- no anomalies

DESC users;

-- gender

SELECT COUNT(*) FROM users
WHERE TRIM(gender) = ''; -- 0 NULLs

SELECT DISTINCT gender FROM users; -- Male, Female

-- validation
SELECT COUNT(*) FROM users
WHERE gender NOT IN ('Male','Female'); -- no anomalies

-- Male - M, Female - F
UPDATE users
SET gender = 'F'
WHERE gender = 'Female';

UPDATE users
SET gender = 'M'
WHERE gender = 'Male';

SELECT * FROM users
LIMIT 10;

SELECT DISTINCT gender FROM users;

ALTER TABLE users
MODIFY gender CHAR(1) NOT NULL;

DESC users;

-- marital_status
SELECT * FROM users
LIMIT 10;

SELECT DISTINCT marital_status FROM users;-- Single, Married, Preder not to say
-- confirms no null values

-- validation
SELECT COUNT(*) FROM users
WHERE marital_status NOT IN ('Single', 'Married', 'Prefer not to say');
-- no anomalies

ALTER TABLE users
MODIFY marital_status VARCHAR(50) NOT NULL;

DESC users;


-- occupation
SELECT * FROM users
LIMIT 10;

SELECT DISTINCT occupation FROM users; -- Student, House wife, Employee, Self Employeed
-- confirms no NULL values, no anomalies

ALTER TABLE users
MODIFY occupation VARCHAR(50) NOT NULL;

DESC users;


-- VALIDATION ACROSS ALL TABLES

SELECT 'food'         AS table_name, COUNT(*) AS row_count FROM food
UNION ALL
SELECT 'menu',                       COUNT(*) FROM menu
UNION ALL
SELECT 'orders',                     COUNT(*) FROM orders
UNION ALL
SELECT 'orders_type',                COUNT(*) FROM orders_type
UNION ALL
SELECT 'restaurant',                 COUNT(*) FROM restaurant
UNION ALL
SELECT 'users',                      COUNT(*) FROM users;
-- expected: food 371552, menu 1047370, orders 150281,
--           orders_type 150281, restaurant 148540, users 100000


SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY, COLUMN_DEFAULT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'zomato'
ORDER BY TABLE_NAME, ORDINAL_POSITION;
-- eyeball this: PRI should appear once per table on the intended
-- primary key column; IS_NULLABLE should say 'NO' only on columns
-- you deliberately enforced NOT NULL on


SELECT TABLE_NAME, COLUMN_NAME AS primary_key_column
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'zomato'
  AND CONSTRAINT_NAME = 'PRIMARY'
ORDER BY TABLE_NAME;
-- expected: food.f_id, orders_type.Order_Id, restaurant.id, users.user_id
-- menu and orders have no single-column PK by design — that's fine,
-- menu has no natural unique row, orders has no id column in the source data


SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'zomato'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME;
-- expected 4 rows:
--   menu.f_id       -> food.f_id
--   menu.r_id       -> restaurant.id
--   orders.user_id  -> users.user_id
--   orders.r_id     -> restaurant.id


-- referential integrity
SELECT 'menu.f_id -> food.f_id'      AS check_name, COUNT(*) AS orphan_rows
FROM menu t1 LEFT JOIN food t2 ON t1.f_id = t2.f_id
WHERE t2.f_id IS NULL
UNION ALL
SELECT 'menu.r_id -> restaurant.id', COUNT(*)
FROM menu t1 LEFT JOIN restaurant t2 ON t1.r_id = t2.id
WHERE t2.id IS NULL
UNION ALL
SELECT 'orders.user_id -> users.user_id', COUNT(*)
FROM orders t1 LEFT JOIN users t2 ON t1.user_id = t2.user_id
WHERE t2.user_id IS NULL
UNION ALL
SELECT 'orders.r_id -> restaurant.id (non-null only)', COUNT(*)
FROM orders t1 LEFT JOIN restaurant t2 ON t1.r_id = t2.id
WHERE t1.r_id IS NOT NULL AND t2.id IS NULL;
-- expected: 0 for all four rows


-- NULL AUDIT

-- food: should show 0 everywhere, table has no NULLs
SELECT
    SUM(f_id IS NULL)          AS f_id_nulls,
    SUM(item IS NULL)          AS item_nulls,
    SUM(veg_or_non_veg IS NULL) AS veg_flag_nulls
FROM food;
 
-- menu: should show 0 everywhere
SELECT
    SUM(menu_id IS NULL) AS menu_id_nulls,
    SUM(r_id IS NULL)    AS r_id_nulls,
    SUM(f_id IS NULL)    AS f_id_nulls,
    SUM(cuisine IS NULL) AS cuisine_nulls,
    SUM(price IS NULL)   AS price_nulls        -- 59 expected (zero-price placeholders)
FROM menu;
 
-- orders: r_id and sales_amount are expected to have NULLs
SELECT
    SUM(order_date IS NULL)   AS order_date_nulls,   -- expect 0
    SUM(sales_qty IS NULL)    AS sales_qty_nulls,     -- expect 0
    SUM(sales_amount IS NULL) AS sales_amount_nulls,  -- expect 1611
    SUM(currency IS NULL)     AS currency_nulls,      -- expect 0
    SUM(user_id IS NULL)      AS user_id_nulls,       -- expect 0
    SUM(r_id IS NULL)         AS r_id_nulls           -- expect 1618
FROM orders;
 
-- orders_type: should show 0 everywhere
SELECT
    SUM(Order_Id IS NULL) AS order_id_nulls,
    SUM(`Type` IS NULL)   AS type_nulls
FROM orders_type;
 
-- restaurant: name/rating/rating_count/cuisine/address expected to have NULLs
SELECT
    SUM(`id` IS NULL)           AS id_nulls,          -- expect 0
    SUM(`name` IS NULL)         AS name_nulls,         -- expect 86
    SUM(Country IS NULL)        AS country_nulls,      -- expect 0
    SUM(city IS NULL)           AS city_nulls,         -- expect 0
    SUM(rating IS NULL)         AS rating_nulls,       -- expect 87099
    SUM(rating_count IS NULL)   AS rating_count_nulls, -- expect 86
    SUM(cuisine IS NULL)        AS cuisine_nulls,      -- expect 99
    SUM(`link` IS NULL)         AS link_nulls,         -- expect 0
    SUM(`address` IS NULL)      AS address_nulls       -- expect 86
FROM restaurant;
 
-- users: should show 0 everywhere
SELECT
    SUM(user_id IS NULL)        AS user_id_nulls,
    SUM(`name` IS NULL)         AS name_nulls,
    SUM(age IS NULL)            AS age_nulls,
    SUM(gender IS NULL)         AS gender_nulls,
    SUM(marital_status IS NULL) AS marital_status_nulls,
    SUM(occupation IS NULL)     AS occupation_nulls
FROM users;

-- NO DUPLICATES
SELECT 'food.f_id'        AS column_name, COUNT(*) - COUNT(DISTINCT f_id) AS duplicate_count FROM food
UNION ALL
SELECT 'restaurant.id',                   COUNT(*) - COUNT(DISTINCT `id`) FROM restaurant
UNION ALL
SELECT 'users.user_id',                   COUNT(*) - COUNT(DISTINCT user_id) FROM users
UNION ALL
SELECT 'orders_type.Order_Id',            COUNT(*) - COUNT(DISTINCT Order_Id) FROM orders_type;
-- expected: 0 for all four

-- DOMAIN CHECKS

-- restaurant.rating should be between 0 and 5, or NULL
SELECT COUNT(*) AS rating_out_of_range
FROM restaurant
WHERE rating IS NOT NULL AND (rating < 0 OR rating > 5);
-- expected: 0
 
-- restaurant.Country should only ever be 'India'
SELECT DISTINCT Country FROM restaurant;
-- expected: single row, 'India'
 
-- users.age should be a plausible adult age
SELECT MIN(age) AS min_age, MAX(age) AS max_age FROM users;
-- expected: 18 to 33 (per source data)
 
-- users.gender should only be 'M' or 'F'
SELECT DISTINCT gender FROM users;
-- expected: M, F
 
-- orders_type.Type should only be one of three values
SELECT DISTINCT `Type` FROM orders_type;
-- expected: Veg, Non-Veg, Other
 
-- menu.price should be positive or NULL, never 0 or negative
SELECT COUNT(*) AS bad_price_count
FROM menu
WHERE price IS NOT NULL AND price <= 0;
-- expected: 0
 
-- orders.sales_amount should be positive or NULL, never 0 or negative
SELECT COUNT(*) AS bad_sales_amount_count
FROM orders
WHERE sales_amount IS NOT NULL AND sales_amount <= 0;
-- expected: 0
 
-- orders.sales_qty should always be positive
SELECT COUNT(*) AS bad_sales_qty_count
FROM orders
WHERE sales_qty <= 0;
-- expected: 0

-- OUR TABLES ARE NOW READY FOR ANALYSIS