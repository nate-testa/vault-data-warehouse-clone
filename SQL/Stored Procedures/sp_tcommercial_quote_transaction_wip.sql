SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-03-28
-- Description: This stored procedure insert and update info related to tcommercial_quote_transaction.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 03/04/2025           Alberto Almario				1. Created this procedure 
-- 22/04/2025           Alberto Almario				2. Change PolicyNumber to Number from Account table
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_transaction_wip]

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

			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp1;
			-- Step1 limit amount of rows.
			SELECT
				acc.*,
				case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					Else 4 --(Metal)
				end ssk , pr.productcode
			INTO edw_temp.tcommercial_quote_transaction_wip_temp1
			FROM edw_stage.Account acc
			left join edw_stage.Product pr on acc.ProductId = pr.id
			WHERE pr.ProductLine='CommercialLines'
			AND acc.CreatedDate>@last_source_extract_ts
			and not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)

			-- Create temp table with name as sp_tcustomer_temp1 and use it in 
			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp2
			SELECT 
				CAST(tmp1.Number AS VARCHAR(255)) as quote_no,
				case when tmp1.productcode = 'AU' then atvo.[index] else null end as vehicle_no,
				tmp1.ProductId,
				tmp1.EffectiveDate,
				tmp1.ExpirationDate, 
				--acc.BrokerId,
				--acc.MasterInsuredId,
				0 as number,
				null Commission,
				tmp1.TransactionEffectiveDate,
				null IssuedDate,
				null CancellationReason,
				tmp1.CreatedDate,
				iif(tmp1.TransactionEffectiveDate > null, tmp1.TransactionEffectiveDate, null) cal_mn,
				tmp1.UpdatedDate,
				iif(acct.RenewalIndex<>0,iif(tmp1.stage = 'POLICY','RENEWAL',tmp1.stage),tmp1.stage) as stage,
				apc.Coverage ,apc.label,
				apc.premium as wp, 
				apc.premium as ap,
				apc.commission as comm,
				0 as tfs, tmp1.ssk, 'prm' typ,
				apc.CededPremium as ceded_annual_premium_amt,
				apc.CededPremium as ceded_premium_amt,
				null covID
			INTO edw_temp.tcommercial_quote_transaction_wip_temp2  
			FROM edw_temp.tcommercial_quote_transaction_wip_temp1 tmp1 
			inner join edw_stage.Account acct on acct.id = tmp1.id
			inner join edw_stage.Accountpremium ap on ap.AccountId=acct.id -->
			left join edw_stage.AccountPremiumCoverage apc on apc.AccountPremiumId=ap.id --> Accounttransactionversioncoveragepremium
			left join edw_stage.AccountObject atvo on atvo.id=apc.objectid --> Accounttransactionversionobject 
			--where premium!=0  
			union all
			SELECT 
				CAST(tmp1.Number AS VARCHAR(255)) as quote_no,
				null vehicle_no,
				tmp1.ProductId,
				tmp1.EffectiveDate,
				tmp1.ExpirationDate, 
				--acc.BrokerId,
				--acc.MasterInsuredId,
				0 as number,
				null Commission,
				tmp1.TransactionEffectiveDate,
				null IssuedDate,
				''  CancellationReason,
				tmp1.CreatedDate,
				iif(tmp1.TransactionEffectiveDate > tmp1.CreatedDate, tmp1.TransactionEffectiveDate, tmp1.CreatedDate) cal_mn,
				tmp1.UpdatedDate,
				iif(tmp1.RenewalIndex<>0,iif(tmp1.stage = 'POLICY','RENEWAL',tmp1.stage),tmp1.stage) as stage, 
				accptf.Name, '',
				accptf.Amount as wp, 
				accptf.Amount as ap, 
				0 as comm ,
				accptf.Amount as tfs, tmp1.ssk, 'tfs' typ,
				0 as ceded_annual_premium_amt,
				0 as ceded_premium_amt,
				cov.Name covID
			FROM edw_temp.tcommercial_quote_transaction_wip_temp1 tmp1 
			left join edw_stage.Accountpremium ap on ap.AccountId=tmp1.id 
			INNER JOIN edw_stage.[AccountPremiumTaxAndFee] accptf on accptf.AccountPremiumId = ap.Id 
			left join edw_stage.coverage cov on cov.id = accptf.coverageid
			
			delete from   a 
			from edw_commercial.tcommercial_quote_transaction a 
			where exists (select * from edw_temp.tcommercial_quote_transaction_wip_temp2 b, edw_commercial.tcommercial_quote q 
						where q.quote_no = b.quote_no and a.commercial_quote_sk = q.commercial_quote_sk and b.number = a.transaction_seq_no 
						) 
			
			-- Create last temp table
			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp3;
			SELECT
				q.commercial_quote_sk
				,qh.commercial_quote_history_sk
				,dt1.date_sk as effective_dt_sk
				,dt2.date_sk as expiration_dt_sk
				,dt3.date_sk as transaction_effective_dt_sk
				,source.number as transaction_seq_no
				,br.broker_sk
				,cust.customer_sk
				,source.wp as premium_amt
				,source.wp - isnull(source.comm,0) as net_premium_amt
				,source.comm as commission_amt
				,source.ap as annual_premium_amt
				,cpc.commercial_quote_coverage_sk as coverage_sk
				,dt4.date_sk as transaction_dt_sk
				,pr.product_sk
				,source.ssk as source_system_sk
				,0 as user_sk
				,GETDATE() as create_ts
				,GETDATE() as update_ts
				,@etl_audit_sk as etl_audit_sk
			INTO edw_temp.tcommercial_quote_transaction_wip_temp3
			FROM edw_temp.tcommercial_quote_transaction_wip_temp2 source
			LEFT JOIN edw_core.tdate dt1 on dt1.actual_dt = cast(source.EffectiveDate as date)
			LEFT JOIN edw_core.tdate dt2 on dt2.actual_dt = cast(source.ExpirationDate as date)
			LEFT JOIN edw_core.tdate dt3 on dt3.actual_dt = cast(source.EffectiveDate as date)
			LEFT JOIN edw_core.tdate dt4 on dt4.actual_dt = cast(source.CreatedDate as date) 
			LEFT JOIN edw_commercial.tcommercial_quote q on source.quote_no = q.quote_no and cast(source.EffectiveDate as date) = q.effective_dt
			LEFT JOIN edw_commercial.tcommercial_quote_history qh on source.quote_no = qh.quote_no and cast(source.EffectiveDate as date) = qh.effective_dt and source.number = qh.transaction_seq_no
			LEFT JOIN edw_commercial.tcommercial_quote_coverage cpc on source.quote_no = cpc.quote_no and cast(source.EffectiveDate as date) = cast(cpc.effective_dt as date) and source.Number = cpc.transaction_seq_no
			INNER JOIN edw_core.tproduct pr on pr.product_cd = q.product_cd
			LEFT JOIN edw_core.tbroker br on q.broker_id = br.broker_id
			LEFT JOIN edw_core.tcustomer cust on q.customer_id = cust.customer_id
			inner JOIN edw_core.tinternal_coverage ic on ic.internal_coverage_desc = (case when source.typ = 'prm' then source.label else source.coverage end) 
													and (case when source.coverage = 'Subscriber Contribution' and source.covID = 'Lux' then 'LUX' else pr.product_cd end) = ic.product_cd  
			left join edw_core.tquote_collection_class_type cc on 	q.quote_no = cc.quote_no and q.effective_dt = cc.effective_dt and Source.number = cc.transaction_seq_no 
															and case 	when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Music' then 'Musical Instruments' 
																		when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Fine Arts' then 'Fine Art' 
																		when replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')  = 'Jewelry' then 'Worldwide Jewelry'  
																		else replace(replace(ic.internal_coverage_cd,' (Blanket)',''),' (Scheduled)','')
																	end = cc.class_type 
			;		

			-- Start Inserting records
		INSERT INTO edw_commercial.tcommercial_quote_transaction 
		(
			 commercial_quote_sk
			,commercial_quote_history_sk
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
			,product_sk
			,source_system_sk
			,user_sk
			,create_ts
			,update_ts
			,etl_audit_sk
  
		)
		SELECT
			 commercial_quote_sk
			,commercial_quote_history_sk
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
			,product_sk
			,source_system_sk
			,user_sk
			,create_ts
			,update_ts
			,etl_audit_sk
		FROM edw_temp.tcommercial_quote_transaction_wip_temp3;
			

			SET @rows_affected=@@ROWCOUNT; 

			SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.CreatedDate) FROM edw_temp.tcommercial_quote_transaction_wip_temp1 t1),@last_source_extract_ts);
			
			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp1;
			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp2;
			DROP TABLE IF EXISTS edw_temp.tcommercial_quote_transaction_wip_temp3;
			
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
