-- =============================================
-- Author:		Hernando Gonzalez
-- Create Date: 06/05/2024
-- Description: This procedures insert pel quote watercraft data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_pel_watercraft_wip]

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

		drop table if exists edw_temp.tquote_pel_watercraft_wip_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,[Index],quote_history_sk,source_system_sk,
			CreatedDate,[Year],Make,Model,[Length],HullValue,Horsepower,AnyWatercraftOwnedTrustOrLlc,AnyWatercraftCaptainOrCrew,
			MotorType,MilesPerHour,SailboatPowerType
			into edw_temp.tquote_pel_watercraft_wip_temp1
		from
		(
		select * 
		from
			(
			 
			select
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(acc.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,acco.[Index],tph.quote_history_sk,
			0 AS transaction_seq_no,acc.CreatedDate,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			accof.Field,accof.[Value]
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
					'Year','Make','Model','Length','HullValue','Horsepower','AnyWatercraftOwnedTrustOrLlc','AnyWatercraftCaptainOrCrew',
					'MotorType','MilesPerHour','SailboatPowerType'
				)
			) as t
		) as t
		pivot 
		(
			max([Value]) FOR Field IN ([Year],Make,Model,[Length],HullValue,Horsepower,AnyWatercraftOwnedTrustOrLlc,AnyWatercraftCaptainOrCrew,
										MotorType,MilesPerHour,SailboatPowerType)
		) as pivottable

		MERGE INTO [edw_core].[tquote_pel_watercraft] AS TARGET
		USING (
		    SELECT
		        PolicyNumber AS quote_no,
		        EffectiveDate AS effective_dt,
		        ExpirationDate AS expiration_dt,
		        transaction_seq_no AS transaction_seq_no,
		        quote_history_sk,
		        [Index] AS watercraft_no,
		        [Year] AS watercraft_year,
		        Make AS watercraft_make,
		        Model AS watercraft_model,
		        [Length] AS watercraft_length,
		        HullValue AS watercraft_hull_value,
		        Horsepower AS watercraft_horsepower,
		        AnyWatercraftOwnedTrustOrLlc AS vessels_owned_trust_llc_in,
		        AnyWatercraftCaptainOrCrew AS vessels_with_captain_crew_in,
		        source_system_sk,
		        getdate() AS create_ts,
		        getdate() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk,
		        MotorType AS watercraft_motor_type,
		        MilesPerHour AS watercraft_miles_per_hr,
		        SailboatPowerType AS watercraft_sailboat_power_type
		    FROM
		        edw_temp.tquote_pel_watercraft_wip_temp1 AS ttpv
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND
		    TARGET.effective_dt = SOURCE.effective_dt AND
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.watercraft_no = SOURCE.watercraft_no

		WHEN MATCHED THEN
		    UPDATE SET
		        TARGET.expiration_dt = SOURCE.expiration_dt,
		        TARGET.quote_history_sk = SOURCE.quote_history_sk,
		        TARGET.watercraft_year = SOURCE.watercraft_year,
		        TARGET.watercraft_make = SOURCE.watercraft_make,
		        TARGET.watercraft_model = SOURCE.watercraft_model,
		        TARGET.watercraft_length = SOURCE.watercraft_length,
		        TARGET.watercraft_hull_value = SOURCE.watercraft_hull_value,
		        TARGET.watercraft_horsepower = SOURCE.watercraft_horsepower,
		        TARGET.vessels_owned_trust_llc_in = SOURCE.vessels_owned_trust_llc_in,
		        TARGET.vessels_with_captain_crew_in = SOURCE.vessels_with_captain_crew_in,
		        TARGET.watercraft_motor_type = SOURCE.watercraft_motor_type,
		        TARGET.watercraft_miles_per_hr = SOURCE.watercraft_miles_per_hr,
		        TARGET.watercraft_sailboat_power_type = SOURCE.watercraft_sailboat_power_type,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        watercraft_no, watercraft_year, watercraft_make, watercraft_model, watercraft_length, watercraft_hull_value,
		        watercraft_horsepower, vessels_owned_trust_llc_in, vessels_with_captain_crew_in,
		        source_system_sk, create_ts, update_ts, etl_audit_sk,
		        watercraft_motor_type, watercraft_miles_per_hr, watercraft_sailboat_power_type
		    )
		    VALUES (
		        SOURCE.quote_no, SOURCE.effective_dt, SOURCE.expiration_dt, SOURCE.transaction_seq_no, SOURCE.quote_history_sk,
		        SOURCE.watercraft_no, SOURCE.watercraft_year, SOURCE.watercraft_make, SOURCE.watercraft_model, SOURCE.watercraft_length, SOURCE.watercraft_hull_value,
		        SOURCE.watercraft_horsepower, SOURCE.vessels_owned_trust_llc_in, SOURCE.vessels_with_captain_crew_in,
		        SOURCE.source_system_sk, SOURCE.create_ts, SOURCE.update_ts, SOURCE.etl_audit_sk,
		        SOURCE.watercraft_motor_type, SOURCE.watercraft_miles_per_hr, SOURCE.watercraft_sailboat_power_type
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_watercraft_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_watercraft_wip_temp1
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
