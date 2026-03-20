IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'BrokerageProducer')
BEGIN
CREATE TABLE edw_stage.BrokerageProducer
(
[Id]                               [uniqueidentifier] NOT NULL,
[BrokerageId]                      [uniqueidentifier] NOT NULL,
[Name]                             [nvarchar](500) NULL,
[MailingAddressLine1]              [nvarchar](500) NULL,
[MailingAddressLine2]              [nvarchar](500) NULL,
[MailingAddressLineUnit]           [nvarchar](500) NULL,
[MailingAddressCity]               [nvarchar](500) NULL,
[MailingAddressState]              [nvarchar](500) NULL,
[MailingAddressZipCode]            [nvarchar](500) NULL,
[MailingAddressCounty]             [nvarchar](500) NULL,
[MailingAddressCountry]            [nvarchar](500) NULL,
[Phone]                            [nvarchar](20) NULL,
[CreatedDate]                      [datetime2](7) NOT NULL,
[UpdatedDate]                      [datetime2](7) NOT NULL
);
END


