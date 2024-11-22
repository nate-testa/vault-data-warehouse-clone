-- =============================================
---------------------------------------------------------------------------------------------------
-- Change date      |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 11/21/24		    Yunus Mohammed				1. Created this procedure 
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_marine_boat_yacht_location]

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
		
		drop table if exists edw_temp.tquote_marine_boat_yacht_location_temp1
		select 
			PolicyNumber as quote_no,EffectiveDate as effective_dt,
			ExpirationDate as expiration_dt,transaction_seq_no,
			source_system_sk,quote_history_sk,
			CreatedDate,AddressLine1 as address_line_1,
            AddressLine2 as address_line_2,AddressCity as city_nm,
            AddressLineUnit as unit_no,
            AddressState as state_cd,AddressZipCode as zip_cd,AddressCounty as county_nm,AddressCountry as country_nm
		into edw_temp.tquote_marine_boat_yacht_location_temp1
		from
		(
		select * 
		from
			(
			
			select
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			tph.quote_history_sk,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			act.Number AS transaction_seq_no, atvo.[index],
			act.CreatedDate,atvof.Field,atvof.[Value]
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product pr on pr.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join edw_stage.AccountTransactionVersionObjectField atvof_2 on atvof_2.ReferenceObjectId = atvo.id and atvof_2.Field = 'PrimaryLocationId'
				left join [edw_core].[tquote_history] tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.[Number]
			where
			    act.PolicyNumber is not null and
				act.[Stage] IN ('QUOTE','POLICY')
				and pr.[Name]='Marine Boat & Yacht'
				and pr.ProductLine = 'PersonalLines'
				
				and atvof.Field IN 
				(
					'AddressLine1','AddressLine2','AddressLineUnit','AddressCity','AddressState','AddressZipCode','AddressCounty',
					'AddressCountry'
				)
				and act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN 
            (
                AddressLine1,AddressLine2,AddressLineUnit,AddressCity,AddressState,AddressZipCode,AddressCounty,AddressCountry
            )
		) as pivottable

		INSERT INTO [edw_core].[tquote_marine_boat_yacht_location]
		(
            quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
            address_line_1,address_line_2,unit_no,city_nm,state_cd,zip_cd,county_nm,country_nm,
            source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
            address_line_1,address_line_2,unit_no,city_nm,state_cd,zip_cd,county_nm,country_nm,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_marine_boat_yacht_location_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_marine_boat_yacht_location_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_marine_boat_yacht_location_temp1
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