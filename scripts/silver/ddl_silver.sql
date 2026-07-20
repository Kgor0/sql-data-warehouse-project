/* DDL Script: CREATE SILVER TABLES 

Script Purpose:
 This script creates tables in the 'silva' schema, dropping exisitng tables if they already exist.
  Run this script to re-define the DDL structure of 'bronze' tables. */

CREATE SCHEMA IF NOT EXISTS silver;

CREATE TABLE silver.crm_cust_info (
    customer_id INT,
    customer_key VARCHAR(50),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    marital_status VARCHAR(20),
    gender VARCHAR(20),
    create_date DATE
);

DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    product_id INT,
	category_id VARCHAR(50),
    product_key VARCHAR(50),
    product_name VARCHAR(100),
    product_cost NUMERIC(10,2),
    product_line VARCHAR(50),
    start_date DATE,
    end_date DATE
);

CREATE TABLE silver.crm_sales_details (
    order_number VARCHAR(50),
    product_key VARCHAR(50),
    customer_id INT,
    order_date DATE,
    ship_date DATE,
    due_date DATE,
    sales_amount NUMERIC(10,2),
    quantity INT,
    price NUMERIC(10,2)
);

DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    customer_id VARCHAR(20),
    birth_date DATE,
    gender VARCHAR(20)
);

DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    customer_id VARCHAR(20),
    country VARCHAR(50)
);

DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id VARCHAR(20),
    category VARCHAR(50),
    subcategory VARCHAR(100),
    maintenance VARCHAR(20)
);
