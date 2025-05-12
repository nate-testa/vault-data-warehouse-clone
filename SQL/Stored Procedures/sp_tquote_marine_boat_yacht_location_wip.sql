-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/21/24		    Yunus Mohammed				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_location_wip]

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

		-- Get last [Source] extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_[Source]_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
		
		drop table if exists edw_temp.tquote_marine_boat_yacht_location_wip_temp1
		select 
			PolicyNumber as quote_no,EffectiveDate as effective_dt,
			ExpirationDate as expiration_dt,transaction_seq_no,
			source_system_sk,quote_history_sk,
			MooringLocationAddressLine1 as address_line_1,
            MooringLocationAddressLine2 as address_line_2,MooringLocationAddressCity as city_nm,
            MooringLocationAddressLineUnit as unit_no,
            MooringLocationAddressState as state_cd,MooringLocationAddressZipCode as zip_cd,MooringLocationAddressCounty as county_nm,
            MooringLocationAddressCountry as country_nm,
			CreatedDate,UpdatedDate,
			GETDATE() AS create_ts, GETDATE() AS update_ts,@etl_audit_sk AS etl_audit_sk
		into edw_temp.tquote_marine_boat_yacht_location_wip_temp1
		from
		(
		select * 
		from
			(
			
			select			
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
            0 AS transaction_seq_no,tph.quote_history_sk,
			CASE WHEN acc.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,            
			acc.CreatedDate,acc.UpdatedDate,accof.Field,accof.[Value]
			from
			    (
				    SELECT *
				    FROM [edw_stage].[Account] AS a
				    WHERE NOT EXISTS (select * from [edw_stage].[AccountTransaction] b where b.AccountId=a.id)
				    AND GREATEST(CreatedDate,UpdatedDate) > @last_source_extract_ts
					AND a.PolicyNumber IS NOT NULL
				) acc
				inner join edw_stage.Product pr on pr.Id=acc.ProductId
				inner join [edw_stage].[AccountObject] AS acco ON acco.AccountId = acc.Id
				inner join [edw_stage].[AccountObjectField] AS accof ON accof.ObjectId = acco.id
				left join [edw_core].[tquote_history] tph on tph.quote_no=acc.PolicyNumber
						and tph.effective_dt=acc.EffectiveDate
						and tph.transaction_seq_no = 0
			where
			    acc.PolicyNumber is not null
				and pr.[Name]='Marine Boat & Yacht'
				and pr.ProductLine = 'PersonalLines'				
				and accof.Field IN 
				(
					'MooringLocationAddressLine1','MooringLocationAddressLine2','MooringLocationAddressLineUnit','MooringLocationAddressCity',
                    'MooringLocationAddressState','MooringLocationAddressZipCode','MooringLocationAddressCounty','MooringLocationAddressCountry'
				)				
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN 
            (
                MooringLocationAddressLine1,MooringLocationAddressLine2,MooringLocationAddressLineUnit,MooringLocationAddressCity,
                MooringLocationAddressState,MooringLocationAddressZipCode,MooringLocationAddressCounty,MooringLocationAddressCountry
            )
		) as pivottable

        MERGE INTO [edw_core].[tquote_marine_boat_yacht_location] AS [Target]
		USING edw_temp.tquote_marine_boat_yacht_location_wip_temp1 AS [Source]
		ON
		    [Target].quote_no = [Source].quote_no AND
		    [Target].effective_dt = [Source].effective_dt AND
		    [Target].transaction_seq_no = [Source].transaction_seq_no

		WHEN MATCHED THEN
		    UPDATE SET
		        [Target].effective_dt = [Source].effective_dt,
		        [Target].expiration_dt = [Source].expiration_dt,
		        [Target].quote_history_sk = [Source].quote_history_sk,
		        [Target].address_line_1 = [Source].address_line_1,
		        [Target].address_line_2 = [Source].address_line_2,
		        [Target].unit_no = [Source].unit_no,
		        [Target].city_nm = [Source].city_nm,
		        [Target].state_cd = [Source].state_cd,
		        [Target].zip_cd = [Source].zip_cd,
		        [Target].county_nm = [Source].county_nm,
		        [Target].country_nm = [Source].country_nm,
		        [Target].source_system_sk = [Source].source_system_sk,
		        [Target].update_ts = [Source].update_ts,
		        [Target].etl_audit_sk = [Source].etl_audit_sk

			WHEN NOT MATCHED BY Target THEN
		    INSERT (
		        quote_no, effective_dt, expiration_dt, transaction_seq_no, quote_history_sk,
		        address_line_1, address_line_2, unit_no, city_nm, state_cd, zip_cd, county_nm, country_nm, 
                source_system_sk, create_ts, update_ts, etl_audit_sk
		    )
		    VALUES (
		        [Source].quote_no, [Source].effective_dt, [Source].expiration_dt, [Source].transaction_seq_no, [Source].quote_history_sk,
		        [Source].address_line_1, [Source].address_line_2, [Source].unit_no, [Source].city_nm, [Source].state_cd, [Source].zip_cd, [Source].county_nm, 
                [Source].country_nm, [Source].source_system_sk, [Source].create_ts, [Source].update_ts, [Source].etl_audit_sk
			);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(UpdatedDate,CreatedDate)) FROM edw_temp.tquote_marine_boat_yacht_location_wip_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_[Source]_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_location_wip_temp1
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