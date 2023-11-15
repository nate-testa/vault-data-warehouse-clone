-- =================================================================================================
-- Author:		Yunus Mohammed 
-- Description: This procedures inserts and updates user data
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23		Yunus Mohammed					1. Created this procedure
-- 06/28/23		Architha Gudimalla				2. Made changes to fix the errors on first run 
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tuser]

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
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm)
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT
		
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Create temp table with name as tuser_temp
		DROP TABLE IF EXISTS edw_temp.tuser_temp
        SELECT 	id,
				NULLIF(TRIM(usr.name),'') name, 
				NULLIF(TRIM(usr.FirstName),'') FirstName,  
				NULLIF(TRIM(usr.LastName),'') LastName,  
				NULLIF(TRIM(usr.MobilePhone),'') MobilePhone, 
				NULLIF(TRIM(usr.OtherPhone),'') OtherPhone,  
				NULLIF(TRIM(usr.Email),'') Email,  
				NULLIF(TRIM(usr.PreferredName),'') PreferredName ,  
				NULLIF(TRIM(usr.ProfileImageURL),'') ProfileImageURL,
				CreatedDate,UpdatedDate
        INTO edw_temp.tuser_temp 
		FROM edw_stage.[user] usr
		WHERE greatest(CreatedDate,UpdatedDate) > @last_source_extract_ts

		INSERT into edw_core.tuser
		(
				[user_id], [first_nm], [last_nm], [email], [phone_no],    
				[create_ts], [update_ts], [etl_audit_sk]
			)
		select  id, FirstName, LastName, Email, MobilePhone, getdate(), getdate(), @etl_audit_sk
		from edw_temp.tuser_temp;
			
		/*
		-- Insert and Update tuser table
		MERGE [edw_core].[tuser] AS Target
		USING edw_temp.tuser_temp AS Source
		ON Source.Id = Target.[user_id]
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				[user_id],[first_nm],[last_nm],[email],[phone_no],[address_line1],[address_line2],[city_nm],[state_cd],
				[zip_cd],[branch_nm],[create_ts],[update_ts],[etl_audit_sk]
			)
		VALUES (Source.Id,Source.FirstName,Source.LastName,Source.Email,Source.MobilePhone,
			null,null,null,null,null,null,@current_date,@current_date,@etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.[first_nm]	= Source.FirstName,
        Target.[last_nm]	= Source.LastName,
		Target.[email]	= Source.Email,
		Target.[phone_no]	= Source.MobilePhone;
		*/
	
		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(u.CreatedDate,u.UpdatedDate)) FROM edw_temp.tuser_temp u),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		DROP TABLE IF EXISTS edw_temp.tuser_temp
		
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + CAST(ERROR_NUMBER() AS NVARCHAR(100)) + ' Error State:' + CAST(ERROR_STATE() AS NVARCHAR(100))
							+ ' Error Severity:' + CAST(ERROR_SEVERITY() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Procedure:' + ERROR_PROCEDURE() + ' Error Line:' +CAST(ERROR_LINE() AS NVARCHAR(100)) +
							CHAR(13) + 'Error Message:' + ERROR_MESSAGE()
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message
	END CATCH

END

