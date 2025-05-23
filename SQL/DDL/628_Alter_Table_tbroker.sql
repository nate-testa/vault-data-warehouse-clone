IF NOT EXISTS (                
SELECT 1                    
FROM INFORMATION_SCHEMA.COLUMNS                
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tbroker'                  
AND COLUMN_NAME = 'broker_servicing_team_sk'                    
)
BEGIN
ALTER TABLE edw_core.tbroker ADD broker_servicing_team_sk int
END;

IF NOT EXISTS ( 
SELECT *
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA='edw_core'                
AND TABLE_NAME = 'tbroker' 
  AND CONSTRAINT_NAME = 'fk_tbroker_broker_servicing_team_sk'
)
BEGIN
ALTER TABLE edw_core.tbroker ADD CONSTRAINT fk_tbroker_broker_servicing_team_sk FOREIGN KEY (broker_servicing_team_sk) REFERENCES edw_core.tbroker_servicing_team(broker_servicing_team_sk)
END;