--=================================================================================================
-- Author:		Hernando Gonzalez Garcia
-- Description: This procedures insert homeowners mortgagee data
---------------------------------------------------------------------------------------------------
-- Change date 			|Author							|	Change Description
---------------------------------------------------------------------------------------------------
-- 05/05/24				Hernando Gonzalez Garcia		1. Created this procedure 
-- 05/14/24				Architha Gudimalla				2. Corrected errors
-- 08/22/24				Yunus Mohammed					3. Removed effective date from merge and added in update clause
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_mortgagee_wip]
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

		drop table if exists edw_temp.tquote_mortgagee_wip_temp1
		select 
			PolicyNumber as quote_no,EffectiveDate,ExpirationDate
			--,transaction_seq_no
			,0 as transaction_seq_no
			,createdDate,UpdatedDate,quote_history_sk,source_system_sk,
			mortgagee_no,NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
			IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,AddressState,
			AddressZipCode,AddressCounty,AddressCountry
			into edw_temp.tquote_mortgagee_wip_temp1
		from
		(
		select 
			acc.PolicyNumber,CAST(acc.EffectiveDate AS DATE) AS EffectiveDate,CAST(acc.ExpirationDate AS DATE) AS ExpirationDate,
			tqh.quote_history_sk,acco.[index] mortgagee_no,
			0 AS transaction_seq_no,acc.createdDate,acc.UpdatedDate,
			CASE WHEN acc.ExternalSourceId IS NULL THEN 2 ELSE 4 END source_system_sk,accof.Field,accof.[Value]
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
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=acc.PolicyNumber
						and tqh.effective_dt=acc.EffectiveDate
						and tqh.transaction_seq_no = 0
				left join edw_stage.Product pr on acc.ProductId = pr.id
			where
				acco.ObjectType IN ('Mortgagee')
				and pr.ProductLine = 'PersonalLines'
				and accof.Field IN ('NumberOfMortgagees','Name','MortgageeType','BillMortgagee','Email','Fax','Phone',
					'IsaoAtima','IsaoAtimaOther','LoanNumber','AddressLine1','AddressLine2','AddressCity',
					'AddressState','AddressZipCode','AddressCounty','AddressCountry')
				and acc.createdDate > @last_source_extract_ts
		) as t
		pivot 
		(
			max(Value) FOR Field IN (NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
					IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,
					AddressState,AddressZipCode,AddressCounty,AddressCountry)
		) as pivottable

		MERGE INTO [edw_core].[tquote_mortgagee] AS TARGET
		USING (
		    SELECT
		        ttlc.quote_no AS quote_no,
		        ttlc.EffectiveDate AS effective_dt,
		        ExpirationDate AS expiration_dt,
		        transaction_seq_no AS transaction_seq_no,
		        quote_history_sk,
		        mortgagee_no,
		        [Name] AS mortgagee_nm,
		        MortgageeType AS mortgagee_type,
		        BillMortgagee AS bill_mortgagee_in,
		        Email AS email,
		        Fax AS fax_no,
		        Phone AS phone_no,
		        IsaoAtima AS isao_atima,
		        IsaoAtimaOther AS isao_atima_other,
		        LoanNumber AS loan_no,
		        AddressLine1 AS address_line_1,
		        AddressLine2 AS address_line_2,
		        AddressCity AS city_nm,
		        AddressState AS state_cd,
		        AddressZipCode AS zip_cd,
		        AddressCounty AS county_nm,
		        AddressCountry AS country_nm,
		        source_system_sk,
		        GETDATE() AS create_ts,
		        GETDATE() AS update_ts,
		        @etl_audit_sk AS etl_audit_sk
		    FROM
		        edw_temp.tquote_mortgagee_wip_temp1 AS ttlc
		) AS SOURCE
		ON
		    TARGET.quote_no = SOURCE.quote_no AND		    
		    TARGET.transaction_seq_no = SOURCE.transaction_seq_no AND
		    TARGET.mortgagee_no = SOURCE.mortgagee_no 
		    --TARGET.expiration_dt = SOURCE.expiration_dt AND
		    --TARGET.quote_history_sk = SOURCE.quote_history_sk

		WHEN MATCHED THEN
		    UPDATE SET
				TARGET.effective_dt = SOURCE.effective_dt,
		        TARGET.mortgagee_nm = SOURCE.mortgagee_nm,
		        TARGET.mortgagee_type = SOURCE.mortgagee_type,
		        TARGET.bill_mortgagee_in = SOURCE.bill_mortgagee_in,
		        TARGET.email = SOURCE.email,
		        TARGET.fax_no = SOURCE.fax_no,
		        TARGET.phone_no = SOURCE.phone_no,
		        TARGET.isao_atima = SOURCE.isao_atima,
		        TARGET.isao_atima_other = SOURCE.isao_atima_other,
		        TARGET.loan_no = SOURCE.loan_no,
		        TARGET.address_line_1 = SOURCE.address_line_1,
		        TARGET.address_line_2 = SOURCE.address_line_2,
		        TARGET.city_nm = SOURCE.city_nm,
		        TARGET.state_cd = SOURCE.state_cd,
		        TARGET.zip_cd = SOURCE.zip_cd,
		        TARGET.county_nm = SOURCE.county_nm,
		        TARGET.country_nm = SOURCE.country_nm,
		        TARGET.source_system_sk = SOURCE.source_system_sk,
		        TARGET.create_ts = SOURCE.create_ts,
		        TARGET.update_ts = SOURCE.update_ts,
		        TARGET.etl_audit_sk = SOURCE.etl_audit_sk

		WHEN NOT MATCHED BY TARGET THEN
		    INSERT (
		        quote_no,
		        effective_dt,
		        expiration_dt,
		        transaction_seq_no,
		        quote_history_sk,
		        mortgagee_no,
		        mortgagee_nm,
		        mortgagee_type,
		        bill_mortgagee_in,
		        email,
		        fax_no,
		        phone_no,
		        isao_atima,
		        isao_atima_other,
		        loan_no,
		        address_line_1,
		        address_line_2,
		        city_nm,
		        state_cd,
		        zip_cd,
		        county_nm,
		        country_nm,
		        source_system_sk,
		        create_ts,
		        update_ts,
		        etl_audit_sk
		    )
		    VALUES (
		        SOURCE.quote_no,
		        SOURCE.effective_dt,
		        SOURCE.expiration_dt,
		        SOURCE.transaction_seq_no,
		        SOURCE.quote_history_sk,
		        SOURCE.mortgagee_no,
		        SOURCE.mortgagee_nm,
		        SOURCE.mortgagee_type,
		        SOURCE.bill_mortgagee_in,
		        SOURCE.email,
		        SOURCE.fax_no,
		        SOURCE.phone_no,
		        SOURCE.isao_atima,
		        SOURCE.isao_atima_other,
		        SOURCE.loan_no,
		        SOURCE.address_line_1,
		        SOURCE.address_line_2,
		        SOURCE.city_nm,
		        SOURCE.state_cd,
		        SOURCE.zip_cd,
		        SOURCE.county_nm,
		        SOURCE.country_nm,
		        SOURCE.source_system_sk,
		        SOURCE.create_ts,
		        SOURCE.update_ts,
		        SOURCE.etl_audit_sk
		);

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(greatest(t1.CreatedDate, t1.UpdatedDate)) FROM edw_temp.tquote_mortgagee_wip_temp1 t1),@last_source_extract_ts);	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_mortgagee_wip_temp1
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