-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts workday payment data for commercial claims
---------------------------------------------------------------------------------------------------
-- Change date |Author						     |	Change Description
---------------------------------------------------------------------------------------------------
-- 12/10/25		Yunus Mohammed	    1. Created this procedure
-- ================================================================================================= 

CREATE OR ALTER  PROCEDURE [edw_core].[sp_commercial_claim_workday_payment]
AS
BEGIN
	DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
		BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);			

		DECLARE @year_month INT,@begin_dt DATE,@end_dt DATE,@begin_sk INT,@end_sk INT
		
		DECLARE cur_main CURSOR FOR
		select yearmonth
		from edw_core.tdate
		where
		actual_dt > @last_source_extract_ts
		and actual_dt < cast(@current_date as date)
		group by yearmonth
		order by 1; 

		OPEN cur_main
		FETCH NEXT FROM cur_main INTO @year_month
		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
	
			SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
			
			select @begin_dt = MIN(actual_dt),@end_dt = MAX(actual_dt), @begin_sk = MIN(date_sk),
			@end_sk = MAX(date_sk) 
			from
			edw_core.tdate
			where
			yearmonth=@year_month;
			
            DELETE lp
            FROM edw_integration.claim_workday_payment_feed AS lp
            INNER JOIN edw_core.tproduct AS p ON lp.product = p.product_nm
            WHERE transaction_date BETWEEN @begin_dt AND @end_dt
            AND p.product_category_nm = 'CommercialLines';
		
            WITH commercial_claim_workday_payment_feed_temp AS
            (
            SELECT
                        'Vault E&S Insurance Company' AS company,
                        tc.claim_no AS claim_no,
                        tc.policy_no AS policy_no,
                        CAST(tcr.transaction_ts AS DATE) AS transaction_date,
                        tc.effective_dt AS policyeffectivedate,
                        tc.loss_dt AS claimlossdate,
                        tc.report_dt AS claimreporteddate,
                        tp.mailing_address_line1 AS [address],
                        tp.mailing_address_city_nm AS city,
                        tp.mailing_address_state_cd AS [state],
                        tp.mailing_address_zip_cd AS zip,
                        tcl.cause_of_loss_desc AS causeofloss,
                        null AS catastrophecode,
                        null AS catastrophename,
                        tprd.product_nm AS product,
                        tcf.claim_coverage_desc AS policycoveragetype,
                        ttr.cat_name AS paymenttype,
                        tpay.payee_nm AS payeename,
                        ttr.amt AS paymentamount,
                        tpay.party_role_nm AS settlementtype,
                        YEAR(tc.loss_dt) AS accident_year,
                        COALESCE(st.state_cd,tp.risk_state_cd) AS risk_state,
                        CAST(tasl.aslob_cd AS INT) AS aslob,
                        tpay.payment_no AS transaction_id,
                        @end_dt AS monthend,			
                        tc.claim_status AS claim_status,
                        tcf.claim_feature_status AS loss_status,
                        tpay.party_subtype_role_nm
                        FROM
                        edw_commercial.tcommercial_claim tc
                        LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_sk=tc.cause_of_loss_sk
                        --LEFT JOIN edw_core.tcatastrophe tcat ON tcat.catastrophe_sk=tc.catastrophe_sk			
                        INNER JOIN edw_commercial.tcommercial_claim_feature tcf ON tc.commercial_claim_sk=tcf.commercial_claim_sk
                        LEFT JOIN edw_core.taslob tasl ON tasl.aslob_sk=tcf.aslob_sk
                        INNER JOIN edw_core.tproduct tprd ON tprd.product_sk=tc.product_sk
                        INNER JOIN edw_commercial.tcommercial_claim_payment tpay ON tpay.commercial_claim_feature_sk=tcf.commercial_claim_feature_sk
                        INNER JOIN edw_commercial.tcommercial_claim_transaction tcr ON tcr.commercial_claim_feature_sk = tcr.commercial_claim_feature_sk AND tcr.commercial_claim_payment_sk=tpay.commercial_claim_payment_sk
                        INNER JOIN
                        (
                            SELECT
                                commercial_claim_feature_sk,commercial_claim_payment_sk,cat_name,SUM(amt) AS amt
                            FROM
                                (
                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(loss_paid_amt+overpayment_recovery_amt+deductible_recovery_amt) AS amt, 'Loss (Indemnity)' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk

                                    UNION
                                        
                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(deductible_expense_recovery_amt+expense_paid_amt+overpayment_expense_recovery_amt) AS amt, 'Loss (Expense - A&O)' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                --	AND t.defense_cost_in = 'N'
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk

                                    UNION
                                        
                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(deductible_defense_recovery_amt+defense_paid_amt+overpayment_defense_recovery_amt) AS amt, 'Loss (Expense - DCC)' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                --	AND t.defense_cost_in = 'Y'
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk
                                        
                                    UNION
                                        
                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(subrogation_recovery_amt+subrogation_defense_recovery_amt) AS amt, 'Subrogation' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk

                                    UNION
                                        
                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(subrogation_expense_recovery_amt) AS amt, 'Subrogation Expense' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk

                                    UNION

                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(salvage_defense_recovery_amt + salvage_recovery_amt) AS amt, 'Salvage' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk

                                    UNION

                                    SELECT
                                        commercial_claim_feature_sk,commercial_claim_payment_sk,SUM(salvage_expense_recovery_amt) AS amt, 'Salvage Expense' AS cat_name
                                    FROM edw_commercial.tcommercial_claim_transaction t
                                    WHERE t.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                                    GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk
                                ) AS A
                                GROUP BY commercial_claim_feature_sk,commercial_claim_payment_sk,cat_name
                        ) AS ttr ON ttr.commercial_claim_feature_sk=tcr.commercial_claim_feature_sk and ttr.commercial_claim_payment_sk=tcr.commercial_claim_payment_sk
                        LEFT JOIN edw_commercial.tcommercial_policy tp on tp.policy_no=tc.policy_no
                        LEFT JOIN edw_core.tstate st on st.state_cd=tp.risk_state_cd
                        WHERE tcr.transaction_dt_sk BETWEEN @begin_sk AND @end_sk
                        and tc.policy_no not like '%VRE' and tc.policy_no not like '%VES'
                        AND ttr.amt!=0
                        )

                    INSERT INTO edw_integration.claim_workday_payment_feed
                    (
                    company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
                    zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,paymenttype,payeename,paymentamount,settlementtype,
                    accident_year,risk_state,aslob,transaction_id,monthend,claim_status,loss_status,party_subtype_role_nm,
                    create_ts,update_ts,etl_audit_sk
                    )
                    SELECT
                        company,claim_no,policy_no,transaction_date,policyeffectivedate,claimlossdate,claimreporteddate,[address],city,[state],
                        zip,causeofloss,catastrophecode,catastrophename,product,policycoveragetype,paymenttype,payeename,paymentamount,settlementtype,
                        accident_year,risk_state,aslob,transaction_id,monthend,claim_status,loss_status,party_subtype_role_nm,
                        GETDATE() AS create_ts,GETDATE() AS update_ts, @etl_audit_sk AS etl_audit_sk
                    FROM
                        commercial_claim_workday_payment_feed_temp

                    SET @rows_affected=@@ROWCOUNT;

                    -- Update control table
                    SET @new_last_source_extract_ts= dateadd(day,-1,cast(@current_date as date))
                    EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

                    -- Update audit table
                    SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
                    EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;		

                    SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);

                    FETCH NEXT FROM cur_main INTO @year_month
                END
		        CLOSE cur_main;

		        DEALLOCATE cur_main;
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END
