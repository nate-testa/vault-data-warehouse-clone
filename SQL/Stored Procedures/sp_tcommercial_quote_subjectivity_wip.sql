SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2025-04-04
-- Description: This stored procedure insert and update info related to tcommercial_quote_subjectivity.
-----------------------------------------------------------------------------------------------------------------------
-- Change date          |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 04/04/2025           Alberto Almario				1. Created this procedure 
-- 22/04/2025           Alberto Almario				2. Change PolicyNumber to Number from Account table
-- ===================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_quote_subjectivity_wip]
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


		--************Start************
        
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp3;

		-- Step1 limit amount of rows.
		SELECT 
			 acc.Id
			,CAST(acc.Number AS VARCHAR(255)) as quote_no
			,acc.EffectiveDate
			,acc.ExpirationDate
			,0 as transaction_seq_no
			,accs.Required
			,accs.Description
			,CASE WHEN accs.IsCompleted = 1 THEN 'Yes' ELSE 'No' END as completed_in
			,CASE 
				WHEN acc.ExternalSourceId IS NOT NULL THEN 2 --(AV2) 
				ELSE 4 --(Metal)
			 END source_system_sk
			,acc.CreatedDate
			,acc.UpdatedDate
		INTO edw_temp.tcommercial_quote_subjectivity_wip_temp1 
		FROM edw_stage.Account acc
		INNER JOIN edw_stage.AccountSubjectivity accs ON accs.AccountId = acc.Id
		INNER JOIN edw_stage.AccountPremium acctvp ON acctvp.AccountId = acc.Id
		LEFT JOIN edw_stage.Product pr on acc.ProductId = pr.id
		WHERE pr.ProductLine = 'CommercialLines'
		AND not exists (select * from edw_stage.AccountTransaction actr where actr.AccountId=acc.id)
		AND GREATEST(acc.CreatedDate,acc.UpdatedDate) > @last_source_extract_ts

		-- Exit if there is no data in the temp table 1.
		IF NOT EXISTS (SELECT * FROM edw_temp.tcommercial_quote_subjectivity_wip_temp1)
		BEGIN
			SET @parameter_desc = @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@last_source_extract_ts AS VARCHAR(200));
			EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk, 0, @parameter_desc;
			RETURN;
		END

		-- Pivot Table
		SELECT	
			 Id
			,RequieredFor
			,DescriptionText
			,CompletedIn
		INTO edw_temp.tcommercial_quote_subjectivity_wip_temp2
		FROM
			(
				SELECT  
					 acc.Id
					,acctvof.Field
					,acctvof.Value
				FROM edw_temp.tcommercial_quote_subjectivity_wip_temp1 acc
				INNER JOIN edw_stage.AccountObject acctvo ON acctvo.AccountId = acc.Id
				INNER JOIN edw_stage.AccountObjectField acctvof ON acctvof.ObjectId = acctvo.id
				WHERE acctvo.ObjectType in ('Tower')
			) t
		PIVOT 
			(
				MAX(Value) FOR Field IN (
					RequieredFor,DescriptionText,CompletedIn
					)
			) pivottable 

		--Create last temp table
		SELECT 
			 cp.commercial_quote_history_sk
			,tmp1.quote_no
			,tmp1.EffectiveDate as effective_dt
			,tmp1.ExpirationDate as expiration_dt
			,tmp1.transaction_seq_no
			,tmp1.Required as required_for
			,tmp1.Description as [description]
			,tmp1.completed_in
			,GETDATE() as create_ts
			,GETDATE() as update_ts
			,@etl_audit_sk as etl_audit_sk
			,tmp1.source_system_sk
		INTO edw_temp.tcommercial_quote_subjectivity_wip_temp3
		FROM edw_temp.tcommercial_quote_subjectivity_wip_temp1 tmp1
		LEFT JOIN edw_temp.tcommercial_quote_subjectivity_wip_temp2 tmp2 on tmp2.Id = tmp1.Id
		LEFT JOIN edw_commercial.tcommercial_quote_history cp on tmp1.quote_no = cp.quote_no and cast(tmp1.EffectiveDate as date) = cast(cp.effective_dt as date) and tmp1.transaction_seq_no = cp.transaction_seq_no


		-- Start Merge process
		MERGE edw_commercial.tcommercial_quote_subjectivity AS Target
		USING edw_temp.tcommercial_quote_subjectivity_wip_temp3 AS Source	
		ON Target.quote_no = Source.quote_no 
		AND Target.effective_dt = Source.effective_dt
		AND Target.transaction_seq_no = Source.transaction_seq_no
		AND Target.required_for = Source.required_for
		AND Target.description = Source.description
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN 
		INSERT 
		(
			 commercial_quote_history_sk
			,quote_no
			,effective_dt
			,expiration_dt
			,transaction_seq_no
			,required_for
			,[description]
			,completed_in
			,create_ts
			,update_ts
			,etl_audit_sk
			,source_system_sk
		)
		VALUES
		(
			 Source.commercial_quote_history_sk
			,Source.quote_no
			,Source.effective_dt
			,Source.expiration_dt
			,Source.transaction_seq_no
			,Source.required_for
			,Source.description
			,Source.completed_in
			,Source.create_ts
			,Source.update_ts
			,Source.etl_audit_sk
			,Source.source_system_sk
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			 Target.commercial_quote_history_sk = Source.commercial_quote_history_sk
			-- ,Target.quote_no = Source.quote_no
			-- ,Target.effective_dt = Source.effective_dt
			,Target.expiration_dt = Source.expiration_dt
			-- ,Target.transaction_seq_no = Source.transaction_seq_no
			-- ,Target.required_for = Source.required_for
			-- ,Target.description = Source.description
			,Target.completed_in = Source.completed_in
			,Target.update_ts = GETDATE()
			,Target.etl_audit_sk = Source.etl_audit_sk
			,Target.source_system_sk = Source.source_system_sk
		;

        --************End************

		SET @rows_affected=@@ROWCOUNT;


		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(CreatedDate,UpdatedDate)) FROM edw_temp.[tcommercial_quote_subjectivity_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp1;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp2;
		DROP TABLE IF EXISTS edw_temp.tcommercial_quote_subjectivity_wip_temp3;

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
