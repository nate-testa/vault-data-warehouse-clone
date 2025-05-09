IF NOT EXISTS 
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'BrokerageServicingTeam')
BEGIN
CREATE TABLE edw_stage.BrokerageServicingTeam (
	Id uniqueidentifier NULL,
	Name nvarchar(200) NULL,
	ExternalSourceId nvarchar(2000) NULL,
	CreatedDate datetime2(7) NULL,
	UpdatedDate datetime2(7) NULL
) 
END ; 