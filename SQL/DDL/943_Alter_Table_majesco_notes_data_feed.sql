IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_stage'					
      AND TABLE_NAME = 'stage_majesco_notes_data_feed'					
      AND COLUMN_NAME = 'remarks'					
) 
BEGIN 
ALTER TABLE edw_stage.stage_majesco_notes_data_feed ALTER COLUMN remarks nvarchar(max) null END ;
