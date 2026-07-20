/* REMOVING DUPLICATES */
SELECT 
*
FROM (
SELECT
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
)t WHERE flag_last = 1;

SELECT * FROM bronze.crm_cust_info;

/* CHECK FOR UNWANTED SPACES */
/* TRIM() REMOVES LEADING AND TRAILING SPACES FROM A STRING */
/* EXPECTATION: NO RESULTS */
SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

SELECT cst_lastname
FROM bronze.crm_cust_info
WHERE cst_lastname != TRIM(cst_lastname);

/* CHECK FOR NULLS OR DUPLICATES IN PRIMARY KEY */
/* EXPECTATION: NO RESULT */

SELECT 
	cst_id,	
	COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

SELECT cst_key
FROM bronze.crm_cust_info
WHERE cst_key != TRIM(cst_key)

/* DATA STANDARDIZATION & CONSISTENCY */
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

SELECT DISTINCT cst_marital_status
FROM bronze.crm_cust_info;

/* PRODUCTS */
SELECT 
	prd_id,
	COUNT(*)
FROM bronze.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

/* CHECK FOR UNWANTED SPACES */
/* EXPECTATION: NO RESULTS */
SELECT prd_nm
FROM bronze.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);

/* CHECK FOR NULLS OR NEGATIVE NUMBERS */
/* EXPECTATION: NO RESULTS */
SELECT prd_cost
FROM bronze.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

/* DATA STANDARDIZATION & CONSISTENCY */
SELECT DISTINCT prd_line
FROM bronze.crm_prd_info;

/* CHECK FOR INVALID DATE ORDERS */
SELECT *
FROM bronze.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

/* ORDERS */

/* CHECK FOR INVALID DATES */
SELECT
	NULLIF(sls_order_dt, '0') AS sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= '0' OR LENGTH(sls_order_dt) != 8;

/* CHECK FOR INVALID DATE ORDERS */
SELECT 
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt;

/* CHECK DATA CONSISTENCY: BETWEEN SALES, QUANTITY, AND PRICE
   SALES = QUANTITY * PRICE
   VALUES MUST NOT BE NULL, ZERO, OR NEGATIVE */

SELECT DISTINCT
	sls_sales,
	sls_quantity,
	sls_price
FROM bronze.crm_sales_details
WHERE sls_sales::NUMERIC != sls_quantity::NUMERIC * sls_price::NUMERIC
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= '0' OR sls_quantity <= '0' OR sls_price <= '0'
ORDER BY sls_sales, sls_quantity, sls_price


/* CASE WHEN */	
	CASE WHEN sls_order_dt = '0' OR LENGTH(sls_order_dt) != 8 
		 THEN NULL
		 ELSE TO_DATE(sls_order_dt, 'YYYYMMDD')
	END AS order_date, /* change int to date */
	
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

	sls_quantity AS quantity,

    CASE 
        WHEN sls_price IS NULL
             OR sls_price::NUMERIC <= 0
        THEN sls_sales::NUMERIC / NULLIF(sls_quantity::NUMERIC, 0)
        ELSE sls_price::NUMERIC
    END AS price;

/* CUSTOMERS */

/* IDENTIFY OUT-OF-RANGE DATES */
SELECT DISTINCT
    bdate
FROM bronze.erp_cust_az12
WHERE
    TO_DATE(TRIM(bdate), 'YYYY-MM-DD') < DATE '1924-01-01'
    OR TO_DATE(TRIM(bdate), 'YYYY-MM-DD') > CURRENT_DATE;


SELECT DISTINCT bdate
FROM bronze.erp_cust_az12;

/* DATA STANDARDIZATION & CONSISTNECY */
SELECT DISTINCT gen
FROM bronze.erp_cust_az12;

SELECT DISTINCT
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'Female') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'Male') THEN 'Male'
	 ELSE 'n/a'
END AS gender
FROM bronze.erp_cust_az12;

/* LOCATION */
SELECT 
REPLACE(cid, '-', '')::VARCHAR AS customer_id,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
	 ELSE TRIM(cntry)
END::VARCHAR AS country
FROM bronze.erp_loc_a101;

/* DATA STANDARDIZATION & CONSISTNECY */
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101
ORDER BY cntry;

/* CATEGORIES */

/* CHECK FOR UNWANTED SPACES */
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

/* DATA STANDARDIZATION & CONSISTENCY */
SELECT DISTINCT
	cat,
	subcat,
	maintenance
FROM bronze.erp_px_cat_g1v2;
