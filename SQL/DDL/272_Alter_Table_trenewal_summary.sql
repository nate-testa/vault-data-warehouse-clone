IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_written_premium_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_written_premium_amt decimal (15,2) null END;

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_tiv_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_tiv_amt int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_dwelling_limit_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_dwelling_limit_amt int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_other_structures_limit_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_other_structures_limit_amt int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_contents_limit_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_contents_limit_amt int null END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_core'
    AND     TABLE_NAME = 'trenewal_summary'
    AND     COLUMN_NAME = 'renewal_quote_loss_of_use_limit_amt'
) BEGIN ALTER TABLE edw_core.trenewal_summary ADD renewal_quote_loss_of_use_limit_amt varchar(255) null END;   