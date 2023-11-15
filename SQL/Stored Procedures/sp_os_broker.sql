-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: 10/20/2023
-- Description: This procedures insert OneShied Broker into tbroker table
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_os_broker]

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

		DROP TABLE IF EXISTS edw_temp.os_tbroker_temp1

		SELECT partner_id as broker_id,partner_name as broker_nm,broker_type as broker_type,partner_phone as broker_phone_no,null as broker_email,
		partner_object_status as broker_status,partner_type as entity_type, 
		CASE WHEN CHARINDEX(' | ',partner_primary_address)>0 THEN
			SUBSTRING(partner_primary_address,1,CHARINDEX(' | ',partner_primary_address)-1)
			ELSE
				partner_primary_address
		END
		AS primary_address_line_1,
		CASE
			WHEN LEN(partner_primary_address) - LEN(REPLACE(partner_primary_address, '|', '')) = 4 THEN NULL
			ELSE
				SUBSTRING
				(partner_primary_address,
					CHARINDEX(' | ',partner_primary_address)+3,
						CHARINDEX(' | ',SUBSTRING(partner_primary_address,CHARINDEX(' | ',partner_primary_address)+3,100))
				)
		END as primary_address_line_2,
		partner_city AS primary_address_city_nm,
		partner_us_state AS primary_address_state_cd,
		partner_zip AS primary_address_zip_cd,
		partner_county AS primary_address_county_nm
		INTO edw_temp.os_tbroker_temp1
		FROM edw_stage.dragon_partner
		WHERE partner_name IS NOT NULL

		INSERT INTO edw_core.tbroker
		(
		broker_id,broker_nm,broker_phone_no,broker_email,broker_status,broker_type,
		entity_type,primary_address_line_1,primary_address_line_2,primary_address_city_nm,primary_address_state_cd,
		primary_address_zip_cd,primary_address_county_nm,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			broker_id,broker_nm,broker_phone_no,broker_email,broker_status,broker_type,
			entity_type,primary_address_line_1,primary_address_line_2,primary_address_city_nm,primary_address_state_cd,
			primary_address_zip_cd,primary_address_county_nm,
			GETDATE() AS create_ts,GETDATE() update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.os_tbroker_temp1

		SET @rows_affected=@@ROWCOUNT;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.os_tbroker_temp1
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