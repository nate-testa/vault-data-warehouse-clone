-- =============================================================================================================
-- Author:		Yunus Mohammed
-- Description: This procedure insert litigation policy for commercial
------------------------------------------------------------------------------------------------------------
-- Change date |Author						    |	Change Description
------------------------------------------------------------------------------------------------------------
-- 06/30/25		Yunus Mohammed		1. Created this procedure 
-- ============================================================================================================= 

CREATE OR ALTER PROCEDURE [edw_core].[sp_tcommercial_policy_onetime_litigation]

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

        DROP TABLE IF EXISTS edw_temp.tcommercial_policy_onetime_litigation_temp1  
		
        select policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,policy_term,policy_status,
        insured_nm,mailing_address_line1,mailing_address_line2,mailing_address_city_nm,
        mailing_address_state_cd,mailing_address_zip_cd,source_system_sk,create_ts,update_ts,etl_audit_sk
        into edw_temp.tcommercial_policy_onetime_litigation_temp1
        from
            (
          select 'CVG7777VES' as policy_no, '2020-01-01' as effective_dt, '2030-12-31' as expiration_dt,  '56536' as broker_id, 'LIT9999' as customer_id,
            'PEL' as product_cd,'FL' as risk_state_cd, 'New' as policy_term, 'Active' as policy_status,'Vault Insurance' as insured_nm,
            '300 First Ave S' as mailing_address_line1,'Suite 401' as mailing_address_line2,'St. Petersburg' as mailing_address_city_nm, 
            'FL' as mailing_address_state_cd,'33701' as mailing_address_zip_cd,
            4 as source_system_sk,GETDATE() AS create_ts,null AS update_ts,0 etl_audit_sk
            
      ) as t
            WHERE
            not exists
            (
                    select 1 from edw_commercial.tcommercial_policy p
                    where p.policy_no = t.policy_no
            )
        
        insert into edw_commercial.tcommercial_policy
        (
       policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,policy_term,policy_status,
        insured_nm,mailing_address_line1,mailing_address_line2,mailing_address_city_nm,
        mailing_address_state_cd,mailing_address_zip_cd,source_system_sk,create_ts,update_ts,etl_audit_sk
        )
        select
	    policy_no,effective_dt,expiration_dt,broker_id,customer_id,product_cd,risk_state_cd,policy_term,policy_status,
        insured_nm,mailing_address_line1,mailing_address_line2,mailing_address_city_nm,
        mailing_address_state_cd,mailing_address_zip_cd,source_system_sk,create_ts,update_ts,etl_audit_sk
        from edw_temp.tcommercial_policy_onetime_litigation_temp1 t    

		SET @rows_affected=@@ROWCOUNT;
		
        DROP TABLE IF EXISTS edw_temp.[tcommercial_policy_onetime_litigation_temp1]
	
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