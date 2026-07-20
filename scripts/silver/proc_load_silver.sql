/* Stored Procedure: Load silver layer (bronze -> silver)

Script Purpose:
  This stored prodecure perfroms the ETL (Extract, Transform, Load) process to 
  populate the 'silver' schema tables from the 'bronze' schema.

Acrions Performed:
  - Truncates Silver tables.
  - Inserts transformed and cleaned data from bronze into silver tables.

Parameters:
  None.
 This stored procedure does not accept any parameters or return any values.

*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
BEGIN

	TRUNCATE silver.crm_cust_info;
	INSERT INTO silver.crm_cust_info (
		customer_id,
		customer_key,
		first_name,
		last_name,
		marital_status,
		gender,
		create_date
	)
	SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_firstname, 
		TRIM(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
			 WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
			 ELSE 'n/a'
		END cst_marital_status,
		CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
			 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
	FROM (
		SELECT
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
		FROM bronze.crm_cust_info
		WHERE cst_id IS NOT NULL
	)t WHERE flag_last = 1;
	
	SELECT * FROM silver.crm_cust_info;
	
	/* PRODUCTS */
	TRUNCATE silver.crm_prd_info;
	INSERT INTO silver.crm_prd_info
	(
	    product_id,
	    category_id,
	    product_key,
	    product_name,
	    product_cost,
	    product_line,
	    start_date,
	    end_date
	)
	SELECT 
	    CAST(prd_id AS INT) AS product_id,
		REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS category_id,
	    SUBSTRING(prd_key, 7, LENGTH(prd_key)) AS product_key,
	    prd_nm AS product_name,
	    COALESCE(prd_cost, 0) AS product_cost,
	    CASE 
	        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
	        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
	        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
	        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
	        ELSE 'n/a'
	    END AS product_line,
	    CAST(prd_start_dt AS DATE) AS start_date,
	    (
	       LEAD(CAST(prd_start_dt AS DATE))
	        OVER (
	            PARTITION BY prd_key
	            ORDER BY CAST(prd_start_dt AS DATE)
	        ) - INTERVAL '1 day'
	    )::DATE AS end_date 
	FROM bronze.crm_prd_info;
	
	SELECT * FROM silver.crm_prd_info;
	
	/* ORDERS */
	TRUNCATE silver.crm_sales_details;
	INSERT INTO silver.crm_sales_details(
		order_number,
	    product_key,
	    customer_id,
	    order_date,
	    ship_date,
	    due_date,
	    sales_amount,
	    quantity,
	    price
	)
	SELECT 
		sls_ord_num AS order_number,
		sls_prd_key AS product_key,
		sls_cust_id::INT AS customer_id,
		
		CASE WHEN sls_order_dt = '0' OR LENGTH(sls_order_dt) != 8 
			 THEN NULL
			 ELSE TO_DATE(sls_order_dt, 'YYYYMMDD')
		END AS order_date,
		
		CASE WHEN sls_ship_dt = '0' OR LENGTH(sls_ship_dt) != 8 
			 THEN NULL
			 ELSE TO_DATE(sls_ship_dt, 'YYYYMMDD')
		END AS ship_date,
		
		CASE WHEN sls_due_dt = '0' OR LENGTH(sls_due_dt) != 8 
			 THEN NULL
			 ELSE TO_DATE(sls_due_dt, 'YYYYMMDD')
		END AS due_date,
		
		    CASE 
	        WHEN sls_sales IS NULL
	             OR sls_sales::NUMERIC <= 0
	             OR sls_sales::NUMERIC != sls_quantity::NUMERIC * ABS(sls_price::NUMERIC)
	        THEN sls_quantity::NUMERIC * ABS(sls_price::NUMERIC)
	        ELSE sls_sales::NUMERIC
	    END AS sales_amount,
	
		sls_quantity::INT AS quantity,
	
	    CASE 
	        WHEN sls_price IS NULL
	             OR sls_price::NUMERIC <= 0
	        THEN sls_sales::NUMERIC / NULLIF(sls_quantity::NUMERIC, 0)
	        ELSE sls_price::NUMERIC
	    END AS price
	FROM bronze.crm_sales_details;
	
	/* CUSTOMERS */
	TRUNCATE silver.erp_cust_az12;
	INSERT INTO silver.erp_cust_az12(
		customer_id,
	    birth_date,
	    gender
	)
	SELECT
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid))
		 ELSE cid
	END AS customer_id,
	CASE WHEN TO_DATE(TRIM(bdate), 'YYYY-MM-DD') > CURRENT_DATE
	      THEN NULL
	      ELSE TO_DATE(TRIM(bdate), 'YYYY-MM-DD')
	END AS birth_date,
	CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		 ELSE 'n/a'
	END AS gender
	FROM bronze.erp_cust_az12;
	
	/* LOCATION */
	TRUNCATE silver.erp_loc_a101;
	INSERT INTO silver.erp_loc_a101(
		customer_id,
	    country 
	)
	SELECT 
	REPLACE(cid, '-', '')::VARCHAR AS customer_id,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END::VARCHAR AS country
	FROM bronze.erp_loc_a101;
	
	/* CATEGORIES */
	TRUNCATE silver.erp_px_cat_g1v2;
	INSERT INTO silver.erp_px_cat_g1v2(
		id,
		category,
		subcategory,
		maintenance
	)
	SELECT
		id::VARCHAR,
		cat AS category,
		subcat AS subcategory,
		maintenance
	FROM bronze.erp_px_cat_g1v2;
END;
$$;
