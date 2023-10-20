-- =============================================
-- Author:		Alberto Almario Valbuena
-- Create Date: 2023-08-01
-- Description: This procedures insert and update info related to Claim Policy Search API
-- =============================================
CREATE OR ALTER PROCEDURE [edw_core].[sp_tclaim_policy_search_api]
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
		DECLARE @parameter_desc VARCHAR(255)
		-- Get last source extract date
		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
		EXEC edw_core.sp_ins_tetl_audit @process_nm,@CU,@etl_audit_sk=@etl_audit_sk OUTPUT;
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS [edw_temp].[tclaim_policy_search_api_temp1];
		SELECT DISTINCT p.policy_no,
				p.effective_dt,
				p.expiration_dt,
				d2.actual_dt as transaction_effective_dt,
				pt.transaction_seq_no,
				p.policy_status,
				p.insured_nm,
				c.Insured_type,
				p.uw_company_nm,
				pr.product_nm,
				ptt.policy_transaction_type_nm as transaction_type,
				CASE 
					WHEN p.product_cd in ('PEL','LUX') THEN CONCAT(p.mailing_address_line1,'-',p.mailing_address_line2,'-',p.mailing_address_unit_no,'-',p.mailing_address_city_nm,'-',p.mailing_address_state_cd,'-',p.mailing_address_zip_cd)
					WHEN p.product_cd = 'HO' THEN CONCAT(hl.address_line_1,'-',hl.address_line_2,'-',hl.unit_no,'-',hl.city_nm,'-',hl.state_cd,'-',hl.zip_cd)
					WHEN p.product_cd = 'AU' THEN av.vehicle_vin
					ELSE '***!Pending!***'
				END as risk_item,
				ss.source_system_nm,
				pt.create_ts as policy_transaction_create_ts
		INTO [edw_temp].[tclaim_policy_search_api_temp1] 
		FROM (
				SELECT DISTINCT pt.policy_sk, pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, pt.source_system_sk, pt.item_sk, pt.vehicle_coverage_sk, pt.create_ts
				FROM edw_core.tpolicy_transaction as pt
				INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
				LEFT JOIN edw_core.tauto_vehicle_coverage AS avc ON pt.vehicle_coverage_sk = avc.auto_vehicle_coverage_sk
				WHERE 1=1
				AND cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
				AND CASE WHEN pr.product_cd = 'AU' AND pt.item_sk = 0 THEN 0  ELSE 1 END = 1
				AND CASE WHEN pr.product_cd = 'AU' AND avc.vehicle_deleted_in = 'Yes' THEN 0  ELSE 1 END = 1
			) AS pt
		INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
		LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_effective_dt_sk = d2.date_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
		LEFT JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tpolicy_transaction_type AS ptt ON pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
		LEFT JOIN edw_core.tsource_system AS ss ON pt.source_system_sk = ss.source_system_sk
		LEFT JOIN edw_core.thome_location AS hl ON pt.item_sk = hl.home_location_sk
		LEFT JOIN edw_core.tauto_vehicle AS av ON pt.item_sk = av.auto_vehicle_sk


		-- Start Insert process
		INSERT INTO [edw_integration].[claim_policy_search_api](
			policy_no,
			effective_dt,
			expiration_dt,
			transaction_effective_dt,
			transaction_seq_no,
			policy_status,
			insured_nm,
			insured_type,
			uw_company_nm,
			product_nm,
			transaction_type,
			risk_item,
			source_system_nm,
			create_ts,
			update_ts,
			etl_audit_sk
		)
		SELECT policy_no,
			effective_dt,
			expiration_dt,
			transaction_effective_dt,
			transaction_seq_no,
			policy_status,
			insured_nm,
			insured_type,
			uw_company_nm,
			product_nm,
			transaction_type,
			risk_item,
			source_system_nm,
			getdate(),
			getdate(),
		    @etl_audit_sk
		FROM [edw_temp].[tclaim_policy_search_api_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_transaction_create_ts) FROM [edw_temp].[tclaim_policy_search_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[tclaim_policy_search_api_temp1];
		
		-- Update control table
		EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;

		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

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

