IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote'					
AND COLUMN_NAME = 'first_offered_commercial_quote_history_sk'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_quote ADD first_offered_commercial_quote_history_sk int NULL END
; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_commercial'					
AND TABLE_NAME = 'tcommercial_quote'					
AND COLUMN_NAME = 'first_offered_commercial_quote_ts'					
) BEGIN ALTER TABLE edw_commercial.tcommercial_quote ADD first_offered_commercial_quote_ts datetime2(7) NULL END
; 
