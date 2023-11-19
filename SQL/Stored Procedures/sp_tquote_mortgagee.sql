SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Hernando Gonzalez Garcia
-- Create Date: <Create Date, , >
-- Description: This procedures insert homeowners mortgagee data
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tquote_mortgagee]

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

		drop table if exists edw_temp.tquote_mortgagee_temp1
		select 
			PolicyNumber as quote_no,EffectiveDate,ExpirationDate,transaction_seq_no,createdDate,quote_history_sk,source_system_sk,
			mortgagee_no,NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
			IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,AddressState,
			AddressZipCode,AddressCounty,AddressCountry
			into edw_temp.tquote_mortgagee_temp1
		from
		(
		select 
			act.PolicyNumber,CAST(act.EffectiveDate AS DATE) AS EffectiveDate,CAST(act.ExpirationDate AS DATE) AS ExpirationDate,
			tqh.quote_history_sk,atvo.[index] mortgagee_no,
			act.number AS transaction_seq_no,act.createdDate,
			CASE WHEN act.ExternalSourceId IS NULL THEN 2 ELSE 4 END source_system_sk,atvof.Field,atvof.[Value]
			from
				edw_stage.AccountTransaction act
				inner join edw_stage.Product p on p.Id=act.ProductId
				inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
				inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
				inner join edw_stage.AccountTransactionVersionObjectField atvof on atvo.Id=atvof.VersionObjectId
				LEFT JOIN edw_core.tquote_history tqh on tqh.quote_no=act.PolicyNumber
						and tqh.effective_dt=act.EffectiveDate
						and tqh.transaction_seq_no = act.number
				left join edw_stage.Product pr on act.ProductId = pr.id
			where
				act.PolicyNumber is not null
				and act.[Stage] IN ('QUOTE','POLICY')
				and atvo.ObjectType IN ('Mortgagee')
				and pr.ProductLine = 'PersonalLines'
				and atvof.Field IN ('NumberOfMortgagees','Name','MortgageeType','BillMortgagee','Email','Fax','Phone',
					'IsaoAtima','IsaoAtimaOther','LoanNumber','AddressLine1','AddressLine2','AddressCity',
					'AddressState','AddressZipCode','AddressCounty','AddressCountry')
				and act.createdDate > @last_source_extract_ts
		) as t
		pivot 
		(
			max(Value) FOR Field IN (NumberOfMortgagees,[Name],MortgageeType,BillMortgagee,Email,Fax,Phone,
					IsaoAtima,IsaoAtimaOther,LoanNumber,AddressLine1,AddressLine2,AddressCity,
					AddressState,AddressZipCode,AddressCounty,AddressCountry)
		) as pivottable

		INSERT INTO [edw_core].[tquote_mortgagee]
		(
			
			quote_no,effective_dt,expiration_dt,transaction_seq_no,quote_history_sk,
			mortgagee_no,mortgagee_nm,mortgagee_type,bill_mortgagee_in,email,fax_no,phone_no,isao_atima,isao_atima_other,loan_no,
			address_line_1,address_line_2,city_nm,state_cd,zip_cd,county_nm,country_nm,source_system_sk,create_ts,update_ts,etl_audit_sk
		)
		SELECT
			ttlc.quote_no AS policy_no,ttlc.EffectiveDate AS effective_dt,
			ExpirationDate AS expiration_dt,transaction_seq_no AS transaction_seq_no,quote_history_sk,
			mortgagee_no,	[Name] AS mortgagee_nm,MortgageeType AS mortgagee_type,BillMortgagee bill_mortgagee_in,
			Email AS email,Fax AS fax,Phone AS phone_no,IsaoAtima AS isao_atima,IsaoAtimaOther isao_atima_other,
			LoanNumber AS loan_no,AddressLine1 AS address_line_1,AddressLine2 AS address_line_2,AddressCity AS city_nm,
			AddressState AS state_cd,AddressZipCode AS zip_cd,AddressCounty AS country_nm,AddressCountry AS country_nm,
			source_system_sk,getdate() AS create_ts,getdate() AS update_ts,@etl_audit_sk AS etl_audit_sk
		FROM
			edw_temp.tquote_mortgagee_temp1 AS ttlc

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(createdDate) FROM edw_temp.tquote_mortgagee_temp1),@last_source_extract_ts);	
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tquote_mortgagee_temp1
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