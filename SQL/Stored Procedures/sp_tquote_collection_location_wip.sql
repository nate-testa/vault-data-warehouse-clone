-- ========================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This stored procedure insert and update info related to Collection Location.
-----------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-----------------------------------------------------------------------------------------------------------
-- 11/10/23		Hernando Gonzalez Garcia		1. Created this procedure 
-- 11/14/23		Sandeep Gundreddy       		2. Remove effective date partition by clause
-- ======================================================================================================== 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_collection_location_wip]
AS
BEGIN
    DECLARE @ProcedureName NVARCHAR(120)
    SET @ProcedureName = OBJECT_NAME(@@PROCID)
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=@ProcedureName
		DECLARE @CU DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255) --20230717 added
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) --20230717 added

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tquote_collection_location_wip_temp1];
		SELECT 
			Id, PolicyNumber as quote_no, EffectiveDate, CreatedDate, UpdatedDate, [NamedInsured], [CompanyName], [RiskAddressLine1], [RiskAddressLine2], [UnitFloor], [RiskAddressCity], [RiskAddressState], [RiskAddressZipCode]
			,[RiskAddressCounty], [RiskAddressCountry]
			,[Latitude], [Longitude]
			,source_system_sk --20230717 added
		INTO [edw_temp].[tquote_collection_location_wip_temp1]
		FROM
			(
			SELECT
				acc.Id, acc.PolicyNumber, acc.EffectiveDate, acc.CreatedDate, acc.UpdatedDate, accof.[Field], accof.[Value]
				,case when acc.ExternalSourceId is not NULL then 2--(AV2) 
					  Else 4 --(Metal)
				 end as [source_system_sk] --20230717 added
			FROM
				(
				    SELECT *
					,ROW_NUMBER() OVER (PARTITION BY PolicyNumber ORDER BY [number] DESC) AS AccountTransaction_Rank
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				INNER JOIN [edw_stage].[Product] p on p.Id = acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
			WHERE
				acc.AccountTransaction_Rank = 1
				AND p.[Name]='Collections'
				AND acco.ObjectType = 'Collection'
				AND p.ProductLine='PersonalLines' --20230717 added
			) t
		PIVOT 
			(
				MAX([Value]) FOR [Field] IN (
					[NamedInsured], [CompanyName], [RiskAddressLine1], [RiskAddressLine2], [UnitFloor], [RiskAddressCity], [RiskAddressState], [RiskAddressZipCode]
					,[RiskAddressCounty], [RiskAddressCountry]
					,[Latitude], [Longitude])
			) pivottable

		-- Start Merge process
		MERGE [edw_core].[tquote_collection_location] AS Target
		USING (
	        SELECT 
				t1.quote_no,
				t1.EffectiveDate as [effective_dt],
				t1.RiskAddressLine1 as [address_line_1],
				t1.RiskAddressLine2 as [address_line_2],
				t1.UnitFloor as [unit_no],
				t1.RiskAddressCity as [city_nm],
				t1.RiskAddressState as [state_cd],
				t1.RiskAddressZipCode as [zip_cd],
				t1.RiskAddressCounty as [county_nm],
				t1.RiskAddressCountry as [country_nm],
				t1.[longitude],
				t1.[latitude],
				t1.[source_system_sk]
				FROM 
					[edw_temp].[tquote_collection_location_wip_temp1] t1
		) AS Source
		ON 	Source.[quote_no] = Target.[quote_no]
        AND Source.[effective_dt] = Target.[effective_dt]    
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			[quote_no]
           ,[effective_dt]
           ,[address_line_1]
           ,[address_line_2]
           ,[unit_no]
           ,[city_nm]
           ,[state_cd]
           ,[zip_cd]
           ,[county_nm]
           ,[country_nm]
           ,[longitude]
           ,[latitude]
           ,[source_system_sk]
           ,[create_ts]
           ,[update_ts]
           ,[etl_audit_sk]
			)
		VALUES (Source.quote_no, Source.effective_dt, Source.[address_line_1], Source.[address_line_2], 
			    Source.[unit_no], Source.[city_nm], Source.[state_cd], Source.[zip_cd], 
				Source.[county_nm], Source.[country_nm], Source.[longitude], Source.[latitude],
				 Source.[source_system_sk], getdate(), getdate(), @etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
        Target.[longitude]		= Source.[longitude],
        Target.[latitude]		= Source.[latitude],
        Target.[address_line_1]	= Source.[address_line_1],
        Target.[address_line_2]	= Source.[address_line_2],
        Target.[unit_no]		= Source.[unit_no],
        Target.[city_nm]		= Source.[city_nm],
        Target.[state_cd]		= Source.[state_cd],
        Target.[zip_cd]			= Source.[zip_cd],
        Target.[county_nm]		= Source.[county_nm],
        Target.[country_nm]		= Source.[country_nm];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.createddate) FROM edw_temp.[tquote_collection_location_wip_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.[tquote_collection_location_wip_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		print @etl_audit_sk
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200)) --20230717 added
		--EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected; --20230717 removed
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc; --20230717 added


	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1; --20230717 added

	END CATCH
END

GO