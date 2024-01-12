IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'tbroker_summary'
        AND LOWER(COLUMN_NAME) = 'one_year_written_premium_amt')
BEGIN
    ALTER TABLE edw_core.tbroker_summary ADD one_year_written_premium_amt decimal(15, 2)  NULL;
	ALTER TABLE edw_core.tbroker_summary ADD three_year_written_premium_amt decimal(15, 2)  NULL; 
END