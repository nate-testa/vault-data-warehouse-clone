-- =======================================================================================================================================================
-- Description: This procedures updates tquote
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/08/23		Architha Gudimalla			1. Created this procedure  
-- ======================================================================================================================================================= 

CREATE  or alter PROCEDURE [edw_core].[sp_tquote_update]

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
		set a.quote_status = case when b.state = 'WIP' and tr_status = 'No Trans' then 'In Progress'
								  when b.state = 'WIP' and tr_status_offered >= 1 then 'Offered'
								  when b.state = 'WIP' and tr_status_referred >= 1 and tr_status_offered = 0 then 'Referred'
								  when b.state = 'Closed' and tr_status_offered = 0 then 'Declined'
								  when b.state = 'Closed' and tr_status_offered >= 1 then 'Not taken'
								  when b.state = 'Issued'  then 'Issued'
								  else 'In Progress'
							 end
		from edw_core.tquote a
		inner join (
						select policynumber, effectivedate , state, tr_status, sum(tr_status_offered) tr_status_offered, sum(tr_status_referred) tr_status_referred
						FROM
						(
							select 	policynumber, effectivedate , acc.state, 
									case when qtsh.quote_no is null then 'No Trans' else '' end tr_status, 
									case when upper(qtsh.transaction_status) = 'OFFERED' then 1 else 0 end tr_status_offered, 
									case when qtsh.transaction_status = 'REFERRED' then 1 else 0 end tr_status_referred 
							from 	edw_stage.account acc
							left join edw_core.tquote_transaction_status_history  qtsh on acc.policynumber = qtsh.quote_no and qtsh.effective_dt = acc.effectivedate
							where	acc.UpdatedDate 
									> @last_source_extract_ts
						) aa
						group by policynumber, effectivedate , state, tr_status
					) b on	 a.quote_no = b.policynumber and a.effective_dt = b.effectivedate ; 

		update a
		set first_offered_quote_ts 	= b.min_create_ts
		from edw_core.tquote a
		inner join ( select quote_no, min(create_ts) min_create_ts
					from edw_core.tquote_transaction_status_history  
					WHERE upper(transaction_status) = 'OFFERED'
					group by quote_no 
					) b on	a.quote_no = b.quote_no
					;

		update a
		set first_offered_quote_history_sk 	= b.quote_history_sk
		from edw_core.tquote a
		inner join (
						select *
						FROM
						(
							select quote_no, transaction_created_ts,quote_history_sk, 
									RANK() OVER (PARTITION BY quote_no,Effective_dt ORDER BY transaction_created_ts ) AS rnk
							from 	edw_core.tquote_history   

						) aa 
						where	rnk = 1
					) b on	a.quote_no = b.quote_no 

		update a
		set policy_sk 	= b.policy_sk
		from edw_core.tquote a
		inner join edw_core.tpolicy b on	a.quote_no = b.policy_no and a.effective_dt = b.effective_dt;

		--max bind date
		--QUOTE CREATE TS
		--PRIOR TERM POL SK

		SET @rows_affected=@@ROWCOUNT;   
	
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UpdatedDate) FROM edw_stage.account),@last_source_extract_ts); 
		
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

