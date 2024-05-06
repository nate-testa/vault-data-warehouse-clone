-- =================================================================================================
-- Description: This procedures inserts into sp_tquote_history_wip
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------
-- 10/23/23		Architha Gudimalla				1. Created this procedure 
-- ===================================================================================================================== 

CREATE  OR ALTER  PROCEDURE [edw_core].[sp_tquote_history_wip]

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
        DROP TABLE IF EXISTS edw_temp.tquote_history_temp1
        SELECT  acc.id,
			acc.PolicyNumber,
			acc.EffectiveDate,
			acc.ExpirationDate,
			--acct.AccountId,
			CAST(brk.producerid AS VARCHAR(255)) as BrokerId,
			nullif(trim(isnull(br.firstname,'') + ' ' + isnull(br.LastName,'')),'') as producer_nm,
			CAST(ins.ReferenceCode AS VARCHAR(255)) as customer_id,
			ins.id as MasterInsuredId,
			0 as Number,
			DENSE_RANK()OVER(PARTITION BY acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) ORDER BY acc.UpdatedDate DESC) AS rnk, 
			case when acc.TransactionEffectiveDate is null then acc.EffectiveDate else acc.TransactionEffectiveDate end TransactionEffectiveDate,
			null CancellationReason, 
			acc.CreatedDate,
			acc.UpdatedDate, 
			ap.totalpremium wp,
			ap.commissionAmount comm,
			ap.totalpremium ap,
			0 tfs,
			--acct.totalpremium,
			--acct.totalpremiumdeltaprorated,
			--acct.totalpremiumdelta,
			--acct.commissiondelta , 
			--acct.commission , 
			coalesce(ap.CommissionPercent, 0) CommissionPercent, 
			coalesce(ap.CommissionPercentOverride, 0) CommissionPercentOverride, 
			ap.CommissionPercentOverrideRetention, null nottakenreason,
			'' policychangenotes, 
			--iif(acc.isrenewal=1,iif(acct.stage='POLICY','RENEWAL',acct.stage),acct.stage) stage,
			null reviewedbyid, null createdbyid,
				case when acc.ExternalSourceId is not NULL 
					 then 2 --(AV2) 
					 Else 4 --(Metal)
				end ssk,
				nullif(trim(pr.ProductCode),'') product_cd,
				usr.name uw_nm,'' note,
                acc.state, acc.isrenewal, null BindDate, null ReferredByUserId,
				pd.producer_sk 
		INTO edw_temp.tquote_history_temp1 --select acct.* 
		FROM edw_stage.Account acc   
        left join edw_stage.Accountpremium ap on ap.AccountId=acc.id  
		left join edw_stage.[user] usr on usr.id = acc.UnderwriterUserId 
		left join edw_stage.Brokerage brk on acc.BrokerageId = brk.id
		left join edw_stage.[Broker] br on acc.BrokerId = br.id
		left join edw_stage.Insured ins on acc.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acc.ProductId = pr.id
		LEFT JOIN edw_core.tproducer pd on pd.producer_id = acc.BrokerId
		WHERE --acct.Stage in ('QUOTE','POLICY')  and
			acc.PolicyNumber is not null 
		and pr.ProductLine = 'PersonalLines'  
		and not exists (select * from dbo.AccountTransaction actr where actr.AccountId=acc.id)
        and greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts 

		DROP TABLE IF EXISTS edw_temp.tquote_history_temp3
        SELECT acc.id, 
			sum(accptf.Amount) as tfs  
		INTO edw_temp.tquote_history_temp3 --select acct.* 
		FROM edw_stage.Account acc 
        left join edw_stage.Accountpremium ap on ap.AccountId=acc.id 
		INNER JOIN edw_stage.[AccountPremiumTaxAndFee] accptf on accptf.AccountPremiumId = ap.Id 
		left join edw_stage.Product pr on acc.ProductId = pr.id
		WHERE --acct.Stage in ('QUOTE','POLICY') and
			acc.PolicyNumber is not null 
		and pr.ProductLine = 'PersonalLines'  
		and not exists (select * from dbo.AccountTransaction actr where actr.AccountId=acc.id)
        and greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts 
		group by acc.id  

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tquote_history_temp2;
		SELECT	AccountId,  CompanionCreditHomeowner, CompanionCreditPersonalExcessLiability, CompanionCreditCollections, CompanionCreditAuto,
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
		INTO edw_temp.tquote_history_temp2
		FROM
			(				
				SELECT  acctvo.AccountId, 
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tquote_history_temp1 acc 
					INNER JOIN edw_stage.AccountObject acctvo ON acctvo.AccountId = acc.Id
					INNER JOIN edw_stage.AccountObjectField acctvof ON acctvof.ObjectId = acctvo.id
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

		-- Start Inserting records
		INSERT INTO edw_core.tquote_history 
			(quote_no
           ,effective_dt
           ,expiration_dt
           ,transaction_effective_dt
           ,transaction_seq_no
           ,quote_sk
           ,broker_sk
           ,customer_sk
		   ,product_sk
           ,broker_id
           ,customer_id
		   ,underwriter_nm
		   ,producer_nm
           ,transaction_type
           ,transaction_Status
           ,transaction_desc 
           --,transaction_ts
		   ,policy_change_summary
           ,premium_amt
           ,net_premium_amt
           ,[tax_fee_surcharge_amt]
           ,commission_amt
           ,annual_premium_amt 
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
		   ,transaction_created_ts
		   ,transaction_updated_ts
		   ,commission_pc,override_commission_pc,commission_retention,not_taken_reason_desc
		   ,[created_by_nm], [referred_by_nm], [reviewed_by_nm]
		   ,bind_dt
           --,[created_by_nm],[referred_by_nm],[reviewed_by_nm],[approval_note],[deny_note] --updated using seprate update proc
		   ,insurance_score
		   ,insurance_score_cd1
		   ,insurance_score_desc1
		   ,insurance_score_cd2
		   ,insurance_score_desc2
		   ,insurance_score_cd3
		   ,insurance_score_desc3
		   ,insurance_score_cd4
		   ,insurance_score_desc4
		   ,producer_sk
		   ,insurance_score_last_run_dt
		   )
		SELECT	Source.PolicyNumber, Source.EffectiveDate, Source.ExpirationDate, 
				Source.TransactionEffectiveDate, Source.Number, 
				q.quote_sk, br.broker_sk, cust.customer_sk,pr.product_sk, br.Broker_Id, 
				cast(source.customer_id as varchar)
				,source.uw_nm
				,source.producer_nm,
				case when source.IsRenewal = 1 then 'Renewal' else 'New' end as policy_term,  
				upper(substring(source.state,1,1)) + lower(substring(source.state, 2, len(source.state)-1))  ,
				source.note
				,source.policychangenotes,  
				wp, 
				wp-isnull(tfs.tfs,0),isnull(tfs.tfs,0),
				comm,
				ap,  
				source1.CompanionCreditCollections, source1.CompanionCreditPersonalExcessLiability, 
				source1.CompanionCreditAuto, source1.CompanionCreditHomeowner,
				ResidenceHasPrior, PriorResidenceAddressLine1, PriorResidenceAddressLine2, PriorResidenceAddressLineUnit, PriorResidenceAddressCity, 
				PriorResidenceAddressState, PriorResidenceAddressZipCode, PriorResidenceAddressCounty, PriorResidenceAddressCountry, 
				source.ssk, 
				getdate(), 
				getdate(), 
				@etl_audit_sk,
                Source.CreatedDate, 
				Source.UpdatedDate
				,source.CommissionPercent
				,source.CommissionPercentOverride
				,source.CommissionPercentOverrideRetention, source.nottakenreason
				, rfu.name as refname, cu.name crename, rvu.name revname
				,source.BindDate
				,source1.InsuranceScore
				,source1.InsuranceScoreCode1
				,source1.InsuranceScoreCode1Description
				,source1.InsuranceScoreCode2
				,source1.InsuranceScoreCode2Description
				,source1.InsuranceScoreCode3
				,source1.InsuranceScoreCode3Description
				,source1.InsuranceScoreCode4
				,source1.InsuranceScoreCode4Description
				,source.producer_sk
				,source1.InsuranceScoreLastRunDate
		FROM edw_temp.tquote_history_temp1 source
		LEFT JOIN edw_temp.tquote_history_temp3 tfs on source.id = tfs.id
		LEFT JOIN edw_temp.tquote_history_temp2 source1 on source.id = source1.AccountId 
		LEFT JOIN edw_core.tquote q on source.PolicyNumber = q.quote_no
		LEFT JOIN edw_core.tbroker br on cast(source.BrokerId as varchar)  = br.broker_id
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = source.product_cd 
		left join edw_core.tcustomer cust on cast(source.customer_id as varchar) = cust.customer_id
		--eft join edw_stage.[user] cu on cu.id = source.CreatedById    -- commented bedcause of no id
		--left join edw_stage.[user] rvu on rvu.id = source.ReviewedById -- commented bedcause of no id
		--left join edw_stage.[user] rfu on rfu.id = source.ReferredByUserId  -- commented bedcause of no id

		SET @rows_affected=@@ROWCOUNT;

		update h
		set latest_transaction_in = 'N'
		from edw_core.tquote_history h
		where exists (select 'x' from edw_temp.tquote_history_temp1 h1 where h.quote_no = h1.policynumber and h.effective_dt = cast(h1.EffectiveDate as date));

		update h
		set latest_transaction_in = 'Y'
		from edw_core.tquote_history h
		where exists (select 'x' from edw_temp.tquote_history_temp1 h1 
					  where h.quote_no = h1.policynumber 
					  and h.effective_dt = cast(h1.EffectiveDate as date) 
					  and h.transaction_seq_no = h1.Number and h1.rnk = 1);

		/*
		with max_tr as
		(
			select  policy_sk, max(transaction_seq_no) transaction_seq_no
			from edw_core.tquote_history h
			where exists (select 'x' from edw_temp.tquote_history_temp2 h1 where h.policy_no = h1.policynumber)
			group by policy_sk
		)
		update edw_core.tquote_history  
		set latest_transaction_in = 'Y'
		from edw_core.tquote_history h, max_tr 
		where h.policy_sk = max_tr.policy_sk
		and   h.transaction_seq_no = max_tr.transaction_seq_no;*/

		
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.tquote_history_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.tquote_history_temp1
        DROP TABLE IF EXISTS edw_temp.tquote_history_temp2
		
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

