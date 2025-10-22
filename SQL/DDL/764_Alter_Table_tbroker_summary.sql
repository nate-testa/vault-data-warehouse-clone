IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_claim_ct')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_claim_ct int NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_loss_incurred_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_loss_incurred_amt decimal(15, 2) NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_loss_incurred_capped_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_loss_incurred_capped_amt decimal(15, 2) NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_mtd_claim_ct')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_claim_ct int NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_mtd_loss_incurred_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_loss_incurred_amt decimal(15, 2) NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_mtd_loss_incurred_capped_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_loss_incurred_capped_amt decimal(15, 2) NULL;
END; 

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_mtd_earned_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_earned_premium_amt decimal(15, 4)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_mtd_earned_net_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_mtd_earned_net_premium_amt decimal(15, 4)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_year_earned_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_year_earned_premium_amt decimal(15, 4)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'prior_year_earned_net_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD prior_year_earned_net_premium_amt decimal(15, 4)  NULL;
END;