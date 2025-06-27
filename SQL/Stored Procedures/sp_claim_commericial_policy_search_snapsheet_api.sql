-- =================================================================================================
-- Description: This procedures inserts info related to Claim Policy Search API for commercial policies
---------------------------------------------------------------------------------------------------
-- Change date 				|Author						|	Change Description
---------------------------------------------------------------------------------------------------
--	06-24-2025				Yunus Mohammed				1 - Created procedure
-- ================================================================================================= 
CREATE OR ALTER PROCEDURE [edw_core].[sp_claim_commericial_policy_search_snapsheet_api]
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
		
		DROP TABLE IF EXISTS [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp1];
		DROP TABLE IF EXISTS [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp2];

		SELECT
			DISTINCT
				p.policy_no,
				'professional_liability' as policy_type,
				p.policy_status as [status],
				pr.product_nm as product_code,
				p.effective_dt as inception_date,
				JSON_QUERY((
						select
							case when [c].insured_type = 'Entity' then p.insured_nm end as [name],
							case when [c].Insured_type = 'Individual' then c.first_nm end as [firstName],
							case when [c].insured_type = 'Individual' then c.last_nm end as [lastName],
							case
								when c.insured_type = 'Entity' then 'ORGANIZATION'
								else 'PERSON'
							end as [entityType],
							(
								SELECT 
									p.mailing_address_line1 as [address1],
									p.mailing_address_line2 as [address2],
									trim(p.mailing_address_city_nm) as [city],
									upper(trim(p.mailing_address_state_cd)) as [region],
									trim(p.mailing_address_zip_cd) as [postalCode],
									'US' as [country]
								for json path, include_null_values
							) AS addresses,
							(
								select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
							) as contactMethods
							for json path, include_null_values
					)) as policy_entities,
					p.expiration_dt,
					pt.transaction_effective_dt,
					pt.transaction_seq_no,
					pt.transaction_type,
					ss.source_system_nm,
					'pending' as api_status,
					pt.create_ts as policy_transaction_create_ts
		INTO [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp1] 
		FROM (

				SELECT distinct
					pt.commercial_policy_sk,pt.transaction_seq_no, pt.transaction_effective_dt, pt.customer_sk, pt.transaction_type, 
					pt.source_system_sk,pt.create_ts
					FROM
					(
						select
						dense_rank() OVER(PARTITION BY pt.commercial_policy_sk ORDER BY pt.transaction_seq_no desc) AS rn,pt. *
						from
							edw_commercial.tcommercial_policy_history pt
						where
							cast(pt.create_ts as datetime2(7)) > @last_source_extract_ts
					)as pt
					INNER JOIN edw_core.tproduct as pr ON pt.product_sk = pr.product_sk					
					WHERE
						rn = 1
			) AS pt
		INNER JOIN edw_commercial.tcommercial_policy AS p ON pt.commercial_policy_sk = p.commercial_policy_sk
		INNER JOIN edw_core.tproduct AS pr ON p.product_cd = pr.product_cd		
		LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk		
		LEFT JOIN edw_core.tsource_system AS ss ON pt.source_system_sk = ss.source_system_sk		
		where
			pr.product_category_nm = 'CommercialLines'
			
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
		FROM [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp1];
		SET @rows_affected=@@ROWCOUNT;
		
		-- Vault litigation
		SELECT * INTO [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp2]
		FROM
		(
			SELECT
			'CVG7777VES' AS policyNumber,'general_liability' AS policyType,'Active' AS [status],'Excess Liability' AS productCode,
			'[{"name":null,"firstName":"Vault","lastName":"Insurance","entityType":"PERSON","addresses":[{"address1":"300 First Ave S","address2":"Suite 401","city":"St. Petersburg", "region":"FL","postalCode":"33701", "country":"US" } ],"contactMethods":[]}]' AS policyEntities,
			'2020-01-01' AS inceptionDate,'2030-12-31' AS expiration_dt,'2020-01-01' AS transaction_effective_dt,
			0 AS transaction_seq_no,'New' AS transaction_type,'Metal' AS source_system_nm,'pending' AS api_status,null AS api_error_description,
			GETDATE() AS create_ts,null AS update_ts,0 etl_audit_sk
		
		) as temp
		WHERE
			NOT EXISTS
			(
					SELECT 1 FROM [edw_integration].[claim_policy_search_snapsheet_api] cps
					WHERE
						cps.policyNumber = temp.policyNumber
						and cps.inceptionDate = temp.inceptionDate
						and cps.transaction_seq_no = temp.transaction_seq_no
			)

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
			getdate(),
		    @etl_audit_sk
		FROM [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp2];

		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(t1.policy_transaction_create_ts) FROM [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp1] t1),@last_source_extract_ts);

        DROP TABLE IF EXISTS [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp1];
		DROP TABLE IF EXISTS [edw_temp].[claim_commericial_policy_search_snapsheet_api_temp2];
		
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