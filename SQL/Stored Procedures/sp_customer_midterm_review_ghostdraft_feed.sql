-- =====================================================================================================================
-- Author:      Architha Gudimalla
-- Description: This procedures loads customer recommendation feed
-----------------------------------------------------------------------------------------------------------------------
-- Change date |Author                      |   Change Description
-----------------------------------------------------------------------------------------------------------------------
-- 09/29/25     Architha Gudimalla          1. Created this procedure  
-- 10/28/25     Architha Gudimalla          2. Changed broker to producer
-- 10/30/25     Architha Gudimalla          3. Updated message for au if length > 96
-- 10/30/25     Architha Gudimalla          4. Updated to use ho producer
-- 12/04/25		Architha Gudimalla			5. Updated yacht boat list
-- 12/19/25		Architha Gudimalla			6. Updated recommendation message list
-- 12/29/25		Architha Gudimalla			7. Fixed Customer message 1 years issue
-- 01/05/26		Architha Gudimalla		    8. Removed monoline_home_in column
-- 01/05/26		Architha Gudimalla		    9. Added primary and non primary monoline_home_in column
-- 01/05/26		Architha Gudimalla		   10. Update recommendation line count to 11 from 10 
-- 01/05/26		Architha Gudimalla		   11. Populated recommendation_message_id_seq_line_ct
-- 01/07/26		Architha Gudimalla		   12. Updated to pick producer from tpolicy table
-- 01/08/26		Architha Gudimalla		   13. Added InitCap for customer_nm, producer_nm, risk address
-- =====================================================================================================================
 
CREATE OR ALTER PROCEDURE [edw_core].[sp_customer_midterm_review_ghostdraft_feed]
@in_start_dt DATE = null
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
               
        -- Get last source extract date
        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
           
        sET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) ; 

		IF(@in_start_dt IS NULL) 
		BEGIN
			SET @in_start_dt = (select actual_dt from edw_core.tdate where date_sk = (select max(inforce_dt_sk) from edw_core.tdaily_inforce_policy))
		END

        drop table if exists edw_temp.customer_midterm_review_ghostdraft_feed_temp1;
		
		WITH Nonho_pols AS 
		(
    
			 select e.customer_id,
					cust.customer_nm,
					e.midterm_review_year,
					r.product_nm,
					r.existing_product_in, 
					STRING_AGG(p.policy_no, '||') policy_no, 
					case when p.no_of_years_with_vault = 0 then '002' else '001' end customer_message_id,
					--customer_message,  
					p.[mailing_address_line1],
					p.[mailing_address_line2],
					p.[mailing_address_unit_no],
					p.[mailing_address_city_nm],
					p.[mailing_address_state_cd],
					p.[mailing_address_zip_cd],
					null producer_id, 			-- broker_id,
					null producer_nm, 			-- broker_nm,
					null producer_phone_no, 	-- broker_phone_no,
					null producer_email, 		-- broker_email, 
					null risk_address_line1,
					null risk_address_line2,
					null risk_address_unit_no,
					null risk_address_city_nm,
					null risk_address_state_cd,
					null risk_address_zip_cd,
					null risk_address,  
					null occupancy_type,
					null occupancy_type_order,
					null total_insured_value_amt, 
					FORMAT(case when r.product_nm = 'Excess Liability' then sum(p.pel_limit_amt) end, 'C0', 'en-US') pel_limit_amt,
					case when r.product_nm = 'Excess Liability' then sum(p.pel_location_ct) end pel_location_ct,
					case when r.product_nm = 'Excess Liability' then sum(p.pel_watercraft_ct) end pel_watercraft_ct,
					case when r.product_nm = 'Excess Liability' then sum(p.pel_vehicle_ct) end pel_vehicle_ct, 
					case when r.product_nm = 'Excess Liability' and r.existing_product_in = 'Yes' then '031' 
						 when r.product_nm = 'Excess Liability' and r.existing_product_in = 'No' then '009' 
					end pel_message_id,
					--pel_message, 
					null wildfire_protection_enrollment_in, 
					null backup_generator_in, 
					FORMAT(case when r.product_nm = 'Collections' then sum(p.total_collection_limit_amt) end, 'C0', 'en-US') total_collection_limit_amt, 
					case when r.product_nm = 'Collections' and r.existing_product_in = 'Yes' then '004' 
						 when r.product_nm = 'Collections' and r.existing_product_in = 'No' then '008' 
					end collection_message_id, 
					--collection_message, 
					case when r.product_nm = 'Lux_on_endorsement' and r.existing_product_in = 'No' then '027' 
					end lux_on_endorsement_message_id,  
					--lux_on_endorsement_message, 
					p.no_of_years_with_vault,
					p.no_of_years_with_vault_tx,  
					case when r.product_nm = 'Auto' then max(p.auto_vehicle_list) end auto_vehicle_list, 
					case when r.product_nm = 'Auto' then max(p.auto_vehicle_ct) end auto_vehicle_ct,   
					case when r.product_nm = 'Auto' and r.existing_product_in = 'Yes' then '003' 
						 when r.product_nm = 'Auto' and r.existing_product_in = 'No' then '010' 
					end auto_message_id,  
					--auto_message,
					--case when r.product_nm = 'Marine Boat & Yacht' then STRING_AGG(p.yatch_product_type, '||') end  yatch_product_type,
					case when r.product_nm = 'Marine Boat & Yacht' then max(p.yacht_boat_list) end  yacht_boat_list,
					case when r.product_nm = 'Marine Boat & Yacht' then max(p.yacht_boat_ct) end  yacht_boat_ct,    
					case when r.product_nm = 'Marine Boat & Yacht' and r.existing_product_in = 'Yes' then '006' 
						 when r.product_nm = 'Marine Boat & Yacht' and r.existing_product_in = 'No' then '011' 
					end yacht_boat_message_id,  
					--yacht_boat_message,
					case when r.product_nm = 'Aviation' and r.existing_product_in = 'Yes' then '007' 
						 when r.product_nm = 'Aviation' and r.existing_product_in = 'No' then '012' 
					end aviation_message_id,
					--aviation_message,
					r.rms_recommendation rms_recommendation_message,
					r.wildfire_protection_recommendation wildfire_protection_recommendation_message,
					r.backup_generator_recommendation backup_generator_recommendation_message,
					null rms_recommendation_message_1_id,
					--rms_recommendation_message_1,
					null rms_recommendation_message_2_id,
					--rms_recommendation_message_2,
					null wildfire_protection_recommendation_message_1_id,
					--wildfire_protection_recommendation_message_1,
					null wildfire_protection_recommendation_message_2_id,
					--wildfire_protection_recommendation_message_2,
					null backup_generator_recommendation_message_1_id,
					--backup_generator_recommendation_message_1,    
					case when r.product_nm = 'Auto' and r.existing_product_in = 'Yes' then '028' 
					end new_driver_recommendation_message_1_id,  
					--new_driver_recommendation_message_1
					null primary_ho_monoline_recommendation_message_1_id,  
					--primary_ho_monoline_recommendation_message_1
					null non_primary_ho_monoline_recommendation_message_1_id,  
					--non_primary_ho_monoline_recommendation_message_1
					null renovation_recommendation_message_1_id  
					--renovation_recommendation_message_1
					--custom_recommendation_message_1_id,
					--custom_recommendation_message_1,
					--custom_recommendation_message_2_id 
					--custom_recommendation_message_2,
					--custom_recommendation_message_3_id,
					--custom_recommendation_message_3,
					--custom_recommendation_message_4_id,
					--custom_recommendation_message_4, 
					,null account_id 
					,null primary_home_monoline_in
					,null non_primary_home_monoline_in
				from edw_integration.customer_midterm_review_eligibility_feed e
				inner join edw_core.tcustomer cust on e.customer_id = cust.customer_id
				inner join edw_integration.customer_midterm_review_recommendation r on e.customer_id = r.customer_id
				left join edw_integration.customer_midterm_review_policy_detail p on r.existing_policy_no = p.policy_no
				where r.product_nm not in ('Condo','Homeowners') 
				and r.update_ts >  @last_source_extract_ts
				and e.midterm_review_process_in ='Yes'
				group by e.customer_id,
					cust.customer_nm,
					e.midterm_review_year,  
					r.product_nm,
					r.existing_product_in,  
					case when p.no_of_years_with_vault = 0 then '002' else '001' end  ,
					--customer_message,   
					p.[mailing_address_line1],
					p.[mailing_address_line2],
					p.[mailing_address_unit_no],
					p.[mailing_address_city_nm],
					p.[mailing_address_state_cd],
					p.[mailing_address_zip_cd],
					p.producer_id, 			-- broker_id,
					p.producer_nm, 			-- broker_nm,
					p.producer_phone_no, 	-- broker_phone_no,
					p.producer_email,   	-- broker_email, 
					p.no_of_years_with_vault,
					p.no_of_years_with_vault_tx,
					r.rms_recommendation,
					r.wildfire_protection_recommendation,
					r.backup_generator_recommendation
		), 
		ho_pols AS (
			select e.customer_id,
					cust.customer_nm,
					e.midterm_review_year,   
					r.product_nm,
					r.existing_product_in, 
					p.policy_no , 
					case when p.no_of_years_with_vault = 0 then '002' else '001' end customer_message_id,
					--customer_message,   
					p.[mailing_address_line1],
					p.[mailing_address_line2],
					p.[mailing_address_unit_no],
					p.[mailing_address_city_nm],
					p.[mailing_address_state_cd],
					p.[mailing_address_zip_cd],
					pd.producer_id, 
					CONCAT(pd.First_nm, ' ', pd.Last_nm) producer_nm, 
					pd.phone_no producer_phone_no, 
					pd.email producer_email, 
					edw_core.fn_Init_Cap(p.risk_address_line1) risk_address_line1,
					edw_core.fn_Init_Cap(p.risk_address_line2) risk_address_line2 ,
					p.risk_address_unit_no,
					edw_core.fn_Init_Cap(p.risk_address_city_nm) risk_address_city_nm, 
					p.risk_address_state_cd,
					p.risk_address_zip_cd,
					replace( 
							CONCAT(
								isnull(       edw_core.fn_Init_Cap(p.risk_address_line1), ''), 
								isnull(' '  + edw_core.fn_Init_Cap(p.risk_address_line2), ''), 
								isnull(' '  + p.risk_address_unit_no, ''),
								isnull(', ' + edw_core.fn_Init_Cap(p.risk_address_city_nm), ''), 
								isnull(', ' + p.risk_address_state_cd, ''), 
								isnull(' '  + p.risk_address_zip_cd, '')
							 ),'  ',''
					) AS risk_address,  
					p.occupancy_type,
					case p.occupancy_type
						when 'Primary' then '1_Primary'
						else '2_Non_Primary' 
					end occupancy_type_order,
					p.total_insured_value_amt, 
					null pel_limit_amt,
					null pel_location_ct,
					null pel_watercraft_ct,
					null pel_vehicle_ct, 
					null pel_message_id,
					--pel_message, 
					p.wildfire_protection_enrollment_in, 
					p.backup_generator_in, 
					FORMAT(p.total_collection_limit_amt, 'C', 'en-US') total_collection_limit_amt,
					null collection_message_id, 
					--collection_message, 
					null lux_on_endorsement_message_id,
					--lux_on_endorsement_message, 
					p.no_of_years_with_vault,
					p.no_of_years_with_vault_tx,  
					null auto_vehicle_list, 
					null auto_vehicle_ct,   
					null auto_message_id,  
					--auto_message,
					--p.yatch_product_type,
					null yacht_boat_list,
					null yacht_boat_ct,   
					null yacht_boat_message_id,   
					--yacht_boat_message,
					null aviation_message_id,
					--aviation_message,
					r.rms_recommendation rms_recommendation_message,
					r.wildfire_protection_recommendation wildfire_protection_recommendation_message,
					r.backup_generator_recommendation backup_generator_recommendation_message,
					IIF(r.rms_recommendation is not null, '013', null) rms_recommendation_message_1_id,
					--rms_recommendation_message_1,
					--IIF(r.rms_recommendation is not null, '014', null) 
					null rms_recommendation_message_2_id,
					--rms_recommendation_message_2,
					IIF(r.wildfire_protection_recommendation is not null, '017', null) wildfire_protection_recommendation_message_1_id,
					--wildfire_protection_recommendation_message_1,
					--IIF(r.wildfire_protection_recommendation is not null, '018', null) 
					null wildfire_protection_recommendation_message_2_id,
					--wildfire_protection_recommendation_message_2,
					IIF(r.backup_generator_recommendation is not null, '017', null) backup_generator_recommendation_message_1_id,
					--backup_generator_recommendation_message_1, 
					null new_driver_recommendation_message_1_id,  
					--new_driver_recommendation_message_1
					case when p.primary_home_monoline_in = 'Yes' then '025' end primary_ho_monoline_recommendation_message_1_id,  
					--primary_ho_monoline_recommendation_message_1
					case when p.non_primary_home_monoline_in = 'Yes' then '026' end non_primary_ho_monoline_recommendation_message_1_id,  
					--non_primary_ho_monoline_recommendation_message_1
					case when r.product_nm in ('Condo','Homeowners') then '029' end renovation_recommendation_message_1_id  
					--renovation_recommendation_message_1 
					,acc.id account_id
					, p.primary_home_monoline_in, p.non_primary_home_monoline_in
				from edw_integration.customer_midterm_review_eligibility_feed e
				inner join edw_core.tcustomer cust on e.customer_id = cust.customer_id
				inner join edw_integration.customer_midterm_review_recommendation r on e.customer_id = r.customer_id
				left join edw_integration.customer_midterm_review_policy_detail p on r.existing_policy_no = p.policy_no
				left join edw_stage.account acc on acc.policynumber = p.policy_no
				left join edw_core.tpolicy pol on acc.policynumber = pol.policy_no
				LEFT JOIN edw_core.tproducer pd on pd.producer_sk = pol.current_producer_sk 
				where r.product_nm in ('Condo','Homeowners')
				and r.update_ts >  @last_source_extract_ts
				and e.midterm_review_process_in ='Yes'
		)
		select *
		into edw_temp.customer_midterm_review_ghostdraft_feed_temp1
		from
		(
			SELECT * FROM ho_pols
			UNION ALL
			SELECT * FROM Nonho_pols
		) a
		order by 1,7,6; 
   
        --truncate table edw_integration.customer_midterm_review_ghostdraft_feed;
   
        insert into edw_integration.customer_midterm_review_ghostdraft_feed
		(
			customer_id,
			customer_nm,
			midterm_review_year,  
			producer_id, 			
			producer_nm, 			
			producer_phone_no, 	
			producer_email,		
			account_id,
			product_nm,
			existing_product_in, 
			policy_no,
			customer_message_id,
			--customer_message, 
			[mailing_address_line1],
			[mailing_address_line2],
			[mailing_address_unit_no],
			[mailing_address_city_nm],
			[mailing_address_state_cd],
			[mailing_address_zip_cd], 
			risk_address_line1,
			risk_address_line2,
			risk_address_unit_no,
			risk_address_city_nm,
			risk_address_state_cd,
			risk_address_zip_cd,
			risk_address,   
			occupancy_type, 
			pel_limit_amt,
			pel_location_ct,
			pel_watercraft_ct,
			pel_vehicle_ct,
			pel_message_id,
			--pel_message, 
			wildfire_protection_enrollment_in, 
			backup_generator_in,
			total_collection_limit_amt,
			collection_message_id,
			--collection_message, 
			lux_on_endorsement_message_id,
			--lux_on_endorsement_message, 
			no_of_years_with_vault,
			no_of_years_with_vault_tx,
			auto_vehicle_list, 
			auto_vehicle_ct,
			auto_message_id,
			--auto_message, 
			--yatch_product_type,
			yacht_boat_list, 
			yacht_boat_ct,
			yacht_boat_message_id,
			--yacht_boat_message,
			aviation_message_id,
			--aviation_message,
			rms_recommendation,
			wildfire_protection_recommendation,
			backup_generator_recommendation,
			rms_recommendation_message_1_id,
			---rms_recommendation_message_1,
			rms_recommendation_message_2_id,
			--rms_recommendation_message_2,
			wildfire_protection_recommendation_message_1_id,
			--wildfire_protection_recommendation_message_1,
			wildfire_protection_recommendation_message_2_id,
			--wildfire_protection_recommendation_message_2,
			backup_generator_recommendation_message_1_id,
			--backup_generator_recommendation_message_1, 
			new_driver_recommendation_message_1_id,  
			--new_driver_recommendation_message_1
			primary_ho_monoline_recommendation_message_1_id,
			--primary_ho_monoline_recommendation_message_1,
			non_primary_ho_monoline_recommendation_message_1_id,
			--non_primary_ho_monoline_recommendation_message_1,
			renovation_recommendation_message_1_id,
			--renovation_recommendation_message_1
			--custom_recommendation_message_1_id,
			--custom_recommendation_message_1,
			--custom_recommendation_message_2_id,
			--custom_recommendation_message_2,
			--custom_recommendation_message_3_id,
			--custom_recommendation_message_3,
			--custom_recommendation_message_4_id,
			--custom_recommendation_message_4, 
			etl_audit_sk,
			create_ts,
			update_ts
			,primary_home_monoline_in
			,non_primary_home_monoline_in
		)
		select a.customer_id,
				a.customer_nm,
				midterm_review_year,   
				producer_ho.producer_id, 			
				producer_ho.producer_nm, 			
				producer_ho.producer_phone_no, 
				producer_ho.producer_email,		 
                producer_ho.account_id,
				product_nm,
				existing_product_in, 
				policy_no, 
				customer_message_id,
				[mailing_address_line1],
				[mailing_address_line2],
				[mailing_address_unit_no],
				[mailing_address_city_nm],
				[mailing_address_state_cd],
				[mailing_address_zip_cd],
				risk_address_line1,
				risk_address_line2,
				risk_address_unit_no,
				risk_address_city_nm,
				risk_address_state_cd,
				risk_address_zip_cd,
				risk_address,  
				a.occupancy_type, 
				pel_limit_amt,
				pel_location_ct,
				pel_watercraft_ct,
				pel_vehicle_ct, 
				pel_message_id,
				--pel_message, 
				wildfire_protection_enrollment_in, 
				backup_generator_in, 
				total_collection_limit_amt,
				collection_message_id, 
				--collection_message, 
				lux_on_endorsement_message_id,
				--lux_on_endorsement_message, 
				no_of_years_with_vault,
				no_of_years_with_vault_tx,  
				auto_vehicle_list, 
				auto_vehicle_ct,   
				auto_message_id,  
				--auto_message,
				--yatch_product_type,
				yacht_boat_list,
				yacht_boat_ct,   
				yacht_boat_message_id,   
				--yacht_boat_message,
				aviation_message_id,
				--aviation_message,
				rms_recommendation_message,
				wildfire_protection_recommendation_message,
				backup_generator_recommendation_message,
				rms_recommendation_message_1_id,
				--rms_recommendation_message_1,
				rms_recommendation_message_2_id,
				--rms_recommendation_message_2,
				wildfire_protection_recommendation_message_1_id,
				--wildfire_protection_recommendation_message_1,
				wildfire_protection_recommendation_message_2_id,
				--wildfire_protection_recommendation_message_2,
				backup_generator_recommendation_message_1_id,
				--backup_generator_recommendation_message_1, 
				new_driver_recommendation_message_1_id,  
				--new_driver_recommendation_message_1
				primary_ho_monoline_recommendation_message_1_id,
				--primary_ho_monoline_recommendation_message_1,
				non_primary_ho_monoline_recommendation_message_1_id,
				--non_primary_ho_monoline_recommendation_message_1,
				renovation_recommendation_message_1_id,
				--renovation_recommendation_message_1
				--custom_recommendation_message_1_id,
				--custom_recommendation_message_1,
				--custom_recommendation_message_2_id ,
				@etl_audit_sk etl_audit_sk,
                getdate() create_ts,
                getdate() update_ts 
				,primary_home_monoline_in
				,non_primary_home_monoline_in
		from edw_temp.customer_midterm_review_ghostdraft_feed_temp1 a
		left join ( 
					select  customer_id, account_id, producer_id, producer_nm, producer_phone_no, producer_email,
							occupancy_type, occupancy_type_order, total_insured_value_amt, 
							row_number() over (partition by customer_id order by occupancy_type_order, total_insured_value_amt desc) rn 
					from edw_temp.customer_midterm_review_ghostdraft_feed_temp1 
					where product_nm in ('Condo','Homeowners') 
					and existing_product_in = 'Yes' 
				   ) producer_ho on a.customer_id = producer_ho.customer_id and producer_ho.rn = 1  
		;  

		--update generator id
		WITH genid AS (
			SELECT 
				customer_id, 
				CASE
					WHEN COUNT(DISTINCT policy_no) > 1 AND SUM(CASE WHEN backup_generator_in = 'No' THEN 1 ELSE 0 END) > 0 THEN '019'
					WHEN SUM(CASE WHEN non_primary_home_monoline_in = 'Yes' and occupancy_type in ('Seasonal','Seasonal/Secondary','Seasonal (with no Vault Primary Residence)') THEN 1 ELSE 0 END) > 0 
						AND SUM(CASE WHEN backup_generator_in = 'No' THEN 0 ELSE 1 END) = 0  THEN '030'
					WHEN SUM(CASE WHEN backup_generator_in = 'No' THEN 1 ELSE 0 END) > 0 THEN '032'
					ELSE NULL
				END AS code 
			FROM edw_integration.customer_midterm_review_ghostdraft_feed 
			where product_nm in ('Homeowners','Condo')  and existing_product_in = 'Yes'
			GROUP BY customer_id
		) 
		UPDATE gd
		SET backup_generator_recommendation_message_1_id = cc.code
		FROM edw_integration.customer_midterm_review_ghostdraft_feed  gd
		JOIN genid cc ON gd.customer_id = cc.customer_id
		where product_nm in ('Homeowners','Condo')
		and gd.update_ts >  @last_source_extract_ts;
		 
        --- Update customer message
        update a
        set customer_message = replace(case when m.message_id = '002' then m.message_desc
									else replace(m.message_desc, '<<<X>>>', a.no_of_years_with_vault )
								end,'Thank you for allowing us to serve you for 1 years.','Thank you for allowing us to serve you for 1 year.')
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.customer_message_id = m.message_id
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update coll message 
        update a
        set collection_message =  case when m.message_id = '008' then m.message_desc
										else replace(m.message_desc, 
										'<<<Total Coverage Amount>>>', a.total_collection_limit_amt )
									end  
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.collection_message_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update pel message 
        update a
        set pel_message =  case when m.message_id = '009' then m.message_desc
										else --replace(replace(replace(replace( replace(replace(
															replace(m.message_desc, 
																'<<< Total Coverage Amount >>>', a.pel_limit_amt )
																--, 
																--'<<<Z>>>', isnull(a.pel_watercraft_ct,0) ), 
																--'<<<Y>>>', isnull(a.pel_vehicle_ct,0) ), 
																--'<<<X>>>', isnull(a.pel_location_ct,0) ), 
																--'0 properties, ', ''), 
																--'0 vehicles, ', ''), 
																--', and 0 watercraft', '') 
									end 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.pel_message_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update au message 
        update a
        set auto_message =  case when m.message_id = '010' then m.message_desc
										else auto_vehicle_list --concat(auto_vehicle_list, ' and ', auto_vehicle_ct, ' covered vehicles' )
									end 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.auto_message_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update yacht message 
        update a
        set yacht_boat_message =  case when m.message_id = '011' then m.message_desc
										else a.yacht_boat_list
									end
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.yacht_boat_message_id = m.message_id  
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update aviation message 
        update a
        set aviation_message =  m.message_desc 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.aviation_message_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update lux_on_endorsement message 
        update a
        set lux_on_endorsement_message =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.lux_on_endorsement_message_id = m.message_id
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update water shut off reco message 
        update a
        set rms_recommendation_message_1 =  replace(m.message_desc, 
													'<<CITY NAME >> ', aa.risk_address_city_nm 
													) 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.rms_recommendation_message_1_id = m.message_id 
		inner join (select customer_id, string_agg(risk_address_city_nm,',') risk_address_city_nm
					from (select distinct customer_id, risk_address_city_nm 
						  from edw_integration.customer_midterm_review_ghostdraft_feed
						  where rms_recommendation_message_1_id is not null
						 ) a  
					group by customer_id
					) aa on a.customer_id = aa.customer_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update water shut off QR message 
        update a
        set rms_recommendation_message_2 =  m.message_desc 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.rms_recommendation_message_2_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update wildfire/redzone reco message 
        update a
        set wildfire_protection_recommendation_message_1 =  replace(m.message_desc, 
																	'<<CITY NAME>>', aa.risk_address_city_nm 
																	) 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.wildfire_protection_recommendation_message_1_id = m.message_id  
		inner join (select customer_id, string_agg(risk_address_city_nm,',') risk_address_city_nm
					from (select distinct customer_id, risk_address_city_nm 
						  from edw_integration.customer_midterm_review_ghostdraft_feed
						  where wildfire_protection_recommendation_message_1_id is not null
						 ) a 
					group by customer_id
					) aa on a.customer_id = aa.customer_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update wildfire qr message 
        update a
        set wildfire_protection_recommendation_message_2 =  m.message_desc 
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.wildfire_protection_recommendation_message_2_id = m.message_id
		where a.update_ts >  @last_source_extract_ts 
		 
        --- Update backup generator message 
        update a
        set backup_generator_recommendation_message_1 =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.backup_generator_recommendation_message_1_id = m.message_id  
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update au new driver message 
        update a
        set new_driver_recommendation_message_1 =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.new_driver_recommendation_message_1_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts
		 
        --- Update primary_ho monoline message 
        update a
        set primary_ho_monoline_recommendation_message_1 =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.primary_ho_monoline_recommendation_message_1_id = m.message_id 
		where a.update_ts >  @last_source_extract_ts 
		 
        --- Update non primary_ho monoline message 
        update a
        set non_primary_ho_monoline_recommendation_message_1 =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.non_primary_ho_monoline_recommendation_message_1_id = m.message_id  
		where a.update_ts >  @last_source_extract_ts  
		 
        --- Update renovation message 
        update a
        set renovation_recommendation_message_1 =  m.message_desc
		from edw_integration.customer_midterm_review_ghostdraft_feed a
		inner join edw_stage.customer_midterm_review_message m on a.renovation_recommendation_message_1_id = m.message_id   
		where a.update_ts >  @last_source_extract_ts
		 
		drop table if exists edw_temp.customer_midterm_review_ghostdraft_feed_temp2;
		
		with CustomerList as
		(
			--******** if in future we run eligibility for monoline Auto, make sure to update the producer logic when loading ghostdraft table
			select distinct
					a.customer_id,
					cust.insured_type,
					cust.customer_nm,
					cust.email customer_email, 
					cust.home_phone_no customer_phone_no,
					a.customer_message,
					a.mailing_address_line1,
					a.mailing_address_line2,
					a.mailing_address_unit_no,
					a.mailing_address_city_nm,
					a.mailing_address_state_cd,
					a.mailing_address_zip_cd,
					a.producer_id,
					a.producer_nm,
					a.producer_phone_no producer_phone,
					a.producer_email
			from edw_integration.customer_midterm_review_ghostdraft_feed a
			inner join edw_core.tcustomer cust on cust.customer_id = a.customer_id
			where a.existing_product_in  = 'Yes'
			and a.update_ts >  @last_source_extract_ts 
			/*
			 
					a.customer_id,
					case when cust.insured_type <>  'Entity' then edw_core.fn_Init_Cap(cust.customer_nm) else cust.customer_nm end customer_nm , 
					lower(cust.email) customer_email, 
					cust.home_phone_no customer_phone_no,
					a.customer_message,
					edw_core.fn_Init_Cap(a.mailing_address_line1) mailing_address_line1,
					edw_core.fn_Init_Cap(a.mailing_address_line2) mailing_address_line2,
					a.mailing_address_unit_no,
					edw_core.fn_Init_Cap(a.mailing_address_city_nm) mailing_address_city_nm,
					a.mailing_address_state_cd,
					a.mailing_address_zip_cd,
					a.producer_id,
					edw_core.fn_Init_Cap(a.producer_nm) producer_nm,
					a.producer_phone_no producer_phone,
					lower(a.producer_email) producer_email 
			*/
		),
		reco_message as
		(
					select distinct mrm.customer_id, mrm.rms_recommendation_message_1_id recommendation_message_1_id,mrm.rms_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm, edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id and 
					mrm.rms_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.rms_recommendation_message_2_id,mrm.rms_recommendation_message_2 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm, edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.rms_recommendation_message_2_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.wildfire_protection_recommendation_message_1_id, mrm.wildfire_protection_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm, edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.wildfire_protection_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.wildfire_protection_recommendation_message_2_id,mrm.wildfire_protection_recommendation_message_2 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm, edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.wildfire_protection_recommendation_message_2_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.backup_generator_recommendation_message_1_id,mrm.backup_generator_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm, edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id  and 
					mrm.backup_generator_recommendation_message_1_id = m.message_id 
					union
					select distinct mrm.customer_id, mrm.new_driver_recommendation_message_1_id,mrm.new_driver_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm , edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.new_driver_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.primary_ho_monoline_recommendation_message_1_id,mrm.primary_ho_monoline_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm , edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.primary_ho_monoline_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.non_primary_ho_monoline_recommendation_message_1_id,mrm.non_primary_ho_monoline_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm , edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.non_primary_ho_monoline_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.renovation_recommendation_message_1_id,mrm.renovation_recommendation_message_1 as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm , edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id   and 
					mrm.renovation_recommendation_message_1_id = m.message_id
					union
					select distinct mrm.customer_id, mrm.lux_on_endorsement_message_id,mrm.lux_on_endorsement_message as [message], m.sequence_id, m.line_ct
					from  edw_integration.customer_midterm_review_ghostdraft_feed mrm , edw_stage.customer_midterm_review_message m, CustomerList
					where CustomerList.customer_id= mrm.customer_id  and 
					mrm.lux_on_endorsement_message_id = m.message_id
		),
		reco_message_order as
		(
			select *,  SUM(line_ct) OVER (
						   PARTITION BY customer_id
						   ORDER BY sequence_id
						   ROWS UNBOUNDED PRECEDING
					   ) AS running_line_ct
			from reco_message
		),
		reco_message_order_final as
		(
			select * 
			from reco_message_order
			where running_line_ct <= 11
		)
		select  
			cmr.customer_id,
			(
			SELECT
			case when cmr.insured_type <>  'Entity' then edw_core.fn_Init_Cap(cmr.customer_nm) else cmr.customer_nm end as insured_full_name,
			cmr.customer_message as insured_message,
			edw_core.fn_Init_Cap(cmr.producer_nm) producer_name, 
			cmr.producer_phone,
			lower(cmr.producer_email) producer_email,
			edw_core.fn_Init_Cap(cmr.mailing_address_line1) mailing_address_line1,
			edw_core.fn_Init_Cap(cmr.mailing_address_line2) mailing_address_line2,
			cmr.mailing_address_unit_no,
			edw_core.fn_Init_Cap(cmr.mailing_address_city_nm) mailing_address_city_nm,
			cmr.mailing_address_state_cd,
			cmr.mailing_address_zip_cd,  
			(
			select TOP 1 'Yes'
			from edw_integration.customer_midterm_review_ghostdraft_feed cmrh
						inner join edw_integration.customer_midterm_review_policy_detail cmrp on cmrh.policy_no = cmrp.policy_no
						WHERE cmrh.customer_id = cmr.customer_id
							and cmrh. product_nm in ('Condo','Homeowners')
							and cmrh.existing_product_in = 'Yes'
			) as [current_coverage.existing_home],
			(
			select TOP 1 CASE WHEN ROW_NUMBER() OVER (ORDER BY
														CASE cmrp.occupancy_type WHEN 'Primary' THEN '1_Primary' ELSE '2_Non_Primary' END,
														cmrp.total_insured_value_amt DESC) = 1
								THEN cmrh.account_id
								ELSE NULL
						END [account_primary_image]   
			from edw_integration.customer_midterm_review_ghostdraft_feed cmrh
						inner join edw_integration.customer_midterm_review_policy_detail cmrp on cmrh.policy_no = cmrp.policy_no
						WHERE cmrh.customer_id = cmr.customer_id
							and cmrh. product_nm in ('Condo','Homeowners')
							and cmrh.existing_product_in = 'Yes'
			) as [current_coverage.account_primary_image],
				JSON_QUERY(            
					(	
						select        
						cmrh.risk_address_line1 as [risk_address_line1],
						cmrh.risk_address_line2 as [risk_address_line2],
						cmrh.risk_address_unit_no as [risk_address_unit_no],
						cmrh.risk_address_city_nm as [risk_address_city_nm],
						cmrh.risk_address_state_cd as [risk_address_state_cd],
						cmrh.risk_address_zip_cd as [risk_address_zip_cd],
						cmrh.risk_address as [risk_address]
						from edw_integration.customer_midterm_review_ghostdraft_feed cmrh
						inner join edw_integration.customer_midterm_review_policy_detail cmrp on cmrh.policy_no = cmrp.policy_no
						WHERE cmrh.customer_id = cmr.customer_id
							and cmrh. product_nm in ('Condo','Homeowners')
							and cmrh.existing_product_in = 'Yes'
							and cmrh.update_ts > @last_source_extract_ts
						order by case cmrp.occupancy_type
									when 'Primary' then '1_Primary'
									else '2_Non_Primary' 
								end, cmrp.total_insured_value_amt desc
					--) as a
					for json path, include_null_values
				)) as [current_coverage.home]
				,
					(
					select top 1
						'Yes' 
						from edw_integration.customer_midterm_review_ghostdraft_feed cmra 
						where cmra.customer_id = cmr.customer_id
						and cmra. product_nm = 'Auto'
						and cmra.existing_product_in = 'Yes'
						and cmra.update_ts > @last_source_extract_ts
					) as [current_coverage.existing_auto],
					(
					select top 1
						auto_message
						from edw_integration.customer_midterm_review_ghostdraft_feed cmra 
						where cmra.customer_id = cmr.customer_id
						and cmra. product_nm = 'Auto'
						and cmra.update_ts > @last_source_extract_ts
					--and cmra.existing_product_in = 'Yes'
					) as [current_coverage.message_auto],
					(
					select top 1
						'Yes' 
						from edw_integration.customer_midterm_review_ghostdraft_feed cmre
						where cmre.customer_id = cmr.customer_id
						and cmre. product_nm = 'Excess Liability'
						and cmre.existing_product_in = 'Yes'
						and cmre.update_ts > @last_source_extract_ts
					) as [current_coverage.existing_excess],
						(
						select top 1
							pel_message
							from edw_integration.customer_midterm_review_ghostdraft_feed cmre 
							where cmre.customer_id = cmr.customer_id
							and cmre. product_nm = 'Excess Liability'
							and cmre.update_ts > @last_source_extract_ts
						--and cmre.existing_product_in = 'Yes'
					) as [current_coverage.message_excess],
					(
						select top 1
							'Yes' 
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Collections'
							and cmrc.existing_product_in = 'Yes'
							and cmrc.update_ts > @last_source_extract_ts
					) as [current_coverage.existing_collection],
						(
						select top 1
							collection_message
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc 
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Collections'
							and cmrc.update_ts > @last_source_extract_ts
						--and cmrc.existing_product_in = 'Yes'
					) as [current_coverage.message_collection],
					(
						select top 1
							'Yes' 
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Marine Boat & Yacht'
							and cmrc.existing_product_in = 'Yes'
							and cmrc.update_ts > @last_source_extract_ts
					) as [current_coverage.existing_marine],
						(
						select top 1
							yacht_boat_message
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc 
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Marine Boat & Yacht'
							and cmrc.update_ts > @last_source_extract_ts
						--and cmrc.existing_product_in = 'Yes'
					) as [current_coverage.message_marine] ,
					(
						select top 1
							'Yes' 
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Aviation'
							and cmrc.existing_product_in = 'Yes'
							and cmrc.update_ts > @last_source_extract_ts
					) as [current_coverage.existing_aviation],
						(
						select top 1
							aviation_message
							from edw_integration.customer_midterm_review_ghostdraft_feed cmrc 
							where cmrc.customer_id = cmr.customer_id
							and cmrc. product_nm = 'Aviation'
							and cmrc.update_ts > @last_source_extract_ts
						--and cmrc.existing_product_in = 'Yes'
					) as [current_coverage.message_aviation] 
			
			,json_query
			( (
				select  recommendation_message_1_id, [message] from
				(  
					select recommendation_message_1_id, [message], sequence_id
					from reco_message_order_final mrm
					where mrm.customer_id= cmr.customer_id   			
			) as a
			order by sequence_id
			for json path, include_null_values
			))  as custom_recommendations
			for json path, include_null_values , without_array_wrapper
			) as  customer_json ,
			( 
				select  STRING_AGG(concat(recommendation_message_1_id, '|',sequence_id, '|',line_ct), '; ') aa   
					from reco_message_order_final mrm
					where mrm.customer_id= cmr.customer_id  
			) as  recommendation_message_id_seq_line_ct 
		into edw_temp.customer_midterm_review_ghostdraft_feed_temp2
		from CustomerList as cmr; 

		update [target]
		set
			[target].[data] 									= [source].[customer_json],
			[target].[recommendation_message_id_seq_line_ct] 	= [source].[recommendation_message_id_seq_line_ct],
			[target].midterm_review_process_in 					= 'No',
			[target].midterm_review_completed_dt 				= cast(getdate() as date),
			[target].update_ts 									= getdate()
		from edw_integration.customer_midterm_review_eligibility_feed [target]
		inner join edw_temp.customer_midterm_review_ghostdraft_feed_temp2 [source] on [target].customer_id = [source].customer_id
		where [target].midterm_review_process_in = 'Yes';
		               
        SET @rows_affected=@@ROWCOUNT;
 
        set @new_last_source_extract_ts = getdate();
       
        --Update control table
        SET @new_last_source_extract_ts = COALESCE(@new_last_source_extract_ts,@last_source_extract_ts);
 
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
       
        -- Update audit table
        SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts > ' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
        if @in_start_dt is not null
        begin
            set @parameter_desc= 'last_source_extract_ts = ' + CAST(@in_start_dt AS VARCHAR(200))
        end
        EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;  
		
        drop table if exists edw_temp.customer_midterm_review_ghostdraft_feed_temp1;
		drop table if exists edw_temp.customer_midterm_review_ghostdraft_feed_temp2; 
 
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