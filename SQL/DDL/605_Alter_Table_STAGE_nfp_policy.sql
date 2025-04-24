IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'nfp_policy'					
AND COLUMN_NAME = 'fronting_fee_total'					
) BEGIN ALTER TABLE edw_stage.nfp_policy ADD fronting_fee_total decimal(18,2) END
;

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_stage'					
AND TABLE_NAME = 'nfp_policy'					
AND COLUMN_NAME = 'underwriting_year_percentage'					
) BEGIN ALTER TABLE edw_stage.nfp_policy ADD underwriting_year_percentage varchar(255) END
;