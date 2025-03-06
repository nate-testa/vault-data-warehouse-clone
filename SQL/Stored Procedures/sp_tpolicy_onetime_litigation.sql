-- =============================================================================================================
------------------------------------------------------------------------------------------------------------
-- Change date |Author						    |	Change Description
------------------------------------------------------------------------------------------------------------
-- 06/03/25		Yunus Mohammed		1. Created this procedure 
-- ============================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_onetime_litigation]

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

        DROP TABLE IF EXISTS edw_temp.tpolicy_onetime_litigation_temp1  

        select policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,
        uw_company_nm,program_type,policy_status,mailing_adreess_line1,mailing_adreess_line2,mailing_adreess_city,
        mailing_adreess_state_cd,mailing_adreess_zip_cd,mailing_adreess_country_cd,source_system_sk
        from
            (
            select 'FPP9999VES' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'HO' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_es_insurance_litigation_co' as uw_company_nm,
            'Non-Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
            union
            select 'FPP9999VRE' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'HO' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_reciprocal_exchange_litigation' as uw_company_nm,
            'Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
            union
            select 'COV9999VES' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'PEL' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_es_insurance_litigation_co' as uw_company_nm,
            'Non-Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
            union
            select 'COV9999VRE' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'PEL' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_reciprocal_exchange_litigation' as uw_company_nm,
            'Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
            union
            select 'AU9999VES' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'AU' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_es_insurance_litigation_co' as uw_company_nm,
            'Non-Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
            union
            select 'AU9999VRE' as policy_no, '2020-01-01' as effective_dt, '2026-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'AU' as product_cd,'FL' as risk_state_cd, 'Vault Insurance' as insured_nm, 'Individual' as insured_type, 'vault_reciprocal_exchange_litigation' as uw_company_nm,
            'Admitted' as program_type,'Active' as policy_status,
            '300 First Ave S' as mailing_adreess_line1,'Suite 401' as mailing_adreess_line2,'St. Petersburg' as mailing_adreess_city, 
            'FL' as mailing_adreess_state_cd,'33701' as mailing_adreess_zip_cd, 'US' as mailing_adreess_country_cd,
            4 as source_system_sk
      ) as t
            WHERE
            not exists
            (
                    select 1 from edw_core.tpolicy p
                    where p.policy_no = t.policy_no
            )

        insert into edw_core.tpolicy
        (
        policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,
        uw_company_nm,program_type,policy_status,mailing_adreess_line1,mailing_adreess_line2,mailing_adreess_city,
        mailing_adreess_state_cd,mailing_adreess_zip_cd,mailing_adreess_country_cd,source_system_sk,create_ts,update_ts,etl_audit_sk
        )
		select policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,insured_nm,insured_type,
        uw_company_nm,program_type,policy_status,mailing_adreess_line1,mailing_adreess_line2,mailing_adreess_city,
        mailing_adreess_state_cd,mailing_adreess_zip_cd,mailing_adreess_country_cd,source_system_sk,
        GETDATE() as create_ts, GETDATE() as update_ts, @etl_audit_sk as etl_audit_sk
        from edw_temp.tpolicy_onetime_litigation_temp1 t
         WHERE
            not exists
            (
                    select 1 from edw_core.tcustomer c
                    where c.policy_no = t.policy_no
            )

		SET @rows_affected=@@ROWCOUNT;
		
        DROP TABLE IF EXISTS edw_temp.[tpolicy_onetime_litigation_temp1]
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
	
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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
END

