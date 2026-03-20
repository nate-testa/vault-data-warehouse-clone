IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
           WHERE 
			CONSTRAINT_NAME = 'fk_tgrpel_master_coverage_enrollment_coverage_sk' AND TABLE_NAME = 'tgrpel_master_coverage_enrollment'
			AND TABLE_SCHEMA = 'edw_core'
		)
BEGIN    
    ALTER TABLE edw_core.tgrpel_master_coverage_enrollment DROP CONSTRAINT fk_tgrpel_master_coverage_enrollment_coverage_sk
    END;

IF EXISTS (					
    SELECT 1					
    FROM INFORMATION_SCHEMA.COLUMNS					
    WHERE TABLE_SCHEMA='edw_core'					
      AND TABLE_NAME = 'tgrpel_master_coverage_enrollment'					
      AND COLUMN_NAME = 'grpel_master_coverage_sk'					
) 
BEGIN 
ALTER TABLE edw_core.tgrpel_master_coverage_enrollment DROP COLUMN grpel_master_coverage_sk   END ;