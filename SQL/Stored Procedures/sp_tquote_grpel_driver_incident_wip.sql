-- ================================================================================================================================================
-- Description: This stored procedure insert info related to tquote_grpel_driver_incident.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 03/17/26		    Yunus Mohammed				1. Created the proc
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_driver_incident_wip] 
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

        -- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_grpel_driver_incident_wip_temp1];

		select 
			PolicyNumber,EffectiveDate,ExpirationDate,
			0 as transaction_seq_no,source_system_sk,quote_history_sk,[Index] as incident_no,
			CreatedDate,UpdatedDate,IncidentSource,IncidentStatus,IncidentDate,IncidentType,IncidentDescription,
			UniqueId as incident_unique_id,	quote_grpel_driver_sk,driver_no
        into [edw_temp].[tquote_grpel_driver_incident_wip_temp1]	
		from
		(					 
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			acco.[Index],tqh.quote_history_sk,
			acco.UniqueId,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,			
			acc.CreatedDate,acc.UpdatedDate,accof.Field,accof.[Value], qgrpd.quote_grpel_driver_sk,qgrpd.driver_no	
			from
            (
                SELECT *
                FROM [edw_stage].[Account] AS a
                WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                AND a.PolicyNumber IS NOT NULL
            ) acc
				inner join edw_stage.Product p on p.Id=acc.ProductId
				inner join edw_stage.AccountObject acco on acc.Id=acco.AccountId
				inner join edw_stage.AccountObjectField accof on acco.Id=accof.ObjectId
				INNER JOIN edw_stage.AccountObject AS pid ON acco.ParentObjectId = pid.Id
				left join [edw_core].[tquote_history] tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0				
                LEFT JOIN edw_core.[tquote_grpel_driver] AS qgrpd ON qgrpd.quote_no = acc.PolicyNumber
                    AND qgrpd.effective_dt = acc.EffectiveDate
					AND qgrpd.transaction_seq_no = 0 and qgrpd.driver_unique_id=pid.UniqueId
			where
                p.[Name]='Participant Personal Excess Liability'
				and p.ProductLine = 'PersonalLines'
				and acco.ObjectType='ReportedIncidents'
				and accof.Field IN 
				(
					'IncidentSource','IncidentStatus','IncidentDate','IncidentType','IncidentDescription'
				)
		) as t
		pivot 
		(
			max([Value]) FOR Field IN 
			(
                IncidentSource,IncidentStatus,IncidentDate,IncidentType,IncidentDescription
            )
		) as pivottable        
		
				-- Start Merge process
		MERGE INTO [edw_core].[tquote_grpel_driver_incident] AS TARGET
		USING (
		    SELECT 
                PolicyNumber as quote_no, EffectiveDate as effective_dt, ExpirationDate as expiration_dt,
                transaction_seq_no, quote_history_sk, quote_grpel_driver_sk,driver_no, 
                incident_no,IncidentSource as incident_source, IncidentStatus as incident_status,IncidentDate as incident_dt,
                incident_unique_id, IncidentType as incident_type,IncidentDescription as incident_description,
                source_system_sk,getdate() as create_ts,getdate()as update_ts,@etl_audit_sk as etl_audit_sk			
            FROM
             [edw_temp].[tquote_grpel_driver_incident_wip_temp1]
		) AS SOURCE
			ON TARGET.quote_no = SOURCE.quote_no
            AND TARGET.quote_grpel_driver_sk = SOURCE.quote_grpel_driver_sk
            AND TARGET.incident_no = SOURCE.incident_no
            AND TARGET.transaction_seq_no = SOURCE.transaction_seq_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
                TARGET.driver_no = SOURCE.driver_no,
                TARGET.incident_source = SOURCE.incident_source,
                TARGET.incident_status = SOURCE.incident_status,
		        TARGET.incident_dt = SOURCE.incident_dt,
                TARGET.incident_unique_id= SOURCE.incident_unique_id,
		        TARGET.incident_type = SOURCE.incident_type,
                TARGET.incident_description = SOURCE.incident_description,		        
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT
            (
                quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,quote_grpel_driver_sk,
                driver_no,incident_no,incident_source,incident_status,incident_dt,incident_unique_id,incident_type,
                incident_description,
                source_system_sk,create_ts,update_ts,etl_audit_sk
		    )
		    VALUES (
		        SOURCE.quote_no,SOURCE.effective_dt,SOURCE.expiration_dt,SOURCE.transaction_seq_no,SOURCE.quote_history_sk,
                SOURCE.quote_grpel_driver_sk,SOURCE.driver_no,SOURCE.incident_no,SOURCE.incident_source,
                SOURCE.incident_status,SOURCE.incident_dt,SOURCE.incident_unique_id,SOURCE.incident_type,
                SOURCE.incident_description,
                SOURCE.source_system_sk,SOURCE.create_ts,SOURCE.update_ts,SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
        SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_grpel_driver_incident_wip_temp1),@last_source_extract_ts)	
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_grpel_driver_incident_wip_temp1];

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