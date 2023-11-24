
-- =============================================
-- Author:		Yunus Mohammed
-- Create Date: <Create Date, , >
-- Description: This procedures insert pel quote location data
------------------------------------------------------------------------------------------------------------------------------
-- Change date			|Author							|	Change Description
------------------------------------------------------------------------------------------------------------------------------
-- 10/24/2023 			Yunus Mohammed					1. Created this procedure
-- 11/11/23		        Sandeep Gundreddy		        2. modified quote_history_sk 
-- 11/24/23				Yunus Mohammed					3. Removed bug. Only one pel location was showing for a policy.
-- =========================================================================================================================== 
CREATE or alter  PROCEDURE [edw_core].[sp_tquote_pel_location]

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

		drop table if exists edw_temp.tquote_pel_location_temp1
		select 
			PolicyNumber,EffectiveDate,ExpirationDate,TransactionEffectiveDate,transaction_seq_no,source_system_sk,quote_history_sk,
			rownum as [index],
			CreatedDate,AddressLine1,AddressLine2,AddressCity,AddressState,AddressZipCode,AddressCounty,
			NumberOfSwimmingPools,MultiFamilyDwelling,VacantOrUnoccupied,ForSale
			into edw_temp.tquote_pel_location_temp1
		from
		(
		select * 
		from
			(
			-- We are generating rownum becase atvo.[index] is 1 for every row of a policy and we are using it as location_no but we should 
			-- have different location_no for different location of a policy number.
			-- This rownum is used as location no
			select
			DENSE_RANK()OVER(PARTITION BY act.PolicyNumber, CAST(act.EffectiveDate AS DATE), act.policychangenumber ORDER BY atvo.Id) as rownum,
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			CAST(act.TransactionEffectiveDate AS DATE) AS TransactionEffectiveDate,tph.quote_history_sk,
			CASE WHEN act.ExternalSourceId IS NOT NULL THEN 2 ELSE 4 END source_system_sk,
			act.[Number] AS transaction_seq_no, atvo.[index],
			act.CreatedDate,atvof.Field,atvof.[Value] -- ,atvo.Id
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				left join [edw_core].[tquote_history] tph on tph.quote_no=act.PolicyNumber
						and tph.effective_dt=act.EffectiveDate
						and tph.transaction_seq_no = act.[Number]
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null and
				act.[Stage] IN ('QUOTE','POLICY')
				and p.[Name]='Personal Excess Liability'
				and pr.ProductLine = 'PersonalLines'
				and atvo.ObjectType='Location'
				and atvof.Field IN 
				(
					'AddressLine1','AddressLine2','AddressCity','AddressState','AddressZipCode','AddressCounty',
					'AddressCounty','NumberOfSwimmingPools','MultiFamilyDwelling','VacantOrUnoccupied','ForSale'
				)
				and act.CreatedDate > @last_source_extract_ts
			) as t
		) as t
		pivot 
		(
			max(Value) FOR Field IN (NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
					IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,
					AddressState,AddressZipCode,AddressCounty,AddressCountry,NumberOfSwimmingPools,MultiFamilyDwelling,
					VacantOrUnoccupied,ForSale)
		) as pivottable
		
		INSERT INTO [edw_core].[tquote_pel_location]
		(
			quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
			location_no,address_line_1,address_line_2,unit_no,city_nm,state_cd,zip_cd,county_nm,country_nm,longitude,latitude,
			swimming_pool_ct,multi_family_dwelling_in,vacant_unoccupied_in,for_sale_in,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			ttlc.PolicyNumber AS policy_no,ttlc.EffectiveDate AS effective_dt,
			ExpirationDate AS expiration_dt,transaction_seq_no AS transaction_seq_no,quote_history_sk,
			[index] AS location_no,AddressLine1 AS address_line_1,AddressLine2 AS address_line_2,NULL AS unit_no,AddressCity AS city_nm,
			AddressState AS state_cd,AddressZipCode AS zip_cd,AddressCounty AS county_nm,AddressCounty AS country_nm,NULL AS longitude,NULL AS latitude,
			NumberOfSwimmingPools AS swimming_pool_ct,MultiFamilyDwelling AS multi_family_dwelling_in,
			VacantOrUnoccupied AS vacant_unoccupied_in,ForSale AS for_sale_in,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_pel_location_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(CreatedDate) FROM edw_temp.tquote_pel_location_temp1),@last_source_extract_ts)	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_pel_location_temp1
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
