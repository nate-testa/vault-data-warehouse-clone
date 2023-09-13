SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Alberto Almario
-- Create Date: 2023-09-11
-- Description: This stored procedure insert and update info related to tauto_garage_location.
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tauto_garage_location]
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
		DROP TABLE IF EXISTS [edw_temp].[tauto_garage_location_temp1];

		SELECT 
			IssuedDate, policy_no, effective_dt, transaction_effective_dt, expiration_dt, transaction_dt, transaction_seq_no, policy_history_sk, garage_location_no,
            [AddressLine1],[AddressLine2],/*['**Pending garage_address_unit_no'],*/[AddressCity],[AddressZipCode],[AddressState],[AddressCounty],[AddressCountry],
            [CensusTract],[FloodZone],[WildfireThreat],[ProtectionClass],[DistanceToCoast],[CentralReportingFireAlarm],[CentralReportingBurglarAlarm],
			source_system_sk
		
        INTO [edw_temp].[tauto_garage_location_temp1]
		
        FROM
			(
                SELECT
                    acct.IssuedDate, acct.PolicyNumber as policy_no, acct.EffectiveDate as effective_dt, acct.TransactionEffectiveDate as transaction_effective_dt, 
                    acct.ExpirationDate as expiration_dt, acct.IssuedDate as transaction_dt, acct.PolicyChangeNumber as transaction_seq_no, ph.policy_history_sk,
                    acctvo.[Index] as garage_location_no,
                    acctvof.[Field], acctvof.[Value],
                    CASE 
                        WHEN acct.ExternalSourceId IS NOT NULL THEN 2 -- (AV2) 
                        ELSE 4 --(Metal)
                    END as [source_system_sk]
                FROM
                    (
                        SELECT
                            *
                            ,ROW_NUMBER() OVER (PARTITION BY PolicyNumber, EffectiveDate ORDER BY policychangenumber DESC) AS AccountTransaction_Rank
                        FROM [edw_stage].[AccountTransaction]
                        WHERE [State] = 'ISSUED'
                            AND IssuedDate > @last_source_extract_ts
                    ) acct
                INNER JOIN [edw_stage].[Product] AS p on p.Id = acct.ProductId
                INNER JOIN [edw_stage].[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
                INNER JOIN [edw_stage].[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id
                LEFT JOIN [edw_core].[tpolicy_history] AS ph 
                    ON ph.policy_no = acct.PolicyNumber
                    AND ph.effective_dt = acct.EffectiveDate
                    AND ph.transaction_seq_no = acct.policychangenumber
                WHERE
                    acct.AccountTransaction_Rank = 1
                    AND p.[Name] = 'Automobile'
                    AND p.ProductLine = 'PersonalLines'
                    AND acctvof.[Group] in ('Location Address')
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN 
                (
                    [AddressLine1],[AddressLine2],/*['**Pending garage_address_unit_no'],*/[AddressCity],[AddressZipCode],[AddressState],[AddressCounty],[AddressCountry],
                    [CensusTract],[FloodZone],[WildfireThreat],[ProtectionClass],[DistanceToCoast],[CentralReportingFireAlarm],[CentralReportingBurglarAlarm]
                )
			) pivottable

		-- Start Insert process
		INSERT INTO [edw_core].[tauto_garage_location]
        (
            policy_no,
            effective_dt,
            transaction_effective_dt,
            expiration_dt,
            transaction_dt,
            transaction_seq_no,
            policy_history_sk,
            garage_location_no,
            garage_address_line1,
            garage_address_line2,
            --garage_address_unit_no,
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
        SELECT 
            t1.policy_no,
            t1.effective_dt,
            t1.transaction_effective_dt,
            t1.expiration_dt,
            t1.transaction_dt,
            t1.transaction_seq_no,
            t1.policy_history_sk,
            t1.garage_location_no,
            t1.[AddressLine1] as garage_address_line1,
            t1.[AddressLine2] as garage_address_line2,
            -- t1.['**Pending garage_address_unit_no'] as garage_address_unit_no,
            t1.[AddressCity] as garage_address_city_nm,
            t1.[AddressZipCode] as garage_address_zip_code,
            t1.[AddressState] as garage_address_state_cd,
            t1.[AddressCounty] as garage_address_county_nm,
            t1.[AddressCountry] as garage_address_country_nm,
            t1.[CensusTract] as census_tract,
            t1.[FloodZone] as flood_zone,
            t1.[WildfireThreat] as wildfire_threat,
            t1.[ProtectionClass] as protection_class,
            t1.[DistanceToCoast] as distance_to_coast,
            t1.[CentralReportingFireAlarm] as central_reporting_fire_alarm_in,
            t1.[CentralReportingBurglarAlarm] as central_reporting_burglar_alarm_in,
            t1.source_system_sk,
            getdate() AS create_ts,
            getdate() AS update_ts,
            @etl_audit_sk AS etl_audit_sk
        FROM 
            [edw_temp].[tauto_garage_location_temp1] AS t1
        ;

        --************End************

		SET @rows_affected=@@ROWCOUNT;

		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(IssuedDate) FROM edw_temp.[tauto_garage_location_temp1]),@last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.[tauto_garage_location_temp1];

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
