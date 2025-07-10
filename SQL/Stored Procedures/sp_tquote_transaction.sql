-- ====================================================================================================================================
-- Description: This procedures inserts into TQuote_Transaction  
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 06/02/23		Architha Gudimalla		1. Created this procedure
-- 11/14/23		Sandeep Gundreddy		2. modified quote_auto_vehicle join
-- 11/29/23		Architha Gudimalla		3. modified @new_last_source_extract_ts
-- 12/11/23		Architha Gudimalla		4. modified logic for stage pol term
-- 02/27/24		Architha Gudimalla		5. Updated logic for Lux subscriber contributoin on ho
-- 03/20/24		Architha Gudimalla		6. Added logic for class_type_sk
-- 07/12/24		Architha Gudimalla		7. Added these to timternal_coverage table join along with subscriber contributoin
--										   Legislative Fire Marshal Assessment Discount of 1.00% pursuant to section 624.5108(1)(b), F.S
-- 										   Legislative Premium Tax Discount of 1.75% pursuant to section 624.5108(1)(a), F.S
-- 08/30/24		Architha Gudimalla		8. Update product join to inner instead of left
--11/25/2024	Sandeep Gundreddy		9. Added logic to load item_sk and coverage_sk for Marine Boat & Yacht
-- 06/04/2025	Alberto Almario			10. Added new column user_sk 
-- 07/10/2025	Dinesh Bobbili			11. Added IssuedByUserId in the filter
-- ==================================================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_transaction]

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

		DROP TABLE IF EXISTS edw_temp.TQuote_transaction_temp1;
		-- Step1 limit amount of rows.
		SELECT
			acctr.*,
			case when acctr.ExternalSourceId is not NULL then 2--(AV2) 
				 Else 4 --(Metal)
			end ssk , pr.productcode
		INTO edw_temp.TQuote_transaction_temp1
		FROM edw_stage.AccountTransaction acctr
		left join edw_stage.Product pr on acctr.ProductId = pr.id
		WHERE PolicyNumber is not null 
		  and acctr.Stage in ('QUOTE','POLICY') 
		  and pr.ProductLine='PersonalLines'
		  AND acctr.CreatedDate>@last_source_extract_ts

        -- Create temp table with name as sp_tcustomer_temp1 and use it in 
        DROP TABLE IF EXISTS edw_temp.TQuote_transaction_temp2
        SELECT 
			tmp1.PolicyNumber,
			case when tmp1.productcode = 'AU' then acctrvo.[index] else null end as vehicle_no,
			tmp1.ProductId,
			tmp1.EffectiveDate,
			tmp1.ExpirationDate, 
			--acc.BrokerId,
			--acc.MasterInsuredId,
			tmp1.number,
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
			,tmp1.CreatedById
		INTO edw_temp.TQuote_transaction_temp2  
		FROM edw_temp.TQuote_transaction_temp1 tmp1 
		inner join edw_stage.Account acct on acct.id = tmp1.AccountId
		inner join edw_stage.AccountTransactionCoveragePremium acctrcp on acctrcp.AccountTransactionId = tmp1.Id
		left join edw_stage.AccountTransactionVersionObject acctrvo on acctrcp.objectid=acctrvo.id 
		--where premium!=0  
		union all
		SELECT 
			tmp1.PolicyNumber,
			null vehicle_no,
			tmp1.ProductId,
			tmp1.EffectiveDate,
			tmp1.ExpirationDate, 
			--acc.BrokerId,
			--acc.MasterInsuredId,
			tmp1.number,
			tmp1.Commission,
			tmp1.TransactionEffectiveDate,
			tmp1.IssuedDate,
			tmp1.CancellationReason,
			tmp1.CreatedDate,
			iif(tmp1.TransactionEffectiveDate > tmp1.CreatedDate, tmp1.TransactionEffectiveDate, tmp1.CreatedDate) cal_mn,
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
			,tmp1.CreatedById
		FROM edw_temp.TQuote_transaction_temp1 tmp1 
		inner join edw_stage.AccountTransactionTaxAndFee acctrtf on acctrtf.AccountTransactionId = tmp1.Id 
		inner join edw_stage.Account acct on acct.id = tmp1.AccountId
		left join edw_stage.coverage cov on cov.id = acctrtf.coverageid 

		-- Start Inserting records
		INSERT INTO edw_core.TQuote_transaction 
			(quote_sk
           ,quote_history_sk
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
           ,product_sk 
           ,internal_coverage_sk -- not sure
           ,source_system_sk -- not sure ¿From Policy? 
           --,tax_fee_surcharge_sk
		   ,user_sk
           ,create_ts
           ,update_ts
           ,etl_audit_sk
			,ceded_annual_premium_amt
			,ceded_premium_amt
		   ,quote_collection_class_type_sk)
		SELECT
			q.quote_sk
           ,qh.quote_history_sk, dt1.date_sk, dt2.date_sk, dt3.date_sk, Source.number, 
			br.broker_sk, cust.customer_sk, source.wp, Source.comm, source.ap, source.tfs, source.wp - source.tfs, 
			case when ho.quote_no is not null then ho.quote_home_location_sk 
				 when coll.quote_no is not null then coll.quote_collection_location_sk 
			     --when pel_loc.quote_no is not null then pel_loc.pel_location_sk  
			     when au_veh.quote_no is not null then au_veh.quote_auto_vehicle_sk 
				 when qmby.quote_no is not null then qmby.quote_marine_boat_yacht_sk
			     else 0 
			end item_sk, 
			case when ho.quote_no is not null then ho.quote_home_coverage_sk 
				 when coll.quote_no is not null then coll.quote_collection_coverage_sk 
			     when pel_cov.quote_no is not null then pel_cov.quote_pel_coverage_sk 
			     when au_pol_cov.quote_no is not null then au_pol_cov.quote_auto_policy_coverage_sk 
				 when qmby.quote_no is not null then qmby.quote_marine_boat_yacht_coverage_sk
			     else 0 
			end cov_sk, 
			case when au_veh_cov.quote_no is not null then au_veh_cov.quote_auto_vehicle_coverage_sk 
			     else 0 
			end veh_cov_sk, 
			dt4.date_sk tr_dt_sk,  
			pr.product_sk,  
			isnull(ic.internal_coverage_sk,0), 
			source.ssk,  
			--isnull(ttfs.tax_fee_surcharge_sk,0), 
			u.user_sk, 
			getdate(),getdate(), @etl_audit_sk, --select source.coverage, source.label,ic.*
			ceded_annual_premium_amt,
		    ceded_premium_amt
			,case when q.product_cd <> 'Lux' then 0
			      when ic.internal_coverage_category_nm <> 'Premium' then 0
			      when cc.quote_collection_class_type_sk is not null then cc.quote_collection_class_type_sk
				  else 0
			end quote_collection_class_type_sk
		FROM
			edw_temp.TQuote_transaction_temp2 source
		LEFT JOIN edw_core.tdate dt1 on dt1.actual_dt = cast(source.EffectiveDate as date)
		LEFT JOIN edw_core.tdate dt2 on dt2.actual_dt = cast(source.ExpirationDate as date)
		LEFT JOIN edw_core.tdate dt3 on dt3.actual_dt = cast(source.EffectiveDate as date)
		LEFT JOIN edw_core.tdate dt4 on dt4.actual_dt = cast(source.CreatedDate as date) 
		LEFT JOIN edw_core.TQuote q on source.PolicyNumber = q.quote_no --and cast(source.EffectiveDate as date) = q.effective_dt
		LEFT JOIN edw_core.tquote_history qh on source.PolicyNumber = qh.quote_no and cast(source.EffectiveDate as date) = qh.effective_dt and source.number = qh.transaction_seq_no
		LEFT JOIN edw_core.tquote_home_coverage ho on source.PolicyNumber = ho.quote_no and cast(source.EffectiveDate as date) = ho.effective_dt and source.number = ho.transaction_seq_no
		LEFT JOIN edw_core.tquote_collection_coverage coll on source.PolicyNumber = coll.quote_no and cast(source.EffectiveDate as date) = coll.effective_dt and source.number = coll.transaction_seq_no
		LEFT JOIN edw_core.tquote_pel_coverage pel_cov on source.PolicyNumber = pel_cov.quote_no and cast(source.EffectiveDate as date) = pel_cov.effective_dt and source.number = pel_cov.transaction_seq_no
		LEFT JOIN edw_core.tquote_auto_vehicle au_veh on source.PolicyNumber = au_veh.quote_no and source.vehicle_no = au_veh.vehicle_no
		LEFT JOIN edw_core.tquote_auto_policy_coverage au_pol_cov on source.PolicyNumber = au_pol_cov.quote_no and cast(source.EffectiveDate as date) = au_pol_cov.effective_dt and source.number = au_pol_cov.transaction_seq_no
		LEFT JOIN edw_core.tquote_auto_vehicle_coverage au_veh_cov on source.PolicyNumber = au_veh_cov.quote_no and cast(source.EffectiveDate as date) = au_veh_cov.effective_dt and source.number = au_veh_cov.transaction_seq_no and source.vehicle_no = au_veh_cov.vehicle_no
		LEFT JOIN edw_core.tquote_marine_boat_yacht_coverage qmby on source.PolicyNumber = qmby.quote_no and cast(source.EffectiveDate as date) = qmby.effective_dt and source.number = qmby.transaction_seq_no
		inner JOIN edw_core.tproduct pr on pr.product_cd = q.product_cd
		LEFT JOIN edw_core.tbroker br on q.broker_id = br.broker_id
		LEFT JOIN edw_core.tcustomer cust on q.customer_id = cust.customer_id
		--LEFT JOIN edw_core.tinternal_coverage ic on ic.internal_coverage_desc = (case when source.typ = 'prm' then source.label else source.coverage end) and pr.product_cd = ic.product_cd  
		LEFT JOIN edw_core.tinternal_coverage ic on ic.internal_coverage_desc = (case when source.typ = 'prm' then source.label else source.coverage end) 
												and (case when source.coverage in ('Subscriber Contribution',
																				   'Legislative Fire Marshal Assessment Discount of 1.00% pursuant to section 624.5108(1)(b), F.S',
																				   'Legislative Premium Tax Discount of 1.75% pursuant to section 624.5108(1)(a), F.S'
																				  ) and source.covID = 'Lux' then 'LUX' else pr.product_cd end) = ic.product_cd  
		--LEFT JOIN edw_core.ttax_fee_surcharge ttfs on ttfs.tax_fee_surcharge_desc = source.coverage  
		left join edw_core.tquote_collection_class_type cc on 	q.quote_no = cc.quote_no and q.effective_dt = cc.effective_dt and Source.number = cc.transaction_seq_no 
														and case 	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Music' then 'Musical Instruments' 
																	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Fine Arts' then 'Fine Art' 
																	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Jewelry' then 'Worldwide Jewelry'  
																	else replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')
																end = cc.class_type   
		left join edw_core.tuser u on u.user_id = coalesce(source.IssuedByUserId,source.CreatedById)
		

		SET @rows_affected=@@ROWCOUNT; 

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.CreatedDate) FROM edw_temp.TQuote_transaction_temp1 t1),@last_source_extract_ts);
		
        DROP TABLE IF EXISTS edw_temp.TQuote_transaction_temp1
		DROP TABLE IF EXISTS edw_temp.TQuote_transaction_temp2
		
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
