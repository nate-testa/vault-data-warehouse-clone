SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ====================================================================================================================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-11
-- Description: This stored procedure insert and update info related to tauto_vehicle.
---------------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------------------------------------------
-- 11/06/23		Alberto Almario					1. change to use UniqueId instead of Index and change name from vehicle_no to vehicle_unique_id
-- 11/07/23     Sandeep Gundreddy               2. replaced index with uniqueid in the partition by clause
-- 03/04/24     Alberto Almario                 3. add 5 new columns
-- ====================================================================================================================================
CREATE OR ALTER  PROCEDURE [edw_core].[sp_tauto_vehicle]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_vehicle_temp1];

		WITH FinalTable AS (
            SELECT
                ROW_NUMBER() OVER (PARTITION BY PolicyNumber, EffectiveDate, [UniqueId] ORDER BY policychangenumber DESC) AS RN, 
                PolicyNumber, EffectiveDate, [Index] as vehicle_no, [UniqueId] as vehicle_unique_id, IssuedDate,
                [VehicleType],[CollectorCarType],[VIN],[ModelYear],[Make],[Model],[Body],[Weight],[Horsepower],[EngineSize],[EngineType],[HighPerformanceVehicle],[PurchaseDate],[VinIsInvalid],[VinInvalidMessage],
                [VINChangeIndicator],[EngineCylinders],[Height],[Length],[Width],
                source_system_sk
            
            FROM
                (
                    SELECT
                        acct.PolicyNumber, acct.EffectiveDate, acct.IssuedDate, acct.policychangenumber,
                        acctvo.[Index], acctvo.[UniqueId], acctvof.[Field], acctvof.[Value],
                        CASE 
                            WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                            ELSE 4 --(Metal)
                        END as [source_system_sk]
                    FROM
                        (SELECT
                            *
                        FROM [edw_stage].[AccountTransaction]
                        WHERE
                            [State] = 'ISSUED'
                            AND IssuedDate > @last_source_extract_ts
                        ) acct
                    INNER JOIN [edw_stage].[Product] p ON p.Id = acct.ProductId
                    INNER JOIN [edw_stage].[AccountTransactionVersion] acctv ON acctv.AccountTransactionId = acct.Id
                    INNER JOIN [edw_stage].[AccountTransactionVersionObject] acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                    INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] acctvof ON acctvof.VersionObjectId = acctvo.id
                    WHERE 1=1
                        AND p.[Name] = 'Automobile'
                        AND p.ProductLine = 'PersonalLines'
                        AND acctvof.[Group] = 'Vehicle'
                ) t
            PIVOT 
                (
                    MAX([Value]) FOR [Field] IN 
                    (
                        [VehicleType],[CollectorCarType],[VIN],[ModelYear],[Make],[Model],[Body],[Weight],[Horsepower],[EngineSize],[EngineType],[HighPerformanceVehicle],[PurchaseDate],[VinIsInvalid],[VinInvalidMessage],
                        [VINChangeIndicator],[EngineCylinders],[Height],[Length],[Width]
                    )
                ) pivottable

        )

        SELECT * 
        INTO [edw_temp].[tauto_vehicle_temp1]
        FROM FinalTable WHERE RN = 1
        

		-- Start Merge process
		MERGE [edw_core].[tauto_vehicle] AS trg
		USING (
	        SELECT 
                t1.PolicyNumber as policy_no,
                t1.EffectiveDate as effective_dt,
                t1.vehicle_unique_id,
                t1.vehicle_no,
                t1.VehicleType as vehicle_type,
                t1.CollectorCarType as collector_car_type,
                t1.VIN as vehicle_vin,
                t1.ModelYear as vehicle_model_year,
                t1.Make as vehicle_make,
                t1.Model as vehicle_model,
                t1.Body as vehicle_body,
                t1.Weight as vehicle_weight,
                t1.Horsepower as vehicle_horsepower,
                t1.EngineSize as vehicle_engine_size,
                t1.EngineType as vehicle_engine_type,
                t1.HighPerformanceVehicle as high_performance_vehicle_in,
                t1.PurchaseDate as purchase_dt,
                t1.VinIsInvalid as vehicle_vin_invalid_in,
                t1.VinInvalidMessage as vehicle_vin_invalid_message,
                t1.source_system_sk
                ,t1.VINChangeIndicator as vehicle_vin_change_in
                ,t1.EngineCylinders as vehicle_engine_cylinders
                ,t1.Height as vehicle_height
                ,t1.Length as vehicle_length
                ,t1.Width as vehicle_width

			FROM 
				[edw_temp].[tauto_vehicle_temp1] AS t1
		) AS src
		ON src.policy_no = trg.policy_no
        AND src.effective_dt = trg.effective_dt
        AND src.vehicle_unique_id = trg.vehicle_unique_id
		-- For Inserts
		WHEN NOT MATCHED BY TARGET THEN
		INSERT (
            policy_no,
            effective_dt,
            vehicle_no,
            vehicle_type,
            collector_car_type,
            vehicle_vin,
            vehicle_model_year,
            vehicle_make,
            vehicle_model,
            vehicle_body,
            vehicle_weight,
            vehicle_horsepower,
            vehicle_engine_size,
            vehicle_engine_type,
            high_performance_vehicle_in,
            purchase_dt,
            source_system_sk,
            create_ts,
            update_ts,
            etl_audit_sk,
            vehicle_vin_invalid_in,
            vehicle_vin_invalid_message,
            vehicle_unique_id
            ,vehicle_vin_change_in
            ,vehicle_engine_cylinders
            ,vehicle_height
            ,vehicle_length
            ,vehicle_width
			)
		VALUES (
            src.policy_no,
            src.effective_dt,
            src.vehicle_no,
            src.vehicle_type,
            src.collector_car_type,
            src.vehicle_vin,
            src.vehicle_model_year,
            src.vehicle_make,
            src.vehicle_model,
            src.vehicle_body,
            src.vehicle_weight,
            src.vehicle_horsepower,
            src.vehicle_engine_size,
            src.vehicle_engine_type,
            src.high_performance_vehicle_in,
            src.purchase_dt,
            src.source_system_sk,
            getdate(), 
            getdate(), 
            @etl_audit_sk,
            src.vehicle_vin_invalid_in,
            src.vehicle_vin_invalid_message,
            src.vehicle_unique_id
            ,src.vehicle_vin_change_in
            ,src.vehicle_engine_cylinders
            ,src.vehicle_height
            ,src.vehicle_length
            ,src.vehicle_width
            )
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
            trg.vehicle_type = src.vehicle_type,
            trg.collector_car_type = src.collector_car_type,
            trg.vehicle_vin = src.vehicle_vin,
            trg.vehicle_model_year = src.vehicle_model_year,
            trg.vehicle_make = src.vehicle_make,
            trg.vehicle_model = src.vehicle_model,
            trg.vehicle_body = src.vehicle_body,
            trg.vehicle_weight = src.vehicle_weight,
            trg.vehicle_horsepower = src.vehicle_horsepower,
            trg.vehicle_engine_size = src.vehicle_engine_size,
            trg.vehicle_engine_type = src.vehicle_engine_type,
            trg.high_performance_vehicle_in = src.high_performance_vehicle_in,
            trg.purchase_dt = src.purchase_dt,
            trg.vehicle_vin_invalid_in = src.vehicle_vin_invalid_in,
            trg.vehicle_vin_invalid_message = src.vehicle_vin_invalid_message,
            trg.update_ts = getdate(),
            trg.vehicle_no = src.vehicle_no
            ,trg.vehicle_vin_change_in = src.vehicle_vin_change_in
            ,trg.vehicle_engine_cylinders = src.vehicle_engine_cylinders
            ,trg.vehicle_height = src.vehicle_height
            ,trg.vehicle_length = src.vehicle_length
            ,trg.vehicle_width = src.vehicle_width
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_vehicle_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_vehicle_temp1];

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
