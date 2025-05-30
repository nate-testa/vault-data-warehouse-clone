-- ===================================================================================================================== 
-- Author:		    Yunus Mohammed
-- Description: This procedures insert commerical quote coverage wip data
-----------------------------------------------------------------------------------------------------------------------
-- Change date          	|Author						        |	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 03/28/25		          Yunus Mohammed		1.Procedure created
-- 04/22/25              Alberto Almario			  2.Change PolicyNumber to Number from Account table
-- 05/29/25				  Yunus Mohammed		3. AD-9660 Added new columns
-- 05/29/2025			Yunus Mohammed		 4. AD-9649 Update Merge statement join
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_coverage_wip]

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
		
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_coverage_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_coverage_wip_temp2;
        
		select 
			acc.*
			,p.[Name] as product_name
		into edw_temp.tcommercial_quote_coverage_wip_temp1
		from
			edw_stage.Account acc
			inner join edw_stage.Product p on p.Id=acc.ProductId
		where not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
			and p.ProductLine = 'CommercialLines'
			and greatest(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts

        select quote_no,EffectiveDate as effective_dt,
        ExpirationDate as expiration_dt, transaction_seq_no,IsRenewal,source_system_sk,
		CreatedDate,UpdatedDate,commercial_quote_history_sk,product_name,
        CoverageType as coverage_type,CoverageTypeB as coverage_type_b,Revenue as revenue_amt,
        MemorandumOfInsurance as memorandum_of_insurance_in,NumberOfFTEAttorneys as employee_ct,
        coalesce(ClaimsActivity,ClaimsHistory) as claim_history,RetroactiveDate as retroactive_dt_desc,PriorOrPendingDate as prior_or_pending_dt_desc,
		case
				when SingleRoundTheClockReinstatement = 'true' then 'Yes' 
				when SingleRoundTheClockReinstatement = 'false' then 'No'
			end as  single_round_the_clock_resinstatement_in,
		getdate() as create_ts,getdate() as update_ts,@etl_audit_sk as etl_audit_sk
		into edw_temp.tcommercial_quote_coverage_wip_temp2
			from
			(
			select
			CAST(acc.Number AS VARCHAR(255)) as quote_no ,acc.EffectiveDate ,acc.ExpirationDate ,0 as transaction_seq_no,
			cph.commercial_quote_history_sk,acc.CreatedDate, acc.UpdatedDate,acc.product_name,acc.IsRenewal,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,accof.Field,accof.[Value]
			from
				edw_temp.tcommercial_quote_coverage_wip_temp1 acc
				inner join edw_stage.[AccountObject] AS accvo ON accvo.AccountId = acc.Id
                inner join edw_stage.[AccountObjectField] AS accof ON accof.ObjectId = accvo.Id
				left join edw_commercial.tcommercial_quote_history cph on cph.quote_no=CAST(acc.Number AS VARCHAR(255))
						and cph.effective_dt=acc.EffectiveDate
						and cph.transaction_seq_no = 0				
			where				
                accof.Field in ('CoverageType','CoverageTypeB','Revenue','MemorandumOfInsurance','NumberOfFTEAttorneys',
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

            MERGE edw_commercial.tcommercial_quote_coverage AS [Target]
            USING edw_temp.tcommercial_quote_coverage_wip_temp2	 AS [Source]
            ON Source.quote_no = [Target].[quote_no] 
			and [Target].effective_dt = CASE WHEN Source.IsRenewal = 0  THEN [Target].effective_dt ELSE [Source].effective_dt  END
            and [Source].effective_dt = [Target].effective_dt
            and Source.transaction_seq_no = Target.transaction_seq_no
            WHEN NOT MATCHED BY Target THEN			
            INSERT
            (
            quote_no,effective_dt,expiration_dt,transaction_seq_no,
            commercial_quote_history_sk,coverage_type,coverage_type_b,revenue_amt,memorandum_of_insurance_in,
            employee_ct,claim_history,retroactive_dt_desc,prior_or_pending_dt_desc,single_round_the_clock_resinstatement_in,
			source_system_sk,create_ts,update_ts,etl_audit_sk
            )
            VALUES
            (
            quote_no,effective_dt,expiration_dt,transaction_seq_no,
            commercial_quote_history_sk,coverage_type,coverage_type_b,revenue_amt,memorandum_of_insurance_in,
            employee_ct,claim_history,retroactive_dt_desc,prior_or_pending_dt_desc,single_round_the_clock_resinstatement_in,
			source_system_sk,create_ts,update_ts,etl_audit_sk
            )
            WHEN MATCHED THEN UPDATE
            SET
            [target].effective_dt = [source].effective_dt,
            [target].expiration_dt = [source].expiration_dt,
            [target].commercial_quote_history_sk = [source].commercial_quote_history_sk,
            [target].coverage_type = [source].coverage_type,
            [target].coverage_type_b = [source].coverage_type_b,
            [target].revenue_amt = [source].revenue_amt,
            [target].memorandum_of_insurance_in = [source].memorandum_of_insurance_in,
            [target].employee_ct = [source].employee_ct,
            [target].claim_history = [source].claim_history,
			[target].retroactive_dt_desc = [source].retroactive_dt_desc,
			[target].prior_or_pending_dt_desc = [source].prior_or_pending_dt_desc,
			[target].single_round_the_clock_resinstatement_in = [source]. single_round_the_clock_resinstatement_in,
            [target].update_ts = GETDATE();

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate,UpdatedDate)) FROM edw_temp.tcommercial_quote_coverage_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS  edw_temp.tcommercial_quote_coverage_wip_temp1
		DROP TABLE IF EXISTS  edw_temp.tcommercial_quote_coverage_wip_temp2

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
