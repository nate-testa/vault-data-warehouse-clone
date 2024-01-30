SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert homeowners quote risk location data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 10/23/2023 			Yunus Mohammed					1. Created this procedure 
-- 11/11/23				Sandeep Gundreddy		        2. modified source query and transaction_seq_no logic
-- 11/12/23				Sandeep Gundreddy		        3. removed  EffectiveDate from partition clause
-- 01/30/24				Yunus Mohammed					4. Added unit no
-- =========================================================================================================================== 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_home_location]

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

		-- Step1 limit amount of rows.
		DECLARE @sql nvarchar(max)
		DROP TABLE IF EXISTS edw_temp.tquote_home_location_temp1

		SELECT * INTO [edw_temp].[tquote_home_location_temp1]
		FROM (SELECT
				acct.*,
				CASE WHEN acct.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
				DENSE_RANK() OVER (PARTITION BY acct.policyNumber ORDER BY acct.[Number] DESC) AS policy_txn_order
			FROM [edw_stage].[AccountTransaction] acct
			left join edw_stage.Product pr on acct.ProductId = pr.id
			WHERE
				acct.[Stage] IN ('QUOTE','POLICY')				
				and pr.ProductLine = 'PersonalLines'
				AND acct.CreatedDate > @last_source_extract_ts
			) acctr
		WHERE acctr.policy_txn_order = 1

		-- Pivot Table
		DROP TABLE IF EXISTS [edw_temp].[tquote_home_location_temp2];

		SELECT 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,source_system_sk,
			RiskAddressLine2,RiskAddressCity,RiskAddressLine1,RiskAddressZipCode,RiskAddressState,
			RiskAddressCounty,RiskAddressCountry,Longitude,Latitude,RiskAddressLineUnit
		INTO edw_temp.tquote_home_location_temp2
		FROM
		(
		SELECT * 
		FROM
			(
			SELECT 
				DENSE_RANK()OVER(PARTITION BY act.PolicyNumber ORDER BY act.[Number] DESC) AS policy_txn_order,
			act.PolicyNumber ,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,
			act.[Number] AS transaction_seq_no,act.source_system_sk,act.CreatedDate,
			atvof.Field,atvof.[Value]
			from
				[edw_temp].[tquote_home_location_temp1] act
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
			where
				atvo.ObjectType in ('Homeowner','Condo')
				and atvof.Field IN ('RiskAddressLine2','RiskAddressCity','RiskAddressLine1','RiskAddressZipCode','RiskAddressState',
					'RiskAddressCounty','RiskAddressCountry','Longitude','Latitude','RiskAddressLineUnit')
				and act.CreatedDate > @last_source_extract_ts
			) as t
			where policy_txn_order=1
		) as t
		pivot 
		(
			max(Value) FOR Field IN (RiskAddressLine2,RiskAddressCity,RiskAddressLine1,RiskAddressZipCode,RiskAddressState,
				RiskAddressCounty,RiskAddressCountry,Longitude,Latitude,RiskAddressLineUnit)
		) as pivottable

		-- Start Merge process
		MERGE [edw_core].[tquote_home_location] AS Target
		USING edw_temp.tquote_home_location_temp2 AS Source
		ON Source.PolicyNumber = Target.[quote_no]
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				quote_no,effective_dt,address_line_1,address_line_2,unit_no,city_nm,
				state_cd,zip_cd,county_nm,country_nm,Longitude,Latitude,source_system_sk,create_ts,update_ts,etl_audit_sk
				)
		VALUES 
		(
			Source.PolicyNumber,Source.EffectiveDate,Source.RiskAddressLine1,Source.RiskAddressLine2,RiskAddressLineUnit,
			Source.RiskAddressCity,Source.RiskAddressState,Source.RiskAddressZipCode,
			Source.RiskAddressCounty,Source.RiskAddressCountry,Source.Longitude,Source.Latitude,
			Source.source_system_sk,getdate(),getdate(),@etl_audit_sk
		)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
		TARGET.address_line_1=SOURCE.RiskAddressLine1,
		TARGET.address_line_2=SOURCE.RiskAddressLine2,
		TARGET.city_nm=SOURCE.RiskAddressCity,
		TARGET.state_cd=SOURCE.RiskAddressState,
		TARGET.zip_cd=SOURCE.RiskAddressZipCode,
		TARGET.county_nm=SOURCE.RiskAddressCounty,
		TARGET.country_nm=SOURCE.RiskAddressCountry,
		Target.longitude=SOURCE.Longitude,
		Target.latitude=Source.Latitude,
		Target.unit_no=Source.RiskAddressLineUnit,
		TARGET.update_ts=getdate();

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_home_location_temp1),@last_source_extract_ts)
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_home_location_temp1
		DROP TABLE IF EXISTS edw_temp.tquote_home_location_temp2
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
