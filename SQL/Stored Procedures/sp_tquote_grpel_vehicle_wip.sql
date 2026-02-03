-- =========================================================================================================================== 
-- Description: This procedures insert and update info related to grpel WIP quote vehicle data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			   |Author							            |	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 02/03/26 			   Yunus Mohammed					1. Created this procedure
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_grpel_vehicle_wip]

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

		drop table if exists edw_temp.tquote_grpel_vehicle_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,quote_history_sk,source_system_sk,
			CreatedDate,UpdatedDate,[Index],ModelYear,Make,Model,vehicle_unique_id
		into edw_temp.tquote_grpel_vehicle_wip_temp1
		from
		(
		select * 
		from
			(
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tqh.quote_history_sk ,
			0 AS transaction_seq_no,acco.[Index],
			acc.CreatedDate,acc.UpdatedDate,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			accof.Field,accof.[Value]
			,acco.[UniqueId] as vehicle_unique_id
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
				left join [edw_core].[tquote_history] tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acc.PolicyNumber is not null
				and p.[Name]='Participant Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and acco.ObjectType='Vehicle'
				and accof.Field IN 
				(
                        'ModelYear','Make','Model'
				)
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN 
            (
                ModelYear,Make,Model
            )
		) as pivottable

		MERGE INTO  [edw_core].[tquote_grpel_vehicle] AS TARGET
		USING (
		    SELECT
		        PolicyNumber AS quote_no,
		        EffectiveDate AS effective_dt,
		        ExpirationDate AS expiration_dt,
		        transaction_seq_no AS transaction_seq_no,
		        quote_history_sk,
		        [Index] AS vehicle_no,
		        [ModelYear] AS vehicle_year,
		        Make AS vehicle_make,
		        Model AS vehicle_model,
	            source_system_sk,
		        getdate() AS create_ts,
		        getdate() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
				,vehicle_unique_id
		    FROM
		        edw_temp.tquote_grpel_vehicle_wip_temp1 AS ttpv
                where quote_history_sk is not null
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    --TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.vehicle_unique_id = SOURCE.vehicle_unique_id

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,		        
		        TARGET.vehicle_year = SOURCE.vehicle_year,
		        TARGET.vehicle_make = SOURCE.vehicle_make,
		        TARGET.vehicle_model = SOURCE.vehicle_model,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk,
		        TARGET.source_system_sk = SOURCE.source_system_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
                   quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
			vehicle_no,vehicle_year,vehicle_make,vehicle_model,vehicle_unique_id,
			source_system_sk,create_ts,update_ts,etl_audit_sk
		    )
		    VALUES (
		       SOURCE.quote_no,SOURCE.effective_dt,SOURCE.expiration_dt, SOURCE.transaction_seq_no,SOURCE.quote_history_sk,
                SOURCE.vehicle_no,SOURCE.vehicle_year,SOURCE.vehicle_make,SOURCE.vehicle_model,SOURCE.vehicle_unique_id,
                SOURCE.source_system_sk,SOURCE.create_ts,SOURCE.update_ts,SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_grpel_vehicle_wip_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_grpel_vehicle_wip_temp1
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