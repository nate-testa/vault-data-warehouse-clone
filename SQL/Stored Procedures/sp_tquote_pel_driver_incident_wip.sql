-- =============================================
-- Author:		Hernando Gonzalez
-- Create Date: 06/05/2024
-- Description: This procedures insert pel quote driver incident data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 
-- =========================================================================================================================== 
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tquote_pel_driver_incident_wip]

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

		drop table if exists edw_temp.tquote_pel_driver_incident_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,source_system_sk,quote_history_sk,[Index],
			CreatedDate,IncidentDate,IncidentType,IncidentDescription,IncludeInRate,Disputed
			into edw_temp.tquote_pel_driver_incident_wip_temp1
		from
		(
		select * 
		from
			(
			 
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,acco.[Index],tph.quote_history_sk ,
			0 AS transaction_seq_no, 
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,			
			acc.CreatedDate,accof.Field,accof.[Value]
			from
				(
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				inner join edw_stage.Product p on p.Id=acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				left join [edw_core].[tquote_history] tph on tph.quote_no=acc.PolicyNumber
						and tph.effective_dt=acc.EffectiveDate
						and tph.transaction_seq_no = acc.Number
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				--and acc.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and acco.ObjectType='Watercraft'
				and accof.Field IN 
				(
					'IncidentDate','IncidentType','IncidentDescription','IncludeInRate','Disputed'
				)
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN (IncidentDate,IncidentType,IncidentDescription,IncludeInRate,Disputed)
		) as pivottable

		MERGE INTO [edw_core].[tquote_pel_driver_incident] AS TARGET
		USING (
		    SELECT
		        ttpv.PolicyNumber AS quote_no,
		        ttpv.EffectiveDate AS effective_dt,
		        ttpv.ExpirationDate AS expiration_dt,
		        ttpv.transaction_seq_no AS transaction_seq_no,
		        ttpv.quote_history_sk AS quote_history_sk,
		        ttpv.[Index] AS incident_no,
		        ttpv.IncidentDate AS incident_dt,
		        ttpv.IncidentType AS incident_type,
		        ttpv.IncidentDescription AS incident_desc,
		        ttpv.IncludeInRate AS include_in_rate_in,
		        ttpv.Disputed AS incident_disputed_in,
		        ttpv.source_system_sk AS source_system_sk,
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
		    FROM
		        edw_temp.tquote_pel_driver_incident_wip_temp1 AS ttpv
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.incident_no = SOURCE.incident_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.incident_dt = SOURCE.incident_dt,
		        TARGET.incident_type = SOURCE.incident_type,
		        TARGET.incident_desc = SOURCE.incident_desc,
		        TARGET.include_in_rate_in = SOURCE.include_in_rate_in,
		        TARGET.incident_disputed_in = SOURCE.incident_disputed_in,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        incident_no, incident_dt, incident_type, incident_desc, include_in_rate_in, incident_disputed_in,
		        source_system_sk, create_ts, update_ts, etl_audit_sk
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.incident_no, SOURCE.incident_dt, SOURCE.incident_type, SOURCE.incident_desc, SOURCE.include_in_rate_in, SOURCE.incident_disputed_in,
		        SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.tquote_pel_driver_incident_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_driver_incident_temp1
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
