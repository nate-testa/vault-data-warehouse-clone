IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_issued_ct')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_issued_ct int NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_issued_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_issued_premium_amt decimal(15,2) NULL;
END;   

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'accepted_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD accepted_premium_amt decimal(15,2) NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'ytd_prior_issued_ct')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD ytd_prior_issued_ct int NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'ytd_prior_issued_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD ytd_prior_issued_premium_amt decimal(15,2) NULL;
END;   

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'ytd_accepted_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD ytd_accepted_premium_amt decimal(15,2) NULL;
END;  