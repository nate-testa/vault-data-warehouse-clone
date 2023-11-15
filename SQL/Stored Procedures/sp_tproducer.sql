-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert and update producer data 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/12/23		Mohammed Yunus					1. Created this procedure 
-- 10/27/23		Architha Gudimalla				2. Added cast on broker_id
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tproducer]
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

		-- Create temp table with name as sp_tproducer_temp
		DROP TABLE IF EXISTS edw_temp.tproducer_temp1 

		SELECT
			tbr.broker_id,
			tbr.broker_sk,
			NULLIF(br.FirstName,'') AS first_nm,
			NULLIF(LastName,'') AS last_nm,
			NULLIF(Title,'') AS title,
			NULLIF(Email,'') AS email,
			NULLIF(Phone,'') AS phone_no,
			NULLIF(NationalProducerNumber,'') AS national_producer_no,
			br.CreatedDate,
			br.UpdatedDate
		INTO edw_temp.tproducer_temp1
		FROM
			edw_stage.[Broker] br
			INNER JOIN edw_stage.Brokerage brk on brk.id=br.BrokerageId
			INNER JOIN edw_core.tbroker tbr on tbr.broker_id=cast(brk.ProducerId as varchar)
		WHERE
				GREATEST(br.CreatedDate,br.UpdatedDate)>@last_source_extract_ts
		
		-- Delete from [tproducer] table
		DELETE FROM edw_core.[tproducer];

		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tproducer',RESEED,0);

		INSERT edw_core.[tproducer]
			(
				broker_id,broker_sk,first_nm,last_nm,title,email,phone_no,
				national_producer_no,create_ts,update_ts,etl_audit_sk
			)
		SELECT
				broker_id,broker_sk,first_nm,last_nm,title,email,phone_no,
				national_producer_no,GETDATE(),GETDATE(),@etl_audit_sk
		FROM
			edw_temp.tproducer_temp1

		SET @rows_affected=@@ROWCOUNT;	

		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tproducer_temp1
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
