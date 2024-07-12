insert into edw_core.tvalidation_sql 
		(validation_sql_desc
		, source_sql
		, target_sql
		, active_in
		, frequency_desc
		, create_ts
		, update_ts)
select	 'tpolicy_transaction - LUX - collection_class_type_sk = 0'  
		,'select count(*) from edw_core.tpolicy_transaction a
            where isnull(collection_class_type_sk,0) = 0
			and product_sk = 2
			and tax_fee_surcharge_sk = 0'
		,'select 0'
		,'Y'
		,'Daily'
		,getdate()
		,getdate();  