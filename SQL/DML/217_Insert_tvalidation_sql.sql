INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Insured name, address, city, state containing special characters' ,
'select count(*)
    from edw_core.tdaily_inforce_policy dip 
				inner join edw_core.tpolicy pol 
					on dip.policy_sk = pol.policy_sk
				inner join edw_core.tpolicy_insured pins
					on pol.policy_no = pins.policy_no
					and pol.effective_dt = pins.effective_dt
 where dip.inforce_dt_sk = (select max(date_sk) from edw_core.tdate where actual_dt < cast(getdate() as date))
	and (pins.first_nm LIKE ''%"%'' 
   OR pins.insured_nm LIKE ''%"%'' 
   OR pins.last_nm LIKE ''%"%'' 
   OR pins.mailing_address_line_1 LIKE ''%"%'' 
   OR pins.mailing_address_city_nm LIKE ''%"%'' 
   OR pins.mailing_address_state_cd LIKE ''%"%'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;

INSERT INTO edw_core.tvalidation_sql (validation_sql_desc , source_sql , target_sql , active_in , frequency_desc , create_ts , update_ts)
SELECT
'Vehicle VIN, Make, Model containing special characters' ,
'select count(*)
from edw_core.tdaily_inforce_policy dip 
		inner join edw_core.tpolicy_history ph
		on ph.policy_history_sk = dip.policy_history_sk
		inner join edw_core.tauto_vehicle_coverage avc
		on avc.policy_history_sk = ph.policy_history_sk
		inner join edw_core.tauto_vehicle av 
			on avc.auto_vehicle_sk = av.auto_vehicle_sk
		where dip.inforce_dt_sk = (select max(date_sk) from edw_core.tdate where actual_dt < cast(getdate() as date))
		and avc.vehicle_deleted_in = ''No''
		and (av.vehicle_vin LIKE ''%"%'' 
		or av.vehicle_make LIKE ''%"%'' 
		or av.vehicle_model LIKE ''%"%'')' AS source_sql ,
       'select 0' AS target_sql ,
       'Y' AS active_in ,
       'Daily' AS frequency_desc ,
       getdate() AS create_ts ,
       getdate() AS update_ts;