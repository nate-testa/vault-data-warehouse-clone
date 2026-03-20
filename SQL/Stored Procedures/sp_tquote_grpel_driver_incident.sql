-- ================================================================================================================================================
-- Description: This stored procedure insert info related to tquote_grpel_driver_incident.
--------------------------------------------------------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
--------------------------------------------------------------------------------------------------------------------------------------------------
-- 03/17/26		    Yunus Mohammed				1. Created the proc
-- ================================================================================================================================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_driver_incident] 
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_grpel_driver_incident_temp1];

		select 
			PolicyNumber,EffectiveDate,ExpirationDate,
			[Number],source_system_sk,quote_history_sk,[Index] as incident_no,
			CreatedDate,IncidentSource,IncidentStatus,IncidentDate,IncidentType,IncidentDescription,
			UniqueId as incident_unique_id,	quote_grpel_driver_sk,driver_no
        into [edw_temp].[tquote_grpel_driver_incident_temp1]	
		from
		(					 
			select
			acct.PolicyNumber,CAST(acct.EffectiveDate AS DATE) AS EffectiveDate,CAST(acct.ExpirationDate AS DATE) AS ExpirationDate,
			acctvo.[Index],tqh.quote_history_sk,
			acctvo.UniqueId,acct.[Number], 
			CASE WHEN acct.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,			
			acct.CreatedDate,acctvof.Field,acctvof.[Value], qgrpd.quote_grpel_driver_sk,qgrpd.driver_no	
			from
				edw_stage.AccountTransaction acct
				inner join edw_stage.Product p on p.Id=acct.ProductId
				inner join edw_stage.AccountTransactionVersion acctv on acct.Id=acctv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject acctvo on acctv.Id=acctvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField acctvof on acctvo.Id=acctvof.VersionObjectId
				INNER JOIN edw_stage.AccountTransactionVersionObject AS pid ON acctvo.ParentObjectId = pid.Id
				left join [edw_core].[tquote_history] tqh on tqh.quote_no=acct.PolicyNumber
						and tqh.effective_dt=acct.EffectiveDate
						and tqh.transaction_seq_no = acct.policychangenumber
                LEFT JOIN edw_core.[tquote_grpel_driver] AS qgrpd ON qgrpd.quote_no = acct.PolicyNumber AND qgrpd.effective_dt = acct.EffectiveDate
					AND qgrpd.transaction_seq_no = acct.[Number] and qgrpd.driver_unique_id=pid.UniqueId
			where
				acct.PolicyNumber is not null 
				and acct.[Stage] in ('QUOTE','POLICY')
				and p.[Name]='Participant Personal Excess Liability'
				and p.ProductLine = 'PersonalLines'
				and acctvo.ObjectType='ReportedIncidents'
				and acctvof.Field IN 
				(
					'IncidentSource','IncidentStatus','IncidentDate','IncidentType','IncidentDescription'
				)
				and acct.CreatedDate > @last_source_extract_ts
			
		) as t
		pivot 
		(
			max([Value]) FOR Field IN 
			(IncidentSource,IncidentStatus,IncidentDate,IncidentType,IncidentDescription)
		) as pivottable        
		
		INSERT INTO [edw_core].[tquote_grpel_driver_incident]
        (
            quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,quote_grpel_driver_sk,
            driver_no,incident_no,incident_source,incident_status,incident_dt,incident_unique_id,incident_type,
            incident_description,
            source_system_sk,create_ts,update_ts,etl_audit_sk
		)
        SELECT 
           PolicyNumber as quote_no, EffectiveDate as effective_dt, ExpirationDate as expiration_dt,
           [Number] as transaction_seq_no, quote_history_sk, quote_grpel_driver_sk,driver_no, 
           incident_no,IncidentSource as incident_source, IncidentStatus as incident_status,IncidentDate as incident_dt,
           incident_unique_id, IncidentType as incident_type,IncidentDescription as incident_description,
           source_system_sk,getdate() as create_ts,getdate()as update_ts,@etl_audit_sk as etl_audit_sk			
        FROM
            [edw_temp].[tquote_grpel_driver_incident_temp1]

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.[tquote_grpel_driver_incident_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_grpel_driver_incident_temp1];

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