--update the sql to include only policies with effective in or after 2023 
update edw_core.tvalidation_sql
set source_sql = 'select count(*) from 
				 (select policy_no, effective_dt, veh.vehicle_vin  
				  from edw_core.tauto_vehicle veh 
				  where NULLIF(trim(vehicle_vin),'''') is not null and effective_dt >= ''01-jan-2023''     
				  group by policy_no, effective_dt, veh.vehicle_vin      
				  having count(*) > 1
				) a'
where validation_sql_desc = 'tauto_vehicle - duplicate vehicle VIN';

--PEL does not have item_sk so no need to load in titem_summary
delete from edw_core.tvalidation_result
where validation_sql_sk  =  (select validation_sql_sk
							 from edw_core.tvalidation_sql
							 where validation_sql_desc = 'Inforce_ct - PEL - mismatch between tdaily_inforce_policy and titem_summary');

--PEL does not have item_sk so no need to load in titem_summary
delete from edw_core.tvalidation_sql
where validation_sql_desc = 'Inforce_ct - PEL - mismatch between tdaily_inforce_policy and titem_summary';

--update the sql to include only policies with effective in or after 2023 
update edw_core.tvalidation_sql
set source_sql = 'select count(distinct pol.policy_sk) from edw_core.tpolicy_transaction tr,edw_core.tpolicy pol
				  where pol.policy_sk = tr.policy_sk and product_sk = 3 
				  and isnull(vehicle_coverage_sk,0) = 0 and tax_fee_surcharge_sk = 0 and pol.source_system_sk <> 1 
				  and pol.effective_dt >= ''01-jan-2023''
				  and internal_coverage_sk not in (select internal_coverage_sk from edw_core.tinternal_coverage
				                                   where internal_coverage_cd in (''Automobile Death Indemnity and Disability Income'',
												   								  ''Auto Death Disability'',''Emergency Living Expense'',
																				  ''Equipment Manufacturer Parts Enhancement'',
																				  ''Full Glass Coverage Enhancement'',
																				  ''Multiple Policy Deductible Enhancement'',
																				  ''Stated Value Enhancement'')
												  )'
where validation_sql_desc = 'tpolicy_transaction - vehicle_coverage_sk = 0 for AU';

--update to change description as policy count
update 	edw_core.tvalidation_sql
set 	validation_sql_desc = 'tpolicy_transaction - policies having vehicle_coverage_sk = 0 for AU'
where 	validation_sql_desc = 'tpolicy_transaction - vehicle_coverage_sk = 0 for AU'; 

--discuss with sandeep update policy term update to renewal from new in tpolicy_transaction.policy_transaction_type_sk