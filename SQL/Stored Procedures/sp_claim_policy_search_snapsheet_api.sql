-- =================================================================================================
-- Description: This procedures insert and update info related to Claim Policy Search API
---------------------------------------------------------------------------------------------------
-- Change date 				|Author										|	Change Description
---------------------------------------------------------------------------------------------------
--	09-27-2024				Yunus Mohammed				Created procedure
-- 01-28-2025				Yunus Mohammed				Used latest transaction for policy
-- 01-28-2025	           Sandeep Gundreddy			removed source_system_sk<>1  filter to include OS data
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_policy_search_snapsheet_api]
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
		
		DROP TABLE IF EXISTS [edw_temp].[claim_policy_search_snapsheet_api_temp1];
		SELECT
			DISTINCT
				p.policy_no,
				case
					when product_nm = 'Auto' then 'auto'
					when product_nm in ('Homeowners','Condo','Collections') then 'property'
					when product_nm = 'Excess Liability' then 'general_liability'					
				end as policy_type,
				p.policy_status as [status],
				pr.product_nm as product_code,
				p.effective_dt as inception_date,
				JSON_QUERY((
						select
							case when [pi].insured_type = 'Entity' then [pi].insured_nm end as [name],
							case when [pi].Insured_type = 'Individual' then [pi].first_nm end as [firstName],
							case when [pi].insured_type = 'Individual' then [pi].last_nm end as [lastName],
							case
								when [pi].insured_type = 'Entity' then 'ORGANIZATION'
								else 'PERSON'
							end as [entityType],
							(
								SELECT 
									p.mailing_address_line1 as [address1],
									p.mailing_address_line2 as [address2],
									p.mailing_address_city_nm as [city],
									p.mailing_address_state_cd as [region],
									p.mailing_address_zip_cd as [postalCode],
									p.mailing_address_country_nm as [country]
								for json path, include_null_values
							) AS addresses,
							(
								select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
							) as contactMethods
							for json path, include_null_values
					)) as policy_entities,
					p.expiration_dt,
					d2.actual_dt as transaction_effective_dt,
					pt.transaction_seq_no,
					ptt.policy_transaction_type_nm as transaction_type,
					ss.source_system_nm,
					'pending' as api_status,
					pt.create_ts as policy_transaction_create_ts
		INTO [edw_temp].[claim_policy_search_snapsheet_api_temp1] 
		FROM (

				SELECT distinct
					pt.policy_sk,pt.transaction_seq_no, pt.transaction_effective_dt_sk, pt.customer_sk, pt.policy_transaction_type_sk, 
					pt.source_system_sk, pt.item_sk, pt.vehicle_coverage_sk, pt.create_ts
					FROM
					(
						select
						dense_rank() OVER(PARTITION BY pt.policy_sk ORDER BY pt.transaction_seq_no desc) AS rn,pt. *
						from
							edw_core.tpolicy_transaction pt
						where
							cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
					)as pt
					INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk
					LEFT JOIN edw_core.tauto_vehicle_coverage AS avc ON pt.vehicle_coverage_sk = avc.auto_vehicle_coverage_sk
					WHERE
					CASE WHEN pr.product_cd = 'AU' AND pt.item_sk = 0 THEN 0  ELSE 1 END = 1
					AND CASE WHEN pr.product_cd = 'AU' AND avc.vehicle_deleted_in = 'Yes' THEN 0  ELSE 1 END = 1
					and rn = 1
			) AS pt
		INNER JOIN edw_core.tpolicy AS p ON pt.policy_sk = p.policy_sk
		inner JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd
		LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_effective_dt_sk = d2.date_sk
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk		
		LEFT JOIN edw_core.tpolicy_transaction_type AS ptt ON pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
		LEFT JOIN edw_core.tsource_system AS ss ON pt.source_system_sk = ss.source_system_sk
		LEFT JOIN edw_core.thome_location AS hl ON pt.item_sk = hl.home_location_sk
		LEFT JOIN edw_core.tauto_vehicle AS av ON pt.item_sk = av.auto_vehicle_sk
		LEFT JOIN edw_core.tpel_location AS pl ON p.policy_no = pl.policy_no AND p.effective_dt = pl.effective_dt AND pt.transaction_seq_no = pl.transaction_seq_no
		LEFT JOIN edw_core.tpolicy_insured AS [pi] ON p.policy_no = [pi].policy_no AND p.effective_dt = [pi].effective_dt
			AND pt.transaction_seq_no = [pi].transaction_seq_no AND pi.primary_insured_in = 'Yes'
		WHERE
			pr.product_nm in ('Auto','Homeowners','Condo','Collections','Excess Liability')	

		-- Start Insert process
		INSERT INTO [edw_integration].[claim_policy_search_snapsheet_api]
		(			
			policyNumber,
			policyType,
			[status],
			productCode,
			policyEntities,
			inceptionDate,
			expiration_dt,
			transaction_effective_dt,
			transaction_seq_no,
			transaction_type,
			source_system_nm,
			api_status,			
			create_ts,
			etl_audit_sk
		)
		SELECT
			policy_no,
			policy_type,
			[status],
			product_code,
			policy_entities,
			inception_date,			
			expiration_dt,
			transaction_effective_dt,
			transaction_seq_no,
			transaction_type,
			source_system_nm,
			api_status,
			getdate(),
		    @etl_audit_sk
		FROM [edw_temp].[claim_policy_search_snapsheet_api_temp1];

		SET @rows_affected=@@ROWCOUNT;

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_transaction_create_ts) FROM [edw_temp].[claim_policy_search_snapsheet_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[claim_policy_search_snapsheet_api_temp1];
		
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