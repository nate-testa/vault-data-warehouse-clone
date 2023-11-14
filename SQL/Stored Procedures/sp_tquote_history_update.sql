-- =======================================================================================================================================================
-- Description: This procedures updates tquote
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/08/23		Architha Gudimalla			1. Created this procedure  
-- ======================================================================================================================================================= 

CREATE or alter  PROCEDURE [edw_core].[sp_tquote_history_update]

AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET ANSI_WARNINGS OFF
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

		update a
		set created_by_nm 	= b.crename,
			referred_by_nm  = b.refname,
			reviewed_by_nm	= b.revname,
			approval_note 	= case when (b.ApproveNote) = '' then null else ApproveNote end,
			deny_note 		= case when (b.DenyNote) = '' then null else DenyNote end,
			bind_dt 		= b.binddate
		from edw_core.tquote_history a
		inner join ( select policynumber, effectivedate, [number], ApproveNote, DenyNote, 
							ReferredByUserId, rfu.name as refname, 
							--SubmitById, su.name subname, 
							CreatedById, cu.name crename, 
							ReviewedById, rvu.name revname, binddate
					from edw_stage.accounttransaction acc
					left join edw_stage.[user] cu on cu.id = acc.CreatedById
					left join edw_stage.[user] rvu on rvu.id = acc.ReviewedById 
					left join edw_stage.[user] rfu on rfu.id = acc.ReferredByUserId 
					where	acc.UpdatedDate 
							> @last_source_extract_ts
					) b on	 a.quote_no = b.policynumber and a.effective_dt = b.effectivedate and a.transaction_seq_no = b.[number];  

		update a
		set policy_sk 	= b.policy_sk
		from edw_core.tquote a
		inner join edw_core.tpolicy b on	a.quote_no = b.policy_no and a.effective_dt = b.effective_dt;

		SET @rows_affected=@@ROWCOUNT;   
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UpdatedDate) FROM edw_stage.accounttransaction),@last_source_extract_ts); 
		
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

