IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_transaction_data_feed'					
      AND COLUMN_NAME = 'user_remarks'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_transaction_data_feed ALTER COLUMN user_remarks nvarchar(max) null END ;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_transaction_data_feed'					
      AND COLUMN_NAME = 'system_remarks'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_transaction_data_feed ALTER COLUMN system_remarks nvarchar(max) null END ;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_transaction_data_feed'					
      AND COLUMN_NAME = 'cancellation_reason'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_transaction_data_feed ALTER COLUMN cancellation_reason nvarchar(max) null END ;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_transaction_data_feed'					
      AND COLUMN_NAME = 'writeoff_reason'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_transaction_data_feed ALTER COLUMN writeoff_reason nvarchar(max) null END ;

