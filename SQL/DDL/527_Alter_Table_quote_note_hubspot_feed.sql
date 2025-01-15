IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'quote_hubspot_feed'
    AND     COLUMN_NAME = 'occupancy_type'
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD occupancy_type varchar(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'quote_hubspot_feed'
    AND     COLUMN_NAME = ' new_client_for_agency_in'
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD  new_client_for_agency_in varchar(255) END; 

IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'quote_hubspot_feed'
    AND     COLUMN_NAME = 'current_underlying_company_nm'
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD current_underlying_company_nm varchar(255) END; 
