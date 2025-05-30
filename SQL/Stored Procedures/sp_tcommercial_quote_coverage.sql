-- ===================================================================================================================== 
-- Author:		    Yunus Mohammed
-- Description: This procedures insert commerical quote coverage data
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						         |	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 03/28/25		          Yunus Mohammed		1.Procedure created
-- 04/22/25          	  Alberto Almario			  2.Change PolicyNumber to Number from Account table
-- 05/29/25				  Yunus Mohammed		3. AD-9660 Added new columns
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_coverage]

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
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_coverage_temp1;
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_coverage_temp2;
        
        select 
			act.*
			,CAST(acc.Number AS VARCHAR(255)) as quote_no
			,p.name as product_name
        into edw_temp.tcommercial_quote_coverage_temp1
        from
            edw_stage.AccountTransaction act
			inner join edw_stage.Account acc on act.AccountId = acc.Id 
            inner join edw_stage.Product p on p.Id=act.ProductId
            where act.[Stage]  IN ('QUOTE','POLICY')
				and p.ProductLine = 'CommercialLines'
                and act.CreatedDate > @last_source_extract_ts
         
        select quote_no,EffectiveDate as effective_dt,
        ExpirationDate as expiration_dt, transaction_seq_no,source_system_sk,
		CreatedDate,commercial_quote_history_sk,product_name	,
        CoverageType as coverage_type,CoverageTypeB as coverage_type_b,Revenue as revenue_amt,
        MemorandumOfInsurance as memorandum_of_insurance_in,NumberOfFTEAttorneys as employee_ct,
        coalesce(ClaimsActivity,ClaimsHistory) as claim_history,RetroactiveDate as retroactive_date_desc,PriorOrPendingDate as prior_or_pending_date_desc,
		case
				when SingleRoundTheClockReinstatement = 'true' then 'Yes' 
				when SingleRoundTheClockReinstatement = 'false' then 'No'
			end as  single_round_the_clock_resinstatement_in,
		getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		into edw_temp.tcommercial_quote_coverage_temp2
			from
			(
			select
			act.quote_no ,act.EffectiveDate ,act.ExpirationDate ,act.[Number] as transaction_seq_no,
			cph.commercial_quote_history_sk,act.CreatedDate,act.product_name,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value]			
			from
				edw_temp.tcommercial_quote_coverage_temp1 act
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId 
				left join edw_commercial.tcommercial_quote_history cph on cph.quote_no=act.quote_no
						and cph.effective_dt=act.EffectiveDate
						and cph.transaction_seq_no = act.[Number]				
			where
                atvof.Field in ('CoverageType','CoverageTypeB','Revenue','MemorandumOfInsurance','NumberOfFTEAttorneys',
                'ClaimsActivity','ClaimsHistory','RetroactiveDate','PriorOrPendingDate','SingleRoundTheClockReinstatement'
                )
			) as t
			pivot 
			(
				max(Value) FOR Field IN
                 (
                    CoverageType,CoverageTypeB,Revenue,MemorandumOfInsurance,NumberOfFTEAttorneys, ClaimsActivity,ClaimsHistory,
					RetroactiveDate,PriorOrPendingDate,SingleRoundTheClockReinstatement
                )
			) as pivottable
    
        insert into edw_commercial.tcommercial_quote_coverage
        (
            quote_no,effective_dt,expiration_dt,transaction_seq_no,
            commercial_quote_history_sk,coverage_type,coverage_type_b,revenue_amt,memorandum_of_insurance_in,
        employee_ct,claim_history,retroactive_date_desc,prior_or_pending_date_desc,single_round_the_clock_resinstatement_in,
		source_system_sk,create_ts,update_ts,etl_audit_sk
        )
        select
         quote_no,effective_dt,expiration_dt,transaction_seq_no,
        commercial_quote_history_sk,coverage_type,coverage_type_b,revenue_amt,memorandum_of_insurance_in,
        employee_ct,claim_history,retroactive_date_desc,prior_or_pending_date_desc,single_round_the_clock_resinstatement_in,
		source_system_sk,create_ts,update_ts,etl_audit_sk
        from
            edw_temp.tcommercial_quote_coverage_temp2

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tcommercial_quote_coverage_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS  edw_temp.tcommercial_quote_coverage_temp1
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_coverage_temp2

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
