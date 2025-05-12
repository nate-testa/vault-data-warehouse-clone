create table edw_core.tpolicy_form (
	policy_form_sk int identity(1,1) not null,
	policy_no varchar(255) not null,
	effective_dt date not null,
	transaction_effective_dt date not null,
	expiration_dt date not null,
	transaction_dt date not null,
	transaction_seq_no int not null,
	policy_history_sk int not null,
	form_cd varchar(255) not null,
	form_edition varchar(255) null,
    form_description varchar(255) null,
    form_type varchar(255) null,
    document_type varchar(255) null,
	source_system_sk int not null,
	create_ts datetime not null,
	update_ts datetime not null,
	etl_audit_sk int not null,
	constraint pk_tpolicy_form primary key (policy_form_sk),
	constraint fk_tpolicy_form_policy_history_sk foreign key (policy_history_sk) references edw_core.tpolicy_history(policy_history_sk)
) ; 

INSERT INTO edw_core.tedw_table_detail(table_nm,table_type,table_category_nm,domain_nm,load_method,load_type,load_frequency,create_ts,update_ts)
    VALUES ('tpolicy_form','Type-2 Dimension','Base','Policy','Stored Procedure','Insert','Daily',getdate(),getdate());