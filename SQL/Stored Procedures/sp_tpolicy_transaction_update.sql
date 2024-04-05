-- ===================================================================================================================================================
-- Description: This procedures updates TPolicy_Transaction  
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 03/25/24		Architha Gudimalla				1. Created this procedure 
-- 03/29/24		Architha Gudimalla				2. Added update for 0 veh_cov_sk
-- ====================================================================================================================================================== 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_tpolicy_transaction_update]

AS
BEGIN
   -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @CU DATETIME=GETDATE()
		
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		DECLARE @parameter_desc VARCHAR(255)
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))  

		/*
		update edw_core.tpolicy_transaction 
		set collection_class_type_sk = 0;

		--update all policies that have an exact match on class type
		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no = cc.transaction_seq_no 
																	and case when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Music' then 'Musical Instruments' 
																			when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Fine Arts' then 'Fine Art' 
																			else replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')
																		end = cc.class_type   
					where 	tr.collection_class_type_sk = 0
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

		*/

		--update all policies that have class type as Jewelry (Scheduled) in tpolicy_transaction and class type as Bank Vaulted Jewelry in tcollection_class_type
		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no = cc.transaction_seq_no 
																	and internal_coverage_cd = 'Jewelry (Scheduled)' and cc.class_type like '%Bank Vaulted Jewelry%'
					where 	tr.collection_class_type_sk = 0
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium' --and pol.policy_sk = 111021
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

		--update all policies that have class type as Jewelry (Blanket) in tpolicy_transaction and class type as Bank Vaulted Jewelry in tcollection_class_type
		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no = cc.transaction_seq_no 
																	and internal_coverage_cd = 'Jewelry (Blanket)' and cc.class_type like '%Worldwide Jewelry%'-- and cc.blanket_limit_amt <> 0
					where 	tr.collection_class_type_sk = 0
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

		--update all policies that do not have the same seq record in tcollection_class_type to a record prior to max
		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no > cc.transaction_seq_no 
																	and case when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Music' then 'Musical Instruments' 
																			when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Fine Arts' then 'Fine Art' 
																			else replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')
																		end = cc.class_type   
					where 	tr.collection_class_type_sk = 0
					and 	tr.product_sk in (1,2,5) 
					and 	tr.source_system_sk <> 4
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

		--update all policies that do not have the same seq record in tcollection_class_type to a record prior to max for pols that have class type as Jewelry (Blanket) in tpolicy_transaction and class type as Bank Vaulted Jewelry in tcollection_class_type
		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no > cc.transaction_seq_no 
																	and internal_coverage_cd = 'Jewelry (Scheduled)' and cc.class_type like '%Bank Vaulted Jewelry%' 
					where 	tr.collection_class_type_sk = 0
					and 	tr.product_sk in (1,2,5) 
					and 	tr.source_system_sk <> 4
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium' --and pol.policy_sk = 111021
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk; 

		drop table if exists edw_temp.tpolicy_transaction_update_temp1;
	
		select *
		into edw_temp.tpolicy_transaction_update_temp1
		from edw_core.tpolicy_transaction
		where product_sk = 3 and vehicle_coveragE_sk = 0 and tax_fee_surcharge_sk = 0
		and source_system_sk <> 1 and internal_coverage_sk not in (select internal_coverage_sk from edw_core.tinternal_coverage       
																	where internal_coverage_cd in ('Automobile Death Indemnity and Disability Income','Auto Death Disability','Emergency Living Expense',
																	'Equipment Manufacturer Parts Enhancement','Full Glass Coverage Enhancement','Multiple Policy Deductible Enhancement','Stated Value Enhancement'))
		and item_sk <> 0
		and source_system_sk = 2;

		update tr
		set tr.vehicle_coveragE_sk = tmp1.auto_vehicle_coverage_sk
		from edw_core.tpolicy_transaction tr
		inner join (	
					Select distinct --pol.policy_sk, tr.transaction_seq_no, tr.item_sk , tr.internal_coverage_sk, 
							tr.policy_transaction_sk, 
							first_value(avc.auto_vehicle_coverage_sk) over (partition by avc.policy_no, pol.effective_dt,avc.auto_vehicle_sk order by avc.transaction_seq_no desc) auto_vehicle_coverage_sk
						from edw_temp.tpolicy_transaction_update_temp1 tr
						inner join edw_core.tpolicy pol on pol.policy_sk = tr.policy_sk
						left join edw_core.tauto_vehicle_coverage avc on pol.policy_no = avc.policy_no and pol.effective_dt = avc.effective_dt and tr.item_sk = avc.auto_vehicle_sk and tr.transaction_seq_no >= avc.transaction_seq_no  
					) tmp1 on tr.policy_transaction_sk = tmp1.policy_transaction_sk
		where product_sk = 3 and vehicle_coveragE_sk = 0 and tax_fee_surcharge_sk = 0
		and item_sk <> 0
		and source_system_sk = 2 ;

		drop table if exists edw_temp.tpolicy_transaction_update_temp1;


		SET @new_last_source_extract_ts=COALESCE((SELECT actual_dt from edw_core.tdate where date_sk = ( select MAX(transaction_dt_sk) FROM edw_core.tpolicy_transaction))
													,@last_source_extract_ts);
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
	
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
