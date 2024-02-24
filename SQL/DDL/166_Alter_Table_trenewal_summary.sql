IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'trenewal_summary'
    AND COLUMN_NAME = 'renewal_tiv_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_tiv_amt decimal (15,2) null END;


IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'trenewal_summary'
    AND COLUMN_NAME = 'renewal_cova_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_cova_amt decimal (15,2) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'trenewal_summary'
    AND COLUMN_NAME = 'renewal_total_finished_square_feet'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_total_finished_square_feet decimal (15,2) null END;