CREATE TABLE [edw_stage].[hubspot_quote_notes](
	[hs_note_id] [varchar](255) NOT NULL,
	[hs_note_body] [nvarchar](max) NOT NULL,
	[note_id] [varchar](255) NOT NULL,
	[created_by] [varchar](255) NOT NULL,
	[create_ts] [datetime] NOT NULL,
	[update_ts] [datetime] NOT NULL, 
	CONSTRAINT pk_hubspot_quote_notes PRIMARY KEY (hs_note_id)
	)