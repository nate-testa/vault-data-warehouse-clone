CREATE TABLE edw_core.tquote_referral_message
( 
quote_referral_message_sk INT IDENTITY(1,1) NOT NULL,
[quote_no] [varchar](255) NOT NULL,
[effective_dt] [date] NOT NULL,
[expiration_dt] [date] NOT NULL,
[transaction_seq_no] [int] NOT NULL,
[quote_history_sk] [int] NOT NULL,
referral_message nvarchar(max), 
referral_level INT ,
refer_in varchar(255) ,
approved_in varchar(255) ,
referral_message_created_ts datetime2(7),
referral_message_updated_ts datetime2(7),
[source_system_sk] [int] NULL,
[create_ts] [datetime] NULL,
[update_ts] [datetime] NULL,
[etl_audit_sk] [int] NULL,
CONSTRAINT pk_quote_referral_message_sk PRIMARY KEY(quote_referral_message_sk)
);

INSERT INTO edw_core.tedw_table_detail (table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts) 
    VALUES ('tquote_referral_message','Type-2 Dimension','Base','Quote','Stored Procedure','Insert/Update','Daily',getdate(),getdate());