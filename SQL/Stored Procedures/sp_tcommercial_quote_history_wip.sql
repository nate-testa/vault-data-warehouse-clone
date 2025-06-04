-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-28
-- Description: This stored procedure insert and update info related to tcommercial_quote.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author									 |	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 03/04/25              Alberto Almario				  1. Created this procedure
-- 22/04/25           	 Alberto Almario				  2. Change PolicyNumber to Number from Account table
-- 06/04/25				 Yunus Mohammed		  		3. AD-9649 Update Merge statement join
-- ===================================================================================================================== 
CREATE  OR ALTER  PROCEDURE [edw_core].[sp_tcommercial_quote_history_wip]

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
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp1
        SELECT  acc.id,
			CAST(acc.Number AS VARCHAR(255)) as quote_no,
			acc.EffectiveDate,
			acc.ExpirationDate,
			--acct.AccountId,
			CAST(brk.producerid AS VARCHAR(255)) as BrokerId,
			nullif(trim(isnull(br.firstname,'') + ' ' + isnull(br.LastName,'')),'') as producer_nm,
			CAST(ins.ReferenceCode AS VARCHAR(255)) as customer_id,
			ins.id as MasterInsuredId,
			0 as transaction_seq_no,
			DENSE_RANK()OVER(PARTITION BY acc.Number,CAST(acc.EffectiveDate AS DATE) ORDER BY acc.UpdatedDate DESC) AS rnk, 
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
                acc.state, acc.isrenewal, CAST(null AS DATE) BindDate, null ReferredByUserId,
				pd.producer_sk ,
				arr.[Version] as premium_rater_version
		INTO edw_temp.tcommercial_quote_history_wip_temp1 --select acct.* 
		FROM edw_stage.Account acc   
        left join edw_stage.Accountpremium ap on ap.AccountId=acc.id  
		left join edw_stage.[user] usr on usr.id = acc.UnderwriterUserId 
		left join edw_stage.Brokerage brk on acc.BrokerageId = brk.id
		left join edw_stage.[Broker] br on acc.BrokerId = br.id
		left join edw_stage.Insured ins on acc.PrimaryInsuredID = ins.Id
		left join edw_stage.Product pr on acc.ProductId = pr.id
		LEFT JOIN edw_core.tproducer pd on pd.producer_id = acc.BrokerId
		LEFT JOIN (SELECT * FROM edw_stage.AccountRaterReference WHERE ReferenceType = 'Premium') arr on arr.AccountId = acc.ID	
		and pr.[InternalName] = arr.ProductInternalName  
		WHERE pr.ProductLine = 'CommercialLines'
		and not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
        and greatest(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts 

		-- Exit if there is no data in the temp table 1.
		IF NOT EXISTS (SELECT * FROM edw_temp.tcommercial_quote_history_wip_temp1)
		BEGIN
			SET @parameter_desc = @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@last_source_extract_ts AS VARCHAR(200));
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk, 0, @parameter_desc;
			RETURN;
		END

		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp3
        SELECT acc.id, 
			sum(accptf.Amount) as tfs  
		INTO edw_temp.tcommercial_quote_history_wip_temp3 --select acct.* 
		FROM edw_stage.Account acc 
        left join edw_stage.Accountpremium ap on ap.AccountId=acc.id 
		INNER JOIN edw_stage.[AccountPremiumTaxAndFee] accptf on accptf.AccountPremiumId = ap.Id 
		left join edw_stage.Product pr on acc.ProductId = pr.id		
		WHERE pr.ProductLine = 'CommercialLines'  
		and not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
        and greatest(acc.CreatedDate,acc.UpdatedDate)>@last_source_extract_ts 
		group by acc.id  

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp2;
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
		INTO edw_temp.tcommercial_quote_history_wip_temp2
		FROM
			(				
				SELECT  acctvo.AccountId, 
						acctvof.Field, 
						acctvof.Value
				FROM edw_temp.tcommercial_quote_history_wip_temp1 acc 
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

		-- Pivot Table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp4
		SELECT	
			 AccountId
			,[Rate Change] AS rate_change_pc
		INTO edw_temp.tcommercial_quote_history_wip_temp4
		FROM
			(
				SELECT  
					 acc.Id AS AccountId 
					,acctvps.Label
					,acctvps.Value
				FROM edw_temp.tcommercial_quote_history_wip_temp1 acc
				LEFT JOIN edw_stage.AccountPremium AS acctvp ON acctvp.AccountId = acc.Id
				LEFT JOIN edw_stage.accountpremiumsummary AS acctvps ON acctvps.AccountPremiumId = acctvp.id
				WHERE LTRIM(RTRIM(acctvps.Label)) IN ('Rate Change')
			) t
		PIVOT 
			(
				MAX(Value) FOR Label IN (
					[Rate Change]
					)
			) pivottable_2 

		

		-- Create last temp table
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp5;
		SELECT	
			 source.quote_no
			,source.EffectiveDate as effective_dt
			,source.ExpirationDate as expiration_dt
			,source.TransactionEffectiveDate as transaction_effective_dt
			,source.transaction_seq_no
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
			,source.wp - isnull(source.comm,0) as net_premium_amt
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
		INTO edw_temp.tcommercial_quote_history_wip_temp5
		FROM edw_temp.tcommercial_quote_history_wip_temp1 source
		LEFT JOIN edw_temp.tcommercial_quote_history_wip_temp3 tfs on source.id = tfs.id
		LEFT JOIN edw_temp.tcommercial_quote_history_wip_temp2 source1 on source.id = source1.AccountId 
		LEFT JOIN edw_temp.tcommercial_quote_history_wip_temp4 tmp4 on tmp4.AccountId = source.id
		LEFT JOIN edw_commercial.tcommercial_quote q on source.quote_no = q.quote_no and cast(source.EffectiveDate as date) = q.effective_dt
		LEFT JOIN edw_core.tbroker br on cast(source.BrokerId as varchar(255))  = br.broker_id
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = source.product_cd 
		left join edw_core.tcustomer cust on cast(source.customer_id as varchar(255)) = cust.customer_id
		left join edw_stage.[user] cu on cast(cu.id as varchar(255)) = cast(source.CreatedById as varchar(255))
		left join edw_stage.[user] rvu on cast(rvu.id as varchar(255)) = cast(source.ReviewedById as varchar(255)) 
		left join edw_stage.[user] rfu on cast(rfu.id as varchar(255)) = cast(source.ReferredByUserId as varchar(255))

		-- Start Merge process
		MERGE edw_commercial.tcommercial_quote_history AS Target
		USING 
		edw_temp.tcommercial_quote_history_wip_temp5 AS Source	
		ON Source.quote_no = Target.quote_no  and Source.transaction_seq_no = Target.transaction_seq_no
		AND (
						(Source.quote_term = 'New'  AND YEAR(Target.effective_dt) = YEAR(Source.effective_dt))
						OR
						(Source.quote_term != 'New'  AND Target.effective_dt = Source.effective_dt)
    			)
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN 
		INSERT 
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
		VALUES (
			 Source.quote_no
			,Source.effective_dt
			,Source.expiration_dt
			,Source.transaction_effective_dt
			,Source.transaction_seq_no
			,Source.latest_transaction_in
			,Source.commercial_quote_sk
			,Source.broker_sk
			,Source.customer_sk
			,Source.product_sk
			,Source.broker_id
			,Source.customer_id
			,Source.underwriter_nm
			,Source.producer_nm
			,Source.transaction_type
			,Source.transaction_status
			,Source.not_taken_reason_desc
			,Source.transaction_created_ts
			,Source.transaction_updated_ts
			,Source.transaction_desc
			,Source.bind_dt
			,Source.created_by_nm
			,Source.referred_by_nm
			,Source.reviewed_by_nm
			,Source.approval_note
			,Source.deny_note
			,Source.policy_change_summary
			,Source.premium_amt
			,Source.net_premium_amt
			,Source.commission_amt
			,Source.annual_premium_amt
			,Source.commission_pc
			,Source.override_commission_pc
			,Source.rate_change_pc
			,Source.producer_sk
			,Source.premium_rater_version
			,Source.source_system_sk
			,Source.create_ts
			,Source.update_ts
			,Source.etl_audit_sk
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        	 Target.quote_no = Source.quote_no
			,Target.effective_dt = Source.effective_dt
			,Target.expiration_dt = Source.expiration_dt
			,Target.transaction_effective_dt = Source.transaction_effective_dt
			,Target.transaction_seq_no = Source.transaction_seq_no
			,Target.latest_transaction_in = Source.latest_transaction_in
			,Target.commercial_quote_sk = Source.commercial_quote_sk
			,Target.broker_sk = Source.broker_sk
			,Target.customer_sk = Source.customer_sk
			,Target.product_sk = Source.product_sk
			,Target.broker_id = Source.broker_id
			,Target.customer_id = Source.customer_id
			,Target.underwriter_nm = Source.underwriter_nm
			,Target.producer_nm = Source.producer_nm
			,Target.transaction_type = Source.transaction_type
			,Target.transaction_status = Source.transaction_status
			,Target.not_taken_reason_desc = Source.not_taken_reason_desc
			,Target.transaction_created_ts = Source.transaction_created_ts
			,Target.transaction_updated_ts = Source.transaction_updated_ts
			,Target.transaction_desc = Source.transaction_desc
			,Target.bind_dt = Source.bind_dt
			,Target.created_by_nm = Source.created_by_nm
			,Target.referred_by_nm = Source.referred_by_nm
			,Target.reviewed_by_nm = Source.reviewed_by_nm
			,Target.approval_note = Source.approval_note
			,Target.deny_note = Source.deny_note
			,Target.policy_change_summary = Source.policy_change_summary
			,Target.premium_amt = Source.premium_amt
			,Target.net_premium_amt = Source.net_premium_amt
			,Target.commission_amt = Source.commission_amt
			,Target.annual_premium_amt = Source.annual_premium_amt
			,Target.commission_pc = Source.commission_pc
			,Target.override_commission_pc = Source.override_commission_pc
			,Target.rate_change_pc = Source.rate_change_pc
			,Target.producer_sk = Source.producer_sk
			,Target.premium_rater_version = Source.premium_rater_version
			,Target.source_system_sk = Source.source_system_sk
			,Target.update_ts = getdate()
		; 

		SET @rows_affected=@@ROWCOUNT;  

		
		update h
		set latest_transaction_in='Y'
		from edw_commercial.tcommercial_quote_history h
		where not exists (select * from edw_commercial.tcommercial_quote_history h1 where h1.commercial_quote_sk = h.commercial_quote_sk and latest_transaction_in='Y')
		and exists (select commercial_quote_sk from edw_commercial.tcommercial_quote_history h2 where h2.commercial_quote_sk = h.commercial_quote_sk and isnull(latest_transaction_in,'N')='N')
		and transaction_seq_no = 0;
		
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.tcommercial_quote_history_wip_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp1;
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp3;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp4;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_history_wip_temp5;
		
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

