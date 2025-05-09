IF NOT EXISTS 
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'BrokerageServicingTeamMember')
BEGIN
CREATE TABLE edw_stage.BrokerageServicingTeamMember (
	Id int NULL,
	BrokerageServicingTeamId uniqueidentifier NULL,
	UserId nvarchar(MAX) NULL,
	ExternalSourceId nvarchar(2000) NULL,
	ExternalSourceUniqueId nvarchar(2000) NULL,
	CreatedDate datetime2 NULL,
	UpdatedDate datetime2 NULL
)
END ; 