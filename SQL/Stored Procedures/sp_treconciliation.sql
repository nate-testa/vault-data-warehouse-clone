-- =============================================================================================================================================
-- Author:		Architha Gudimalla 
-- Description: This procedure reconciles data 
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 07/24/23		Architha Gudimalla				1. Created this procedure 
-- 10/23/23		Architha Gudimalla				2. Updated the proc to run for 30 days
-- 11/27/23		Architha Gudimalla				3. Add source_system_sk and datamart
-- 12/01/23		Architha Gudimalla				4. Using dbo for metal tables
-- 12/04/23		Architha Gudimalla				5. Updated the proc to run for 7 days
-- 01/23/24		Architha Gudimalla				6. Rounded the premiums
-- 03/27/24		Architha Gudimalla				7. Replaced AccountTransaction with AccountTransactionCoveragePremium,AccountTransactionTaxAndFee
-- 05/22/25		Yunus Mohammed				 8. Used external table
-- ===============================================================================================================================================

CREATE OR ALTER PROCEDURE [edw_core].[sp_treconciliation]
@in_start_dt date = null,
@in_end_dt date = null
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

		SELECT @last_source_extract_ts = cast(edw_core.fn_get_last_source_extract_ts(@process_nm) as date);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  

		if @last_source_extract_ts = '01-jan-1999'
		begin
			SELECT @last_source_extract_ts = min(cast(IssuedDate as date)) from dbo.[AccountTransaction];
		end
	
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));
		declare @max_transaction_ts datetime2(6)

        select @max_transaction_ts = max(dt.actual_dt)
		from
			edw_core.tpolicy_transaction pt
			LEFT JOIN edw_core.tdate dt on dt.date_sk = cast(pt.transaction_dt_sk as date);

		with src_metal as
		(
			/*select cast(acct.IssuedDate as date) iss_dt, count(*) cnt, 
					round(sum(coalesce(totalpremiumdeltaprorated, totalpremium)),2) prm ,
					case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
					end ssk
			from dbo.[AccountTransaction] acct  
			left join edw_stage.Product pr on acct.ProductId = pr.id
			WHERE acct.State ='ISSUED' --- Review BOUND transactions
			and	acct.PolicyNumber is not null 
			and pr.ProductLine = 'PersonalLines'  
			AND cast(acct.IssuedDate as date) >= @last_source_extract_ts
			group by cast(acct.IssuedDate as date),
					case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
					end
					*/
			select  iss_dt , --policy_no, transaction_seq_no, 
					count(distinct policy_no||transaction_seq_no) cnt, 
					round(sum(prm),2) prm , ssk 
			from 
			(
				select acctr.PolicyNumber policy_no, acctr.policychangenumber transaction_seq_no,
							cast(acctr.IssuedDate as date) iss_dt,  
							round(COALESCE (acctrcp.PremiumDeltaProRated ,premium),2) prm ,
							iif(acctr.ExternalSourceId is null,4,2) ssk 
				FROM dbo.AccountTransaction acctr 
				left join edw_stage.Product pr on acctr.ProductId = pr.id 
				inner join dbo.AccountTransactionCoveragePremium acctrcp on acctrcp.AccountTransactionId = acctr.Id
				where acctr.PolicyNumber  is not null 
				  and acctr.State ='ISSUED' 
				  and pr.ProductLine='PersonalLines' 
				  AND cast(acctr.IssuedDate as date) between @last_source_extract_ts and @max_transaction_ts

				union all

				select acctr.PolicyNumber policy_no, acctr.policychangenumber transaction_seq_no,
							cast(acctr.IssuedDate as date) iss_dt, 
							round(COALESCE (acctrtf.AmountDeltaProRated ,acctrtf.Amount),2) prm ,
							iif(acctr.ExternalSourceId is null,4,2) ssk 
				FROM dbo.AccountTransaction acctr 
				left join edw_stage.Product pr on acctr.ProductId = pr.id 
				inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = acctr.Id 
				left join edw_stage.coverage cov on cov.id = acctrtf.coverageid 
				where acctr.PolicyNumber  is not null 
				  and acctr.State ='ISSUED' 
				  and pr.ProductLine='PersonalLines' 
				  AND cast(acctr.IssuedDate as date) between @last_source_extract_ts and @max_transaction_ts
			) a 
			group by  iss_dt,  ssk --, policy_no, transaction_seq_no
		),
		src_edw as
		(
			select td.actual_dt iss_dt, count(distinct pol.policy_sk+transaction_seq_no) cnt, 
					round(sum(premium_amt),2) prm , tr.source_system_sk ssk
			from edw_core.tpolicy_transaction tr, edw_core.tpolicy pol , edw_core.tdate td
			where pol.policy_sk = tr.policy_sk
			and td.date_sk = tr.transaction_dt_sk 
			and tr.source_system_sk!=1
			and td.actual_dt >= @last_source_extract_ts
			group by td.actual_dt, tr.source_system_sk
		) 
		MERGE edw_core.treconciliation AS Target
		USING 
		( 
			select 	'Policy' datamart_nm, isnull(a.iss_dt, b.iss_dt) iss_dt, 
					isnull(a.cnt,0) metal_ct, isnull(a.prm,0) metal_prm, 
					isnull(b.cnt,0) edw_ct, isnull(b.prm,0) edw_prm,
					case when COALESCE(a.ssk,b.ssk) = 2 then 'AV2' when COALESCE(a.ssk,b.ssk) = 4 then 'Metal' end source_system_nm
			from 	src_metal a 
			full join src_edw b on a.iss_dt = b.iss_dt and a.ssk = b.ssk 
		) AS Source
		ON Target.transaction_start_dt = Source.iss_dt and Target.transaction_end_dt = Source.iss_dt 
		and Target.datamart_nm = Source.datamart_nm 
		and Target.source_system_nm = Source.source_system_nm 
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			transaction_start_dt,
			transaction_end_dt,
			source_record_ct,
			source_amt,
			target_record_ct,
			target_amt,
			datamart_nm,
			status_desc,
			source_system_nm,
			create_ts,
			update_ts
			)
		VALUES (Source.iss_dt,
				Source.iss_dt,
				Source.metal_ct, 
				Source.metal_prm, 
				Source.edw_ct,
				Source.edw_prm,
				source.datamart_nm,
				CASE WHEN source.metal_prm=source.edw_prm THEN 'Success' ELSE 'Failure' END,
				source.source_system_nm,
				getdate(),
				getdate())
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET 
			Target.source_record_ct=source.metal_ct,
			Target.source_amt=source.metal_prm,
			Target.target_record_ct=source.edw_ct,
			Target.target_amt=source.edw_prm,
			Target.status_desc=CASE WHEN source.metal_prm=source.edw_prm THEN 'Success' ELSE 'Failure' END,
			Target.update_ts=getdate()
		;

	   
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=cast(DATEADD(day, -7, getdate())  as date);
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

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