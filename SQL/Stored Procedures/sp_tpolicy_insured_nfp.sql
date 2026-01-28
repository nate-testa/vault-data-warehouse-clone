-- =================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedures inserts policy insured data for NFP policies
---------------------------------------------------------------------------------------------------
-- Change date      |Author										|	Change Description
---------------------------------------------------------------------------------------------------
-- 01/28/26		      Yunus Mohammed				 1. Created this procedure  
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tpolicy_insured_nfp]

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
        DECLARE @ssk VARCHAR(50)
		select @ssk=source_system_sk from edw_core.tsource_system where source_system_nm = 'NFP';

		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
	
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))     
    
        drop table if exists edw_temp.tpolicy_insured_nfp_temp1
        drop table if exists edw_temp.tpolicy_insured_nfp_temp2
        
        select *
        into edw_temp.tpolicy_insured_nfp_temp1
        from
            edw_core.tpolicy_history tp
        where
            product_sk = @ssk
            and create_ts > @last_source_extract_ts

        select *
        into edw_temp.tpolicy_insured_nfp_temp2
        from
        (
        SELECT
            ROW_NUMBER() OVER (
                PARTITION BY 
                    np.insured_cert_no,
                    np.term_effective_date,
                    np.transaction_seq_no
                ORDER BY 
                    np.transaction_seq_no DESC
            ) AS dup_rn,
            tp.policy_no,
            tp.effective_dt,
            tp.transaction_seq_no,
            tp.transaction_effective_dt,
            tp.transaction_ts as transaction_dt,
            tp.policy_history_sk,
            concat_ws(' ',np.insured_first_name, np.insured_last_name) as insured_nm,
            np.insured_first_name as first_nm,
            np.insured_last_name as last_nm,
            'Individual' as insured_type,
            'Yes' as primary_insured_in,
            np.address1 as mailing_address_line_1,
            np.address2 as mailing_address_line_2,
            np.city as mailing_address_city_nm,
            np.state as mailing_address_state_cd,
            np.zip as mailing_address_zip_cd
        FROM edw_stage.nfp_policy np
        inner join edw_temp.tpolicy_insured_nfp_temp1 tp on np.insured_cert_no = tp.policy_no
        and np.effective_date = tp.effective_dt and np.transaction_seq_no = tp.transaction_seq_no
        where insured_cert_no is not null 
        ) as a
        where dup_rn = 1

        union

        select *
        from
        (
        SELECT
            ROW_NUMBER() OVER (
                PARTITION BY 
                    np.insured_cert_no,
                    np.term_effective_date,
                    np.transaction_seq_no
                ORDER BY 
                    np.transaction_seq_no DESC
            ) AS dup_rn,
            tp.policy_no,
            tp.effective_dt,
            tp.transaction_seq_no,
            tp.transaction_effective_dt,
            tp.transaction_ts as transaction_dt,
            tp.policy_history_sk,
            concat_ws(' ',np.insured_spouse_first_name, np.insured_spouse_last_name) as insured_nm,
            np.insured_spouse_first_name as first_nm,
            np.insured_spouse_last_name as last_nm,
            'Individual' as insured_type,
            'No' as primary_insured_in,
            np.address1 as mailing_address_line_1,
            np.address2 as mailing_address_line_2,
            np.city as mailing_address_city_nm,
            np.state as mailing_address_state_cd,
            np.zip as mailing_address_zip_cd
        FROM edw_stage.nfp_policy np
        inner join edw_temp.tpolicy_insured_nfp_temp1 tp on np.insured_cert_no = tp.policy_no
        and np.effective_date = tp.effective_dt and np.transaction_seq_no = tp.transaction_seq_no
        where np.insured_spouse_first_name is not null
            or np.insured_spouse_last_name is not null
        ) as a
        where dup_rn = 1

		INSERT into edw_core.tpolicy_insured
			(
				policy_no, effective_dt, transaction_effective_dt, transaction_seq_no, transaction_dt, policy_history_sk, 
				insured_nm, dba_nm, first_nm, middle_nm, last_nm, insured_type, primary_insured_in, 
				coinsured_in, birth_dt, home_phone_no, mobile_phone_no, title, prefix, suffix, 
				mailing_address_line_1, mailing_address_line_2, mailing_address_unit_no, 
				mailing_address_city_nm, mailing_address_state_cd, mailing_address_zip_cd, mailing_address_county_nm, mailing_address_country_nm, 
				include_on_dec_in, email, employer_nm, insurance_score, 
				insurance_score_cd1, insurance_score_desc1, insurance_score_cd2, insurance_score_desc2, 
				insurance_score_cd3, insurance_score_desc3, insurance_score_cd4, insurance_score_desc4, subscriber_contribution_end_dt,
				source_system_sk, create_ts, update_ts, etl_audit_sk, named_insured_limit_type
			)
		select 	policy_no, effective_dt, transaction_effective_dt, transaction_seq_no, transaction_dt, policy_history_sk, 
				insured_nm, null as dba_nm, first_nm, null as middle_nm, last_nm, insured_type, primary_insured_in, 
				null as coinsured_in, null as birth_dt,null as home_phone_no, null as mobile_phone_no, null as title, null as prefix, null as suffix, 
				mailing_address_line_1, mailing_address_line_2, null as mailing_address_unit_no, 
				mailing_address_city_nm, mailing_address_state_cd, mailing_address_zip_cd, null as mailing_address_county_nm, null as mailing_address_country_nm, 
			    null as include_on_dec_in,null as  email, null as employer_nm, null as insurance_score, 
				null as insurance_score_cd1, null as insurance_score_desc1, null as insurance_score_cd2,null as  insurance_score_desc2, 
                null as insurance_score_cd3, null as insurance_score_desc3, null as insurance_score_cd4, null as insurance_score_desc4,
                null as  subscriber_contribution_end_dt,
				@ssk AS source_system_sk, getdate() as create_ts, getdate()as update_ts, @etl_audit_sk as  etl_audit_sk, null as named_insured_limit_type
		FROM edw_temp.tpolicy_insured_nfp_temp2

		SET @rows_affected=@@ROWCOUNT;

		-- Update control table
		SET @new_last_source_extract_ts=COALESCE((SELECT MAX((t1.IssuedDate)) FROM edw_temp.tpolicy_insured_temp1 t1),@last_source_extract_ts)

        
        drop table if exists edw_temp.tpolicy_insured_nfp_temp1
        drop table if exists edw_temp.tpolicy_insured_nfp_temp2
		
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

