-- ===================================================================================================================================================
-- Author:		Hernando Gonzalez Garcia  
-- Description: This procedures inserts into TPolicy_Transaction  
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- 06/02/23		Hernando Gonzalez Garcia		1. Created this procedure
-- 06/28/23		Architha Gudimalla				2. Made changes to fix the errors on first run
-- 06/29/23		Architha Gudimalla				3. Updated to add the premiums at coverage level
-- 07/05/23		Architha Gudimalla				4. Updated the logic for item_sk, coverage_sk
-- 07/06/23		Architha Gudimalla				5. Updated the logic for cal_mn and acc_mn
-- 09/18/23		Sandeep Gundreddy				6. Updated the logic for cal_mn and policy_transaction_type_sk
-- 09/27/23		Mohammed Yunus					7. Added HSB Ceded Premium cols and updated logic to convert renewal transaction
-- 10/02/23		Architha Gudimalla				8. Added logic for AU vehicle level premium
-- 10/05/23		Architha Gudimalla				9. Moved out updates at the end to another proc
--												   Removed pel loc join
--												   Corrected ceded premium
-- 10/13/23		Architha Gudimalla				10. corrected transaction_type_sk logic
-- 10/31/23		Architha Gudimalla				11. Added tfs_sk to the insert
-- 11/06/23		Alberto Almario					12. change to use UniqueId instead of Index and change name from vehicle_no to vehicle_unique_id
-- 11/10/23		Architha Gudimalla				13. Corrected cal_mn for tfs temp table
-- 12/11/23		Architha Gudimalla				14. Updated logic for source.stage (used as transaction type)
-- 02/14/24		Architha Gudimalla				15. Updated logic for Lux subscriber contributoin on ho
-- ====================================================================================================================================================== 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_tpolicy_transaction]

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

		DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_temp1;
		-- Step1 limit amount of rows.
		SELECT
			acctr.*,
			case when acctr.ExternalSourceId is not NULL then 2--(AV2) 
				 Else 4 --(Metal)
			end ssk , pr.productcode
		INTO edw_temp.tpolicy_transaction_temp1
		FROM edw_stage.AccountTransaction acctr
		left join edw_stage.Product pr on acctr.ProductId = pr.id
		WHERE PolicyNumber is not null 
		  and acctr.State ='ISSUED' --- Review BOUND transactions
		  and pr.ProductLine='PersonalLines'
		  AND acctr.IssuedDate>@last_source_extract_ts

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_temp2
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
		INTO edw_temp.tpolicy_transaction_temp2  
		FROM edw_temp.tpolicy_transaction_temp1 tmp1 
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
		FROM edw_temp.tpolicy_transaction_temp1 tmp1 
		inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = tmp1.Id 
		inner join edw_stage.Account acct on acct.id = tmp1.AccountId
		left join edw_stage.coverage cov on cov.id = acctrtf.coverageid

		-- Start Inserting records
		INSERT INTO edw_core.tpolicy_transaction 
			(policy_sk
           ,effective_dt_sk
           ,expiration_dt_sk
           ,transaction_effective_dt_sk
           ,transaction_seq_no
           ,broker_sk
           ,customer_sk
           ,premium_amt
           ,commission_amt
           ,annual_premium_amt
           ,tax_fee_surcharge_amt
           ,net_premium_amt
           ,item_sk
           ,coverage_sk 
           ,vehicle_coverage_sk 
           ,transaction_dt_sk
           ,calendar_month_sk
           ,accouting_month_sk -- not sure
           ,product_sk
           ,policy_transaction_type_sk -- not sure
           ,internal_coverage_sk -- not sure
           ,source_system_sk -- not sure ¿From Policy?
           ,policy_status_sk -- from policy_status ¿?
           ,tax_fee_surcharge_sk
			,ceded_annual_premium_amt
			,ceded_premium_amt
		   ,user_sk -- not sure
           ,create_ts
           ,update_ts
           ,etl_audit_sk)
		SELECT
			pol.policy_sk, dt1.date_sk, dt2.date_sk, dt3.date_sk, Source.PolicyChangeNumber, 
			br.broker_sk, cust.customer_sk, source.wp, Source.comm, source.ap, source.tfs, source.wp - source.tfs, 
			case when ho.policy_no is not null then ho.home_location_sk 
				 when coll.policy_no is not null then coll.collection_location_sk 
			     --when pel_loc.policy_no is not null then pel_loc.pel_location_sk  
			     when au_veh.policy_no is not null then au_veh.auto_vehicle_sk 
			     else 0 
			end item_sk, 
			case when ho.policy_no is not null then ho.home_coverage_sk 
				 when coll.policy_no is not null then coll.collection_coverage_sk 
			     when pel_cov.policy_no is not null then pel_cov.pel_coverage_sk 
			     when au_pol_cov.policy_no is not null then au_pol_cov.auto_policy_coverage_sk 
			     else 0 
			end cov_sk, 
			case when au_veh_cov.policy_no is not null then au_veh_cov.auto_vehicle_coverage_sk 
			     else 0 
			end veh_cov_sk, 
			dt4.date_sk tr_dt_sk, 
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) cal_mn_sk, 
			(select max(date_sk) from edw_core.tdate 
			 where yearmonth = (select yearmonth from edw_core.tdate where date_sk = dt5.date_sk)) acc_mn_sk, 
			pr.product_sk, 
			isnull(tt.policy_transaction_type_sk,0), 
			isnull(ic.internal_coverage_sk,0), 
			source.ssk, 
			case when isnull(tt.policy_transaction_type_sk,0) = 5 then 2 else 1 end pol_status,
			isnull(tfs.internal_coverage_sk,0) , 
			ceded_annual_premium_amt,
		    ceded_premium_amt,
			0 user_sk, 
			getdate(),getdate(), @etl_audit_sk --select source.coverage, source.label,ic.*
		FROM
			edw_temp.tpolicy_transaction_temp2 source
		LEFT JOIN edw_core.tdate dt1 on dt1.actual_dt = cast(source.EffectiveDate as date)
		LEFT JOIN edw_core.tdate dt2 on dt2.actual_dt = cast(source.ExpirationDate as date)
		LEFT JOIN edw_core.tdate dt3 on dt3.actual_dt = cast(source.TransactionEffectiveDate as date)
		LEFT JOIN edw_core.tdate dt4 on dt4.actual_dt = cast(source.IssuedDate as date)
		LEFT JOIN edw_core.tdate dt5 on dt5.actual_dt = cast(source.cal_mn as date)
		LEFT JOIN edw_core.tpolicy pol on source.PolicyNumber = pol.policy_no and cast(source.EffectiveDate as date) = pol.effective_dt
		LEFT JOIN edw_core.thome_coverage ho on source.PolicyNumber = ho.policy_no and cast(source.EffectiveDate as date) = ho.effective_dt and source.PolicyChangeNumber = ho.transaction_seq_no
		LEFT JOIN edw_core.tcollection_coverage coll on source.PolicyNumber = coll.policy_no and cast(source.EffectiveDate as date) = coll.effective_dt and source.PolicyChangeNumber = coll.transaction_seq_no
		LEFT JOIN edw_core.tpel_coverage pel_cov on source.PolicyNumber = pel_cov.policy_no and cast(source.EffectiveDate as date) = pel_cov.effective_dt and source.PolicyChangeNumber = pel_cov.transaction_seq_no
		--LEFT JOIN edw_core.tpel_location pel_loc on source.PolicyNumber = pel_loc.policy_no and cast(source.EffectiveDate as date) = pel_loc.effective_dt and source.PolicyChangeNumber = pel_loc.transaction_seq_no
		LEFT JOIN edw_core.tauto_vehicle au_veh on source.PolicyNumber = au_veh.policy_no and cast(source.EffectiveDate as date) = au_veh.effective_dt and source.vehicle_unique_id = au_veh.vehicle_unique_id
		LEFT JOIN edw_core.tauto_policy_coverage au_pol_cov on source.PolicyNumber = au_pol_cov.policy_no and cast(source.EffectiveDate as date) = au_pol_cov.effective_dt and source.PolicyChangeNumber = au_pol_cov.transaction_seq_no
		LEFT JOIN edw_core.tauto_vehicle_coverage au_veh_cov on source.PolicyNumber = au_veh_cov.policy_no and cast(source.EffectiveDate as date) = au_veh_cov.effective_dt and source.PolicyChangeNumber = au_veh_cov.transaction_seq_no and source.vehicle_unique_id = au_veh_cov.vehicle_unique_id
		LEFT JOIN edw_core.tproduct pr on pr.product_cd = pol.product_cd
		LEFT JOIN edw_core.tbroker br on pol.broker_id = br.broker_id
		LEFT JOIN edw_core.tcustomer cust on pol.customer_id = cust.customer_id
		LEFT JOIN edw_core.tinternal_coverage ic on ic.internal_coverage_desc = (case when source.typ = 'prm' then source.label else source.coverage end) 
												and (case when source.coverage = 'Subscriber Contribution' and source.covID = 'Lux' then 'LUX' else pr.product_cd end) = ic.product_cd  
		--LEFT JOIN edw_core.tinternal_coverage tfs on tfs.internal_coverage_desc = source.coverage and source.typ <> 'prm' and (pr.product_cd = tfs.product_cd)    
		LEFT JOIN edw_core.tinternal_coverage tfs on tfs.internal_coverage_desc = source.coverage and source.typ <> 'prm' 
													and (case when source.coverage = 'Subscriber Contribution' and source.covID = 'Lux' then 'LUX' else pr.product_cd end = tfs.product_cd)    
		LEFT JOIN edw_core.tpolicy_transaction_type tt on tt.policy_transaction_type_cd = source.stage 

		SET @rows_affected=@@ROWCOUNT; 

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.IssuedDate) FROM edw_temp.tpolicy_transaction_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_temp1
		DROP TABLE IF EXISTS edw_temp.tpolicy_transaction_temp2
		
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
