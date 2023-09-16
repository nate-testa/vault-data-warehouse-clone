-- =================================================================================================
-- Author:		Yunus Mohammed 
-- Description: This procedures inserts and updates tax fee and surcharge
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23		Yunus Mohammed					1. Created this procedure
-- 06/28/23		Architha Gudimalla				2. Made changes to fix the errors on first run 
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_ttax_fee_surcharge]

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

		-- Create temp table with name
		DROP TABLE IF EXISTS edw_temp.ttax_fee_surcharge_temp1 

		SELECT	nullif(trim(replace([name], '  ',' ')),'') as tax_fee_surcharge_name, 
				max(nullif(trim([Type]),'')) as tax_fee_surcharge_type,
				max(case when UpdatedDate is not null then UpdatedDate else CreatedDate end) UpdatedDate
		INTO edw_temp.ttax_fee_surcharge_temp1
		FROM edw_stage.AccountTransactionTaxAndFee
		WHERE GREATEST(CreatedDate,UpdatedDate)>@last_source_extract_ts
		group by replace([name], '  ',' ')    

		-- Insert and Update [ttax_fee_surcharge] table
		MERGE [edw_core].[ttax_fee_surcharge] AS Target
		USING edw_temp.ttax_fee_surcharge_temp1 AS Source
		ON Source.tax_fee_surcharge_name = Target.tax_fee_surcharge_cd and source.tax_fee_surcharge_type = target.tax_fee_surcharge_category_nm
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT 
			(
				tax_fee_surcharge_cd,tax_fee_surcharge_desc,tax_fee_surcharge_category_nm,create_ts,update_ts
			)
		VALUES
			(
				Source.tax_fee_surcharge_name,Source.tax_fee_surcharge_name,Source.tax_fee_surcharge_type,GETDATE(),GETDATE()
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.tax_fee_surcharge_desc			= Source.tax_fee_surcharge_name,
		Target.tax_fee_surcharge_category_nm	= Source.tax_fee_surcharge_type,
		Target.[update_ts]						= GETDATE();

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(UpdatedDate) FROM edw_temp.ttax_fee_surcharge_temp1 ct),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.ttax_fee_surcharge_temp1
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

