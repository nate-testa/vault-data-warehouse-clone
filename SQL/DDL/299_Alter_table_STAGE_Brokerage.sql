IF NOT EXISTS (SELECT *
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE lower(TABLE_NAME) = 'Brokerage'
        AND LOWER(COLUMN_NAME) = 'IsNationalAgency')
BEGIN
    ALTER TABLE edw_stage.Brokerage ADD IsNationalAgency bit NULL;
END