-- =============================================
-- Author:		Hernando Gonzalez
-- Description: This stored procedure insert info related to Hubspot - Contact
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/17/24		Hernando Gonzalez			1. Created this procedure 
-- 07/26/24		Hernando Gonzalez			2. Updated logic for @last_source_extract_ts
-- 11/20/25		Dinesh Bobbili				3. Update logic and changed insert to merge
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_producer_hubspot_feed]
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT = NULL
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
		DROP TABLE IF EXISTS edw_temp.producer_hubspot_feed_producer_dupes;
		select email
		into edw_temp.producer_hubspot_feed_producer_dupes
		from edw_core.tproducer
		group by email
		having count(*) > 1

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[producer_hubspot_feed_temp1];

		-- Start Insert process
        -- TRUNCATE TABLE [edw_integration].[producer_hubspot_feed]
        ;

		SELECT
			p.broker_id,
			p.producer_id,
			p.email,
			p.first_nm,
			p.last_nm,
			p.phone_no,
			br.broker_status,
			p.title,
			p.producer_role [producer_role],
			p.producer_status,
			getdate() as create_ts,
			getdate() as update_ts,
			@etl_audit_sk AS etl_audit_sk
		INTO [edw_temp].[producer_hubspot_feed_temp1] 
		FROM edw_core.tproducer p	
		INNER JOIN edw_core.tbroker br
			ON p.broker_sk = br.broker_sk
		and greatest(p.create_ts, p.update_ts) > @last_source_extract_ts
		and not exists (select 1 from edw_integration.producer_hubspot_feed f where p.producer_id = f.producer_id)
		and p.email not in (select  email from edw_temp.producer_hubspot_feed_producer_dupes)
		UNION ALL 
		SELECT
			p.broker_id,
			p.producer_id,
			p.email,
			p.first_nm,
			p.last_nm,
			p.phone_no,
			br.broker_status,
			p.title,
			p.producer_role [producer_role],
			p.producer_status,
			getdate() as create_ts,
			getdate() as update_ts,
			@etl_audit_sk AS etl_audit_sk
		FROM edw_core.tproducer p	
		INNER JOIN edw_core.tbroker br
			ON p.broker_sk = br.broker_sk
		and greatest(p.create_ts, p.update_ts) > @last_source_extract_ts
		and exists (select 1 from edw_integration.producer_hubspot_feed f where p.producer_id = f.producer_id
		and (ISNULL(p.broker_id,'')        <> ISNULL(f.broker_id,'')
			OR ISNULL(p.email,'')            <> ISNULL(f.email,'')
			OR ISNULL(p.first_nm,'')         <> ISNULL(f.first_nm,'')
			OR ISNULL(p.last_nm,'')          <> ISNULL(f.last_nm,'')
			OR ISNULL(p.phone_no,'')         <> ISNULL(f.phone_no,'')
			OR ISNULL(br.broker_status,'')    <> ISNULL(f.broker_status,'')
			OR ISNULL(p.title,'')            <> ISNULL(f.title,'')
			OR ISNULL(p.producer_role,'')    <> ISNULL(f.producer_role,'')
			OR ISNULL(p.producer_status,'')  <> ISNULL(f.producer_status,'')))
		and p.email not in (select  email from edw_temp.producer_hubspot_feed_producer_dupes)
		UNION ALL 
		select  p.broker_id,
			p.producer_id,
			case when p.producer_status = 'Disabled'  then null else p.email end as email,
			p.first_nm,
			p.last_nm,
			p.phone_no,
			br.broker_status,
			p.title,
			p.producer_role [producer_role],
			p.producer_status,
			getdate() as create_ts,
			getdate() as update_ts,
			@etl_audit_sk AS etl_audit_sk
		from edw_core.tproducer p 
		INNER JOIN edw_core.tbroker br ON p.broker_sk = br.broker_sk
		left join edw_integration.producer_hubspot_feed f on p.producer_id = f.producer_id
		where p.email in (select  email from edw_temp.producer_hubspot_feed_producer_dupes)
		and (ISNULL(p.broker_id,'')        <> ISNULL(f.broker_id,'')
		OR ISNULL(case when p.producer_status = 'Disabled'  then null else p.email end,'')            <> ISNULL(f.email,'')
		OR ISNULL(p.first_nm,'')         <> ISNULL(f.first_nm,'')
		OR ISNULL(p.last_nm,'')          <> ISNULL(f.last_nm,'')
		OR ISNULL(p.phone_no,'')         <> ISNULL(f.phone_no,'')
		OR ISNULL(br.broker_status,'')    <> ISNULL(f.broker_status,'')
		OR ISNULL(p.title,'')            <> ISNULL(f.title,'')
		OR ISNULL(p.producer_role,'')    <> ISNULL(f.producer_role,'')
		OR ISNULL(p.producer_status,'')  <> ISNULL(f.producer_status,''))
		;

        -- Start Merge process
        MERGE edw_integration.producer_hubspot_feed AS Target
		USING edw_temp.producer_hubspot_feed_temp1 AS Source
			ON Target.producer_id = Source.producer_id
		WHEN NOT MATCHED BY TARGET
		THEN INSERT (
				broker_id,
				producer_id,
				email,
				first_nm,
				last_nm,
				phone_no,
				broker_status,
				title,
				producer_role,
				producer_status,
				create_ts,
				update_ts,
				etl_audit_sk
			)
			VALUES (
				Source.broker_id,
				Source.producer_id,
				Source.email,
				Source.first_nm,
				Source.last_nm,
				Source.phone_no,
				Source.broker_status,
				Source.title,
				Source.producer_role,
				Source.producer_status,
				Source.create_ts,
				Source.update_ts,
				Source.etl_audit_sk
			)
		WHEN MATCHED
		THEN UPDATE SET
				Target.broker_id       = Source.broker_id,
				Target.email           = Source.email,
				Target.first_nm        = Source.first_nm,
				Target.last_nm         = Source.last_nm,
				Target.phone_no        = Source.phone_no,
				Target.broker_status   = Source.broker_status,
				Target.title           = Source.title,
				Target.producer_role   = Source.producer_role,
				Target.producer_status = Source.producer_status,
				Target.update_ts       = Source.update_ts;
        --************End************

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS [edw_temp].[producer_hubspot_feed_temp1];

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
GO