SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert and update info related to Collection Coverage
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 10/11/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_status_history]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_status_history_temp1];
		SELECT 
			PolicyNumber as quote_no, EffectiveDate
			,quote_sk
			,user_sk
			,transaction_type, transaction_status, transaction_ts
			,user_nm
			,[source_system_sk]
			,CreatedDate
		INTO [edw_temp].[tquote_status_history_temp1]
		FROM
			(
			SELECT DISTINCT
				ac.PolicyNumber, ac.EffectiveDate
				,tq.quote_sk
				,tusr.user_sk
				,CONCAT(tusr.first_nm, ' ', tusr.last_nm) as user_nm
				,ash.Stage as transaction_type, ash.[State] as transaction_status, ash.CreatedDate as transaction_ts
				,ash.CreatedDate
                --, acct.UpdatedDate
				,case when ash.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(select * from edw_stage.AccountStatusHistory
				WHERE
					CreatedDate>@last_source_extract_ts 
				) ash
                INNER JOIN edw_stage.Account ac ON ash.AccountId=ac.id
				INNER JOIN edw_core.tquote tq on tq.quote_no=ac.PolicyNumber 
				LEFT JOIN edw_core.[tuser] tusr on tusr.[user_id] = ash.UserId 
				
		) as f
			
		-- Start Insert process
		INSERT INTO [edw_core].[tquote_status_history] (
			[quote_no]
           ,[effective_dt]
           ,[quote_sk]
           ,[user_sk]
           ,[user_nm]
           ,[transaction_type]
           ,[transaction_status]
           ,[transaction_ts]
           ,[source_system_sk]
           ,[create_ts]
           ,[update_ts]
           ,[etl_audit_sk]
		)
		SELECT [quote_no]
           ,[EffectiveDate]
           ,[quote_sk]
           ,[user_sk]
           ,[user_nm]
           ,[transaction_type]
           ,[transaction_status]
           ,[transaction_ts]
           ,[source_system_sk]
           ,getdate()
           ,getdate()
		   ,@etl_audit_sk
		FROM 
			[edw_temp].[tquote_status_history_temp1]

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.[CreatedDate]) FROM edw_temp.[tquote_status_history_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_status_history_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END

GO