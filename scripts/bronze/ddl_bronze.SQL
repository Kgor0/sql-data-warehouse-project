CREATE TABLE bronze.crm_cust_info (
	cst_id INT,
	cst_key VARCHAR(50),
	cst_firstname VARCHAR(50),
	cst_lastname VARCHAR(50),
	cst_marital_status VARCHAR(50),
	cst_gndr VARCHAR(50),
	cst_create_date DATE
);

CREATE TABLE bronze.crm_prd_info (
    prd_id INT,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(50),
    prd_cost NUMERIC(10,2),
    prd_line VARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE
);

DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num VARCHAR(50),
    sls_prd_key VARCHAR(50),
    sls_cust_id VARCHAR(50),
    sls_order_dt VARCHAR(50),
    sls_ship_dt VARCHAR(50),
    sls_due_dt VARCHAR(50),
    sls_sales VARCHAR(50),
    sls_quantity VARCHAR(50),
    sls_price VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid VARCHAR(50),
    bdate VARCHAR(50),
    gen VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
	CID VARCHAR(50),
	CNTRY VARCHAR(50)
);

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
	ID VARCHAR(50),
	CAT VARCHAR(50),
	SUBCAT VARCHAR(50),
	MAINTENANCE VARCHAR(50)
);

SELECT * FROM bronze.crm_cust_info;

SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'bronze';

CREATE OR REPLACE PROCEDURE bronze.load_crm_cust_info()
LANGUAGE plpgsql
AS $$
BEGIN
    TRUNCATE TABLE bronze.crm_cust_info;

    copy bronze.crm_cust_info
    FROM 'C:/Data/crm_cust_info.csv'
    DELIMITER ','
    CSV HEADER;
END;
$$;
