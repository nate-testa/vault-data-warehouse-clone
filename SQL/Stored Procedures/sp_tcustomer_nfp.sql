-- =============================================================================================================
-- Author:		Dinesh Bobbili
-- Description: This procedures inserts and updates nfp Customer data
------------------------------------------------------------------------------------------------------------
-- Change date  |Author						        |	Change Description
------------------------------------------------------------------------------------------------------------
-- 08/22/2023   Dinesh Bobbili						1. Created this procedure 
-- ============================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcustomer_nfp]

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

		DECLARE @max_customer_id INT;
		SELECT @max_customer_id = ISNULL(MAX(CAST(SUBSTRING(customer_id, 4, 7) AS INT)), 0)
		FROM [edw_core].[tcustomer] 
		WHERE customer_id LIKE 'NFP%';

		DROP TABLE IF EXISTS edw_temp.tcustomer_nfp_temp1;
		with nfp_base as (
		SELECT 	insured_first_name + ' ' + insured_last_name AS customer_nm,
				insured_first_name AS first_nm,
				insured_last_name AS last_nm,
				address1 AS mailing_address_line1,
				address2 AS mailing_address_line2,
				city AS mailing_address_city_nm,
				state AS mailing_address_state_cd,
				zip AS mailing_address_zip_cd,
				row_number() over(partition by insured_first_name, insured_last_name, address1, zip order by  create_ts) as rn,
				reporting_month
		FROM edw_stage.nfp_policy
		WHERE reporting_month > @last_source_extract_ts)
		select 'NFP' + RIGHT('0000000' + CAST(@max_customer_id + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR), 7)  AS customer_id,
			customer_nm,
			first_nm,
			last_nm,
			mailing_address_line1,
			mailing_address_line2,
			mailing_address_city_nm,
			mailing_address_state_cd,
			mailing_address_zip_cd,
			reporting_month
		INTO edw_temp.tcustomer_nfp_temp1
		from nfp_base a 
		where not exists (select 1 
				from edw_core.tcustomer b
				where  UPPER(a.first_nm) = UPPER(b.first_nm)
				and UPPER(a.last_nm) = UPPER(b.last_nm)
				and UPPER(a.mailing_address_line1) = UPPER(b.mailing_address_line1)
				and a.mailing_address_zip_cd = b.mailing_address_zip_cd)
		and rn = 1

		INSERT INTO [edw_core].[tcustomer] (
			customer_id,
			customer_nm,
			first_nm,
			last_nm,
			mailing_address_line1,
			mailing_address_line2,
			mailing_address_city_nm,
			mailing_address_state_cd,
			mailing_address_zip_cd,
			create_ts, 
			update_ts, 
			etl_audit_sk)
		select customer_id,
			customer_nm,
			first_nm,
			last_nm,
			mailing_address_line1,
			mailing_address_line2,
			mailing_address_city_nm,
			mailing_address_state_cd,
			mailing_address_zip_cd,
			GETDATE(), 
			GETDATE(),
			@etl_audit_sk
		from edw_temp.tcustomer_nfp_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(reporting_month) FROM edw_temp.[tcustomer_nfp_temp1] t1),@last_source_extract_ts)

        DROP TABLE IF EXISTS edw_temp.[tcustomer_nfp_temp1]
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
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