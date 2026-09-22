-- Active: 1790015617336@@127.0.0.1@3306@mysql

-- creating database for our project
DROP DATABASE IF EXISTS swiggy;
CREATE DATABASE swiggy;
USE swiggy;

DROP TABLE IF EXISTS food;
DROP TABLE IF EXISTS menu;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS orders_type;
DROP TABLE IF EXISTS restaurant;
DROP TABLE IF EXISTS users;

SHOW TABLES;


-- creating tables to store our data
CREATE TABLE food(
    f_id VARCHAR(255),
    item VARCHAR(255),
    veg_or_non_veg VARCHAR(255)
);

CREATE TABLE menu(
    menu_id VARCHAR(255),
    r_id VARCHAR(255),
    f_id VARCHAR(255),
    cuisine VARCHAR(255),
    price VARCHAR(255)
);

CREATE TABLE orders_type(
    Order_Id VARCHAR(255),
    `Type` VARCHAR(255)
);

CREATE TABLE orders(
    order_date VARCHAR(255),
    sales_qty VARCHAR(255),
    sales_amount VARCHAR(255),
    currency VARCHAR(255),
    user_id VARCHAR(255),
    r_id VARCHAR(255)
);

CREATE TABLE restaurant(
    `id` VARCHAR(255),
    `name` VARCHAR(255),
    Country VARCHAR(255),
    city VARCHAR(255),
    rating VARCHAR(255),
    rating_count VARCHAR(255),
    cuisine VARCHAR(255),
    `link` TEXT,
    `address` TEXT 
);

CREATE TABLE users(
    user_id VARCHAR(255),
    `name` VARCHAR(255),
    age VARCHAR(255),
    gender VARCHAR(255),
    marital_status VARCHAR(255),
    occupation VARCHAR(255)
);


-- loading data into tables

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/food.csv'
INTO TABLE food
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 371560 rows loaded

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/menu.csv'
INTO TABLE menu
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 1048575 rows loaded

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/orders_type.csv'
INTO TABLE orders_type
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 150281 rows loaded

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/orders.csv'
INTO TABLE orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 150281

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/restaurant.csv'
INTO TABLE restaurant
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 148540 rows loaded

LOAD DATA LOCAL INFILE 'C:/Users/hp/Desktop/zomato/datasets_csv/users.csv'
INTO TABLE users
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY ''
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS; -- 100000 rows loaded

-- data loaded into all tables.