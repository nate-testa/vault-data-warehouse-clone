-- ==================================================================================================================
-- Author:		Hernando Gonzalez
-- Description: This stored procedure insert info related to Hubspot - Customer
-------------------------------------------------------------------------------------------------------------------
-- Change date |Author						|	Change Description
-------------------------------------------------------------------------------------------------------------------
-- 07/17/24		Hernando Gonzalez			1. Created this procedure 
-- 07/23/24		Architha Gudimalla			2. Updated to use data from tpolicy_insured
-- 07/29/24		Architha Gudimalla			3. Corrections after first runs
-- 08/02/24		Architha Gudimalla			4. Added customer_id
-- 08/09/24		Archtha Gudimalla			5. Excluded test brokers
-- 08/09/24		Archtha Gudimalla			6. Only included pols with eff dt >= 20230601
-- 08/29/24		Archtha Gudimalla			7. Updated address to use from customer table to keep it 
--											   consistent across all policies of the customer
-- 09/19/24		Archtha Gudimalla			8. Updated to null wherever cust email is like '%papermail%'
-- 09/19/24		Archtha Gudimalla			9. Updated to null wherever cust email is like '%@%@%' (has two email)
-- 09/25/24		Archtha Gudimalla			10. Added producer id and name
-- 09/30/24		Archtha Gudimalla			11. Added new customer that only have quotes bu no inforce policies, 
--												just to create a customer record
-- 10/01/24		Archtha Gudimalla			12. Commented change 11 to use in future
-- 10/02/24		Archtha Gudimalla			13. Add mailing address country
-- 10/02/24		Archtha Gudimalla			14. Excluded Yacht
-- 10/25/24		Archtha Gudimalla			15. Added isnull to code when checking names for test quotes
-- 12/30/24		Alberto Almario				16. VI35256 - Insured name update for entity/trust LLC
-- 01/13/25		Alberto Almario				17. AD8013 - Included yacht data
-- 03/06/25		Archtha Gudimalla			18. AD8781 - Send latest broker info
-- 04/29/25		Archtha Gudimalla			19. VI37310/AD9292 - Add monoline_in
-- 06/05/25		Archtha Gudimalla			20. AZ9641 - Added customer_business_type
-- 06/06/25		Archtha Gudimalla			21. SR38158/AZ9753 - Added doc delivery preference
-- 06/18/25		Dinesh Bobbili				22. AD9848 Added product_cd column
-- 06/24/25		Dinesh Bobbili				23. AD9848 Removed product_cd column
-- 09/09/25		Archtha Gudimalla			24. AD10935 - Added monoline fix
-- 09/10/25		Archtha Gudimalla			25. AD10960 - Added customer email id fix
-- 09/30/25		Dinesh Bobbili				26. AD10938 - Added new columns
-- ================================================================================================================== 

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

		DROP TABLE IF exists edw_temp.customer_hubspot_feed_temp0;

        --used to see if there are any changes on the broker/broker_vault
        select a.policy_no
		into  edw_temp.customer_hubspot_feed_temp0
		from  [edw_integration].[customer_hubspot_feed] a
		inner join edw_core.tpolicy q on a.policy_no = q.policy_no
        inner join edw_core.tproduct pr	on pr.product_cd = q.product_cd
        left join edw_core.tbroker br on br.broker_id = q.broker_id
        left join edw_core.tbroker_vault_team bvt on br.broker_id = bvt.broker_id and bvt.product_nm = pr.product_nm
                                                    and bvt.team_member_type = 'BusinessDevelopmentManager' and q.program_type = bvt.program_type
                                                    and  isnull(bvt.state_cd,q.risk_state_cd)=q.risk_state_cd
		where a.broker_id <> br.broker_id
		or isnull(a.broker_nm,'') <> isnull(br.broker_nm,'')
		or isnull(a.broker_phone_no,'') <> isnull(br.broker_phone_no,'') 
		or isnull(a.bdm_nm,'') <> isnull(bvt.team_member_nm,''); 

        --used to see if there are any changes in customer email
        insert into  edw_temp.customer_hubspot_feed_temp0
		select a.policy_no 
		from  [edw_integration].[customer_hubspot_feed] a
		inner join edw_core.tcustomer cust on cust.customer_id = a.customer_id 
		where a.email <> cust.email
		and policy_no not in (select policy_no from edw_temp.customer_hubspot_feed_temp0);

 		DROP TABLE IF exists edw_temp.customer_hubspot_feed_temp01;

		--get customer inforce counts
		SELECT customer_id = CASE 
								WHEN customer_id IS NULL THEN 
									'[Grand Total]' 
								ELSE customer_id 
							END
				, product_cd = CASE 
								WHEN pr.product_cd IS NULL THEN 
									'[Total' + case when customer_id is null then '- Overall' else '' end + ']' COLLATE SQL_Latin1_General_CP1_CI_AS 
								ELSE pr.product_cd 
								END
				, inforce_ct = COUNT(*)   
		into  edw_temp.customer_hubspot_feed_temp01
		FROM edw_core.tdaily_inforce_policy summ, edw_core.tproduct pr , edw_core.tcustomer cust 
		where inforce_dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(dd,-1,cast(getdate() as date)))
		and pr.product_sk = summ.product_sk 
		and summ.customer_sk = cust.customer_sk 
		GROUP BY ROLLUP (customer_id, pr.product_cd);		

		--added to handle future effective inforce monoline customers
		insert into edw_temp.customer_hubspot_feed_temp0
		select c.policy_no 
		from edw_integration.customer_hubspot_feed c
		inner join edw_core.tpolicy pol on pol.policy_no = c.policy_no
		inner join edw_core.tdaily_inforce_policy inf on inf.policy_sk = pol.policy_sk and inforce_dt_sk = (select date_sk from edw_core.tdate where actual_dt = dateadd(dd,-1,cast(getdate() as date)))
		left join edw_temp.customer_hubspot_feed_temp01 pinf on c.customer_id = pinf.customer_id and c.product_nm = pinf.product_cd 
		left join edw_temp.customer_hubspot_feed_temp01 cinf on c.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 
		where c.monoline_in
			<> case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end
         and c.policy_no not in (select policy_no from edw_temp.customer_hubspot_feed_temp0);  

		--used to see if there are any changes in policy_inforce_in
		insert into  edw_temp.customer_hubspot_feed_temp0
        select a.policy_no
        from  [edw_integration].[customer_hubspot_feed] a
        inner join edw_core.tpolicy pol on pol.policy_no = a.policy_no
        where a.policy_inforce_in <> pol.policy_inforce_in 
        and a.policy_no not in (select policy_no from edw_temp.customer_hubspot_feed_temp0);

 		-- Step1 limit amount of rows.
		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp1; 
		--for policies
		SELECT
			pol.policy_no,
			pi.first_nm,
			case when pi.insured_type = 'Entity' then pi.insured_nm  else pi.last_nm end as last_nm,
			case when cust.email like '%papermail%' or cust.email like '%@%@%' then null else cust.email end email, 
			pol.risk_state_cd,
			pol.product_cd AS product_nm,
			br.broker_id,
			bvt.team_member_nm AS bdm_nm,
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
			, case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end monoline_in
            , case when pol.document_delivery_to = 'Broker' then 'Send to Agent Only'
				 when pol.document_delivery_to = 'Customer' and pol.document_delivery_method = 'Email' then 'Send to Customer by Email'
				 when pol.document_delivery_to = 'Customer' and pol.document_delivery_method = 'Mail' then 'Send to Customer by Mail'
				 when pol.document_delivery_to = 'Customer' and pol.document_delivery_method = 'Email & Mail' then 'Send to Customer by Email & Mail'
				 else null
			end document_delivery_preference,
			hc.occupancy_type,
			pol.effective_dt,
			pol.expiration_dt,
			pol.policy_inforce_in
		INTO edw_temp.customer_hubspot_feed_temp1
		FROM edw_core.tpolicy pol		
		INNER JOIN edw_core.tcustomer cust ON cust.customer_id = pol.customer_id	
		INNER JOIN edw_core.tproduct pr	ON pr.product_cd = pol.product_cd
		INNER JOIN edw_core.tbroker br	ON br.broker_id = pol.broker_id
		LEFT JOIN edw_core.tbroker_vault_team bvt	ON br.broker_id = bvt.broker_id
													AND bvt.product_nm = pr.product_nm
													AND bvt.team_member_type = 'BusinessDevelopmentManager'
													AND pol.program_type = bvt.program_type
													AND isnull(bvt.state_cd,pol.risk_state_cd)=pol.risk_state_cd
		INNER join edw_core.tpolicy_history ph on ph.policy_sk = pol.policy_sk and ph.latest_transaction_in = 'Y'
		INNER join edw_core.tpolicy_insured pi on pi.policy_history_sk = ph.policy_history_sk and pi.primary_insured_in = 'Yes'
		left join edw_core.tproducer p on ph.producer_sk = p.producer_sk 
		left join edw_temp.customer_hubspot_feed_temp01 pinf on cust.customer_id = pinf.customer_id and pr.product_cd = pinf.product_cd 
		left join edw_temp.customer_hubspot_feed_temp01 cinf on cust.customer_id = cinf.customer_id and '[Total]' = cinf.product_cd 
		left join edw_core.thome_coverage hc on ph.policy_history_sk = hc.policy_history_sk
		left join edw_core.tdaily_inforce_policy dip on ph.policy_history_sk = dip.policy_history_sk
		WHERE (greatest(pol.create_ts, pol.update_ts) > @last_source_extract_ts
		or exists (select 'x' from edw_temp.customer_hubspot_feed_temp0 a where a.policy_no = pol.policy_no)
		)
		and isnull(pol.insured_nm,'') not like '%test%' 
		and isnull(cust.last_nm,'') not like '%test%'
		and isnull(cust.first_nm,'') not like '%test%' 
		and isnull(cust.customer_nm,'') not like '%test%' 
		and pol.effective_dt >= '01-jun-2023'
		-- and pol.product_cd <> 'BY'
		;

		/*
		DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp2; 
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
		INTO edw_temp.customer_hubspot_feed_temp2
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
		and not exists (select 'x' from edw_temp.customer_hubspot_feed_temp1 a where a.customer_id = cust.customer_id)
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
				,document_delivery_preference
				,occupancy_type
				,effective_dt
				,expiration_dt
				,policy_inforce_in
				FROM edw_temp.customer_hubspot_feed_temp1/*
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
				FROM edw_temp.customer_hubspot_feed_temp2*/
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
			,customer_business_type
			,document_delivery_preference
			,occupancy_type
			,effective_dt
			,expiration_dt
			,policy_inforce_in
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
				,'Personal Lines'
				,source.document_delivery_preference
				,source.occupancy_type
				,source.effective_dt
				,source.expiration_dt
				,source.policy_inforce_in)
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
			,target.document_delivery_preference	=	source.document_delivery_preference
			,target.occupancy_type 			= source.occupancy_type
			,target.effective_dt 			= source.effective_dt
			,target.expiration_dt 			= source.expiration_dt
			,target.policy_inforce_in 		= source.policy_inforce_in
		;

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update control table
		SET @new_last_source_extract_ts = COALESCE((SELECT MAX(greatest(create_ts, update_ts)) FROM edw_temp.customer_hubspot_feed_temp1), @last_source_extract_ts);
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

        -- Drop temp table
        DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp0;
        DROP TABLE IF EXISTS edw_temp.customer_hubspot_feed_temp01;
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