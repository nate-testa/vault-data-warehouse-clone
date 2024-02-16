
CREATE TABLE edw_core.tedw_release_summary 
(
edw_release_summary_sk int IDENTITY(1,1) NOT NULL,
release_summary nvarchar(max),
send_email_in  varchar(255),
send_email_dt date,
create_ts  datetime,
update_ts  datetime,
CONSTRAINT pk_tedw_release_summary PRIMARY KEY (edw_release_summary_sk)
);