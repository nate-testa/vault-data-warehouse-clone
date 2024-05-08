SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2024-04-06
-- Description: This stored procedure insert and update info related to tquote_auto_garage_location_wip.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_auto_garage_location_wip]
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
		DROP TABLE IF EXISTS [edw_temp].[tquote_auto_garage_location_wip_temp1];

		SELECT 
			CreatedDate, quote_no, effective_dt, expiration_dt, 0 as transaction_seq_no, quote_history_sk, garage_location_no,
            [AddressLine1],[AddressLine2],/*['**Pending garage_address_unit_no'],*/[AddressCity],[AddressZipCode],[AddressState],[AddressCounty],[AddressCountry],
            [CensusTract],[FloodZone],[WildfireThreat],[ProtectionClass],[DistanceToCoast],[CentralReportingFireAlarm],[CentralReportingBurglarAlarm],
			source_system_sk
		
        INTO [edw_temp].[tquote_auto_garage_location_wip_temp1]
		
        FROM
			(
                SELECT
                    acc.CreatedDate, acc.PolicyNumber as quote_no, acc.EffectiveDate as effective_dt, 
                    acc.ExpirationDate as expiration_dt, acc.Number as transaction_seq_no, qh.quote_history_sk,
                    acco.[Index] as garage_location_no,
                    accof.[Field], accof.[Value],
                    CASE 
                        WHEN acc.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (
                        SELECT *
                        FROM [edw_stage].[Account] AS a
                        WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
                        AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
                        AND a.PolicyNumber IS NOT NULL
                    ) acc
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acc.ProductId
                INNER JOIN [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
                INNER JOIN [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
                LEFT JOIN [edw_core].[tquote_history] AS qh 
                    ON qh.quote_no = acc.PolicyNumber
                    AND qh.effective_dt = acc.EffectiveDate
                    AND qh.transaction_seq_no = acc.Number
                WHERE
                    p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND accof.[Group] in ('Location Address')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [AddressLine1],[AddressLine2],/*['**Pending garage_address_unit_no'],*/[AddressCity],[AddressZipCode],[AddressState],[AddressCounty],[AddressCountry],
                    [CensusTract],[FloodZone],[WildfireThreat],[ProtectionClass],[DistanceToCoast],[CentralReportingFireAlarm],[CentralReportingBurglarAlarm]
              )
			) pivottable

		-- Start Merge process
		MERGE INTO [edw_core].[tquote_auto_garage_location] AS target
        USING [edw_temp].[tquote_auto_garage_location_wip_temp1] AS source
            ON target.quote_no = source.quote_no
            AND target.effective_dt = source.effective_dt
            AND target.garage_location_no = source.garage_location_no
            AND target.transaction_seq_no = source.transaction_seq_no
        WHEN MATCHED THEN
            UPDATE SET
                target.expiration_dt = source.expiration_dt,
                target.quote_history_sk = source.quote_history_sk,
                target.garage_address_line1 = source.[AddressLine1],
                target.garage_address_line2 = source.[AddressLine2],
                target.garage_address_unit_no = NULL,
                target.garage_address_city_nm = source.[AddressCity],
                target.garage_address_zip_code = source.[AddressZipCode],
                target.garage_address_state_cd = source.[AddressState],
                target.garage_address_county_nm = source.[AddressCounty],
                target.garage_address_country_nm = source.[AddressCountry],
                target.census_tract = source.[CensusTract],
                target.flood_zone = source.[FloodZone],
                target.wildfire_threat = source.[WildfireThreat],
                target.protection_class = source.[ProtectionClass],
                target.distance_to_coast = source.[DistanceToCoast],
                target.central_reporting_fire_alarm_in = source.[CentralReportingFireAlarm],
                target.central_reporting_burglar_alarm_in = source.[CentralReportingBurglarAlarm],
                target.source_system_sk = source.source_system_sk,
                target.update_ts = GETDATE(),
                target.etl_audit_sk = @etl_audit_sk
        WHEN NOT MATCHED THEN
            INSERT (
                quote_no,
                effective_dt,
                expiration_dt,
                transaction_seq_no,
                quote_history_sk,
                garage_location_no,
                garage_address_line1,
                garage_address_line2,
                garage_address_unit_no,
                garage_address_city_nm,
                garage_address_zip_code,
                garage_address_state_cd,
                garage_address_county_nm,
                garage_address_country_nm,
                census_tract,
                flood_zone,
                wildfire_threat,
                protection_class,
                distance_to_coast,
                central_reporting_fire_alarm_in,
                central_reporting_burglar_alarm_in,
                source_system_sk,
                create_ts,
                update_ts,
                etl_audit_sk
            )
            VALUES (
                source.quote_no,
                source.effective_dt,
                source.expiration_dt,
                source.transaction_seq_no,
                source.quote_history_sk,
                source.garage_location_no,
                source.[AddressLine1],
                source.[AddressLine2],
                NULL,
                source.[AddressCity],
                source.[AddressZipCode],
                source.[AddressState],
                source.[AddressCounty],
                source.[AddressCountry],
                source.[CensusTract],
                source.[FloodZone],
                source.[WildfireThreat],
                source.[ProtectionClass],
                source.[DistanceToCoast],
                source.[CentralReportingFireAlarm],
                source.[CentralReportingBurglarAlarm],
                source.source_system_sk,
                GETDATE(),
                GETDATE(),
                @etl_audit_sk
            );


        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.[tquote_auto_garage_location_wip_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tquote_auto_garage_location_wip_temp1];

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
