IF NOT EXISTS (
    SELECT  1
    FROM    INFORMATION_SCHEMA.COLUMNS
    WHERE   TABLE_SCHEMA='edw_integration'
    AND     TABLE_NAME = 'claim_workday_payment_feed'
    AND     COLUMN_NAME = 'party_subtype_role_nm'
) BEGIN 
ALTER TABLE edw_integration.claim_workday_payment_feed ADD party_subtype_role_nm varchar(255);
END; 