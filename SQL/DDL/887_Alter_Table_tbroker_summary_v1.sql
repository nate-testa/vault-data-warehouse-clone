IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'prior_issued_ct')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD prior_issued_ct int NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'prior_issued_premium_amt')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD prior_issued_premium_amt decimal(15,2) NULL;
END;   

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'accepted_premium_amt')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD accepted_premium_amt decimal(15,2) NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'ytd_prior_issued_ct')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD ytd_prior_issued_ct int NULL;
END;  

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'ytd_prior_issued_premium_amt')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD ytd_prior_issued_premium_amt decimal(15,2) NULL;
END;   

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary_v1'
        AND LOWER(COLUMN_NAME) = 'ytd_accepted_premium_amt')
BEGIN
    ALTER TABLE edw_stage.tbroker_summary_v1 ADD ytd_accepted_premium_amt decimal(15,2) NULL;
END;  