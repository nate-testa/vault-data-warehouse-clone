-- ==================================================================================================================
-- Author:		Dinesh Bobbili
-- Description: This stored procedure insert info related to Hubspot - Customer Commercial
-------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------
-- 05/30/25		Dinesh Bobbili			    1. Created this procedure
-- 06/18/25		Dinesh Bobbili			    2. AD9853 added underwriter_nm column 
-- 06/30/25		Architha Gudimalla		    3. Updated last name to use policy insured_nm
-- 09/30/25		Dinesh Bobbili				4. AD10938 - Added new columns
-- ================================================================================================================== 

CREATE OR ALTER PROCEDURE edw_core.sp_customer_hubspot_feed_commercial
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

		DROP TABLE IF exists edw_temp.customer_hubspot_feed_commercial_temp0;

        --used to see if there are any changes on the broker/broker_vault
        select a.policy_no
		into  edw_temp.customer_hubspot_feed_commercial_temp0
		from  [edw_integration].[customer_hubspot_feed] a
		inner join edw_commercial.tcommercial_policy q on a.policy_no = q.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        left join edw_core.tbroker br on br.broker_id = q.broker_id
		where (a.broker_id <> br.broker_id
		or isnull(a.broker_nm,'') <> isnull(br.broker_nm,'')
		or isnull(a.broker_phone_no,'') <> isnull(br.broker_phone_no,''))
		and pr.product_category_nm = 'CommercialLines'; 

		--used to see if there are any changes in policy_inforce_in
		insert into  edw_temp.customer_hubspot_feed_commercial_temp0
        select a.policy_no
        from  [edw_integration].[customer_hubspot_feed] a
        inner join edw_commercial.tcommercial_policy  pol on pol.policy_no = a.policy_no
        where a.policy_inforce_in <> pol.policy_inforce_in
        and a.policy_no not in (select policy_no from edw_temp.customer_hubspot_feed_commercial_temp0);

		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_commercial_temp3;
		SELECT DISTINCT
			p.commercial_policy_sk,
			p.policy_no,
			p.effective_dt,
			ISNULL(pqs.max_per_claim_policy_limit_amt, ptl.max_per_claim_policy_limit_amt) AS per_claim_policy_limit_amt,
			ptl_1.per_claim_attachment_amt AS per_claim_attachment_amt,
			pt.per_claim_retention_amt AS per_claim_retention_amt
		into edw_temp.customer_hubspot_feed_commercial_temp3
		FROM edw_commercial.tcommercial_policy AS p
		LEFT JOIN (
			SELECT
				policy_no,
				effective_dt,
				per_claim_retention_amt
			FROM edw_commercial.tcommercial_policy_tower
			WHERE tower_type = 'primary'
		) AS pt
			ON p.policy_no = pt.policy_no
		AND p.effective_dt = pt.effective_dt
		LEFT JOIN (
			SELECT
				policy_no,
				effective_dt,
				MAX(aggregate_policy_limit_amt) AS max_per_claim_policy_limit_amt
			FROM edw_commercial.tcommercial_policy_tower
			WHERE company_nm = 'Vault E&S Insurance Company'
			GROUP BY policy_no, effective_dt
		) AS ptl
			ON p.policy_no = ptl.policy_no
		AND p.effective_dt = ptl.effective_dt
		LEFT JOIN (
			SELECT
				policy_no,
				effective_dt,
				MAX(aggregate_policy_limit_amt) AS max_aggregate_policy_limit_amt,
				MAX(per_claim_policy_limit_amt) AS max_per_claim_policy_limit_amt
			FROM edw_commercial.tcommercial_policy_quota_share
			WHERE company_nm LIKE 'Vault%'
			GROUP BY policy_no, effective_dt
		) AS pqs
			ON p.policy_no = pqs.policy_no
		AND p.effective_dt = pqs.effective_dt
		LEFT JOIN (
			SELECT
				policy_no,
				effective_dt,
				MAX(per_claim_attachment_amt) AS per_claim_attachment_amt
			FROM edw_commercial.tcommercial_policy_tower
			GROUP BY policy_no, effective_dt
		) AS ptl_1
			ON p.policy_no = ptl_1.policy_no
		AND p.effective_dt = ptl_1.effective_dt
		LEFT JOIN edw_core.tbroker AS br
			ON br.broker_id = p.broker_id
		LEFT JOIN edw_commercial.tcommercial_policy_history AS ph
			ON p.policy_no = ph.policy_no
		AND p.effective_dt = ph.effective_dt
		LEFT JOIN (
			SELECT
				policy_no,
				effective_dt,
				MAX(
					CASE
						WHEN memorandum_of_insurance_in = 'true'  THEN 'Yes'
						WHEN memorandum_of_insurance_in = 'false' THEN 'No'
					END
				) AS moi_val,
				MAX(coverage_type) AS coverage_type
			FROM edw_commercial.tcommercial_policy_coverage
			GROUP BY policy_no, effective_dt
		) AS pc
			ON pc.policy_no = p.policy_no
		AND pc.effective_dt = p.effective_dt
		LEFT JOIN (
			SELECT
				commercial_policy_sk,
				SUM(premium_amt)   AS premium_amt,
				SUM(commission_amt) AS commission_amt
			FROM edw_commercial.tcommercial_policy_transaction
			GROUP BY commercial_policy_sk
		) AS ptxn
			ON ptxn.commercial_policy_sk = ph.commercial_policy_sk;
 

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_commercial_temp1; 
		--for policies
		SELECT
			pol.policy_no,
			null as first_nm,
			pol.insured_nm last_nm,
			case when cust.email like '%papermail%' or cust.email like '%@%@%' then null else cust.email end email, 
			pol.risk_state_cd,
			pol.product_cd AS product_nm,
			br.broker_id,
			null AS bdm_nm,
			br.broker_nm,
			br.broker_phone_no,
			pol.policy_status,
			pol.create_ts,
			pol.update_ts,
			cust.mailing_address_line1 mailing_address_line_1, 
			cust.mailing_address_line2 mailing_address_line_2, 
			cust.mailing_address_unit_no, 
			cust.mailing_address_city_nm, 
			cust.mailing_address_state_cd, 
			cust.mailing_address_zip_cd,
			cust.mailing_address_country_nm,
			pol.customer_id,
			ph.producer_nm,
			p.producer_id
			,null as monoline_in
			,pol.insured_nm
			,'Commercial Lines' as customer_business_type
			,ph.underwriter_nm
			,pol.effective_dt
			,pol.expiration_dt
			,pol.policy_inforce_in
			,cmt.per_claim_policy_limit_amt
			,cmt.per_claim_attachment_amt
			,cmt.per_claim_retention_amt
		INTO edw_temp.customer_hubspot_feed_commercial_temp1
		FROM edw_commercial.tcommercial_policy pol		
		INNER JOIN edw_core.tcustomer cust ON cust.customer_id = pol.customer_id	
		INNER JOIN edw_core.tproduct pr	ON pr.product_cd = pol.product_cd
		INNER JOIN edw_core.tbroker br	ON br.broker_id = pol.broker_id
		INNER join edw_commercial.tcommercial_policy_history ph on ph.commercial_policy_sk = pol.commercial_policy_sk and ph.latest_transaction_in = 'Y'
		left join edw_core.tproducer p on ph.producer_sk = p.producer_sk 
		left join edw_temp.customer_hubspot_feed_commercial_temp3 cmt on pol.commercial_policy_sk = cmt.commercial_policy_sk
		WHERE (greatest(pol.create_ts, pol.update_ts) > @last_source_extract_ts
		or exists (select 'x' from edw_temp.customer_hubspot_feed_commercial_temp0 a where a.policy_no = pol.policy_no)
		)
		and isnull(pol.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%' 
		and pol.effective_dt >= '01-jun-2023'
		-- and pol.product_cd <> 'BY'
		;

		/*
		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_commercial_temp2; 
		--for quotes, just to create a customer record
		SELECT
			pol.quote_no,
			pi.first_nm,
			case when pi.insured_type = 'Entity' then pi.insured_nm  else pi.last_nm end as last_nm,
			case when cust.email like '%papermail%' or cust.email like '%@%@%' then null else cust.email end email,   
			pol.risk_state_cd,
			pol.product_cd AS product_nm,
			br.broker_id,
			bvt.team_member_nm AS bdm_nm,
			br.broker_nm,
			br.broker_phone_no,
			'Inactive' as policy_status,
			pol.create_ts,
			pol.update_ts,
			cust.mailing_address_line1 mailing_address_line_1, 
			cust.mailing_address_line2 mailing_address_line_2, 
			cust.mailing_address_unit_no, 
			cust.mailing_address_city_nm, 
			cust.mailing_address_state_cd, 
			cust.mailing_address_zip_cd,
			pol.customer_id,
			ph.producer_nm,
			p.producer_id
		INTO edw_temp.customer_hubspot_feed_commercial_temp2
		FROM edw_core.tquote pol		
		INNER JOIN edw_core.tcustomer cust ON cust.customer_id = pol.customer_id	
		INNER JOIN edw_core.tproduct pr	ON pr.product_cd = pol.product_cd
		INNER JOIN edw_core.tbroker br	ON br.broker_id = pol.broker_id
		LEFT JOIN edw_core.tbroker_vault_team bvt	ON br.broker_id = bvt.broker_id
													AND bvt.product_nm = pr.product_nm
													AND bvt.team_member_type = 'BusinessDevelopmentManager'
													AND pol.program_type = bvt.program_type
													AND isnull(bvt.state_cd,pol.risk_state_cd)=pol.risk_state_cd
		INNER join edw_core.tquote_history ph on ph.quote_sk = pol.quote_sk and ph.latest_transaction_in = 'Y'
		INNER join edw_core.tquote_insured pi on pi.quote_history_sk = ph.quote_history_sk and pi.primary_insured_in = 'Yes'
		left join edw_core.tproducer p on ph.producer_sk = p.producer_sk
		WHERE   isnull(pol.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%'  
		and pol.effective_dt >= '01-jun-2023'
		and quote_create_ts >= dateadd("mm",-1,cast(getdate() as date))
		and not exists (select 'x' from edw_temp.customer_hubspot_feed_commercial_temp1 a where a.customer_id = cust.customer_id)
		and not exists (select 'x' from edw_integration.customer_hubspot_feed b where b.customer_id = cust.customer_id);
		*/

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
				,mailing_address_country_nm
				,customer_id
			    ,producer_nm
				,producer_id
				,monoline_in
				,insured_nm
				,customer_business_type
				,underwriter_nm
				,effective_dt
				,expiration_dt
				,policy_inforce_in
				,per_claim_policy_limit_amt
				,per_claim_attachment_amt
				,per_claim_retention_amt
				FROM edw_temp.customer_hubspot_feed_commercial_temp1/*
				union ALL 
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
				,mailing_address_country_nm
				,customer_id
			    ,producer_nm
				,producer_id
				,monoline_in
				FROM edw_temp.customer_hubspot_feed_commercial_temp2*/
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
			,mailing_address_country_nm
			,customer_id
			,producer_nm
			,producer_id
			,monoline_in
			,insured_nm
			,customer_business_type
			,underwriter_nm
			,effective_dt
			,expiration_dt
			,policy_inforce_in
			,per_claim_policy_limit_amt
			,per_claim_attachment_amt
			,per_claim_retention_amt
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
				,source.mailing_address_country_nm
				,source.customer_id
				,source.producer_nm
				,source.producer_id
				,source.monoline_in
				,source.insured_nm
				,source.customer_business_type
				,source.underwriter_nm
				,source.effective_dt
				,source.expiration_dt
				,source.policy_inforce_in
				,source.per_claim_policy_limit_amt
				,source.per_claim_attachment_amt
				,source.per_claim_retention_amt
				)
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
            ,target.mailing_address_country_nm 	= source.mailing_address_country_nm
            ,target.customer_id 			= source.customer_id
            ,target.producer_nm 			= source.producer_nm
            ,target.producer_id 			= source.producer_id
            ,target.monoline_in 			= source.monoline_in
			,target.insured_nm				= source.insured_nm
			,target.customer_business_type  = source.customer_business_type
			,target.underwriter_nm  		= source.underwriter_nm 
			,target.effective_dt 			= source.effective_dt
			,target.expiration_dt 			= source.expiration_dt
			,target.policy_inforce_in 		= source.policy_inforce_in
			,target.per_claim_policy_limit_amt 		= source.per_claim_policy_limit_amt
			,target.per_claim_attachment_amt 		= source.per_claim_attachment_amt
			,target.per_claim_retention_amt 		= source.per_claim_retention_amt
		;

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = COALESCE((SELECT MAX(greatest(create_ts, update_ts)) FROM edw_temp.customer_hubspot_feed_commercial_temp1), @last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_commercial_temp0;
        DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_commercial_temp1; 

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