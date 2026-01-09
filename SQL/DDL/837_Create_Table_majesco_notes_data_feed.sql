IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'majesco_notes_data_feed')
BEGIN

CREATE TABLE [edw_stage].[majesco_notes_data_feed](
	[policy_no] [varchar](50) NULL,
	[account_no] [bigint] NULL,
	[remarks] [varchar](max) NULL,
	[private] [char](1) NULL,
	[has_attachment] [char](1) NULL,
	[attachment_category] [varchar](100) NULL,
	[attachment_description] [varchar](255) NULL,
	[attachment_filename] [varchar](255) NULL,
	[source_system_sk] [int] NULL,
	[create_ts] [datetime] NULL,
	[update_ts] [datetime] NULL,
	[etl_audit_sk] [int] NULL
) ON [PRIMARY]

end
