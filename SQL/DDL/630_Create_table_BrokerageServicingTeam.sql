IF NOT EXISTS 
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'BrokerageServicingTeam')
BEGIN
CREATE TABLE edw_stage.BrokerageServicingTeam (
	Id uniqueidentifier NOT NULL,
	Name nvarchar(200) NULL,
	ExternalSourceId nvarchar(2000) NULL,
	CreatedDate datetime2 NOT NULL,
	UpdatedDate datetime2 NOT NULL,
	CONSTRAINT PK_BrokerageServicingTeam PRIMARY KEY (Id)
) 
END ; 