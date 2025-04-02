SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-28
-- Description: This stored procedure insert and update info related to tcommercial_quote.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 31/03/2025           Alberto Almario				1. Created this procedure
-- ===================================================================================================================== 
CREATE  OR ALTER  PROCEDURE [edw_core].[sp_tcommercial_quote_history]

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

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp1
        SELECT acct.id,
			acct.PolicyNumber,
			acct.EffectiveDate,
			acct.ExpirationDate, 
			CAST(brk.producerid AS VARCHAR(255)) as BrokerId,
			nullif(trim(isnull(br.firstname,'') + ' ' + isnull(br.LastName,'')),'') as producer_nm,
			CAST(ins.ReferenceCode AS VARCHAR(255)) as customer_id,
			ins.id as MasterInsuredId,
			acct.Number,
			DENSE_RANK()OVER(PARTITION BY acct.PolicyNumber ORDER BY acct.UpdatedDate DESC, acct.Number DESC) AS rnk, 
			case when acct.TransactionEffectiveDate is null then acct.EffectiveDate else acct.TransactionEffectiveDate end TransactionEffectiveDate,
			acct.CancellationReason, 
			acct.CreatedDate,
			acct.UpdatedDate,  
			coalesce(acct.totalpremiumdeltaprorated,acct.totalpremium, 0) wp,
			coalesce(acct.commissiondelta,acct.commission,0) comm,
			coalesce(acct.totalpremiumdelta,acct.totalpremium,0) ap, 
			0 tfs,
			coalesce(acctvp.CommissionPercent, 0) CommissionPercent, 
			coalesce(acctvp.CommissionPercentOverride, 0) CommissionPercentOverride, 
			CommissionPercentOverrideRetention, nottakenreason,
			nullif(trim(acct.policychangenotes),'') policychangenotes, 
			acct.reviewedbyid, acct.createdbyid,
				case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end ssk,
				nullif(trim(pr.ProductCode),'') product_cd,
				usr.name uw_nm, nullif(trim(acct.note),'') note,
                acct.state, acc.isrenewal, acct.BindDate, acct.ReferredByUserId,
				pd.producer_sk,
				acctvprr.[Version] as premium_rater_version
		INTO edw_temp.tcommercial_quote_history_temp1
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.Account acc ON acct.AccountId = acc.Id 
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id 
		INNER JOIN edw_stage.AccountTransactionVersionPremium acctvp ON acctvp.AccountTransactionVersionId = acctv.Id 
		LEFT JOIN (SELECT * FROM edw_stage.AccountTransactionVersionPremiumRaterReference WHERE ReferenceType = 'Premium') acctvprr on acctvprr.AccountTransactionVersionPremiumId = acctvp.Id
		left join edw_stage.[user] usr on usr.id = acctv.UnderwriterUserId 
		left join edw_stage.Brokerage brk on acctv.BrokerageId = brk.id
		left join edw_stage.[Broker] br on acctv.BrokerId = br.id
		left join edw_stage.Insured ins on acctv.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acctv.ProductId = pr.id 
		--and pr.[InternalName] = acctvprr.ProductInternalName
		LEFT JOIN edw_core.tproducer pd on pd.producer_id = acctv.BrokerId
		WHERE acct.Stage in ('QUOTE','POLICY')
		and	acct.PolicyNumber is not null 
		and pr.ProductLine = 'CommercialLines' 		
		AND acct.CreatedDate > @last_source_extract_ts


		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp3
        SELECT acct.id, 
			sum(COALESCE (acctrtf.AmountDeltaProRated ,acctrtf.Amount)) as tfs  
		INTO edw_temp.tcommercial_quote_history_temp3
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id  
		inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = acct.Id 
		inner join edw_stage.[user] usr on usr.id = acctv.UnderwriterUserId
		left join edw_stage.Brokerage brk on acctv.BrokerageId = brk.id
		left join edw_stage.Insured ins on acctv.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acctv.ProductId = pr.id
		WHERE acct.Stage in ('QUOTE','POLICY')
		and	acct.PolicyNumber is not null 
		and pr.ProductLine = 'CommercialLines'  
		AND acct.CreatedDate > @last_source_extract_ts
		group by acct.id 

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp2;
		SELECT	AccountTransactionId,  CompanionCreditHomeowner, CompanionCreditPersonalExcessLiability, CompanionCreditCollections, CompanionCreditAuto,
				nullif(trim(PriorResidenceAddressLine1),'') PriorResidenceAddressLine1, 
				nullif(trim(PriorResidenceAddressLine2),'') PriorResidenceAddressLine2, 
				nullif(trim(PriorResidenceAddressLineUnit),'') PriorResidenceAddressLineUnit,  
				nullif(trim(PriorResidenceAddressCity),'') PriorResidenceAddressCity, 
				nullif(trim(PriorResidenceAddressState),'') PriorResidenceAddressState, 
				nullif(trim(PriorResidenceAddressZipCode),'') PriorResidenceAddressZipCode, 
				nullif(trim(PriorResidenceAddressCounty),'') PriorResidenceAddressCounty, 
				nullif(trim(PriorResidenceAddressCountry),'') PriorResidenceAddressCountry,
				ResidenceHasPrior,
				InsuranceScore,
				InsuranceScoreCode1,
				InsuranceScoreCode1Description,
				InsuranceScoreCode2,
				InsuranceScoreCode2Description,
				InsuranceScoreCode3,
				InsuranceScoreCode3Description,
				InsuranceScoreCode4,
				InsuranceScoreCode4Description,
				InsuranceScoreLastRunDate
		INTO edw_temp.tcommercial_quote_history_temp2
		FROM
			(
				SELECT  acctv.AccountTransactionId, 
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tcommercial_quote_history_temp1 acc
					INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id --acctv.AccountTransactionId = acc.Id
					INNER JOIN edw_stage.AccountTransactionVersionObject acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
					INNER JOIN edw_stage.AccountTransactionVersionObjectField acctvof ON acctvof.VersionObjectId = acctvo.id
				WHERE (COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') like '%comp%credit%'
				   or COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') like '%prior%'
				   or COALESCE(LTRIM(RTRIM(acctvof.Field)), '''') like '%InsuranceScore%')
				AND acctvo.ObjectType NOT IN ('Insured')
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (CompanionCreditHomeowner, CompanionCreditPersonalExcessLiability, CompanionCreditCollections, CompanionCreditAuto,
										 PriorResidenceAddressLine1, PriorResidenceAddressLine2, PriorResidenceAddressLineUnit, PriorResidenceAddressCity, 
										 PriorResidenceAddressState, PriorResidenceAddressZipCode, PriorResidenceAddressCounty, PriorResidenceAddressCountry, ResidenceHasPrior,
										 InsuranceScore,InsuranceScoreCode1,InsuranceScoreCode1Description,InsuranceScoreCode2,InsuranceScoreCode2Description,
										 InsuranceScoreCode3,InsuranceScoreCode3Description,InsuranceScoreCode4,InsuranceScoreCode4Description,InsuranceScoreLastRunDate)
			) pivottable 

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp4
		SELECT	
			 AccountTransactionId
			,[Rate Change] AS rate_change_pc
		INTO edw_temp.tcommercial_quote_history_temp4
		FROM
			(
				SELECT  
					 acctv.AccountTransactionId 
					,acctvps.Label
					,acctvps.Value
				FROM edw_temp.tcommercial_quote_history_temp1 acc
				INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acc.Id
				LEFT JOIN edw_stage.AccountTransactionVersionPremium AS acctvp ON acctvp.AccountTransactionVersionId = acctv.Id
				LEFT JOIN edw_stage.accounttransactionversionpremiumsummary AS acctvps ON acctvps.AccountTransactionVersionPremiumId = acctvp.id
				WHERE LTRIM(RTRIM(acctvps.Label)) IN ('Rate Change')
			) t
		PIVOT 
			(
				MAX(Value) FOR Label IN (
					[Rate Change]
					)
			) pivottable_2

		-- Create last temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp5;
		SELECT	
			 source.PolicyNumber as quote_no
			,source.EffectiveDate as effective_dt
			,source.ExpirationDate as expiration_dt
			,source.TransactionEffectiveDate as transaction_effective_dt
			,source.Number as transaction_seq_no
			,NULL as latest_transaction_in
			,q.commercial_quote_sk
			,br.broker_sk
			,cust.customer_sk
			,pr.product_sk
			,br.Broker_Id as broker_id
			,cast(source.customer_id as varchar) as customer_id
			,source.uw_nm as underwriter_nm
			,source.producer_nm
			,case when source.IsRenewal = 1 then 'Renewal' else 'New' end as transaction_type
			,upper(substring(source.state,1,1)) + lower(substring(source.state, 2, len(source.state)-1)) as transaction_status
			,source.nottakenreason as not_taken_reason_desc
			,source.CreatedDate as transaction_created_ts 
			,source.UpdatedDate as transaction_updated_ts
			,source.note as transaction_desc
			,source.BindDate as bind_dt
			,cu.name as created_by_nm
			,rfu.name as referred_by_nm
			,rvu.name as reviewed_by_nm
			,NULL as approval_note
			,NULL as deny_note
			,source.policychangenotes as policy_change_summary
			,source.wp as premium_amt
			,source.wp-isnull(tfs.tfs,0) as net_premium_amt
			,source.comm as commission_amt
			,source.ap as annual_premium_amt
			,source.CommissionPercent as commission_pc
			,source.CommissionPercentOverride as override_commission_pc
			,tmp4.rate_change_pc
			,source.producer_sk
			,source.premium_rater_version
			,source.ssk as source_system_sk
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
		INTO edw_temp.tcommercial_quote_history_temp5
		FROM edw_temp.tcommercial_quote_history_temp1 source
		LEFT JOIN edw_temp.tcommercial_quote_history_temp3 tfs on source.id = tfs.id
		LEFT JOIN edw_temp.tcommercial_quote_history_temp2 source1 on source.id = source1.AccountTransactionId 
		LEFT JOIN edw_temp.tcommercial_quote_history_temp4 tmp4 on tmp4.AccountTransactionId = source.id
		LEFT JOIN edw_commercial.tcommercial_quote q on source.PolicyNumber = q.quote_no and cast(source.EffectiveDate as date) = q.effective_dt
		LEFT JOIN edw_core.tbroker br on cast(source.BrokerId as varchar)  = br.broker_id
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = source.product_cd 
		left join edw_core.tcustomer cust on cast(source.customer_id as varchar) = cust.customer_id
		left join edw_stage.[user] cu on cu.id = source.CreatedById
		left join edw_stage.[user] rvu on rvu.id = source.ReviewedById 
		left join edw_stage.[user] rfu on rfu.id = source.ReferredByUserId 

		-- Start Inserting records
		INSERT INTO edw_commercial.tcommercial_quote_history 
		(
			 quote_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,latest_transaction_in
			,commercial_quote_sk
			,broker_sk
			,customer_sk
			,product_sk
			,broker_id
			,customer_id
			,underwriter_nm
			,producer_nm
			,transaction_type
			,transaction_status
			,not_taken_reason_desc
			,transaction_created_ts
			,transaction_updated_ts
			,transaction_desc
			,bind_dt
			,created_by_nm
			,referred_by_nm
			,reviewed_by_nm
			,approval_note
			,deny_note
			,policy_change_summary
			,premium_amt
			,net_premium_amt
			,commission_amt
			,annual_premium_amt
			,commission_pc
			,override_commission_pc
			,rate_change_pc
			,producer_sk
			,premium_rater_version
			,source_system_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		)
		SELECT
			 quote_no
			,effective_dt
			,expiration_dt
			,transaction_effective_dt
			,transaction_seq_no
			,latest_transaction_in
			,commercial_quote_sk
			,broker_sk
			,customer_sk
			,product_sk
			,broker_id
			,customer_id
			,underwriter_nm
			,producer_nm
			,transaction_type
			,transaction_status
			,not_taken_reason_desc
			,transaction_created_ts
			,transaction_updated_ts
			,transaction_desc
			,bind_dt
			,created_by_nm
			,referred_by_nm
			,reviewed_by_nm
			,approval_note
			,deny_note
			,policy_change_summary
			,premium_amt
			,net_premium_amt
			,commission_amt
			,annual_premium_amt
			,commission_pc
			,override_commission_pc
			,rate_change_pc
			,producer_sk
			,premium_rater_version
			,source_system_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		FROM edw_temp.tcommercial_quote_history_temp5;
		

		SET @rows_affected=@@ROWCOUNT;

		update h
		set latest_transaction_in = 'N'
		from edw_commercial.tcommercial_quote_history h
		where exists (select 'x' from edw_temp.tcommercial_quote_history_temp1 h1 where h.quote_no = h1.policynumber);

		update h
		set latest_transaction_in = 'Y'
		from edw_commercial.tcommercial_quote_history h
		where exists (select 'x' from edw_temp.tcommercial_quote_history_temp1 h1 
					  where h.quote_no = h1.policynumber 
					  and h.effective_dt = cast(h1.EffectiveDate as date) 
					  and h.transaction_seq_no = h1.Number and h1.rnk = 1);


		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.CreatedDate) FROM edw_temp.tcommercial_quote_history_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp1;
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp3;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp4;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_temp5;
		
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

