IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_SCHEMA = 'edw_stage' 
               AND TABLE_NAME = 'stage_majesco_notes_data_feed')
BEGIN

CREATE TABLE [edw_stage].[stage_majesco_notes_data_feed](
	[policy_no] [varchar](255) NULL,
	[account_no] [varchar](255) NULL,
	[remarks] [varchar](255) NULL,
	[private] [varchar](255) NULL,
	[has_attachment] [varchar](255) NULL,
	[attachment_category] [varchar](255) NULL,
	[attachment_description] [varchar](255) NULL,
	[attachment_filename] [varchar](255) NULL,
	[start_date] [varchar](255) NULL,
	[end_date] [varchar](255) NULL,
	[create_ts] [datetime2](7) NULL
) ON [PRIMARY]

end
