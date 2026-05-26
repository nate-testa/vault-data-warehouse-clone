-- ================================================================================================================================
-- Author:      Architha Gudimalla
-- Description: This procedures loads customer recommendation feed
-----------------------------------------------------------------------------------------------------------------------------------
-- Change date |Author                      |   Change Description
-----------------------------------------------------------------------------------------------------------------------------------
-- 06/16/25     Architha Gudimalla          1. Created this procedure  
-- 09/11/25     Sandeep Gundreddy           2. Added renewal_quote_review_start_dt filter
-- 09/22/25		Yunus Mohammed				3. Added wildfire protection and backup generator customer recommendation feed
-- 10/22/25		Architha Gudimalla			4. Removed code for primary_home_discount_pc
-- 10/28/25		Architha Gudimalla			5. Added producer to policy detail table
-- 11/05/25		Architha Gudimalla			6. Removed tbroker_vault_team join
-- 11/19/25		Architha Gudimalla			7. Updated auto vehicle list
-- 12/04/25		Architha Gudimalla			8. Updated yacht boat list
-- 12/29/25		Architha Gudimalla			9. Fixed lux on eds join
-- 01/05/26		Architha Gudimalla		   10. Updated merge logic for customer_midterm_review_eligibility_feed
-- 01/05/26		Architha Gudimalla		   11. Updated logic for primary and non primary home monoline
-- 01/05/26		Architha Gudimalla		   12. Removed updating buy auto and others since we now use messages table
-- 05/14/26		Architha Gudimalla		   13. Update customer state to use risk state
-- ================================================================================================================================
 
CREATE OR ALTER PROCEDURE [edw_core].[sp_customer_midterm_review_recommendation]
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
        DECLARE @max_renewal_quote_review_start_dt DATE
        DECLARE @rows_affected INT
        DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
        DECLARE @current_date DATETIME=GETDATE()  
        DECLARE @parameter_desc VARCHAR(255)
 
        -- Get last source extract date
        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
 
        EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;  
               
        -- Get last source extract date
        SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
           
        sET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200)) 

		IF(@in_start_dt IS NULL) 
		BEGIN
			SET @in_start_dt = (select actual_dt from edw_core.tdate where date_sk = (select max(inforce_dt_sk) from edw_core.tdaily_inforce_policy))
		END
 
        --reviwed customer
        drop table if exists edw_temp.customer_midterm_review_recommendation_temp_1_cust;
 
/*
-- Renewal Quotes generated in last 10 days in Metal 
Select distinct b.ReferenceCode from
account a, insured b
where renewalviewshow=1 and IsForecast=0 AND Stage='Submission' and cast(RenewalReviewStartDate as date) between getdate()-12 and getdate()
and a.PrimaryInsuredId=b.id
*/ 

		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_0_inforce

		select inf.*
		into edw_temp.customer_midterm_review_recommendation_temp_0_inforce
		from edw_core.tdaily_inforce_policy inf
        inner join edw_core.tdate td on inf.inforce_dt_sk = td.date_sk and actual_dt = @in_start_dt

		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_0_cust_monoline

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
		into  edw_temp.customer_midterm_review_recommendation_temp_0_cust_monoline
		FROM edw_temp.customer_midterm_review_recommendation_temp_0_inforce summ, edw_core.tproduct pr , edw_core.tcustomer cust 
		where  pr.product_sk = summ.product_sk 
		and summ.customer_sk = cust.customer_sk 
		GROUP BY ROLLUP (customer_id, pr.product_cd);	

		drop table if exists edw_temp.zip_codes

		select *
		into edw_temp.zip_codes
		from
		(
            select '90024' as zip_code union select '90027' as zip_code union select '90046' as zip_code union select '90049' as zip_code union select '90068' as zip_code union select '90069' as zip_code union select '90077' as zip_code union select '90095' as zip_code union select '90210' as zip_code union select '90263' as zip_code union select '90265' as zip_code union select '90272' as zip_code union select '90274' as zip_code union select '90275' as zip_code union
            select '90290' as zip_code union select '90631' as zip_code union select '91006' as zip_code union select '91008' as zip_code union select '91010' as zip_code union select '91011' as zip_code union select '91016' as zip_code union select '91024' as zip_code union select '91103' as zip_code union select '91105' as zip_code union select '91107' as zip_code union select '91108' as zip_code union select '91206' as zip_code union select '91207' as zip_code union
            select '91208' as zip_code union select '91301' as zip_code union select '91302' as zip_code union select '91307' as zip_code union select '91311' as zip_code union select '91316' as zip_code union select '91320' as zip_code union select '91326' as zip_code union select '91344' as zip_code union select '91356' as zip_code union select '91360' as zip_code union select '91361' as zip_code union select '91362' as zip_code union select '91364' as zip_code union
            select '91377' as zip_code union select '91403' as zip_code union select '91423' as zip_code union select '91436' as zip_code union select '91604' as zip_code union select '91709' as zip_code union select '91741' as zip_code union select '91765' as zip_code union select '92602' as zip_code union select '92603' as zip_code union select '92610' as zip_code union select '92612' as zip_code union select '92625' as zip_code union select '92629' as zip_code union
            select '92637' as zip_code union select '92651' as zip_code union select '92653' as zip_code union select '92656' as zip_code union select '92657' as zip_code union select '92660' as zip_code union select '92676' as zip_code union select '92677' as zip_code union select '92679' as zip_code union select '92688' as zip_code union select '92691' as zip_code union select '92692' as zip_code union select '92694' as zip_code union select '92705' as zip_code union
            select '92782' as zip_code union select '92807' as zip_code union select '92808' as zip_code union select '92821' as zip_code union select '92823' as zip_code union select '92869' as zip_code union select '92886' as zip_code union select '92887' as zip_code union select '93001' as zip_code union select '93003' as zip_code union select '93010' as zip_code union select '93012' as zip_code union select '93013' as zip_code union select '93021' as zip_code union
            select '93023' as zip_code union select '93060' as zip_code union select '93063' as zip_code union select '93065' as zip_code union select '93066' as zip_code union select '93067' as zip_code union select '93103' as zip_code union select '93105' as zip_code union select '93108' as zip_code union select '93110' as zip_code union select '93111' as zip_code union select '93117' as zip_code union select '93441' as zip_code union select '93460' as zip_code union select '93463'  as zip_code
		) as a;
		 
		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_1_cust ; /*

        set @max_renewal_quote_review_start_dt = (select max(renewal_quote_review_start_dt) renewal_quote_review_start_dt
                                                from edw_core.tquote
                                                where renewal_quote_review_start_dt > --'01-jan-1999' 
                                                                                    @last_source_extract_ts --Added renewal_quote_review_start_dt filter added by Sandeep Gundreddy on 09/11/25 to filter only recent renewal quotes
                                                and quote_status not in ('Issued', 'Declined by Vault', 'Expired', 'No Response by Broker/Producer', 'Not Needed', 'Not Taken by Insured')
                                                and quote_term = 'Renewal');*/
		
        If @last_source_extract_ts = '1900-01-01'  
        set @last_source_extract_ts = (select Dateadd(dd,-1,cast(getdate() as date))); 

		drop table if exists edw_temp.customer_midterm_review_ghostdraft_feed_temp3;
		
		select  distinct customer_id , quote_no, prior_term_policy_no
		into edw_temp.customer_midterm_review_ghostdraft_feed_temp3
            from    edw_core.tquote
			where   renewal_quote_review_start_dt > @last_source_extract_ts --Added renewal_quote_review_start_dt filter added by Sandeep Gundreddy on 09/11/25 to filter only recent renewal quotes
			and     renewal_quote_review_start_dt < cast(getdate() as date) 
			and     quote_status not in ('Issued', 'Declined by Vault', 'Expired', 'No Response by Broker/Producer', 'Not Needed', 'Not Taken by Insured')
			and     quote_term = 'Renewal' ;
       
        with cust as
		(
			select  distinct customer_id 
            from    edw_core.tquote
			where   renewal_quote_review_start_dt > @last_source_extract_ts --Added renewal_quote_review_start_dt filter added by Sandeep Gundreddy on 09/11/25 to filter only recent renewal quotes
			and     renewal_quote_review_start_dt < cast(getdate() as date) 
			and     quote_status not in ('Issued', 'Declined by Vault', 'Expired', 'No Response by Broker/Producer', 'Not Needed', 'Not Taken by Insured')
			and     quote_term = 'Renewal' 
            --and customer_id in ('1234569569', '1234571848', '1234514366', '1234573126', '1234566318', '1234676241', '1234673481', '1234575934', '1234670470', '1234674950', '1234572264', '1234676903', '1234570281', '1234625857', '1234683585', '1234675204', '1234648425', '1234676100', '1234672936', '1234515240', '1234577613', '1234575493', '1234578223', '1234676766', '1234522350', '1234651118', '1234577833', '1234569256', '1234515688', '1234547539', '1234574605', '1234535898', '1234521500', '1234584007', '1234584585', '1234520385', '1234511734') 
		),
		cust_review as
        (
            select  p.customer_id, p.effective_dt,  p.product_cd,  
                    case when p.product_cd not in ('HO','CO') then null
                         when hc.occupancy_type = 'Primary' then '9_Primary'
                         else '8_non-Primary'  
                    end occupancy_type
			from edw_temp.customer_midterm_review_recommendation_temp_0_inforce inf
            inner join edw_core.tpolicy p on inf.policy_sk = p.policy_sk
            left join edw_core.tpolicy_history ph on ph.policy_sk = p.policy_sk and ph.latest_transaction_in = 'Y'
            left join edw_core.thome_coverage hc on hc.policy_history_sk = ph.policy_history_sk
            where  ISNULL(p.non_renewal_in,'')='No'  -- added by Sandeep Gundreddy on 09/11/25 to ignore non-renewal policies
            and p.customer_id in (select customer_id from cust)
        ) 
		,
        cust_review_curr  as
        (
            select customer_id, 
					max(case when product_cd in ('AU') then 1 else 0 end) has_AU,
                    max(case when product_cd in ('HO','CO') then 1 else 0 end) has_ho,
                    case when max(occupancy_type) = '9_Primary' then 'has_primary'
                         when max(occupancy_type) = '8_non-Primary' then 'has_secondary'
                         when max(occupancy_type) is null then 'No_home'
                    end occupancy_type,
					count(distinct replace(product_cd,'CO','HO')) product_ct,
					count(*) policy_ct,
					sum(case when product_cd in ('HO','CO') then 1 else 0 end) home_ct 
            from cust_review
            --where forecast_quote_in  = 'No' --Removed to get all quotes for the customer
            group by customer_id
        )   -- select * from cust_review_curr    order by 4  
        ,
        cust_primary_future  as
        (
            select q.customer_id, min(q.effective_dt) effective_dt
            from edw_core.tquote q
            left join edw_core.tquote_history qh on qh.quote_sk = q.quote_sk and qh.latest_transaction_in = 'Y'
            left join edw_core.tquote_home_coverage qhc on qhc.quote_history_sk = qh.quote_history_sk
            where q.customer_id in (select customer_id from cust)
			and forecast_quote_in  = 'Yes'
            and qhc.occupancy_type = 'Primary'
            group by q.customer_id 
        )
        select  a.customer_id,    
                case when home_ct >= 4   then 'Has four or more Homes'
                     when policy_ct >= 8 then 'Has eight or more Policies'
                     when product_ct = 1 and has_au = 1 then 'Monoline AU'
                     when has_ho = 0 then 'No Home product'
                     when has_ho = 1 and occupancy_type = 'has_primary' and b.customer_id is not null then 'Primary Home effective on ' + cast(b.effective_dt as varchar)
                     when has_ho = 1 and occupancy_type = 'has_primary' and b.customer_id is null then 'Has Home Primary'
                     when has_ho = 1 and occupancy_type <> 'has_primary' and b.customer_id is null then 'Has Home Secondary'  
                     when has_ho = 1 and occupancy_type <> 'has_primary' and b.customer_id is not null then 'Primary Home effective on ' + cast(b.effective_dt as varchar) 
                end reason_desc, 
				case when has_ho = 1 and occupancy_type = 'has_primary' and product_ct = 1 then 'Yes' else 'No' end primary_home_monoline_in, 
				case when has_ho = 1 and occupancy_type = 'has_secondary'                  then 'Yes' else 'No' end non_primary_home_monoline_in --, a.*,b.*
        into edw_temp.customer_midterm_review_recommendation_temp_1_cust
        from cust_review_curr a
        left join cust_primary_future b on a.customer_id = b.customer_id
        --where a.customer_id = '1234608582'
        order by 2,1  		 
 
        --change this to merge, run thru all scenarios, also add renewal_quote_review_start_dt as last source  

        --update when a record is found in customer_midterm_review_eligibility_feed
        --and midterm_review_completed_dt is null
        --will happen mostly for sec home with a primary effective in future or for customer with 4 or more homes or au monline or 8 or more pols
        update t
        set      t.midterm_review_year      	= s.midterm_review_year
                ,t.midterm_review_process_in    = s.midterm_review_process_in
                ,t.reason_desc      	        = s.reason_desc
                ,t.update_ts      	            = s.update_ts         
        from edw_integration.customer_midterm_review_eligibility_feed t 
        inner join (
                    select distinct customer_id,
                        datepart(yyyy, getdate()) midterm_review_year,
                        case when reason_desc in ('Has Home Primary','Has Home Secondary') then 'Yes' Else 'No' end midterm_review_process_in,  
                        reason_desc , 
                        getdate() create_ts,
                        getdate() update_ts 
                    from edw_temp.customer_midterm_review_recommendation_temp_1_cust
                    ) s ON s.customer_id = t.customer_id 
        where t.latest_review_in = 'Y'
        and t.midterm_review_completed_dt is null
        --and   datediff(dd, isnull(t.midterm_review_completed_dt,'01-jan-9999'),CURRENT_DATE) < 365 --commented this out since we only want to update a record when there is no midterm_review_completed_dt

        --    insert when a record is not found
        --or insert a record when latest midterm_review_completed_dt is completed more than 365 days ago
		INSERT into edw_integration.customer_midterm_review_eligibility_feed
            (customer_id, midterm_review_year, midterm_review_process_in, reason_desc, create_ts, update_ts, etl_audit_sk) 
		select s.customer_id,
				s.midterm_review_year,
				s.midterm_review_process_in,
				s.reason_desc,
				s.create_ts,
				s.update_ts, 
				@etl_audit_sk                
        from (
                    select distinct customer_id,
                        datepart(yyyy, getdate()) midterm_review_year,
                        case when reason_desc in ('Has Home Primary','Has Home Secondary') then 'Yes' Else 'No' end midterm_review_process_in,  
                        reason_desc , 
                        getdate() create_ts,
                        getdate() update_ts 
                    from edw_temp.customer_midterm_review_recommendation_temp_1_cust
                    ) s 
        left join edw_integration.customer_midterm_review_eligibility_feed t ON s.customer_id = t.customer_id
        where t.customer_id is null 
         or (t.latest_review_in = 'Y' and t.midterm_review_completed_dt is not null and datediff(dd, t.midterm_review_completed_dt,CURRENT_DATE) >= 365 
             )

        /*
        merge edw_integration.customer_midterm_review_eligibility_feed target
        using
        (
             select distinct customer_id,
                datepart(yyyy, getdate()) midterm_review_year,
                case when reason_desc in ('Has Home Primary','Has Home Secondary') then 'Yes' Else 'No' end midterm_review_process_in,  
                reason_desc , 
				getdate() create_ts,
				getdate() update_ts 
            from edw_temp.customer_midterm_review_recommendation_temp_1_cust
        ) as SOURCE
		ON Source.customer_id = Target.customer_id and datediff(dd,isnull(target.midterm_review_completed_dt,'01-jan-9999'), CURRENT_DATE) < 365
        WHEN NOT MATCHED BY Target THEN
		INSERT 
            (customer_id, midterm_review_year, midterm_review_process_in, reason_desc, create_ts, update_ts, etl_audit_sk) 
		VALUES (source.customer_id,
				source.midterm_review_year,
				source.midterm_review_process_in,
				source.reason_desc,
				source.create_ts,
				source.update_ts, 
				@etl_audit_sk)
		-- For Updates
		WHEN MATCHED THEN UPDATE 
		SET
            --only when midterm_review_completed_dt is null, update all cols with new source data
			 target.midterm_review_year      	= iif(target.midterm_review_completed_dt is null, source.midterm_review_year      , target.midterm_review_year) 
  			,target.midterm_review_process_in   = iif(target.midterm_review_completed_dt is null, source.midterm_review_process_in, target.midterm_review_process_in) 
  			,target.reason_desc      	        = iif(target.midterm_review_completed_dt is null, source.reason_desc              , target.reason_desc) 
  			,target.update_ts      	            = iif(target.midterm_review_completed_dt is null, source.update_ts                , target.update_ts) 
            ; 
        */
		               
        SET @rows_affected = (select count(*) from edw_integration.customer_midterm_review_eligibility_feed where midterm_review_process_in = 'Yes'); 

		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh ;

        select pol.customer_id, vehicle_model_year,vehicle_make, agreed_value_amt, market_value_amt, 
				ROW_NUMBER() OVER (PARTITION BY pol.customer_id ORDER BY cast(agreed_value_amt as float) DESC, cast(market_value_amt as float) desc) AS rn,
				COUNT(*) OVER (PARTITION BY pol.customer_id) AS auto_vehicle_ct ,
				cast('' as varchar(255)) veh_list
		into edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh
        from edw_core.tauto_vehicle av
		inner join edw_core.tpolicy pol on pol.policy_no = av.policy_no 
        inner join edw_temp.customer_midterm_review_recommendation_temp_0_inforce inf on inf.policy_sk = pol.policy_sk 
		inner join edw_core.tauto_vehicle_coverage avc on av.auto_vehicle_sk = avc.auto_vehicle_sk and avc.policy_history_sk = inf.policy_history_sk 
		where avc.vehicle_deleted_in = 'No'
        and customer_id  in (Select customer_id from edw_integration.customer_midterm_review_eligibility_feed where midterm_review_process_in = 'Yes'  )
                
        DECLARE @custID VARCHAR(255)
		DECLARE @veh_modelyr  VARCHAR(255)
		DECLARE @veh_make  VARCHAR(255)
		DECLARE @old_veh_list  VARCHAR(255)
		DECLARE @veh_list  VARCHAR(255)
		DECLARE @add_veh_ct  int = 0
		
		set @veh_list = '' 
		set @old_veh_list = '' 
 
		DECLARE c999_rec CURSOR
		FOR  
		SELECT distinct customer_id FROM edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh --where customer_id = '1234500131'
		order by 1 
		open c999_rec; 
		FETCH NEXT FROM c999_rec INTO @custID; 
		--print @custID
		WHILE @@FETCH_STATUS = 0
			BEGIN    
				DECLARE c888_rec CURSOR
				FOR  
				SELECT vehicle_model_year,vehicle_make FROM edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh
				where customer_id = @custID
				order by RN 
				open c888_rec; 
				FETCH NEXT FROM c888_rec INTO @veh_modelyr, @veh_make;  
				WHILE @@FETCH_STATUS = 0
					BEGIN 
						set @veh_list = concat(@veh_list, concat_ws('-',@veh_modelyr,@veh_make),'||')
						if len(@veh_list)+len(' and xxx additional covered vehicles.')-2 > 95 
						begin 
							set @veh_list = @old_veh_list
							set @add_veh_ct = @add_veh_ct + 1
						end;
						set @old_veh_list = @veh_list
						--print @old_veh_list 
						--print @veh_list 
						--print @add_veh_ct
						--print len(@veh_list )
						--print len('and xxx additional covered vehicles')
						FETCH NEXT FROM c888_rec INTO @veh_modelyr, @veh_make;
					END; 
				--print @add_veh_ct
				if @add_veh_ct = 0
				begin
					set @veh_list = substring(@veh_list,1,len(@veh_list) -2);
					--print 'final-' @veh_list 
				end
				else
				begin
					set @veh_list = substring(@veh_list,1,len(@veh_list) -2);
					set @veh_list = concat(@veh_list, ' and ', @add_veh_ct, iif(@add_veh_ct = 1,' additional covered vehicle.',' additional covered vehicles.'));
					--print 'final-' @veh_list 
				end
				--print 'final-' + @veh_list 
				--print len(@veh_list)

				update edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh set veh_list = @veh_list where customer_id = @custID

				set @veh_list = '' 
				set @old_veh_list = ''
				set @add_veh_ct = 0

				CLOSE c888_rec;
				DEALLOCATE c888_rec;
 
				FETCH NEXT FROM c999_rec INTO @custID;
			END; 
		CLOSE c999_rec;
		DEALLOCATE c999_rec; 
       
        drop table if exists edw_temp.customer_midterm_review_recommendation_temp_2_inforce_detail ;

        --inforce data 
        with 
        /*
        usr as
        (
            --which user to use, has multiple
            select *, rank() over (partition by first_nm + ' ' + last_nm order by phone_no desc, email) rnk
            from edw_core.tuser
        ),*/
        coll_limit as
        (
             select policy_history_sk, policy_no, sum(COALESCE(scheduled_limit_amt, 0) + COALESCE(blanket_limit_amt, 0)) total_limit
             from edw_core.[tcollection_class_type]
             group by policy_history_sk, policy_no
        )
        select pol.policy_no, pol.original_policy_no, pol.risk_state_cd, pol.effective_dt, pol.expiration_dt, 
                pr.product_nm, pr.product_cd, pol.customer_id, cust.customer_nm, cust.email customer_email, cust.home_phone_no customer_phone_no, cust.vip_in, 
                cust.mailing_address_line1, cust.mailing_address_line2, cust.mailing_address_unit_no,
                cust.mailing_address_city_nm, cust.mailing_address_state_cd, cust.mailing_address_zip_cd,
                pol.broker_id, br.dba_nm, br.broker_nm, br.broker_phone_no, br.broker_email,
                p.producer_id, CONCAT(p.First_nm, ' ', p.Last_nm) producer_nm, p.phone_no producer_phone_no, p.email producer_email, 
                /*
                bdm.team_member_nm bdm_nm, bdm_usr.phone_no bdm_phone_no, bdm_usr.email bdm_email,  
                un.team_member_nm new_business_underwriter_nm, un_usr.phone_no new_business_underwriter_phone_no, un_usr.email new_business_underwriter_email,
                run.team_member_nm renewal_underwriter_nm, run_usr.phone_no renewal_underwriter_phone_no, run_usr.email renewal_underwriter_email,
                */
                hol.address_line_1 risk_address_line1,  
                hol.address_line_2 risk_address_line2,  
                hol.unit_no      unit_no,  
                hol.city_nm      risk_address_city_nm,  
                hol.state_cd     risk_address_state_cd,  
                hol.zip_cd       risk_address_zip_cd,
                hc.occupancy_type ,  
                hac.water_leak_detection_system,
                ph.premium_amt renewal_premium_amt,
                pel.pel_limit_amt,
                pel_loc.loc_ct,
                pel_wc.wc_ct,
                pel_veh.veh_ct, 
                hc.total_insured_value_amt,
                hac.wildfire_protection_enrollment_in,
                hc.distance_to_coast,
                hc.distance_to_shore,
                hac.backup_generator_in,
                cl.total_limit total_collection_limit_amt, 
				y.no_of_years_with_vault,  
                y.customer_since_dt,
				-- Yunus 09/25/2025 (Multiple Yrs with Vault)
				/*case 
					when y.no_of_years_with_vault > 1 then
						concat_ws('','Thank you for allowing us to serve you for '+ cast(y.no_of_years_with_vault as varchar(255)) ,' years')
					else 
						'Thank you for allowing us to serve you this year. We''re glad you''re with us!'
				end*/
                null
				as no_of_years_with_vault_tx,
				apc.emergency_movement_coverage_in,
				avl.auto_vehicle_list, 
				avl.auto_vehicle_ct,
				--ybl.boat_yatch_product_type,
				ybl.yacht_boat_list, 
				ybl.yacht_boat_ct,
				/*case when pinf.customer_id is not null and pinf.inforce_ct = cinf.inforce_ct
							   then 'Yes' 
							   else 'No' 
						  end monoline_home_in,*/
				a.primary_home_monoline_in,
				a.non_primary_home_monoline_in
        into edw_temp.customer_midterm_review_recommendation_temp_2_inforce_detail
        from edw_temp.customer_midterm_review_recommendation_temp_0_inforce inf
        inner join edw_core.tpolicy pol on pol.policy_sk = inf.policy_sk
        inner join edw_core.tpolicy_history ph on ph.policy_no = pol.policy_no and ph.latest_transaction_in = 'Y'
        left join edw_core.tproducer p on p.producer_sk = ph.producer_sk
        inner join edw_core.tproduct pr on pr.product_cd = pol.product_cd
        inner join edw_core.tcustomer cust on cust.customer_id = pol.customer_id 
		inner join edw_temp.customer_midterm_review_recommendation_temp_1_cust a on a.customer_id = cust.customer_id
        inner join edw_core.tbroker br on br.broker_id = pol.broker_id
        /*
        left join edw_core.tbroker_vault_team bdm on br.broker_id = bdm.broker_id and bdm.product_nm = pr.product_nm and bdm.team_member_type = 'BusinessDevelopmentManager'
                                                            AND pol.program_type = bdm.program_type
                                                            AND isnull(bdm.state_cd,pol.risk_state_cd)=pol.risk_state_cd
        left join usr bdm_usr on bdm_usr.first_nm + ' ' + bdm_usr.last_nm = bdm.team_member_nm and bdm_usr.rnk = 1
        left join edw_core.tbroker_vault_team un on br.broker_id = un.broker_id and un.product_nm = pr.product_nm and un.team_member_type = 'Underwriter'
                                                            AND pol.program_type = un.program_type
                                                            AND isnull(un.state_cd,pol.risk_state_cd)=pol.risk_state_cd
        left join usr un_usr on un_usr.first_nm + ' ' + un_usr.last_nm = un.team_member_nm and un_usr.rnk = 1
        left join edw_core.tbroker_vault_team run on br.broker_id = run.broker_id and run.product_nm = pr.product_nm and run.team_member_type = 'RenewalUnderwriter'
                                                            AND pol.program_type = run.program_type
                                                            AND isnull(run.state_cd,pol.risk_state_cd)=pol.risk_state_cd
        left join usr run_usr on run_usr.first_nm + ' ' + run_usr.last_nm = run.team_member_nm and run_usr.rnk = 1
        */
        left join edw_core.thome_additional_coverage hac on hac.policy_no = pol.policy_no and ph.policy_history_sk = hac.policy_history_sk		
        left join coll_limit cl on cl.policy_no = pol.policy_no and cl.policy_history_sk = ph.policy_history_sk
        left join edw_core.thome_coverage hc on hc.home_coverage_sk = hac.home_coverage_sk
        left join edw_core.thome_location hol on hol.policy_no = hc.policy_no
        left join edw_core.tpel_coverage pel on pel.policy_no = pol.policy_no and ph.policy_history_sk = pel.policy_history_sk
        left join (select policy_no,policy_history_sk, count(location_no) loc_ct
                     from edw_core.tpel_location
					where
						location_deleted_in = 'No'
                   group by policy_no,policy_history_sk) pel_loc on pel_loc.policy_no = pol.policy_no and ph.policy_history_sk = pel_loc.policy_history_sk
        left join (select policy_no,policy_history_sk, count(watercraft_no) wc_ct
                     from edw_core.tpel_watercraft
					where
						watercraft_deleted_in = 'No'
                   group by policy_no,policy_history_sk) pel_wc on pel_wc.policy_no = pol.policy_no and ph.policy_history_sk = pel_wc.policy_history_sk
        left join (select policy_no,policy_history_sk, count(vehicle_no) veh_ct
                     from edw_core.tpel_vehicle
					 where
						vehicle_deleted_in = 'No'
                   group by policy_no,policy_history_sk) pel_veh on pel_veh.policy_no = pol.policy_no and ph.policy_history_sk = pel_veh.policy_history_sk
        left join 
		(
			select customer_id,
                    cast(datediff(dd,min(original_policy_effective_dt),GETDATE())/365.25 as int) as no_of_years_with_vault,
                    min(original_policy_effective_dt) customer_since_dt
			from edw_core.tpolicy
			group by customer_id
		) as y on y.customer_id = pol.customer_id
		left join edw_core.tauto_policy_coverage apc on ph.policy_no = apc.policy_no and ph.policy_history_sk = apc.policy_history_sk  
		left join
		(
            select distinct customer_id,veh_list as auto_vehicle_list, auto_vehicle_ct
            from edw_temp.customer_midterm_review_recommendation_temp_3_inf_au_veh
		) as avl on pol.customer_id = avl.customer_id
		left join
		(
			select pol.customer_id, 
                    string_agg(concat(mbt.boat_yatch_product_type,' coverage for your ',boat_yacht_year,'-',boat_yacht_make),'||') as yacht_boat_list,
			        count(mbt.marine_boat_yacht_sk) as yacht_boat_ct
			from    edw_core.tmarine_boat_yacht mbt
			inner join edw_core.tmarine_boat_yacht_coverage mbtc on mbt.marine_boat_yacht_sk = mbtc.marine_boat_yacht_sk
			inner join edw_core.tpolicy pol on pol.policy_no = mbt.policy_no
			inner join edw_temp.customer_midterm_review_recommendation_temp_0_inforce inf on inf.policy_sk = pol.policy_sk and inf.policy_history_sk=mbtc.policy_history_sk
			group by pol.customer_id

		) as ybl on ybl.customer_id = pol.customer_id

		where   pol.non_renewal_in = 'No' --and pol.policy_no = 'AU100177549-03'-- and pol.customer_id = '1234507332'
        and pol.customer_id  in (Select customer_id --from edw_core.tcustomer where customer_id in ('1234500995','1234686788','1234500340','1234521910','1234522128','1234509154')
                                from edw_integration.customer_midterm_review_eligibility_feed where midterm_review_process_in = 'Yes'
        )
            ;		 
   
        insert into edw_integration.customer_midterm_review_policy_detail
		(
			policy_no,
			original_policy_no,
			risk_state_cd, 
			effective_dt,
			expiration_dt, 
			product_nm,
            renewal_year,
			customer_id,
			customer_nm ,
			customer_email,
			customer_phone_no,
			vip_in,
			[mailing_address_line1],
			[mailing_address_line2],
			[mailing_address_unit_no],
			[mailing_address_city_nm],
			[mailing_address_state_cd],
			[mailing_address_zip_cd],
			broker_id,
			dba_nm,
			broker_nm,
			broker_phone_no,
			broker_email,
            producer_id, producer_nm, producer_phone_no, producer_email, 
			/*
            bdm_nm,
			bdm_phone_no,
			bdm_email,
			new_business_underwriter_nm,
			new_business_underwriter_email,
			new_business_underwriter_phone_no,
			renewal_underwriter_nm,
			renewal_underwriter_email,
			renewal_underwriter_phone_no,
            */
			risk_address_line1,
			risk_address_line2,
			risk_address_unit_no,
			risk_address_city_nm,
			risk_address_state_cd,
			risk_address_zip_cd,
			occupancy_type,
			water_leak_detection_system,
			renewal_premium_amt,
			pel_limit_amt,
			pel_location_ct,
			pel_watercraft_ct,
			pel_vehicle_ct,
			total_insured_value_amt,
			wildfire_protection_enrollment_in,
			distance_to_coast,
			distance_to_shore,
			backup_generator_in,
			total_collection_limit_amt,
			no_of_years_with_vault,
            customer_since_dt,
			no_of_years_with_vault_tx,
			emergency_movement_coverage_in,
			auto_vehicle_list, 
			auto_vehicle_ct,
			--yatch_product_type,
			yacht_boat_list, 
			yacht_boat_ct,
			--monoline_home_in,
			primary_home_monoline_in,
			non_primary_home_monoline_in,
			etl_audit_sk,
			create_ts,
			update_ts
		)
        select policy_no,
				original_policy_no,
				risk_state_cd, 
				effective_dt,
				expiration_dt, 
				product_nm,
                datepart(yyyy, getdate()) renewal_year, 
				customer_id,
				customer_nm ,
				customer_email,
				customer_phone_no,
				vip_in,
				[mailing_address_line1],
				[mailing_address_line2],
				[mailing_address_unit_no],
				[mailing_address_city_nm],
				[mailing_address_state_cd],
				[mailing_address_zip_cd],
				broker_id,
				dba_nm,
				broker_nm,
				broker_phone_no,
				broker_email,
                producer_id, producer_nm, producer_phone_no, producer_email, 
				/*
                bdm_nm,
				bdm_phone_no,
				bdm_email,
				new_business_underwriter_nm,
				new_business_underwriter_email,
				new_business_underwriter_phone_no,
				renewal_underwriter_nm,
				renewal_underwriter_email,
				renewal_underwriter_phone_no,
                */
				risk_address_line1,
				risk_address_line2,
				unit_no,
				risk_address_city_nm,
				risk_address_state_cd,
				risk_address_zip_cd,
				occupancy_type,
				water_leak_detection_system,
				renewal_premium_amt,
				pel_limit_amt,
				loc_ct,
				wc_ct,
				veh_ct,
				total_insured_value_amt,
				wildfire_protection_enrollment_in,
				distance_to_coast,
				distance_to_shore,
				backup_generator_in,
				total_collection_limit_amt,
				no_of_years_with_vault,
                customer_since_dt,
				no_of_years_with_vault_tx,
				emergency_movement_coverage_in,
				auto_vehicle_list, 
				auto_vehicle_ct,
				--boat_yatch_product_type,
				yacht_boat_list, 
				yacht_boat_ct,
				--monoline_home_in,
				primary_home_monoline_in,
				non_primary_home_monoline_in,
                @etl_audit_sk etl_audit_sk,
                getdate() create_ts,
                getdate() update_ts --select *
			from edw_temp.customer_midterm_review_recommendation_temp_2_inforce_detail
        --AG commented on 9/26 - no need for new business quotes
		--union all
        --select * from edw_temp.customer_midterm_review_recommendation_temp_1_new_quotes
        --order by 7   
 
       
        drop table if exists edw_temp.customer_midterm_review_recommendation_temp_2_offered_state;
 
 
        SELECT state_cd, replace(replace(replace(replace(replace(replace(product_cd,'_in',''),'homeowners','ho'),'condo','co'),'auto','au'),'collections','Lux'),'marine','BY') product_cd, Value offered_in
        into edw_temp.customer_midterm_review_recommendation_temp_2_offered_state
        FROM
            (SELECT state_cd,  homeowners_in, condo_in, auto_in, pel_in, collections_in, collections_on_endorsement_in, marine_in
            FROM edw_core.tproduct_offered_state) AS src
        UNPIVOT
            (Value FOR product_cd IN ( homeowners_in, condo_in, auto_in, pel_in, collections_in, collections_on_endorsement_in, marine_in)) AS unpvt;

		insert into edw_temp.customer_midterm_review_recommendation_temp_2_offered_state
        select distinct state_cd,  'AV' product_cd, 'Yes' offered_in
		from edw_temp.customer_midterm_review_recommendation_temp_2_offered_state;
       
        insert into edw_integration.customer_midterm_review_recommendation
                (customer_id,
                risk_state_cd,
                mailing_address_state_cd, 
                renewal_year,
                product_nm,
                existing_product_in,
                existing_policy_no,
                occupancy_type, 
                rms_recommendation,
                wildfire_protection_recommendation, 
                backup_generator_recommendation, 
                product_recommendation,
                etl_audit_sk,
                create_ts,
                update_ts)
        select  cust.customer_id, cf.risk_state_cd,cust.mailing_address_state_cd, --cf.uw_company_cd,
                datepart(yyyy, getdate()) renewal_year, --cust.mailing_address_state_cd, cf.product_nm,
                case when pos.product_cd = 'Lux_on_endorsement' then pos.product_cd else pr.product_nm end product_nm,  
                case when cf.policy_no is not null and pr.product_cd = 'ho'
                     and pos.product_cd = 'Lux_on_endorsement' and lux.quote_no is not null then 'Yes'
                     when cf.policy_no is not null and pr.product_cd = 'ho'
                     and pos.product_cd = 'Lux_on_endorsement' and lux.quote_no is null then 'No'
                     when cf.product_nm = pr.product_nm then 'Yes'  
                     when cf.policy_no is not null then 'Yes'
                     else 'No'
                end existing_product_in,
                isnull(cf.policy_no,'') existing_policy_no, cf.occupancy_type,
                case when cf.water_leak_detection_system = 'No' and pos.product_cd in ('ho','co') then 'Install water shutoff system service' end rms_recommendation,
				
				case when exists(select 1 from edw_temp.zip_codes z where z.zip_code = cf.risk_address_zip_cd)
							and cf.wildfire_protection_enrollment_in = 'No' and pos.product_cd in ('ho','co')
					then 'Recommended for wildfire protection'
				end as wildfire_protection_recommendation,
				case when cf.backup_generator_in = 'No' and pos.product_cd in ('ho','co') then 'Intall backup generator'
				end as backup_generator_recommendation,				
				case (case when cf.policy_no is not null and pr.product_cd = 'ho'  and pos.product_cd = 'Lux_on_endorsement' and lux.quote_no is null then 'Yes'
                           when cf.policy_no is not null and pr.product_cd = 'ho' and pos.product_cd = 'Lux_on_endorsement' and lux.quote_no is not null then 'Not recommended'
                           --primary
                           when cf.policy_no is not null and pr.product_cd in ('ho','co') and prim.customer_id is null then 'Primary'
                           --marine
                           when cf.policy_no is null and pos.offered_in = 'Yes' and pr.product_cd = 'by' and marine.customer_id is null then 'Marine'
                           --marine
                           when cf.policy_no is null and pos.offered_in = 'Yes' and pr.product_cd = 'by' and marine.customer_id is not null then 'Not recommended'
                           when cf.policy_no is null and pos.offered_in = 'No' then 'Not Offered'
                           when cf.policy_no is not null then 'Not recommended'
                           when cf.product_nm = pr.product_nm then 'Not recommended'  
                           else 'Yes'
                       end
                      )
                      when  'Yes'		 then 'Buy ' + (case when pos.product_cd = 'Lux_on_endorsement' then pos.product_cd else pr.product_nm end) + ';'
                      when 'Marine'		 then 'If you have a mid-sized to larger boat or yacht, talk to your agent about Vault yacht coverage.'
                      when 'Not Offered' then 'Not Offered in State'
                      when 'Primary'	 then 'Add as primary for additional discount'
                end product_recommendation,
                @etl_audit_sk,
                getdate() create_ts,
                getdate() update_ts-- into edw_integration.customer_midterm_review_recommendation --select *
				
        from (  
              -- this is based on customer homerisk state eligibility
              select a.customer_id, b.risk_address_state_cd mailing_address_state_cd, occupancy_type, total_insured_value_amt, 
                    rank() over (partition by a.customer_id order by case b.occupancy_type
                                                                        when 'Primary' then '1_Primary'
                                                                        else '2_Non_Primary' 
                                                                    end, b.total_insured_value_amt desc, b.policy_no) rnk
              from edw_core.tcustomer a, edw_integration.customer_midterm_review_policy_detail b
              where a.customer_id = b.customer_id 
              and renewal_year =  datepart(yyyy, getdate())
			  and b.product_nm in ('Homeowners','Condo')
			  and a.customer_id  in ( Select customer_id  
									from edw_integration.customer_midterm_review_eligibility_feed 
									where midterm_review_process_in = 'Yes'
								) 
                /*-- this is based on customer mailing state eligibility
                select distinct a.customer_id, a.mailing_address_state_cd--, b.uw_company_cd
                from edw_core.tcustomer a, edw_integration.customer_midterm_review_policy_detail b
                where a.customer_id = b.customer_id 
                and renewal_year =  datepart(yyyy, getdate())
                and a.customer_id  in ( Select customer_id  
                                        from edw_integration.customer_midterm_review_eligibility_feed 
                                        where midterm_review_process_in = 'Yes'
                                    )
                */
         
              ) cust
        cross join (select product_cd, product_nm, product_category_nm from edw_core.tproduct
					union all
					select 'AV', 'Aviation', 'PersonalLines'  
					)pr --on pr.product_nm = cust.product_nm
        left join edw_integration.customer_midterm_review_policy_detail cf on cust.customer_id = cf.customer_id and cf.product_nm = pr.product_nm and cf.renewal_year =  datepart(yyyy, getdate())
        left join edw_temp.customer_midterm_review_recommendation_temp_2_offered_state pos on pos.state_cd = cust.mailing_address_state_cd 
		and pr.product_cd = (case when pos.product_cd = 'Lux_on_endorsement' then (case when cf.total_collection_limit_amt is not null then 'ho' end) else pos.product_cd end)
        left join (select distinct quote_no from edw_core.tquote_collection_class_type) lux on lux.quote_no = cf.policy_no
        left join (select distinct customer_id from edw_core.thome_coverage cov, edw_core.tpolicy pol
                                where occupancy_type ='Primary'
                                and pol.policy_no = cov.policy_no
                                and pol.policy_status = 'Active' --.expiration_dt > @in_start_dt --'27-jul-2025'
                              ) prim on prim.customer_id = cust.customer_id
        left join (select distinct customer_id from edw_integration.customer_midterm_review_policy_detail
                                where product_nm = 'Marine Boat & Yacht'
                                and renewal_year =  datepart(yyyy, getdate())
                              ) marine on marine.customer_id = cust.customer_id
        where cust.rnk = 1
        and pr.product_category_nm = 'PersonalLines' 
		and  (cf.policy_no is not null or (pos.offered_in = 'Yes'
                                            -- Yunus - 09/24/2025 Changes made to handle below 2 scenerios
                                            -- If collections is available in a state, we should not recommend Lux on endorsement, because we will have collections boilerplate in the current coverage section
                                            --If account has collections, we should not recommend Lux on endorsement at all
											and not exists
											(
												select 1
												from
													edw_integration.customer_midterm_review_policy_detail cf1
												where
													cf1.customer_id= cust.customer_id
													and cf1.product_nm = 'Collection'
													and pos.product_cd = 'Lux_on_endorsement'
													and renewal_year =  datepart(yyyy, getdate())				
											))
			)  
        order by 1,5,6 ; 
 
        --- take out product recommendation of a DNR in the last year
        update a
        set product_recommendation = 'Not Recommended, customer has a DNR policy in the last one year'
        from edw_integration.customer_midterm_review_recommendation a
        inner join edw_core.tproduct pr on a.product_nm = pr.product_nm
        inner join (
                        select customer_id,  product_cd
                        from edw_core.tpolicy
                        where non_renewal_in = 'Yes'
                        and effective_dt >= dateadd(yy,-2,@in_start_dt) --'27-jul-2025')
                        group by customer_id, product_cd
                   ) cancels on a.customer_id = cancels.customer_id and pr.product_cd = cancels.product_cd
        where product_recommendation like 'Buy%'
 
        --- take out product recommendation of a cancelled policy in last year
        update a
        set product_recommendation = 'Not Recommended, customer has a cancelled policy in the last three year'
        from edw_integration.customer_midterm_review_recommendation a
        inner join edw_core.tproduct pr on a.product_nm = pr.product_nm
        inner join (
                        select customer_id,  product_cd
                        from edw_core.tpolicy
                        where policy_status = 'Cancelled'
                        and cancellation_effective_dt >= dateadd(yy,-3,@in_start_dt) --'27-jul-2025')
                        group by customer_id, product_cd
                   ) cancels on a.customer_id = cancels.customer_id and pr.product_cd = cancels.product_cd
        where product_recommendation like 'Buy%'
 
        --- take out product recommendation if a quote was Declined in last year
        update a
        set product_recommendation = 'Not Recommended, customer has a declined quote in the last three year'
        from edw_integration.customer_midterm_review_recommendation a
        inner join edw_core.tproduct pr on a.product_nm = pr.product_nm
        inner join (
                    select customer_id,  product_cd
                    from edw_core.tquote
                    where quote_create_ts >= dateadd(yy,-3,@in_start_dt) --'27-jul-2025')
                    and quote_status in ('Declined by Vault')
                    group by customer_id, product_cd
                   ) dec_quote on a.customer_id = dec_quote.customer_id and pr.product_cd = dec_quote.product_cd
        where product_recommendation like 'Buy%'; 	
 
        --- take out condo recommendation
        update edw_integration.customer_midterm_review_recommendation
        set product_recommendation = 'Condo not Recommended'
        where product_recommendation = 'Buy Condo;'
 
        /* --commented on 20261201 since we are now using messages table

        --- Update Auto recommendation phrase
        update edw_integration.customer_midterm_review_recommendation
        set product_recommendation = 'If you have passenger, luxury, collector cars or specialty vehicles, talk to your agent about a Vault auto policy.'
        where product_recommendation = 'Buy Auto;'
 
        --- Update Pel recommendation phrase
        update edw_integration.customer_midterm_review_recommendation
        set product_recommendation = 'If you need excess liability coverage between $0.5M - $30M to protect your assets, talk to your agent.'
        where product_recommendation = 'Buy Excess Liability;'
 
        --- Update Coll recommendation phrase
        update edw_integration.customer_midterm_review_recommendation
        set product_recommendation = 'If you have treasured collectibles and valuables to safeguard, talk to your agent about a collections policy. '
        where product_recommendation = 'Buy Collections;'
 
        --- Update AV recommendation phrase
        update edw_integration.customer_midterm_review_recommendation
        set product_recommendation = 'If you have corporate, charter, or personal aviation coverage needs, talk to your agent. Vault is here for you.'
        where product_recommendation = 'Buy Aviation;'	
        */  
	
        update edw_integration.customer_midterm_review_eligibility_feed  
        set latest_review_in = 'N';
        
        WITH cust_ranked 
        AS 
        (
            select ROW_NUMBER() over(partition by customer_id order by midterm_review_year desc) rn 
                    , *
            from edw_integration.customer_midterm_review_eligibility_feed  
        )
        UPDATE c
        SET latest_review_in = 'Y'
        FROM edw_integration.customer_midterm_review_eligibility_feed c
        inner join cust_ranked cr ON c.customer_id = cr.customer_id and c.midterm_review_year = cr.midterm_review_year
        where cr.rn = 1;
 
        --AG - Using  where renewal_quote_review_start_dt < getdate() becuase of a data issue in prod
        set @new_last_source_extract_ts = (select max(renewal_quote_review_start_dt) from edw_core.tquote 
                                            where renewal_quote_review_start_dt < cast(getdate() as date));
 
        --Update control table
        SET @new_last_source_extract_ts = COALESCE(@new_last_source_extract_ts,@last_source_extract_ts);
		
        EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
       
        -- Update audit table
        SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))
        if @in_start_dt is not null
        begin
            set @parameter_desc= 'last_source_extract_ts = ' + CAST(@last_source_extract_ts AS VARCHAR(200))
        end
        EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;   
         
		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_0_inforce;
		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_0_cust_monoline;
		drop table if exists edw_temp.zip_codes;
		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_1_cust ;
		drop table if exists edw_temp.customer_midterm_review_recommendation_temp_2_inforce_detail ; 
        drop table if exists edw_temp.customer_midterm_review_recommendation_temp_2_offered_state;
        
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
 
 
 