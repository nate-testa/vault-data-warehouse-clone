-- =============================================
-- Author:		Hernando Gonzalez
-- Description: This stored procedure insert info related to Hubspot - Customer
---------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 07/17/24		Hernando Gonzalez			1. Created this procedure 
-- 07/23/24		Architha Gudimalla			2. Updated to use data from tpolicy_insured
-- 07/29/24		Architha Gudimalla			3. Corrections after first runs
-- 08/02/24		Architha Gudimalla			4. Added customer_id
-- ================================================================================================= 

CREATE OR ALTER PROCEDURE edw_core.sp_customer_hubspot_feed
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON

	BEGIN TRY
		DECLARE @last_source_extract_ts DATETIME2(7)
		DECLARE @etl_audit_sk INT = NULL
		DECLARE @new_last_source_extract_ts DATETIME2(7)
		DECLARE @rows_affected INT
		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
		DECLARE @current_date DATETIME=GETDATE()
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		--************Start************

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp1;
        ;

		SELECT
			pol.policy_no,
			pi.first_nm,
			pi.last_nm,
			pi.email,
			pol.risk_state_cd,
			pol.product_cd AS product_nm,
			br.broker_id,
			bvt.team_member_nm AS bdm_nm,
			br.broker_nm,
			br.broker_phone_no,
			pol.policy_status,
			pol.create_ts,
			pol.update_ts,
			pi.mailing_address_line_1, 
			pi.mailing_address_line_2 , 
			pi.mailing_address_unit_no, 
			pi.mailing_address_city_nm, 
			pi.mailing_address_state_cd, 
			pi.mailing_address_zip_cd,
			pol.customer_id
		INTO edw_temp.customer_hubspot_feed_temp1
		FROM edw_core.tpolicy pol		
		INNER JOIN edw_core.tcustomer cust
			ON cust.customer_id = pol.customer_id	
		INNER JOIN edw_core.tproduct pr
			ON pr.product_cd = pol.product_cd
		INNER JOIN edw_core.tbroker br
			ON br.broker_id = pol.broker_id
		LEFT JOIN edw_core.tbroker_vault_team bvt
			ON br.broker_id = bvt.broker_id
			AND bvt.product_nm = pr.product_nm
			AND bvt.team_member_type = 'BusinessDevelopmentManager'
			AND pol.program_type = bvt.program_type
			AND isnull(bvt.state_cd,pol.risk_state_cd)=pol.risk_state_cd
		INNER join edw_core.tpolicy_history ph 
			on ph.policy_sk = pol.policy_sk and ph.latest_transaction_in = 'Y'
		INNER join edw_core.tpolicy_insured pi 
			on pi.policy_history_sk = ph.policy_history_sk and pi.primary_insured_in = 'Yes'
		WHERE
			greatest(pol.create_ts, pol.update_ts) > @last_source_extract_ts;

		MERGE edw_integration.customer_hubspot_feed as TARGET
		USING (
			SELECT 
				policy_no
  				,first_nm
  				,last_nm
  				,email
  				,risk_state_cd
  				,product_nm
  				,broker_id
  				,bdm_nm
  				,broker_nm
  				,broker_phone_no
  				,policy_status
            	,create_ts
            	,update_ts
            	,mailing_address_line_1
				,mailing_address_line_2
				,mailing_address_unit_no
				,mailing_address_city_nm
				,mailing_address_state_cd
				,mailing_address_zip_cd
				,customer_id
				FROM edw_temp.customer_hubspot_feed_temp1
		) as SOURCE
		ON Source.policy_no = Target.policy_no
		-- For Inserts
		WHEN NOT MATCHED BY Target THEN
		INSERT (
			policy_no
  			,first_nm
  			,last_nm
  			,email
  			,risk_state_cd
  			,product_nm
  			,broker_id
  			,bdm_nm
  			,broker_nm
  			,broker_phone_no
  			,policy_status
            ,create_ts
            ,update_ts
            ,etl_audit_sk
            ,mailing_address_line_1
			,mailing_address_line_2
			,mailing_address_unit_no
			,mailing_address_city_nm
			,mailing_address_state_cd
			,mailing_address_zip_cd
			,customer_id
			)
		VALUES (source.policy_no,
				source.first_nm,
				source.last_nm,
				source.email,
				source.risk_state_cd,
				source.product_nm,
				source.broker_id,
				source.bdm_nm,
				source.broker_nm,source.
				broker_phone_no,
				source.policy_status,
				getdate(),
				getdate(),
				@etl_audit_sk
            	,source.mailing_address_line_1
				,source.mailing_address_line_2
				,source.mailing_address_unit_no
				,source.mailing_address_city_nm
				,source.mailing_address_state_cd
				,source.mailing_address_zip_cd
				,source.customer_id)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
			target.first_nm 				= source.first_nm
  			,target.last_nm 				= source.last_nm
  			,target.email 					= source.email
  			,target.risk_state_cd 			= source.risk_state_cd
  			,target.product_nm 				= source.product_nm
  			,target.broker_id 				= source.broker_id
  			,target.bdm_nm 					= source.bdm_nm
  			,target.broker_nm 				= source.broker_nm
  			,target.broker_phone_no 		= source.broker_phone_no
  			,target.policy_status 			= source.policy_status 
            ,target.update_ts 				= getdate()
            ,target.etl_audit_sk 			= @etl_audit_sk 
  			,target.mailing_address_line_1 	= source.mailing_address_line_1
  			,target.mailing_address_line_2 	= source.mailing_address_line_2
  			,target.mailing_address_unit_no = source.mailing_address_unit_no
  			,target.mailing_address_city_nm = source.mailing_address_city_nm 
            ,target.mailing_address_state_cd = source.mailing_address_state_cd
            ,target.mailing_address_zip_cd 	= source.mailing_address_zip_cd
            ,target.customer_id 			= source.customer_id
		;

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = COALESCE((SELECT MAX(greatest(create_ts, update_ts)) FROM edw_temp.customer_hubspot_feed_temp1), @last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp1;

	END TRY
	BEGIN CATCH
		DECLARE @error_message nvarchar(4000)
		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
		EXEC edw_core.sp_upd_error_tetl_audit @etl_audit_sk,@error_message;

		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	
    END CATCH
END
GO