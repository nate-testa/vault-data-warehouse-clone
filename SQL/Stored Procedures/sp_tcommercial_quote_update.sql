SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-31
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 31/03/2025           Alberto Almario				1. Created this procedure 
-- 22/04/2025           Alberto Almario				2. Change PolicyNumber to Number from Account table
-- 02/05/2025           Architha Gudimalla			3. Updated quote_status, commercial_policy_sk update
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_update]

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
        from edw_commercial.tcommercial_quote a
		where exists (select * from edw_commercial.tcommercial_quote_history  b 
					  where upper(transaction_status) = 'ISSUED' and a.quote_no=b.quote_no
					 ) 
		and ISNULL(a.quote_status,'xx')!='Issued';

		update a
		set a.quote_status = case 				
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is not null then b.SubmissionCloseReasonCategory				
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is null 
									and a.close_reason_desc 					
										in ('CAT modeling','Doesn’t meet current guidelines','Lack of updates','Loss history','Mid term COC',					
										'Occupancy','Other','OutsideRiskAppetite','Profile concerns','Unacceptable entity','UnacceptableTerms',					
										'UnavailableProduct','Unprotected','Wildfire concerns'					
										) then 'Declined by Vault'					
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is null 
									and a.close_reason_desc 					
										in ('Expired'					
										) then 'Expired'				
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is null 
									and a.close_reason_desc 					
										in ('BrokerNotResponsive'					
									) then 'No Response by Broker/Producer'				
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is null 
									and a.close_reason_desc 					
										in ('CreatedInError','DuplicateSubmission','RenewalOfAccountCanceled'					
									) then 'Not Needed'			
								when b.state = 'Closed' and b.SubmissionCloseReasonCategory is null 
									and a.close_reason_desc 					
										in ('IncompleteSubmission','NotTaken'					
									) then 'Not Taken by Insured'				
								when b.state = 'Issued' then 'Issued'					
								else 'In Progress'					
								end	 
		from edw_commercial.tcommercial_quote a
		inner join (
						select quote_no, effectivedate , state, SubmissionCloseReasonCategory
						FROM
						(
							select 	CAST(acc.Number AS VARCHAR(255)) as quote_no, effectivedate , acc.state, acc.SubmissionCloseReasonCategory
							from 	edw_commercial.tcommercial_quote  q
							inner join edw_stage.account acc on CAST(acc.Number AS VARCHAR(50)) = q.quote_no 
							where	acc.UpdatedDate > @last_source_extract_ts
						) aa 
					) b on	 a.quote_no = b.quote_no and ISNULL(a.quote_status,'xx')!='Issued'; 

  
		update a
		set a.commercial_policy_sk = b.commercial_policy_sk
		from edw_commercial.tcommercial_quote a
		inner join edw_stage.account acc on CAST(acc.Number AS VARCHAR(50)) = a.quote_no 
		inner join edw_commercial.tcommercial_policy b on CAST(acc.policyNumber AS VARCHAR(50)) = b.policy_no
		where a.commercial_policy_sk is null; 

		update a
		set a.bind_dt = b.max_bind_dt
		from edw_commercial.tcommercial_quote a
		inner join (select quote_no,max(bind_dt) max_bind_dt from edw_commercial.tcommercial_quote_history where bind_dt is not null group by quote_no) b 
        on a.quote_no = b.quote_no; 

		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_update_temp1; 
        
		select 	qh.commercial_quote_sk, max(qh.commercial_quote_history_sk) commercial_quote_history_sk
		into 	edw_temp.tcommercial_quote_update_temp1
		from 	edw_commercial.tcommercial_quote_history qh
		inner join edw_stage.account acc on CAST(acc.Number AS VARCHAR(255)) = qh.quote_no
		where  	qh.transaction_status = 'Issued'
		and 	acc.UpdatedDate	> @last_source_extract_ts
		group by qh.commercial_quote_sk; 
		

		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_update_temp1;
      
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
