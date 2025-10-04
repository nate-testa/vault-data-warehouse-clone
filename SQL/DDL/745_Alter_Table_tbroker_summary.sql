IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'non_flat_cancelled_ct')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD non_flat_cancelled_ct int NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'expiring_sixty_day_written_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD expiring_sixty_day_written_premium_amt decimal(15, 2)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_earned_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_earned_premium_amt decimal(15, 4)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_earned_net_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_earned_net_premium_amt decimal(15, 4)  NULL;
END;

IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'mtd_written_net_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD mtd_written_net_premium_amt decimal(15, 2)  NULL;
END; 