IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'receivable_code'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ADD receivable_code varchar(255) END ;

IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'payment_category'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ADD payment_category varchar(255) END ;
