IF NOT EXISTS (					
SELECT 1					
FROM INFORMATION_SCHEMA.COLUMNS					
WHERE TABLE_SCHEMA='edw_core'					
AND TABLE_NAME = 'tbroker_servicing_team'					
AND COLUMN_NAME = 'broker_servicing_team_id'					
) 
BEGIN 
ALTER TABLE edw_core.tbroker_servicing_team ADD broker_servicing_team_id varchar(255) NOT NULL, 
CONSTRAINT uidx_broker_servicing_team_id UNIQUE (broker_servicing_team_id)
END ; 