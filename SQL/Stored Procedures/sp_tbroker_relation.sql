-- =================================================================================================
-- Author:		Mohammed Yunus
-- Description: This procedures insert broker relation data 
---------------------------------------------------------------------------------------------------
-- Change date 			|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 04/15/24				Yunus Mohammed				1. Create the proc
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tbroker_relation]

AS
BEGIN
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

		DROP TABLE IF EXISTS edw_temp.tbroker_relation_temp

		select
			brk1.referencecode AS related_broker_id, 
			tb1.broker_sk AS related_broker_sk, -- bring this from tbroker
			NULLIF(br.RelationshipType,'') AS relationship_type,
			brk2.referencecode AS relation_broker_id,
			tb2.broker_sk AS relation_broker_sk,
			CASE
				br.IsBillingOffice
				WHEN 1 THEN 'Yes'
				WHEN 0 THEN 'No'
				ELSE ''
			END AS billing_office_in
		into edw_temp.tbroker_relation_temp
		from [edw_stage].[BrokerageRelation] Br
		inner join [edw_stage].[Brokerage] Brk1 on brk1.id = br.relatedbrokerageid
		inner join [edw_stage].[Brokerage] Brk2 on brk2.id = br.relationBrokerageId
		inner join [edw_core].tbroker tb1 on tb1.broker_id = CAST(brk1.referencecode AS VARCHAR(255))
		inner join [edw_core].tbroker tb2 on tb2.broker_id = CAST(brk2.referencecode AS VARCHAR(255))
		WHERE
			GREATEST(br.CreatedDate,br.UpdatedDate) > @last_source_extract_ts

	    DELETE FROM edw_core.tbroker_relation;
		
		-- Reset identity column
		DBCC CHECKIDENT('edw_core.tbroker_relation',RESEED,0);
		
		INSERT INTO edw_core.tbroker_relation
		(
			related_broker_id, related_broker_sk, relationship_type, relation_broker_id,
			relation_broker_sk, billing_office_in, create_ts, update_ts, etl_audit_sk
		)
		SELECT
			related_broker_id, related_broker_sk, relationship_type, relation_broker_id,
			relation_broker_sk, billing_office_in,
			GETDATE() AS create_ts,GETDATE() AS update_ts,@etl_audit_sk
		FROM
			edw_temp.tbroker_relation_temp
		
		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = '2017-01-01'
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tbroker_relation_temp
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