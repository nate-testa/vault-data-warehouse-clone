-- ================================================================================================= 
-- Author:		Dinesh Bobbili
-- Create Date: <Create Date, , >
-- Description: This procedures inserts the nfp related data 
-- ---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- 11/10/25					Dinesh Bobbili				1. Created this procedure  
-- 02/08/26					Rushin Shah					2. AD12499 : Fixed issue associated with one insured having duplicate transaction_seq_no
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_nfp_policy_update]
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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		DROP TABLE IF EXISTS edw_temp.nfp_policy_temp1;		
		WITH temp_nfp_base_1 as (
		select
			DISTINCT insured_cert_no,
			effective_date,
			transaction_date,
			insured_first_name,
			cast(transaction_type as varchar(60)) as transaction_type, 
			insured_last_name,
			address1,
			zip,
			expiration_date,
			FIRST_VALUE(effective_date) OVER (PARTITION BY insured_cert_no ORDER BY effective_date) as term_effective_date,
			case when np.reporting_month > @last_source_extract_ts then 'I' else 'H' end as delta_flag,
			np.reporting_month,
			np.total_collected
		FROM
			edw_stage.nfp_policy np
		WHERE
			insured_cert_no is not null
		)
		,temp_nfp_base_2 AS (
		SELECT  
			np.*,
			DENSE_RANK() OVER (
				PARTITION BY insured_first_name, insured_last_name, address1, zip 
				ORDER BY expiration_date
			) AS rn,
			dense_rank() over (partition by insured_cert_no
					order by 
						reporting_month,
						term_effective_date,
						transaction_date,
						case 
							when cast(transaction_type as varchar(60)) in ('New', 'Renewal') then 0
							when cast(transaction_type as varchar(60)) like 'Cancel%' then 2
							else 1 
						end,
						total_collected desc
				) - 1 as transaction_seq_no,
			CASE 
				WHEN insured_cert_no = LAG(insured_cert_no) OVER (
					PARTITION BY insured_first_name, insured_last_name, address1, zip
					ORDER BY expiration_date
				) THEN NULL 
				ELSE LAG(insured_cert_no) OVER (
					PARTITION BY insured_first_name, insured_last_name, address1, zip 
					ORDER BY expiration_date
				) 
			END AS prior_policy_no
		FROM temp_nfp_base_1 np
		)
		,temp_nfp_base_3 AS (
		select insured_cert_no
				,insured_first_name
				,insured_last_name
				,address1
				,zip
				,effective_date
				,transaction_type
				,transaction_date
				,term_effective_date
				,transaction_seq_no,
				case when rn = 1 then null 
				else FIRST_VALUE(insured_cert_no) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as original_policy_no,
				case when rn = 1 then null 
				else FIRST_VALUE(term_effective_date) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as original_policy_effective_dt,
				LAST_VALUE(prior_policy_no) IGNORE NULLS OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) as prior_term_policy_no,
				case when rn = 1 then null 
				else FIRST_VALUE(term_effective_date) OVER (PARTITION BY insured_first_name, insured_last_name, address1, zip ORDER BY expiration_date) end as uw_company_original_policy_effective_dt,
				'Term ' + cast(rn as varchar) as term_no,
                --case when  cast(transaction_type as varchar(60)) in ('New', 'Renewal')  then transaction_type 
                    --else FIRST_VALUE(transaction_type) OVER (PARTITION BY insured_cert_no  ORDER BY term_effective_date) end  as	policy_term,
				delta_flag,
                reporting_month,
                total_collected 
		from temp_nfp_base_2)
		select insured_cert_no
				,insured_first_name
				,insured_last_name
				,address1
				,zip
				,effective_date
				,transaction_type
				,transaction_date
				,term_effective_date
				,transaction_seq_no,
				original_policy_no,
				original_policy_effective_dt,
				prior_term_policy_no,
				uw_company_original_policy_effective_dt,
				term_no,
				case when original_policy_no is null  then 'New' 
                    else 'Renewal' end  as	policy_term,
				delta_flag,
                reporting_month,
                total_collected 
		into edw_temp.nfp_policy_temp1
		from temp_nfp_base_3;

		
		UPDATE np 
		SET np.term_effective_date = t.term_effective_date, 
			np.transaction_seq_no = t.transaction_seq_no,
			np.original_policy_no = t.original_policy_no,
			np.original_policy_effective_dt = t.original_policy_effective_dt,
			np.prior_term_policy_no = t.prior_term_policy_no,
			np.uw_company_original_policy_effective_dt = t.uw_company_original_policy_effective_dt,
			np.term_no = t.term_no,
            np.policy_term = t.policy_term
		from edw_stage.nfp_policy np 
		inner join edw_temp.nfp_policy_temp1 t 
		on np.insured_cert_no = t.insured_cert_no
		and np.effective_date = t.effective_date
		and cast(np.transaction_type as varchar(60)) = cast(t.transaction_type as varchar(60))
		and np.transaction_date = t.transaction_date 
		and np.reporting_month = t.reporting_month
		and np.total_collected = t.total_collected
		where t.delta_flag = 'I';
			

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.reporting_month) FROM edw_temp.nfp_policy_temp1 t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS edw_temp.nfp_policy_temp1;
		
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