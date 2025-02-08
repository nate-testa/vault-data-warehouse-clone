SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =======================================================================================================================================================
-- Description: This procedures updates tquote
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- 09/08/23		Architha Gudimalla			1. Created this procedure  
-- 11/14/23		Sandeep Gundreddy			2. Modify logic  
-- 11/22/23     Sandeep Gundreddy           3. Modified logic to fix quote_status for Issued quotes
-- 09/08/23		Architha Gudimalla			4. VI34112|AD7632 - Added issued_quote_history_sk
-- 01/23/25		Architha Gudimalla			5. VI33968/AD7635 - Added uwco orig eff dt..
-- ======================================================================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_update]

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

        -- Updating quote status to Issued for all Issued quotes 

        update a 
        set a.quote_status='Issued'
        from edw_core.tquote a
		where exists (select * from edw_core.tquote_history  b where upper(transaction_status) = 'ISSUED' and a.quote_no=b.quote_no) and ISNULL(a.quote_status,'xx')!='Issued';

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
							left join edw_core.tquote_transaction_status_history  qtsh on acc.policynumber = qtsh.quote_no 
							where	acc.UpdatedDate 
									> @last_source_extract_ts
						) aa
						group by policynumber, effectivedate , state, tr_status
					) b on	 a.quote_no = b.policynumber and ISNULL(a.quote_status,'xx')!='Issued'; 

  update a
		set a.first_offered_quote_ts 	=transaction_ts,
            first_offered_quote_history_sk=quote_history_sk
  from edw_core.tquote a,
        (select * from 
            (
             select quote_no, transaction_ts, quote_history_sk, dense_rank() OVER (PARTITION BY quote_no ORDER BY transaction_ts ASC) AS policy_txn_order
					from edw_core.tquote_transaction_status_history  
					WHERE upper(transaction_status) = 'OFFERED')tqtsh
                    where policy_txn_order=1
            )b
             where a.quote_no=b.quote_no and a.first_offered_quote_ts is null;
		
        --AV2 Issued quotes which don't exist in tquote_transaction_status_history
        	         
        update a
		set a.first_offered_quote_ts 	= a.quote_create_ts
		from edw_core.tquote a
        where a.quote_status='Issued' and migrated_in='Yes' and a.first_offered_quote_ts is null;

		update a
		set first_offered_quote_history_sk 	= b.quote_history_sk
		from edw_core.tquote a
		inner join (
   						select quote_no,max(quote_history_sk) quote_history_sk
							from 	edw_core.tquote_history  
							WHERE upper(transaction_status) = 'ISSUED' and source_system_sk=2 
						group by quote_no
                   )b on a.quote_no = b.quote_no  and a.quote_status='Issued' and migrated_in='Yes' and first_offered_quote_history_sk is null;

		update a
		set policy_sk = b.policy_sk
		from edw_core.tquote a
		inner join edw_core.tpolicy b 
        on a.quote_no = b.policy_no and a.effective_dt = b.effective_dt where a.policy_sk is null; 

		update a
		set a.bind_dt = b.max_bind_dt
		from edw_core.tquote a
		inner join (select quote_no,max(bind_dt) max_bind_dt from edw_core.tquote_history where bind_dt is not null group by quote_no) b 
        on a.quote_no = b.quote_no; 

		DROP TABLE IF EXISTS edw_temp.tquote_update_temp1; 
        
		select 	qh.quote_sk, max(qh.quote_history_sk) quote_history_sk
		into 	edw_temp.tquote_update_temp1
		from 	edw_core.tquote_history qh
		inner join edw_stage.account acc on acc.PolicyNumber = qh.quote_no
		where  	qh.transaction_status = 'Issued'
		and 	acc.UpdatedDate	> @last_source_extract_ts
		group by qh.quote_sk; 

		update 	a
		set 	a.issued_quote_history_sk = b.quote_history_sk
		from 	edw_core.tquote a
		inner join edw_temp.tquote_update_temp1 b on a.quote_sk = b.quote_sk; 

		--added on 1/23 for uw_company_original_policy_effective_dt
		update q
		set q.uw_company_original_policy_effective_dt = q1.uw_company_original_policy_effective_dt
		from edw_core.tquote q
		inner join (select  quote_sk, min(effective_dt) over (partition by original_policy_no) uw_company_original_policy_effective_dt
					from edw_core.tquote) q1 on q.quote_sk = q1.quote_sk
		;  

		DROP TABLE IF EXISTS edw_temp.tquote_update_temp1;
      
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

GO
