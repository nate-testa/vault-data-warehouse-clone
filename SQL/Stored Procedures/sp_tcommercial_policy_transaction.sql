SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-26
-- Description: This stored procedure insert and update info related to tcommercial_policy_transaction.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 26/03/2025           Alberto Almario				1. Created this procedure 
-- ===================================================================================================================== 
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tcommercial_policy_transaction]

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

		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp1;
		-- Step1 limit amount of rows.
		SELECT
			acctr.*,
			case when acctr.ExternalSourceId is not NULL then 2--(AV2) 
				 Else 4 --(Metal)
			end ssk , pr.productcode
		INTO edw_temp.tcommercial_policy_transaction_temp1
		FROM edw_stage.AccountTransaction acctr
		left join edw_stage.Product pr on acctr.ProductId = pr.id
		WHERE PolicyNumber is not null 
		  and acctr.State ='ISSUED' --- Review BOUND transactions
		  and pr.ProductLine='CommercialLines'
		  AND acctr.IssuedDate>@last_source_extract_ts

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp2
        SELECT 
			tmp1.PolicyNumber,
			case when tmp1.productcode = 'AU' then acctrvo.[UniqueId] else null end as vehicle_unique_id,
			tmp1.ProductId,
			tmp1.EffectiveDate,
			tmp1.ExpirationDate, 
			--acc.BrokerId,
			--acc.MasterInsuredId,
			tmp1.PolicyChangeNumber,
			tmp1.Commission,
			tmp1.TransactionEffectiveDate,
			tmp1.IssuedDate,
			tmp1.CancellationReason,
			tmp1.CreatedDate,
			iif(tmp1.TransactionEffectiveDate > tmp1.IssuedDate, tmp1.TransactionEffectiveDate, tmp1.IssuedDate) cal_mn,
			tmp1.UpdatedDate,
			iif(acct.RenewalIndex<>0,iif(tmp1.stage = 'POLICY','RENEWAL',tmp1.stage),tmp1.stage) as stage, 
			acctrcp.Coverage ,acctrcp.label,
			COALESCE (acctrcp.PremiumDeltaProRated ,premium) as wp, 
			COALESCE (acctrcp.Premiumdelta ,premium) as ap,
			COALESCE (acctrcp.CommissionDeltaProRated ,acctrcp.commission) as comm,
			0 as tfs, tmp1.ssk, 'prm' typ,
			COALESCE(acctrcp.CededPremiumDelta,acctrcp.CededPremium) as ceded_annual_premium_amt,
			COALESCE(acctrcp.CededPremiumDeltaProRated,acctrcp.CededPremium) as ceded_premium_amt,
			null covID
			,tmp1.ReviewedById
			,tmp1.CreatedById
		INTO edw_temp.tcommercial_policy_transaction_temp2  
		FROM edw_temp.tcommercial_policy_transaction_temp1 tmp1 
		inner join edw_stage.Account acct on acct.id = tmp1.AccountId
		inner join edw_stage.AccountTransactionCoveragePremium acctrcp on acctrcp.AccountTransactionId = tmp1.Id
		left join edw_stage.AccountTransactionVersionObject acctrvo on acctrcp.objectid=acctrvo.id 
		--where premium!=0  
		union all
		SELECT 
			tmp1.PolicyNumber,
			null vehicle_unique_id,
			tmp1.ProductId,
			tmp1.EffectiveDate,
			tmp1.ExpirationDate, 
			--acc.BrokerId,
			--acc.MasterInsuredId,
			tmp1.PolicyChangeNumber,
			tmp1.Commission,
			tmp1.TransactionEffectiveDate,
			tmp1.IssuedDate,
			tmp1.CancellationReason,
			tmp1.CreatedDate,
			iif(tmp1.TransactionEffectiveDate > tmp1.IssuedDate, tmp1.TransactionEffectiveDate, tmp1.IssuedDate) cal_mn,
			tmp1.UpdatedDate,
			iif(acct.RenewalIndex<>0,iif(tmp1.stage = 'POLICY','RENEWAL',tmp1.stage),tmp1.stage) as stage,  
			--ROW_NUMBER() OVER (PARTITION BY tmp1.PolicyNumber, tmp1.EffectiveDate, tmp1.PolicyChangeNumber ORDER BY tmp1.CreatedDate DESC) AS PolicyNumber_Rank,
			acctrtf.Name, '',
			COALESCE (acctrtf.AmountDeltaProRated ,acctrtf.Amount) as wp, 
			COALESCE (acctrtf.AmountDelta  ,acctrtf.Amount) as ap, 
			0 as comm ,
			COALESCE (acctrtf.AmountDeltaProRated ,acctrtf.Amount) as tfs, tmp1.ssk, 'tfs' typ,
			0 as ceded_annual_premium_amt,
			0 as ceded_premium_amt,
			cov.Name covID
			,tmp1.ReviewedById
			,tmp1.CreatedById
		FROM edw_temp.tcommercial_policy_transaction_temp1 tmp1 
		inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = tmp1.Id 
		inner join edw_stage.Account acct on acct.id = tmp1.AccountId
		left join edw_stage.coverage cov on cov.id = acctrtf.coverageid
		
		--Create last temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp3
		SELECT
			 pol.commercial_policy_sk
			,polh.commercial_policy_history_sk
			,dt1.date_sk as effective_dt_sk
			,dt2.date_sk as expiration_dt_sk
			,dt3.date_sk as transaction_effective_dt_sk
			,Source.PolicyChangeNumber as transaction_seq_no
			,br.broker_sk
			,cust.customer_sk
			,source.wp as premium_amt
			,source.wp - source.tfs as net_premium_amt
			,Source.comm as commission_amt
			,source.ap as annual_premium_amt
			,cpc.commercial_policy_coverage_sk as coverage_sk
			,dt4.date_sk as transaction_dt_sk
			,(select max(date_sk) from edw_core.tdate where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) as calendar_month_sk
			,(select max(date_sk) from edw_core.tdate where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) as accounting_month_sk
			,pr.product_sk
			,isnull(tt.policy_transaction_type_sk,0) as policy_transaction_type_sk
			,source.ssk as source_system_sk
			,case when isnull(tt.policy_transaction_type_sk,0) = 5 then 2 else 1 end as policy_status_sk
			,u.user_sk
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,source.PolicyNumber
			,source.EffectiveDate
		INTO edw_temp.tcommercial_policy_transaction_temp3
		FROM edw_temp.tcommercial_policy_transaction_temp2 source
		LEFT JOIN edw_core.tdate dt1 on dt1.actual_dt = cast(source.EffectiveDate as date)
		LEFT JOIN edw_core.tdate dt2 on dt2.actual_dt = cast(source.ExpirationDate as date)
		LEFT JOIN edw_core.tdate dt3 on dt3.actual_dt = cast(source.TransactionEffectiveDate as date)
		LEFT JOIN edw_core.tdate dt4 on dt4.actual_dt = cast(source.IssuedDate as date)
		LEFT JOIN edw_core.tdate dt5 on dt5.actual_dt = cast(source.cal_mn as date)
		LEFT JOIN edw_commercial.tcommercial_policy pol on source.PolicyNumber = pol.policy_no and cast(source.EffectiveDate as date) = cast(pol.effective_dt as date)
		LEFT JOIN edw_commercial.tcommercial_policy_history polh on polh.commercial_policy_sk = pol.commercial_policy_sk and polh.transaction_seq_no = source.PolicyChangeNumber
		LEFT JOIN edw_commercial.tcommercial_policy_coverage cpc on source.PolicyNumber = cpc.policy_no and cast(source.EffectiveDate as date) = cast(cpc.effective_dt as date) and source.PolicyChangeNumber = cpc.transaction_seq_no
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = pol.product_cd
		LEFT JOIN edw_core.tbroker br on pol.broker_id = br.broker_id
		LEFT JOIN edw_core.tcustomer cust on pol.customer_id = cust.customer_id
		LEFT JOIN edw_core.tinternal_coverage ic on ic.internal_coverage_desc = (case when source.typ = 'prm' then source.label else source.coverage end) 
												and (case when source.coverage in ('Subscriber Contribution',
																				   'Legislative Fire Marshal Assessment Discount of 1.00% pursuant to section 624.5108(1)(b), F.S',
																				   'Legislative Premium Tax Discount of 1.75% pursuant to section 624.5108(1)(a), F.S'
																				  ) and source.covID = 'Lux' then 'LUX' else pr.product_cd end) = ic.product_cd  
		--LEFT JOIN edw_core.tinternal_coverage tfs on tfs.internal_coverage_desc = source.coverage and source.typ <> 'prm' and (pr.product_cd = tfs.product_cd)    
		LEFT JOIN edw_core.tinternal_coverage tfs on tfs.internal_coverage_desc = source.coverage and source.typ <> 'prm' 
													and (case when source.coverage in ('Subscriber Contribution',
																						'Legislative Fire Marshal Assessment Discount of 1.00% pursuant to section 624.5108(1)(b), F.S',
																						'Legislative Premium Tax Discount of 1.75% pursuant to section 624.5108(1)(a), F.S'
																						) and source.covID = 'Lux' then 'LUX' else pr.product_cd end = tfs.product_cd)    
		LEFT JOIN edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_cd = source.stage  
		left join edw_core.tcollection_class_type cc on 	pol.policy_no = cc.policy_no and pol.effective_dt = cc.effective_dt and Source.PolicyChangeNumber = cc.transaction_seq_no 
														and case 	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Music' then 'Musical Instruments' 
																	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Fine Arts' then 'Fine Art' 
																	else replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')
																end = cc.class_type  
		left join edw_core.tuser u on u.user_id = CASE WHEN source.ReviewedById IS NOT NULL and source.ReviewedById <> '00000000-0000-0000-0000-000000000000' THEN source.ReviewedById ELSE source.CreatedById END

		
		-- Start Inserting records
		INSERT INTO edw_commercial.tcommercial_policy_transaction 
		(
			 commercial_policy_sk
			,commercial_policy_history_sk
			,effective_dt_sk
			,expiration_dt_sk
			,transaction_effective_dt_sk
			,transaction_seq_no
			,broker_sk
			,customer_sk
			,premium_amt
			,net_premium_amt
			,commission_amt
			,annual_premium_amt
			,coverage_sk
			,transaction_dt_sk
			,calendar_month_sk
			,accounting_month_sk
			,product_sk
			,policy_transaction_type_sk
			,source_system_sk
			,policy_status_sk
			,user_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT
			 commercial_policy_sk
			,commercial_policy_history_sk
			,effective_dt_sk
			,expiration_dt_sk
			,transaction_effective_dt_sk
			,transaction_seq_no
			,broker_sk
			,customer_sk
			,premium_amt
			,net_premium_amt
			,commission_amt
			,annual_premium_amt
			,coverage_sk
			,transaction_dt_sk
			,calendar_month_sk
			,accounting_month_sk
			,product_sk
			,policy_transaction_type_sk
			,source_system_sk
			,policy_status_sk
			,user_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		FROM edw_temp.tcommercial_policy_transaction_temp3
		
		SET @rows_affected=@@ROWCOUNT;  
		
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.tcommercial_policy_transaction_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp1
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp2
		DROP TABLE IF EXISTS edw_temp.tcommercial_policy_transaction_temp3
		
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
