
-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures insert updates quote referral message
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 04/18/2024 			Yunus Mohammed					1. Created this procedure 
-- =========================================================================================================================== 
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tquote_referral_message]

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

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.tquote_referral_message_temp1

		SELECT act.PolicyNumber AS quote_no, act.EffectiveDate AS effective_dt,
        act.ExpirationDate AS expiration_dt,act.Number as transaction_seq_no, tqh.quote_history_sk,
        acti.[Message] AS referral_message,
        acti.ReferralLevel AS referral_level,
        CASE acti.CanRefer
            WHEN 0 THEN 'N'
            WHEN 1 THEN 'Y'
        END AS refer_in,
        CASE acti.IsApproved
            WHEN 0 THEN 'N'
            WHEN 1 THEN 'Y'
        END AS approved_in,
        acti.CreatedDate AS referral_message_created_ts,
        acti.UpdatedDate AS referral_message_updated_ts,
        CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk
        INTO edw_temp.tquote_referral_message_temp1
        FROM 
        edw_stage.AccountTransactionIssue acti
        INNER JOIN edw_stage.AccountTransaction act ON acti.AccountTransactionId = act.Id
        INNER JOIN edw_core.tquote_history tqh ON tqh.quote_no = act.PolicyNumber AND 
            tqh.effective_dt = act.EffectiveDate AND tqh.transaction_seq_no = act.Number
        INNER JOIN edw_stage.Product pr ON pr.Id=act.ProductId
        WHERE act.PolicyNumber IS NOT NULL
        AND	act.[Stage] IN ('QUOTE','POLICY')
        AND pr.ProductLine = 'PersonalLines'
        AND GREATEST(acti.CreatedDate,acti.UpdatedDate) > @last_source_extract_ts

		INSERT INTO edw_core.tquote_referral_message
        (
        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk, referral_message,
        referral_level, refer_in, approved_in, referral_message_created_ts, referral_message_updated_ts,
        source_system_sk, create_ts, update_ts, etl_audit_sk
        )
		SELECT
			quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk, referral_message,
            referral_level, refer_in, approved_in, referral_message_created_ts, referral_message_updated_ts,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_referral_message_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(referral_message_created_ts,referral_message_updated_ts)) 
                        FROM edw_temp.tquote_referral_message_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_watercraft_temp1
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
