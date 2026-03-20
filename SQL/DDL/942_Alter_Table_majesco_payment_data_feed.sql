IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'user_remark'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ALTER COLUMN user_remark nvarchar(max) null END ;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'system_remark'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ALTER COLUMN system_remark nvarchar(max) null END ;


