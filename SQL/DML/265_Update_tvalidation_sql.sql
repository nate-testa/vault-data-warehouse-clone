--87 (tclaim_feature snapsheet claims - missing item_sk)
update edw_core.tvalidation_sql
set target_sql='select 28'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing item_sk';

--86 (tclaim_feature snapsheet claims - missing coverage_sk)
update edw_core.tvalidation_sql
set target_sql='select 6'
where validation_sql_desc = 'tclaim_feature snapsheet claims - missing coverage_sk';

--39 (tauto_vehicle - duplicate vehicle VIN)
update edw_core.tvalidation_sql
set source_sql='select count(*) from
(
	select veh.policy_no, veh.effective_dt, veh.vehicle_vin,cov.transaction_seq_no
	from
	edw_core.tauto_vehicle veh
	inner join edw_core.tauto_vehicle_coverage cov on veh.auto_vehicle_sk = cov.auto_vehicle_sk		
	 where 
	 cov.vehicle_deleted_in = ''No'' and
	  NULLIF(trim(veh.vehicle_vin),'''') is not null
	 and veh.effective_dt >= ''01-jan-2023''
) as a
group by policy_no, effective_dt,transaction_seq_no, vehicle_vin
having count(vehicle_vin) > 1
'
where validation_sql_desc = 'tauto_vehicle - duplicate vehicle VIN';


--39 (tauto_vehicle - duplicate vehicle VIN)
update edw_core.tvalidation_sql
set target_sql='select 0'
where validation_sql_desc = 'tauto_vehicle - duplicate vehicle VIN';


--126 (Clue Auto - ClaimType CP has at_fault_indicator = 'A')
update edw_core.tvalidation_sql
set source_sql='select count(*) from  edw_core.tclaim_feature cf inner join edw_core.tclaim c  on  cf.claim_sk = c.claim_sk 
where cf.claim_coverage_desc = ''Comprehensive'' and c.fault_decision = ''insured''
and claim_feature_status <> ''Cancelled''
'
where validation_sql_desc = 'Clue Auto - ClaimType CP has at_fault_indicator = ''A''';

--125 (Clue Auto - ClaimType contains CO and CP)
update edw_core.tvalidation_sql
set source_sql='select count(*) from (select cf.claim_no from edw_core.tclaim_feature cf where cf.source_system_sk = 5
and cf.product_sk  = 3 	and cf.claim_feature_status <> ''Cancelled''
and cf.claim_coverage_desc  in  (''Collision'', ''Comprehensive'') group by cf.claim_no 
having count(distinct cf.claim_coverage_desc) > 1  ) dup_claims
'
where validation_sql_desc = 'Clue Auto - ClaimType contains CO and CP';

--103 (Updating product_sk to 1 for one caim which was created in error)
update edw_core.tclaim 
set product_sk = 1 
where claim_no = '25ATFL499819318'
and policy_no = 'AU200023455'

--109 (tbroker - null commercial_or_personal_business_type)
UPDATE edw_core.tbroker 
SET  commercial_or_personal_business_type = 'Commercial lines'
where broker_id IN (
'10049',
'10037',
'10048')

update edw_core.tvalidation_sql
set source_sql='select count(*) FROM edw_core.tbroker t where commercial_or_personal_business_type is NULL 
and not (broker_id  NOT LIKE ''%[^0-9]%'' and LEN(TRIM(broker_id)) IN (11,12))'
where validation_sql_desc = 'tbroker - null commercial_or_personal_business_type';


