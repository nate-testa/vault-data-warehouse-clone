IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tquote_auto_policy_coverage'
    AND COLUMN_NAME = 'ncrb_ppa_coll_total'
) BEGIN ALTER TABLE edw_core.tquote_auto_policy_coverage ADD ncrb_ppa_coll_total varchar(255) null END;

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE 
    TABLE_SCHEMA='edw_core'
    AND TABLE_NAME = 'tquote_auto_policy_coverage'
    AND COLUMN_NAME = 'ncrb_ppa_otc_total'
) BEGIN ALTER TABLE edw_core.tquote_auto_policy_coverage ADD ncrb_ppa_otc_total varchar(255) null END;