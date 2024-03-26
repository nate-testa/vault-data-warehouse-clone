-- ===================================================================================================================================================
-- Description: This procedures updates TPolicy_Transaction  
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 03/25/24		Architha Gudimalla				1. Created this procedure 
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

		update edw_core.tpolicy_transaction 
		set collection_class_type_sk = 0;

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
					and		pol.source_system_sk <> 1 
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

		update a
		set a.collection_class_type_sk = b.collection_class_type_sk
		from edw_core.tpolicy_transaction a 
		inner join (
					select  policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type ,  max(cc.collection_class_type_sk  ) collection_class_type_sk
					from 		edw_core.tpolicy pol
					inner join  edw_core.tpolicy_transaction tr on pol.policy_sk = tr.policy_sk  
					inner join 	edw_core.tinternal_coverage ic on ic.internal_coverage_sk = tr.internal_coverage_sk 
					inner join 	edw_core.tcollection_class_type cc on     pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and tr.transaction_seq_no = cc.transaction_seq_no 
																	and internal_coverage_cd = 'Jewelry (Scheduled)' and cc.class_type like '%jew%' 
					where 	tr.collection_class_type_sk = 0
					and		pol.source_system_sk <> 1 
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

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
					and		pol.source_system_sk <> 1 
					and 	tr.product_sk in (1,2,5) 
					and 	ic.primary_coverage_cd = 'Lux' 
					and 	ic.internal_coverage_category_nm = 'Premium'
					group by policy_transaction_sk, tr.transaction_seq_no,  internal_coverage_cd,  cc.class_type
		) b on a.policy_transaction_sk = b.policy_transaction_sk;

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
