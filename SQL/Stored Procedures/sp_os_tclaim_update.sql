-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 11/08/2023
-- Description: This procedures update OneShield claim into tclaim table
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/08/23		Yunus Mohammd				1. Created this procedure
-- 03/01/24		Yunus Mohammd				2. Updated cause_of_loss_sk for 5 claims
-- ======================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_tclaim_update]

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

		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= ''

		DROP TABLE IF EXISTS edw_temp.os_tclaim_update_temp1

		SELECT
		claim_no,loss_dt,report_dt,tc.policy_no,policy_effective_dt,tph.policy_sk,tph.policy_history_sk,tcl.cause_of_loss_sk,
		loss_desc,claim_status,source_claim_status,cat.catastrophe_sk,tc.product_sk,underwriting_company_nm,
		loss_address,loss_city_nm,loss_state_nm,loss_zip_cd,loss_country_nm,NULL AS agencyid,contact_nm,
		contact_type,contact_phone,contact_person_email,loss_reserve_amt,expense_reserve_amt,adjusting_other_reserve_amt,
		subro_reserve_amt,salvage_reserve_amt,salvage_expense_reserve_amt,subro_expense_reserve_amt,loss_paid_amt,
		expense_paid_amt,adjusting_other_paid_amt,subro_recovery_amt,salvage_recovery_amt,salvage_expense_paid_amt,
		subro_expense_paid_amt,refund_indemnity_paid_amt,refund_expense_paid_amt,
		tc.source_system_sk
		INTO edw_temp.os_tclaim_update_temp1
		FROM
		edw_stage.dragon_claim_os tc
		LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_desc=REPLACE(tc.cause_of_loss_sk,'*','') AND tcl.source_system_sk=1
		LEFT JOIN edw_core.tcatastrophe cat ON
		(
		SUBSTRING(tc.catastrophe_sk,CHARINDEX(tc.catastrophe_sk,'CAT-')+5,4) = cat.catastrophe_cd
		OR tc.catastrophe_sk=cat.catastrophe_cd
		)
        LEFT JOIN edw_core.tpolicy_history tph ON TRIM(tc.policy_no) = tph.policy_no
			AND tph.policy_history_sk = (
                                SELECT TOP 1 policy_history_sk
                                FROM
                                    edw_core.tpolicy_history tph1
                                WHERE
                                    tph1.policy_no = tc.policy_no
                                    AND CAST(tph1.transaction_effective_dt AS DATE) <= CAST(tc.loss_dt AS DATE)
								ORDER BY transaction_seq_no DESC
                              )
		-- update policy_sk and policy_history_sk
		update tc
		set
		tc.policy_sk=tct.policy_sk,
		tc.policy_history_sk=tct.policy_history_sk
		from
			edw_core.tclaim tc
			inner join edw_temp.os_tclaim_update_temp1 as tct on tc.claim_no = tct.claim_no
		where
			tc.source_system_sk = 1

		-- cause_of_loss_sk
        update tca
        set
		tca.cause_of_loss_sk = tcl.cause_of_loss_sk
        FROM
            edw_stage.dragon_claim_os tc
            INNER JOIN edw_core.tclaim tca on tc.claim_no = tca.claim_no
            LEFT JOIN edw_core.tcause_of_loss tcl ON tcl.cause_of_loss_desc=REPLACE(tc.cause_of_loss_sk,'*','') AND tcl.source_system_sk=1            
        where
            tca.source_system_sk=1

		-- catastrophe_sk
        update tca
        set
        tca.catastrophe_sk = cat.catastrophe_sk
		FROM
            edw_stage.dragon_claim_os tc
            INNER JOIN edw_core.tclaim tca on tc.claim_no = tca.claim_no
            INNER JOIN edw_core.tcatastrophe cat ON
            (
            SUBSTRING(tc.catastrophe_sk,CHARINDEX(tc.catastrophe_sk,'CAT-')+5,4) = cat.catastrophe_cd
            OR tc.catastrophe_sk=cat.catastrophe_cd
            )
        where
            tca.source_system_sk=1

		-- Update cause_of_loss_sk
		update edw_core.tclaim set cause_of_loss_sk = 1 where claim_no = 'CL-1322129470';
		update edw_core.tclaim set cause_of_loss_sk = 1 where claim_no = 'CL-1357191188';
		update edw_core.tclaim set cause_of_loss_sk = 38 where claim_no = 'CL-1338963181';
		update edw_core.tclaim set cause_of_loss_sk = 23 where claim_no = 'CL-1336345173';
		update edw_core.tclaim set cause_of_loss_sk = 1 where claim_no = 'CL-1372618270';

		-- update catastriphe_sk for below claims
		DECLARE @catastrophe_sk_2030 INT = (SELECT catastrophe_sk FROM edw_core.tcatastrophe WHERE catastrophe_cd = '2030')
		DECLARE @catastrophe_sk_2063 INT = (SELECT catastrophe_sk FROM edw_core.tcatastrophe WHERE catastrophe_cd = '2063')
		DECLARE @catastrophe_sk_2076 INT = (SELECT catastrophe_sk FROM edw_core.tcatastrophe WHERE catastrophe_cd = '2076')
		DECLARE @catastrophe_sk_1954 INT = (SELECT catastrophe_sk FROM edw_core.tcatastrophe WHERE catastrophe_cd = '1954')

		update edw_core.tclaim set catastrophe_sk = @catastrophe_sk_2030 where claim_no = 'CL-1030492334';
		update edw_core.tclaim set catastrophe_sk = @catastrophe_sk_2063 where claim_no IN ('CL-1167935587','CL-1208329762');
		update edw_core.tclaim set catastrophe_sk = @catastrophe_sk_2076 where claim_no IN ('CL-1223668608', 'CL-1226900023', 'CL-1231362490','CL-1231363304','CL-1236477921')
		update edw_core.tclaim set catastrophe_sk = @catastrophe_sk_1954 where claim_no 
		IN('CL-1236837967','CL-764254350','CL-764255891','CL-765445306','CL-765447540') 

		SET @rows_affected=@@ROWCOUNT;	

		-- Update audit table
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tclaim_update_temp1

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;

	END CATCH
END

