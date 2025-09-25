
CREATE TABLE edw_stage.[AccountPremiumAnalytics] (
	Id int  NOT NULL,
	AccountPremiumId uniqueidentifier NOT NULL,
	PerilRanking nvarchar(250)  NULL,
	Peril nvarchar(250)  NULL,
	HighPremiumImpactVariableOne nvarchar(250)  NULL,
	HighPremiumImpactVariableTwo nvarchar(250)  NULL,
	HighPremiumImpactVariableThree nvarchar(250)  NULL,
	RecommendedAction nvarchar(250)  NULL,
	ExternalSourceId nvarchar(2000)  NULL,
	ExternalSourceUniqueId nvarchar(2000)  NULL,
	CreatedDate datetime2 NOT NULL,
	UpdatedDate datetime2 NULL,
	CONSTRAINT PK_AccountPremiumAnalytics PRIMARY KEY (Id),
	
);

CREATE NONCLUSTERED INDEX IX_AccountPremiumAnalytics_AccountPremiumId
ON edw_stage.AccountPremiumAnalytics (  AccountPremiumId ASC  )  

