IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'no_of_private_staff'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD no_of_private_staff VARCHAR(255) NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'uninsured_underinsured_liability_limit_amt'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD uninsured_underinsured_liability_limit_amt VARCHAR(255) NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'reputational_injury_coverage_limit_amt'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD reputational_injury_coverage_limit_amt VARCHAR(255) NULL
END ; 


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'no_of_high_performance_vehicles'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD no_of_high_performance_vehicles VARCHAR(255) NULL
END ; 


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'no_of_recreational_vehicles'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD no_of_recreational_vehicles VARCHAR(255) NULL
END ; 


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'no_of_boats_yachts'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD no_of_boats_yachts VARCHAR(255) NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'no_of_personal_watercraft'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD no_of_personal_watercraft VARCHAR(255) NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'auto_underlying_limit_amt'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD auto_underlying_limit_amt VARCHAR(255) NULL
END ; 

IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'home_underlying_limit_amt'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD home_underlying_limit_amt VARCHAR(255) NULL
END ; 


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'watercraft_underlying_limit_amt'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD watercraft_underlying_limit_amt VARCHAR(255) NULL
END ; 



IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'auto_insurance_company'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD auto_insurance_company VARCHAR(255) NULL
END ; 


IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'home_insurance_company'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD home_insurance_company VARCHAR(255) NULL
END ; 



IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tgrpel_coverage'					
AND COLUMN_NAME = 'watercraft_insurance_company'					
) 
BEGIN 
    ALTER TABLE edw_core.tgrpel_coverage ADD watercraft_insurance_company VARCHAR(255) NULL
END ; 