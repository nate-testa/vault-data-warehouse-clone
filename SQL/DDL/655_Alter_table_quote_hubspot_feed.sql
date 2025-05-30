IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'insured_nm'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD insured_nm varchar(255) END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'retroactive_dt_desc'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD retroactive_dt_desc varchar(255) END			 
;  
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'prior_or_pending_dt_desc'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD prior_or_pending_dt_desc varchar(255) END			 
;  
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'primary_carrier_nm'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD primary_carrier_nm varchar(255) END			 
;  
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'per_claim_retention_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD per_claim_retention_amt int END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'aggregate_retention_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD aggregate_retention_amt int END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'threafter_retention'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD threafter_retention int END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'vault_premium_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD vault_premium_amt decimal(15,2) END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'vault_commission_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD vault_commission_amt decimal(15,2) END		 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'total_layer_premium_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD total_layer_premium_amt decimal(15,2) END			 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'vault_per_claim_policy_limit_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD vault_per_claim_policy_limit_amt int END				 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'vault_aggregate_policy_limit_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD vault_aggregate_policy_limit_amt int END				 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'total_layer_per_claim_policy_limit_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD total_layer_per_claim_policy_limit_amt int END				 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'total_layer_aggregate_policy_limit_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD total_layer_aggregate_policy_limit_amt int END				 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'total_aggregate_attachment_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD total_aggregate_attachment_amt int END				 
; 
IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_integration'					
AND TABLE_NAME = 'quote_hubspot_feed'					
AND COLUMN_NAME = 'total_per_claim_attachment_amt'		
) BEGIN ALTER TABLE edw_integration.quote_hubspot_feed ADD total_per_claim_attachment_amt int END			 
; 