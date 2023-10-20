create table edw_stage.t_clm_subclaim_type
(
  subclaim_type_code varchar(30) not null,
  product_line_code varchar(30) not null,
  subclaim_type_name varchar(200) not null,
  is_unique char(1) null,
  is_insured_object char(1) null,
  subclaim_type_desc varchar(255),
  fraud_subject_code varchar(10)default null,
  insert_by decimal(19,0) default null,
  insert_time datetime default null,
  update_by decimal(19,0) default null,
  update_time datetime default null,
 constraint [pk_t_clm_subclaim_type] primary key clustered 
	(
		[subclaim_type_code] asc
	)
);