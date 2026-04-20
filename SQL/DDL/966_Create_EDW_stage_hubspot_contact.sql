IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES
               WHERE TABLE_SCHEMA = 'edw_stage'
               AND TABLE_NAME = 'hubspot_contact')
BEGIN
CREATE TABLE edw_stage.hubspot_contact
(
[hs_contact_id]                    [nvarchar](50) NOT NULL,
[email]                            [nvarchar](255) NULL,
[firstname]                        [nvarchar](255) NULL,
[lastname]                         [nvarchar](255) NULL,
[type]                             [nvarchar](50) NULL,
[producer_id]                      [nvarchar](50) NULL,
[customer_id]                      [nvarchar](50) NULL,
[broker_id]                        [nvarchar](50) NULL,
[hs_object_source]                 [nvarchar](50) NULL,
[hs_createdate]                    [nvarchar](50) NULL,
[matched_edw_producer_id]          [nvarchar](50) NULL,
[matched_edw_customer_id]          [nvarchar](50) NULL,
[match_status]                     [nvarchar](20) DEFAULT 'UNPROCESSED',
[match_source]                     [nvarchar](50) NULL,
[created]                          [datetime2](7) DEFAULT GETDATE(),
[updated]                          [datetime2](7) DEFAULT GETDATE()
);
END