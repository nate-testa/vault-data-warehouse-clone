IF NOT EXISTS 
(SELECT 1 FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'edw_stage'
AND TABLE_name = 'BrokerageServicingTeamMember')
BEGIN
CREATE TABLE edw_stage.BrokerageServicingTeamMember (
	Id int IDENTITY(1,1) NOT NULL,
	BrokerageServicingTeamId uniqueidentifier NOT NULL,
	UserId nvarchar(MAX) NULL,
	ExternalSourceId nvarchar(2000) NULL,
	ExternalSourceUniqueId nvarchar(2000) NULL,
	CreatedDate datetime2 NOT NULL,
	UpdatedDate datetime2 NULL,
	CONSTRAINT PK_BrokerageServicingTeamMember PRIMARY KEY (Id),
	CONSTRAINT FK_BrokerageServicingTeamMember_BrokerageServicingTeam_BrokerageServicingTeamId FOREIGN KEY (BrokerageServicingTeamId) REFERENCES edw_stage.BrokerageServicingTeam(Id) ON DELETE CASCADE
)
END ; 