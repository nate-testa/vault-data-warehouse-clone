IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
           WHERE 
			CONSTRAINT_NAME = 'fk_tquote_grpel_master_coverage_enrollment_qt_cov_sk' AND TABLE_NAME = 'tquote_grpel_master_coverage_enrollment'
			AND TABLE_SCHEMA = 'edw_core'
		)
BEGIN    
    ALTER TABLE edw_core.tquote_grpel_master_coverage_enrollment DROP CONSTRAINT fk_tquote_grpel_master_coverage_enrollment_qt_cov_sk
    END;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_core'					
      AND TABLE_NAME = 'tquote_grpel_master_coverage_enrollment'					
      AND COLUMN_NAME = 'grpel_master_coverage_sk'					
) 
BEGIN 
ALTER TABLE edw_core.tquote_grpel_master_coverage_enrollment DROP COLUMN quote_grpel_master_coverage_sk   END ;