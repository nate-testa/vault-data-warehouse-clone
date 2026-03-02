IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'payment_seq'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ADD payment_seq varchar(255) END ;

IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_payment_data_feed'					
      AND COLUMN_NAME = 'payment_identifier'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_payment_data_feed ADD payment_identifier varchar(255) END ;
