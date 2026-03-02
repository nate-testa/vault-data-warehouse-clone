IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_notes_data_feed'					
      AND COLUMN_NAME = 'datafixindicator_yn'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_notes_data_feed ADD datafixindicator_yn varchar(255) null END ;

IF NOT EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_notes_data_feed'					
      AND COLUMN_NAME = 'datafix_date'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_notes_data_feed ADD datafix_date varchar(255) null END ;
