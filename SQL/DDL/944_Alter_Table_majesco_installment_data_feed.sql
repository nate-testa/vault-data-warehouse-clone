IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_installment_data_feed'					
      AND COLUMN_NAME = 'user_remarks'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_installment_data_feed ALTER COLUMN user_remarks nvarchar(max) null END ;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_installment_data_feed'					
      AND COLUMN_NAME = 'system_remarks'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_installment_data_feed ALTER COLUMN system_remarks nvarchar(max) null END ;



