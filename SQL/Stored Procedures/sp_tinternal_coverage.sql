 -- =================================================================================================
-- Author:		
-- Description: This procedures loads inforce at item level 
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 06/02/23										1. Created this procedure 
-- 06/28/23		Architha Gudimalla				2. Modified after first run errors
-- 07/25/23		Architha Gudimalla				3. Added TFS to internal coverages
-- 09/20/23     Sandeep Gundreddy				4. Added PersonalLines Filter & modified ASLOB code
-- 10/12/23     Sandeep Gundreddy				5. Added logic for primary_coverage_cd
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tinternal_coverage]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
	SET ANSI_WARNINGS OFF
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

		-- Create temp table with name as tinternal_coverage_temp1
		DROP TABLE IF EXISTS edw_temp.tinternal_coverage_temp1 ;

		SELECT	nullif(trim(atcp.label),'') internal_coverage_cd,
				p.ProductCode  as product_cd, 
				nullif(trim(c.Aslob),'') as aslob_cd,
				'Premium' ic_type, nullif(trim(atcp.coverage) ,'') coverage,
				max(atcp.CreatedDate)  as CreatedDate,
				max(atcp.UpdatedDate) as  UpdatedDate
 		INTO edw_temp.tinternal_coverage_temp1
		FROM edw_stage.AccountTransactionCoveragePremium atcp
		inner join edw_stage.Coverage c on atcp.Coverage =c.name
		inner join edw_stage.ProductCoverages pc on c.Id=pc.CoveragesId
		inner join edw_stage.Product p on p.Id=pc.ProductsId
		WHERE	nullif(label,'') IS NOT NULL 
		and p.ProductLine='PersonalLines'
		and		GREATEST(atcp.CreatedDate,c.UpdatedDate)>@last_source_extract_ts
		and nullif(label,'') not in ('2020 BMW 540I XDRIVE')
		GROUP BY atcp.label, p.ProductCode, atcp.label, c.Aslob, nullif(trim(atcp.coverage) ,'') 
		union all
		SELECT	nullif(trim(replace(accttf.name, '  ',' ')),'') as tax_fee_surcharge_name, 
				pr.ProductCode  as product_cd, 
				case when pr.ProductCode = 'LUX' then '090'
					 when pr.ProductCode = 'HO' then '040'
					 when pr.ProductCode = 'AU' then '211'
					 when pr.ProductCode = 'PEL' then '171'
					 else null
				end aslob,
				max(nullif(trim(accttf.Type),'')) as tax_fee_surcharge_type,null,
				max(acct.CreatedDate)  as CreatedDate,
				max(acct.UpdatedDate) as  UpdatedDate 
		FROM edw_stage.AccountTransaction acct 
		inner join edw_stage.Product pr on pr.Id=acct.ProductId
		inner join edw_stage.AccountTransactionTaxAndFee accttf on acct.id = accttf.accounttransactionid 
		WHERE	GREATEST(acct.CreatedDate,acct.UpdatedDate)>@last_source_extract_ts 
		and		nullif(trim(replace(accttf.name, '  ',' ')),'') is not null
		and pr.ProductLine='PersonalLines'
		group by trim(replace(accttf.name, '  ',' ')) , pr.ProductCode;
			
		-- Insert and Update tinternal_coverage table
		MERGE edw_core.tinternal_coverage AS Target
		USING edw_temp.tinternal_coverage_temp1 AS Source
		ON Source.internal_coverage_cd = Target.internal_coverage_cd 
		AND Source.product_cd = Target.product_cd
		--AND isnull(Source.coverage,'') = isnull(Target.primary_coverage_cd,'')
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
				internal_coverage_cd,
				product_cd,
				internal_coverage_desc,
				aslob_cd,
				primary_coverage_cd,
				internal_coverage_category_nm,
				create_ts,update_ts
			)
		VALUES
			(
				Source.internal_coverage_cd,
				Source.product_cd,
				Source.internal_coverage_cd,
				Source.aslob_cd ,
				nullif(trim(source.coverage),''),
				source.ic_type,
				GETDATE(),GETDATE()
			)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET Target.internal_coverage_desc			= Source.internal_coverage_cd,
			Target.aslob_cd							= Source.aslob_cd,
			Target.primary_coverage_cd				= nullif(trim(source.coverage),''),
			Target.internal_coverage_category_nm	= Source.ic_type,
			Target.update_ts						= GETDATE();

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(GREATEST(ct.CreatedDate,ct.UpdatedDate)) FROM edw_temp.tinternal_coverage_temp1 ct),@last_source_extract_ts) 
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.tinternal_coverage_temp1
	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						     ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')  + 
						  ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') + CHAR(13) + 
					      'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + 
						      ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') + CHAR(13) + 
						    'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;
		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	END CATCH
END;

