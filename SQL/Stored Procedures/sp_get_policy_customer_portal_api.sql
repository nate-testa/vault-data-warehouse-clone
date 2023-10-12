SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: 2023-10-05
-- Description: This stored procedure insert and update info related to Policy Customer
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_get_policy_customer_portal_api]
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

		MERGE [edw_integration].[policy_customer_portal_api] as TARGET
		USING (SELECT
		tp.[policy_no]
        ,tb.[billingaccount_no]
        ,tprod.[product_nm]
        ,tp.[insured_nm]
        ,tp.[create_ts]
        ,tp.[update_ts]
        ,tp.[etl_audit_sk]
		FROM [edw_core].[tpolicy] tp
		LEFT JOIN [edw_core].[tbillingaccount] tb
		ON tp.billingaccount_sk = tb.billingaccount_sk
		LEFT JOIN [edw_core].[tproduct] tprod
		ON tp.product_cd = tprod.product_cd
		WHERE
			GREATEST(tp.[update_ts])>@last_source_extract_ts --20230717 added
			AND tb.[billingaccount_no] is not null
		) as SOURCE
		ON Source.[policy_no] = Target.[policy_no]
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			[policy_no]
            ,[billingaccount_no]
            ,[product_nm]
            ,[insured_nm]
            ,[create_ts]
            ,[update_ts]
            ,[etl_audit_sk]
			)
		VALUES (Source.[policy_no],Source.[billingaccount_no],Source.[product_nm],Source.[insured_nm],Source.[create_ts],Source.[update_ts],Source.[etl_audit_sk])
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		Target.[billingaccount_no] = Source.[billingaccount_no],
		Target.[product_nm] = Source.[product_nm],
		Target.[insured_nm] = Source.[insured_nm],
		--Target.[create_ts] = Source.[create_ts],
		Target.[update_ts] = Source.[update_ts],
		Target.[etl_audit_sk] = Source.[etl_audit_sk];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX([update_ts]) FROM [edw_integration].[policy_customer_portal_api] t1),@last_source_extract_ts);
		
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