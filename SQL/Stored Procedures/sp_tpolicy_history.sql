-- =================================================================================================
-- Author:		Hernando Gonzalez Garcia  
-- Description: This procedures inserts into TPolicy_history
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23		Hernando Gonzalez Garcia		1. Created this procedure
-- 06/28/23		Architha Gudimalla				2. Made changes to fix the errors on first run 
-- 09/08/23		Architha Gudimalla				3. Made changes for updated model 
-- 10/06/23		Architha Gudimalla				4. Added commission override columns
-- 10/10/23		Architha Gudimalla				5. Updated logic for transaction_type - renewals
-- 10/17/23		Architha Gudimalla				6. Updated logic for transaction_desc
-- 10/17/23		Architha Gudimalla				7. Updated logic for producer_nm
-- 10/26/23		Yunus Mohammed					7. Made changes to fix error on customer_id and broker_id
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_history]

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
        DROP TABLE IF EXISTS edw_temp.tpolicy_history_temp1
        SELECT acct.id,
			acct.PolicyNumber,
			acct.EffectiveDate,
			acct.ExpirationDate, 
			--acct.AccountId,
			CAST(brk.producerid AS VARCHAR(255)) as BrokerId,
			nullif(trim(isnull(br.firstname,'') + ' ' + isnull(br.LastName,'')),'') as producer_nm,			
			CAST(ins.ReferenceCode AS VARCHAR(255)) as customer_id,
			ins.id as MasterInsuredId,
			acct.PolicyChangeNumber,
			DENSE_RANK()OVER(PARTITION BY acct.PolicyNumber,CAST(acct.EffectiveDate AS DATE) ORDER BY acct.policychangenumber DESC) AS rnk, 
			acct.TransactionEffectiveDate,
			acct.CancellationReason,
			acct.IssuedDate,
			acct.UpdatedDate,  
			coalesce(acct.totalpremiumdeltaprorated,acct.totalpremium, 0) wp,
			coalesce(acct.commissiondelta,acct.commission,0) comm,
			coalesce(acct.totalpremiumdelta,acct.totalpremium,0) ap, 
			0 tfs,
			--acct.totalpremium,
			--acct.totalpremiumdeltaprorated,
			--acct.totalpremiumdelta,
			--acct.commissiondelta , 
			--acct.commission , 
			coalesce(acctvp.CommissionPercent, 0) CommissionPercent, 
			coalesce(acctvp.CommissionPercentOverride, 0) CommissionPercentOverride, 
			CommissionPercentOverrideRetention, 
			nullif(trim(acct.policychangenotes),'') policychangenotes, 
			iif(acc.isrenewal=1,iif(acct.stage='POLICY','RENEWAL',acct.stage),acct.stage) stage,
			acct.reviewedbyid, acct.createdbyid,
				case when acct.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end ssk,
				nullif(trim(pr.ProductCode),'') product_cd,
				usr.name uw_nm, nullif(trim(acct.note),'') note
		INTO edw_temp.tpolicy_history_temp1 --select acct.* 
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.Account acc ON acct.AccountId = acc.Id 
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id 
		INNER JOIN edw_stage.AccountTransactionVersionPremium acctvp ON acctvp.AccountTransactionVersionId = acctv.Id 
		left join edw_stage.[user] usr on usr.id = acctv.UnderwriterUserId 
		left join edw_stage.Brokerage brk on acctv.BrokerageId = brk.id
		left join edw_stage.[Broker] br on acctv.BrokerId = br.id
		left join edw_stage.Insured ins on acctv.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acctv.ProductId = pr.id
		WHERE acct.State ='ISSUED' --- Review BOUND transactions
		and	acct.PolicyNumber is not null 
		and pr.ProductLine = 'PersonalLines'  
		AND acct.IssuedDate>@last_source_extract_ts


		DROP TABLE IF EXISTS edw_temp.tpolicy_history_temp3
        SELECT acct.id, 
			sum(COALESCE (acctrtf.AmountDeltaProRated ,acctrtf.Amount)) as tfs  
		INTO edw_temp.tpolicy_history_temp3 --select acct.* 
		FROM edw_stage.AccountTransaction acct 
		INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id  
		inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = acct.Id 
		inner join edw_stage.[user] usr on usr.id = acctv.UnderwriterUserId
		left join edw_stage.Brokerage brk on acctv.BrokerageId = brk.id
		left join edw_stage.Insured ins on acctv.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acctv.ProductId = pr.id
		WHERE acct.State ='ISSUED' --- Review BOUND transactions
		and	acct.PolicyNumber is not null 
		and pr.ProductLine = 'PersonalLines'  
		AND acct.IssuedDate>@last_source_extract_ts
		group by acct.id 

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tpolicy_history_temp2;
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
				InsuranceScoreCode4Description
		INTO edw_temp.tpolicy_history_temp2
		FROM
			(
				SELECT  acctv.AccountTransactionId, 
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tpolicy_history_temp1 acc
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
										 InsuranceScoreCode3,InsuranceScoreCode3Description,InsuranceScoreCode4,InsuranceScoreCode4Description)
			) pivottable 

		-- Start Inserting records
		INSERT INTO edw_core.tpolicy_history 
			(policy_no
           ,effective_dt
           ,expiration_dt
           ,transaction_effective_dt
           ,transaction_seq_no
           ,policy_sk
           ,broker_sk
           ,customer_sk
           ,broker_id
           ,customer_id
           ,transaction_type
           ,transaction_ts
           ,transaction_desc
           ,cancellation_reason_desc
           ,premium_amt
           ,net_premium_amt
           ,[tax_fee_surcharge_amt]
           ,commission_amt
           ,annual_premium_amt 
           ,transaction_initiated_by
           ,transaction_issued_by
           ,collection_policy_credit_in
           ,excess_liability_policy_credit_in
           ,auto_policy_credit_in
           ,home_policy_credit_in
           ,prior_address_in, prior_address_line_1, prior_address_line_2, prior_address_unit_no,
           prior_address_city_nm, prior_address_state_cd, prior_address_zip_cd, prior_address_county_nm, prior_address_country_nm
           ,source_system_sk
           ,create_ts
           ,update_ts
           ,etl_audit_sk
		   ,underwriter_nm
		   ,producer_nm
		   ,product_sk
		   ,policy_change_summary
		   ,commission_pc,override_commission_pc,commission_retention
		   ,insurance_score
		   ,insurance_score_cd1
		   ,insurance_score_desc1
		   ,insurance_score_cd2
		   ,insurance_score_desc2
		   ,insurance_score_cd3
		   ,insurance_score_desc3
		   ,insurance_score_cd4
		   ,insurance_score_desc4
		   )
		SELECT	Source.PolicyNumber, Source.EffectiveDate, Source.ExpirationDate, Source.TransactionEffectiveDate, Source.PolicyChangeNumber, 
				pol.policy_sk, br.broker_sk, cust.customer_sk, br.Broker_Id, Source.customer_id, 
				tt.policy_transaction_type_nm, Source.IssuedDate, source.note, Source.CancellationReason, 
				wp, 
				wp-isnull(tfs.tfs,0),isnull(tfs.tfs,0),
				comm,
				ap, 
				rid.Name, cid.Name, 
				source1.CompanionCreditCollections, source1.CompanionCreditPersonalExcessLiability, 
				source1.CompanionCreditAuto, source1.CompanionCreditHomeowner,
				ResidenceHasPrior, PriorResidenceAddressLine1, PriorResidenceAddressLine2, PriorResidenceAddressLineUnit, PriorResidenceAddressCity, 
				PriorResidenceAddressState, PriorResidenceAddressZipCode, PriorResidenceAddressCounty, PriorResidenceAddressCountry, 
				source.ssk, getdate(), getdate(), @etl_audit_sk
				,source.uw_nm
				,source.producer_nm
				,pr.product_sk
				,source.policychangenotes
				,source.CommissionPercent
				,source.CommissionPercentOverride
				,source.CommissionPercentOverrideRetention
				,source.InsuranceScore
				,source.InsuranceScoreCode1
				,source.InsuranceScoreCode1Description
				,source.InsuranceScoreCode2
				,source.InsuranceScoreCode2Description
				,source.InsuranceScoreCode3
				,source.InsuranceScoreCode3Description
				,source.InsuranceScoreCode4
				,source.InsuranceScoreCode4Description
		FROM edw_temp.tpolicy_history_temp1 source
		LEFT JOIN edw_temp.tpolicy_history_temp3 tfs on source.id = tfs.id
		LEFT JOIN edw_temp.tpolicy_history_temp2 source1 on source.id = source1.AccountTransactionId
	    left join edw_stage.[user] cid on source.createdbyid = cid.Id
	    left join edw_stage.[user] rid on source.reviewedbyid = rid.Id
		LEFT JOIN edw_core.tpolicy pol on source.PolicyNumber = pol.policy_no and cast(source.EffectiveDate as date)=pol.effective_dt
		LEFT JOIN edw_core.tbroker br on source.BrokerId = br.broker_id 
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = source.product_cd 
		left join edw_core.tcustomer cust on source.customer_id = cust.customer_id
		LEFT JOIN edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_cd = source.stage

		SET @rows_affected=@@ROWCOUNT;

		update h
		set latest_transaction_in = 'N'
		from edw_core.tpolicy_history h
		where exists (select 'x' from edw_temp.tpolicy_history_temp1 h1 where h.policy_no = h1.policynumber and h.effective_dt = cast(h1.EffectiveDate as date));

		update h
		set latest_transaction_in = 'Y'
		from edw_core.tpolicy_history h
		where exists (select 'x' from edw_temp.tpolicy_history_temp1 h1 
					  where h.policy_no = h1.policynumber 
					  and h.effective_dt = cast(h1.EffectiveDate as date) 
					  and h.transaction_seq_no = h1.PolicyChangeNumber and h1.rnk = 1);

		/*
		with max_tr as
		(
			select  policy_sk, max(transaction_seq_no) transaction_seq_no
			from edw_core.tpolicy_history h
			where exists (select 'x' from edw_temp.tpolicy_history_temp2 h1 where h.policy_no = h1.policynumber)
			group by policy_sk
		)
		update edw_core.tpolicy_history  
		set latest_transaction_in = 'Y'
		from edw_core.tpolicy_history h, max_tr 
		where h.policy_sk = max_tr.policy_sk
		and   h.transaction_seq_no = max_tr.transaction_seq_no;*/

		
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.tpolicy_history_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.tpolicy_history_temp1
        DROP TABLE IF EXISTS edw_temp.tpolicy_history_temp2
		
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

