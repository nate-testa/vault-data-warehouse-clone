IF NOT EXISTS (SELECT * FROM sys.objects 
               WHERE object_id = OBJECT_ID(N'[edw_stage].[tvendor_report_Clue_Property]') 
               AND type in (N'U'))
BEGIN
    CREATE TABLE [edw_stage].[tvendor_report_Clue_Property](
        [policynumber] [nvarchar](50) NULL,
        [effectivedate] [datetime2](7) NULL,
        [dateordered] [datetime2](7) NULL,
        [dateTimeRecieved] [datetime2](7) NULL,
        [dateTimeCompleted] [datetime2](7) NULL,
        [TransactionStatus] [nvarchar](4000) NULL,
        [JSON_Columns] [nvarchar](max) NULL,
        [create_ts] [datetime] NULL,
        [update_ts] [datetime] NULL,
        [etl_audit_sk] [int] NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
