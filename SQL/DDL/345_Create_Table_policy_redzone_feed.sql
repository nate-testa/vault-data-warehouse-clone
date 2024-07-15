CREATE TABLE edw_integration.policy_redzone_feed
(
    unique_id  varchar(255) NOT NULL,
    policy_id  varchar(255) NOT NULL,
    policy_type varchar(255) NOT NULL,
    latitude	varchar(255),
    longitude	varchar(255),
    address	varchar(255),
    city	varchar(255),
    county	varchar(255),
    state	varchar(255),
    zip	varchar(255),
    tiv	varchar(255),
    insured_name	varchar(255),
    insured_phone	varchar(255),
    insured_email	varchar(255),
    broker_id	varchar(255),
    broker_name	varchar(255),
    broker_phone	varchar(255),
    broker_email	varchar(255),
    coverage_a	varchar(255),
    coverage_b	varchar(255),
    coverage_c	varchar(255),
    coverage_d	varchar(255),
    gate_code	varchar(255),
    create_ts datetime ,
    update_ts datetime ,
    etl_audit_sk int,
  CONSTRAINT pk_policy_redzone_feed PRIMARY KEY (policy_id)
);

INSERT INTO	edw_integration.tintegration_table_detail(table_nm,	table_type,	table_desc,	load_method,	load_type,	load_frequency,	create_ts,	update_ts)
VALUES ('policy_redzone_feed','Feed','This table provides inforce home and collections policy data to RedZone','Stored Procedure','Full Load','Daily',getdate(),getdate());

