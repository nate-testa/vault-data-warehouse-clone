-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures migrats ebao claims to snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 		|Author										|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/24/2024			Yunus Mohammed					1. Created this procedure
-- 01/16/2025			Yunus Mohammed					2. Exposure Type code updated
-- 01/17/2025  		    Yunus Mohammed                  3. InjuredPerson and vehicle object code updated
-- 01/20/2025           Yunus Mohammed                  4. Claimant & Injured Person Claim Party Id adjusted for 'InjuredPerson' & 'PipMedPay' exposures and remoed product filer
-- 01/21/2025			Yunus Mohammed					5. Passed optional param claim_no
-- -01/27/2025			Yunus Mohammed					6. Added first open dt, first close dt,open dt and close dt
--																								Removed -ve payment amount on indemnity and -ve Reserve Amount on Indemnity
--																								Added tpolicy  table to get UW Company Name when it's not available in eBao table		
-- 01/30/2025			Yunus Mohammed					7. claimParties logic updated to get claimParties for claims without coverage
--																								 vehicles - removed check for InjuredPerson and PipMedPay.
-- 01/31/2025			Yunus Mohammed					8. Removed special characters from policy_no stored in case table
-- 02/03/2025			Yunus Mohammed					9 datetimeOfLoss and datetimeOfNotification formatted to default timestamp to 12 PM
-- 02/05/2025			Yunus Mohammed					10 	Used party_id instead of pty_party_id and update claimParties joins
-- 02/05/2025			Yunus Mohammed					 11	Added check for "exposure note should be migrated if content is blank"
--02/06/2025			Yunus Mohammed					12 Used TransactionEffectiveDate instead of EffectiveDate to get vehicles from Metal
--																									Updated join in vehicles object to ensure if VIN not matches with metal we always send object
-- ==================================================================================================================================
CREATE OR ALTER   PROCEDURE [edw_core].[sp_migration_create_claim_api]
@claim_no varchar(max) = null
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
		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200));		

		DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp1;
		DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp2;	

		IF(@claim_no is null) 
		BEGIN			
			SELECT c.* 
			INTO edw_temp.migration_create_claim_api_temp1
			FROM 
				edw_stage.t_clm_case c
			 	LEFT JOIN edw_stage.migration_create_claim_api mcca on c.CLAIM_NO = mcca.claimnumber				
			where 
				mcca.claimNumber is null				
		END
		ELSE
		BEGIN
			SELECT c.*
			INTO edw_temp.migration_create_claim_api_temp1
			FROM 
				edw_stage.t_clm_case c
			 	left join edw_stage.migration_create_claim_api mcca on c.CLAIM_NO = mcca.claimnumber
				INNER JOIN string_split(@claim_no,',') as t on t.[value]  = c.CLAIM_NO
			where 
			mcca.claimNumber is null
		END;
		
		WITH first_open_dt AS 
		(
			SELECT DISTINCT c.claim_no
			,MIN(ch.insert_time) AS claim_first_open_dt
			FROM
				edw_stage.t_clm_case_his ch
				INNER JOIN edw_stage.t_clm_case c ON ch.case_id = c.case_id
			WHERE
				ch.claim_type = 'LOS'
				AND ch.new_status = 'OPEN'
			GROUP BY c.claim_no
		)
		, first_close_dt as 
		(
			SELECT DISTINCT c.claim_no
			,MIN(ch.insert_time) as claim_first_close_dt
			FROM
				edw_stage.t_clm_case_his ch
				INNER JOIN edw_stage.t_clm_case c ON ch.case_id = c.case_id
			WHERE
				ch.claim_type = 'LOS'
				and ch.new_status = 'CLOSED'
			GROUP BY c.claim_no
		)
		, open_dt AS 
		(
			SELECT DISTINCT c.claim_no
			,MAX(ch.insert_time) AS claim_open_dt
			FROM
				edw_stage.t_clm_case_his ch
				INNER JOIN edw_stage.t_clm_case c ON ch.case_id = c.case_id
			WHERE
				ch.claim_type = 'LOS'
				AND ch.new_status in ( 'OPEN','REOPEN')
			GROUP BY c.claim_no
		)
		,close_dt as 
		(
			SELECT DISTINCT c.claim_no
			,MAX(ch.insert_time) as claim_close_dt
			FROM
				edw_stage.t_clm_case_his ch
				INNER JOIN edw_stage.t_clm_case c ON ch.case_id = c.case_id
			WHERE
				ch.claim_type = 'LOS'
				and ch.new_status = 'CLOSED'
			GROUP BY c.claim_no
		)

		SELECT claimNumber, accidentCode,claimType, 
		-- case when [status] = 'OPEN' THEN 'DRAFT' ELSE [status] END AS [status],
		'DRAFT' AS [status],
		policyNumber,
		FORMAT(firstOpenedAt, 'yyyy-MM-ddTHH:mm:ssZ') as firstOpenedAt ,
		FORMAT(firstClosedAt, 'yyyy-MM-ddTHH:mm:ssZ')  as firstClosedAt,
		FORMAT(openedAt, 'yyyy-MM-ddTHH:mm:ssZ')  as openedAt,
		CASE WHEN closedAt < openedAt THEN null ELSE FORMAT(closedAt, 'yyyy-MM-ddTHH:mm:ssZ') END AS closedAt,
		FORMAT(DATEADD(HOUR, 12, CAST(FORMAT(datetimeOfLoss, 'yyyy-MM-dd') AS DATETIME)), 'yyyy-MM-ddTHH:mm:ssZ') AS datetimeOfLoss,
		FORMAT(DATEADD(HOUR, 12, CAST(FORMAT(datetimeOfNotification, 'yyyy-MM-dd') AS DATETIME)), 'yyyy-MM-ddTHH:mm:ssZ') AS datetimeOfNotification,		
		accountCode, lossType,
		attachments, notes,claimIncidentDetails,
		notifier,exposures,
		-- causeOfAccident, incidentComments,
		vehicles, claimParties, getdate() as create_ts,api_status
		INTO edw_temp.migration_create_claim_api_temp2
		FROM
		(
		select
			c.CLAIM_NO as claimNumber, 
			c.accident_code as accidentCode,
			case when prd.product_nm in ( 'Condo', 'LUX', 'Homeowners','Collections')  then 'property'  
			when prd.product_nm in ( 'Auto')  then 'auto' 
			when prd.product_nm in ( 'Excess Liability')  then 'liability'  
			else prd.product_nm 
			end as claimType,
			UPPER(CASE 
						WHEN cstat.status_code IN('1','2','5') THEN 'Open'
						WHEN cstat.status_code IN('3','4','6') THEN 'Closed'
						ELSE cstat.status_name
					END) AS status,
			LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(c.POLICY_NO, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32)))) as policyNumber,
			fod.claim_first_open_dt as firstOpenedAt,
			fcd.claim_first_close_dt as firstClosedAt,
			od.claim_open_dt as openedAt,
			cd.claim_close_dt as closedAt,
			c.ACCIDENT_TIME as datetimeOfLoss,
			c.NOTICE_TIME as datetimeOfNotification,
			CASE
				WHEN cp.organ_id=1000000000002 THEN 'vault_reciprocal_exchange' 
				WHEN cp.organ_id=1000000000001 THEN 'vault_es_insurance_company'
				WHEN tp.uw_company_nm='Vault Reciprocal Exchange' THEN 'vault_reciprocal_exchange' -- Added on 01/24/2025
				WHEN tp.uw_company_nm='Vault E & S Insurance Company' THEN 'vault_es_insurance_company' -- Added on 01/24/2025
				ELSE ''
			END AS accountCode,
			/*
			case
				when prd.product_nm in ( 'Condo', 'Homeowners') and c.sub_cause_of_loss_code is null then 'property_claim_other'
			else
			*/
				(
					select
						top 1 slt.lossType
					from
						edw_stage.migration_loss_type_mapping slt
						where slt.cause_of_loss_cd = c.LOSS_CAUSE and 
						slt.sub_cause_of_loss_cd = isnull( c.sub_cause_of_loss_code,slt.sub_cause_of_loss_cd) and 
						slt.product_cd = prd.product_cd
				)
			/*end*/
			 as lossType,
			(
				select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
			) as attachments,
			(
				select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
			) as notes,
			(
				select top 1 PARTY_ID as claimPartyId
				from
					edw_stage.t_clm_party p
				where p.[CASE_ID] = c.[CASE_ID] and PARTY_ROLE = '01' 
				-- and cast( p.PARTY_NAME as varchar(max)) = c.CONTACT_NAME
				for json path, include_null_values, without_array_wrapper
			) as notifier,
			(
				select
					cast(c.ACCIDENT_DESC as varchar(max)) as incidentLocationDescription,
/*					case
					when prd.product_cd in ('HO','CO','LUX') then 'dwelling' 
					when prd.product_cd in ('AU') then 'other'
					when prd.product_cd in ('PEL') then 'business_address'
					end	
*/
					'other' as incidentLocationType,
					JSON_QUERY((
						SELECT
							tpa.ADDRESS_LINE_1 as address1,
							tpa.ADDRESS_LINE_2 as address2,
							tpa.CITY as city,
							tpa.POST_CODE as postalCode,
							tpa.[STATE] as region,
							tpa.COUNTRY as country
						FROM
							edw_stage.t_int_address tia
							LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID=tpa.ADDRESS_ID
						where
							tia.source_id = c.case_id
						for json path, include_null_values, without_array_wrapper
					)) as incidentLocationAddress
					for json path, include_null_values, without_array_wrapper
			) as claimIncidentDetails,
			--clc.LOSS_CAUSE_NAME as causeOfAccident,
			-- null as incidentComments,
			(
				select
					id,
					exposureType as exposureType,externalReferenceNumber,
					[status],lossParty,claimant,
					notes,vehicle,injuredPerson,property,livingExpense,genericAsset,coverage
					from
					(
					SELECT				
						ext.item_id as id,
						ISNULL(case when rowNum > 1 
						-- and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') 
						then 'Other'
						else ext.snapsheet_exposure_type  end,'Other') as exposureType,
						CONCAT_WS('-', cast(ext.item_id as varchar(max)), cast(ext.subclaim_type_name as varchar(max)), cast(ext.coverage_name as varchar(max)) ) as externalReferenceNumber,
		--				case when ext.STATUS_CODE = 'OPEN' THEN 'DRAFT' ELSE ext.STATUS_CODE END AS [status], 

		/*As per Snapsheet, if Claim status is OPEN/DRAFT, we can not send exposure level status as 'CLOSED (if any). It has to match with Claim level status. 
		This can be adjusted later using "status" object in 'Update an Exposure API'.*/
					--case when c.CASE_STATUS in ('1','2','5') then 'DRAFT' else ext.STATUS_CODE END AS [status], 
					'DRAFT' AS [status],
					--			tcpr.ROLE_NAME AS lossParty, --commented out for below testing--09/03/2024
						case 
							when ext.SUBCLAIM_TYPE_NAME like 'FP%' then 'insured'
							when ext.SUBCLAIM_TYPE_NAME like 'TP%' then 'third-party'
						end	as lossParty,
						JSON_QUERY((
							select 	ext.PARTY_ID as claimPartyId
/*
--Start - testing below block--01202025--
select CASE 
    WHEN ext.snapsheet_exposure_type IN ('InjuredPerson', 'PipMedPay') 
    THEN CONCAT(CONVERT(VARCHAR, ext.PARTY_ID), '-9999')
    ELSE CONVERT(VARCHAR, ext.PARTY_ID)
END AS claimPartyId
--End - testing below block--01202025--
*/
							for json path, include_null_values, without_array_wrapper
						)) as claimant,
						JSON_QUERY((
						select 'COMMENT' as noteType,
						FORMAT(nt.INSERT_TIME, 'yyyy-MM-ddTHH:mm:ssZ') as originatedAt,
						nt.NOTE_CONTENT as body
						from
							edw_stage.t_clm_note nt
						where
							nt.note_level != 'Claim'
							and ISNUMERIC(nt.note_level) =1 and ext.[OBJECT_ID] = cast(nt.note_level as [decimal](19, 0))
							and isnull(cast(nt.NOTE_CONTENT as varchar(max)),'')!=''
							for json path, include_null_values
						)) as notes,
						JSON_QUERY
						(
							(
								select
                                ext.[OBJECT_ID]
                                as vehicleId 
								where
									prd.product_cd = 'AU'
							--As per Snapsheet, vehicle id should not be present for ('InjuredPerson', 'PipMedPay') exposure types--
									and ext.snapsheet_exposure_type not in ('InjuredPerson', 'PipMedPay')
									and rowNum = 1  -- if it is greater than 1 it means exposure is other.
								for json path, include_null_values, without_array_wrapper
							)
						) as vehicle,			
						JSON_QUERY
						(
							(
								select ext.PARTY_ID as id,
/*
select CASE 
    WHEN ext.snapsheet_exposure_type IN ('InjuredPerson', 'PipMedPay') 
    THEN CONCAT(CONVERT(VARCHAR, ext.PARTY_ID), '-9999')
    ELSE CONVERT(VARCHAR, ext.PARTY_ID)
END AS id, 
--End - testing below block--01202025--       
*/                         
								ext.PARTY_ID as [injuredParty.claimPartyId] 
/*
CASE 
    WHEN ext.snapsheet_exposure_type IN ('InjuredPerson', 'PipMedPay') 
    THEN CONCAT(CONVERT(VARCHAR, ext.PARTY_ID), '-9999')
    ELSE CONVERT(VARCHAR, ext.PARTY_ID)
END AS [injuredParty.claimPartyId] 
--End - testing below block--01202025--
*/
								where
									ext.snapsheet_exposure_type in ('InjuredPerson', 'PipMedPay')
                                    and rowNum = 1  -- if it is greater than 1 it means exposure is other.
								for json path, include_null_values, without_array_wrapper
							)
						)
							as injuredPerson,
						
						JSON_QUERY((select ext.item_id as id  ,
							'policy_address' as propertyLocation ,
							'personal_property' as propertyType,
							JSON_QUERY((
										select ext.PARTY_ID as claimPartyId
										for json path, include_null_values, without_array_wrapper
									)) as [owner],
							JSON_QUERY((
								SELECT
									tpa.ADDRESS_LINE_1 as address1,
									tpa.ADDRESS_LINE_2 as address2,
									tpa.CITY as city,
									tpa.POST_CODE as postalCode,
									tpa.[STATE] as region,
									tpa.COUNTRY as country
								FROM
									edw_stage.t_int_address tia
									LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID=tpa.ADDRESS_ID
								where
									tia.source_id = c.case_id
								for json path, include_null_values, without_array_wrapper
							)) as [address]
						where
							ext.product_cd IN ('HO','CO','LUX') 
							and ISNULL(case when rowNum > 1 
							--and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') 
							then 'Other'
								else ext.snapsheet_exposure_type  end,'Other')
							in
							('Property', 'Dwelling', 'OtherStructures', 'PersonalProperty') 
						for json path, include_null_values, without_array_wrapper
						))
						as property,		
						JSON_QUERY(
						(
							select ext.item_id as id,
							ext.snapsheet_coverage_nm as [description],
								json_query(
									(
									select null as id 
									for json path, include_null_values, without_array_wrapper
								) 
								)as temporaryLocation
							where prd.product_cd IN ('HO','CO','LUX') and ext.snapsheet_exposure_type ='livingExpense' 
							for json path, include_null_values, without_array_wrapper
						))
					as livingExpense,
				
					JSON_QUERY
					(
						(
							select ext.item_id as id,
		--					CONCAT_WS('-', cast(ext.item_id as varchar(max)), cast(ext.subclaim_type_name as varchar(max)), cast(ext.coverage_name as varchar(max)) ) as [name]
							ext.coverage_name as [name]
							where
								ISNULL(case when rowNum > 1  
                                -- and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') 
                                then 'Other'
								else ext.snapsheet_exposure_type  end,'Other') in
								(
									'BusinessInterruption', 'CyberLiability', 'DirectorsAndOfficers', 'EmploymentPracticesLiability', 
									'ErrorsAndOmissions', 'PersonalInjuryAndAdvertising', 'ProductsAndCompletedOperations', 'Other'
								)
							for json path, include_null_values, without_array_wrapper
						)
					)
					as genericAsset,
					json_Query
					(
					case
						when ext.product_cd IN ('HO','CO') THEN
						JSON_QUERY
						(
							(
								select 
									'1' as riskIdentifier,
									'1' as locationIdentifier,
--								ext.snapsheet_coverage_nm as coverageCode,
                                ext.snapsheet_coverage_cd as coverageCode,
									ext.coverage_name as externalCoverageDetails
								for json path, include_null_values, without_array_wrapper
							)
						)
						WHEN ext.product_cd = 'AU' THEN
						json_query
						(
							(

						select
							cast(tav.vehicle_identifier as varchar(255)) as riskIdentifier,
							cast(tag.location_identifier as varchar(255)) as locationIdentifier,
--								ext.snapsheet_coverage_nm as coverageCode,
                                ext.snapsheet_coverage_cd as coverageCode,
							ext.coverage_name as externalCoverageDetails
						from
							(
                        	select 
                            	ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt ORDER BY vehicle_unique_id) AS vehicle_identifier,av.*
                        	from
                        		edw_core.tauto_vehicle av
								INNER JOIN edw_stage.t_clm_pol_insured cpi ON av.vehicle_vin = cast(cpi.insured_name as varchar(max))
							WHERE
								ext.insured_id = cpi.insured_id
								AND av.policy_no = ext.policy_no
								AND av.effective_dt = ext.eff_date
						
                    		) as tav
							inner join edw_core.tauto_vehicle_coverage as tavc on tavc.auto_vehicle_sk = tav.auto_vehicle_sk
                    		left JOIN
                        	(
                            select
                                ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt, 
                            transaction_seq_no ORDER BY garage_unique_id) AS location_identifier,*
                            from
                            edw_core.tauto_garage_location
                        	) as tag ON tag.auto_garage_location_sk = tavc.auto_garage_location_sk
							
							for json path, include_null_values, without_array_wrapper
							)
							
						) 
						when ext.product_cd = 'PEL' THEN
							json_query
							(
								(
									SELECT
										'1' as risk_identifier,
										cast(
											ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt, transaction_seq_no ORDER BY location_no)
											 as varchar(255)
										) AS location_identifier,
--								ext.snapsheet_coverage_nm as coverageCode,
                                ext.snapsheet_coverage_cd as coverageCode,
										ext.coverage_name as externalCoverageDetails
									FROM
										edw_core.tpel_location pl
										INNER JOIN edw_stage.t_clm_pol_insured cpi ON
										cast(cpi.insured_name as varchar(max)) like '%'+ pl.address_line_1 +'%'
										and cast(cpi.insured_name as varchar(max)) like '%'+ pl.city_nm +'%'
										and cast(cpi.insured_name as varchar(max)) like '%'+ pl.zip_cd +'%'
									WHERE
										pl.policy_no = ext.policy_no
										and pl.effective_dt  = ext.eff_date
										and pl.transaction_seq_no = 
										(
											SELECT
												max(transaction_seq_no) as transaction_seq_no
											FROM
												edw_core.tpel_location pl1
											WHERE
												pl1.policy_no = pl.policy_no
												and pl1.effective_dt = pl.effective_dt
										)									
								for json path, include_null_values, without_array_wrapper
								)
							)
						WHEN ext.product_cd = 'LUX' THEN
						JSON_QUERY
						(
							(
								SELECT 
								'1' as risk_identifier,
								'1' AS location_identifier,
--								ext.snapsheet_coverage_nm as coverageCode,
                                ext.snapsheet_coverage_cd as coverageCode,
								ext.coverage_name as externalCoverageDetails
								for json path, include_null_values, without_array_wrapper
							)
						)
						END ) as coverage
				
					FROM
						(
							select
                            /*
                                -- Commented on 01/16/2025. New logic implemented
								row_number() over(partition by o.[object_id] -- ISNULL(ext.snapsheet_exposure_type,'Other')
									order by ISNULL(ext.snapsheet_exposure_type,'Other')) as rowNum,
                            */
                            case 
		when ext.snapsheet_exposure_type = 'Vehicle' then 
				row_number() over(partition by o.[object_id] order by ISNULL(ext.snapsheet_exposure_type,'Other'))
		when ext.snapsheet_exposure_type in('PipMedPay','InjuredPerson') then 
			row_number() over(partition by o.case_id,ext.snapsheet_exposure_type, par.PARTY_ID order by ISNULL(ext.snapsheet_exposure_type,'Other'))		
	else
		row_number() over(partition by o.case_id, ISNULL(ext.snapsheet_exposure_type,'Other')order by ISNULL(ext.snapsheet_exposure_type,'Other'))
	end as rowNum,
								ext.snapsheet_exposure_type,
								cov.snapsheet_coverage_nm,
                                cov.snapsheet_coverage_cd,
								o.[OBJECT_ID],
								o.insured_id,
								i.item_id,sct.subclaim_type_name,i.coverage_name,
								i.STATUS_CODE,par.PARTY_ID,
								prd.product_cd,
								p.policy_no,
								p.eff_date
							from
								edw_stage.t_clm_case clm
								inner join edw_stage.t_clm_object o on clm.CASE_ID = o.CASE_ID
								inner join edw_stage.t_clm_item i ON o.[object_id] = i.[object_id]
								left join edw_stage.t_clm_policy p on p.POLICY_NO = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(clm.POLICY_NO, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32))))
								and p.CASE_ID = clm.CASE_ID
								LEFT JOIN edw_core.tproduct prd ON prd.ebao_product_cd=c.product_code
								left join edw_stage.t_clm_party par on o.CLAIMANT_ID = par.PARTY_ID
								left JOIN edw_stage.t_clm_party_role tcpr on par.PARTY_ROLE = tcpr.ROLE_CODE
								LEFT JOIN edw_stage.t_clm_subclaim_type sct ON o.subclaim_type = sct.subclaim_type_code
								left join edw_stage.migration_exposure_type_mapping ext on ext.product_cd = prd.product_cd
								and ext.coverage_name =  cast(i.coverage_name as varchar(max))
								and ext.subclaim_type_name = cast(sct.subclaim_type_name as varchar(max))
						left join edw_stage.migration_coverage_mapping cov on cov.sub_claimtype_nm = cast(sct.subclaim_type_name as varchar(max))
							and cov.coverage_nm = cast(i.coverage_name as varchar(max)) and cov.product_cd = prd.product_cd
						WHERE
							clm.case_id = c.CASE_ID
						) as ext
					) as a
				for json path, include_null_values
			) as exposures
			,JSON_QUERY((
				select distinct
					 obj.[OBJECT_ID] as id,
                  --  i.item_id as id,
                    cast(cpi.insured_name as varchar(max)) as vinNumber,pivottable.Make as make,pivottable.Model as model,
					pivottable.ModelYear as [year],pivottable.EngineSize as engineSize
				from
                 edw_stage.t_clm_object AS obj 
                 INNER JOIN edw_stage.t_clm_pol_insured cpi ON obj.insured_id = cpi.insured_id
				LEFT JOIN
                (
				SELECT
					acctvo.[UniqueId] as id
					,acctvof.Field
					,acctvof.[Value]
					,acctvo.Id as acctvo_id
					,case_id
				FROM
					(
						select RANK()over(partition by c.claim_no order by acct.PolicyNumber,acct.PolicyChangeNumber desc) as row_no,
							*,c.CASE_ID
						from
							edw_stage.AccountTransaction acct
						where
							acct.PolicyNumber = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(c.policy_no, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32))))
							and acct.[State] = 'Issued'
							and acct.TransactionEffectiveDate < = cast(c.ACCIDENT_TIME as date)
					) acct
					INNER JOIN edw_stage.[AccountTransactionVersion] AS acctv ON acctv.AccountTransactionId = acct.Id
					INNER JOIN edw_stage.[AccountTransactionVersionObject] AS acctvo ON acctvo.AccountTransactionVersionId = acctv.Id
					INNER JOIN edw_stage.[AccountTransactionVersionObjectField] AS acctvof ON acctvof.VersionObjectId = acctvo.id			
				WHERE
					acct.row_no = 1
					and acctvof.Field IN ('VIN','Make','Model','ModelYear','EngineSize','VehicleType','VehicleUsage')
					AND acctvof.[Group] = 'Vehicle'
				) as t
				pivot
				(
					max([Value]) for field in (VIN,ModelYear,Make,Model,EngineSize,VehicleType,VehicleUsage)
				) as pivottable	ON pivottable.case_id = obj.CASE_ID  and pivottable.VIN = cast(cpi.insured_name as varchar(max))                
                LEFT JOIN edw_stage.t_clm_item i ON obj.[object_id] = i.[object_id]
                LEFT JOIN edw_stage.t_clm_subclaim_type sct ON obj.subclaim_type = sct.subclaim_type_code
                LEFT JOIN edw_stage.migration_exposure_type_mapping ext on ext.product_cd = prd.product_cd
						and ext.coverage_name = cast(i.coverage_name as varchar(max))
						and ext.subclaim_type_name = cast(sct.subclaim_type_name as varchar(max))
                -- WHERE  ext.snapsheet_exposure_type not in ('InjuredPerson', 'PipMedPay')
                where
                    obj.CASE_ID = c.CASE_ID
				FOR JSON PATH, INCLUDE_NULL_VALUES
			)) as vehicles
			,(
				select distinct
					p.PARTY_ID as id,
					/*
					--Start - testing below block--01202025--
					CASE 
						WHEN ext.snapsheet_exposure_type IN ('InjuredPerson', 'PipMedPay') 
						THEN CONCAT(CONVERT(VARCHAR, par.PARTY_ID), '-9999')
						ELSE CONVERT(VARCHAR, par.PARTY_ID)
					END AS id, 
					--End - testing below block--01202025--
					*/
					p. claimPartyType,
					-- null as partyType
					p.partyType,
					CASE
						WHEN p.IS_ORG_PARTY != 'Y' THEN
							substring(cast(p.party_name as varchar(255)),1,charindex(' ', cast(p.party_name as varchar(255)))-1)
						end	as firstName,
					CASE
						WHEN p.IS_ORG_PARTY != 'Y' then SUBSTRING(cast(p.party_name as varchar(255)), CHARINDEX(' ', 
						cast(p.party_name as varchar(255))) + 1, LEN(cast(p.party_name as varchar(255)))) 
					end as lastName,
					JSON_QUERY(
							(
								SELECT
								tpa.ADDRESS_LINE_1 as address1,
								tpa.ADDRESS_LINE_2 as address2,
								tpa.CITY as city,
								tpa.POST_CODE as postalCode,
								tpa.[STATE] as [region],
								tpa.country as [country]
								FROM
									edw_stage.t_int_address tia 
									LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID=tpa.ADDRESS_ID
								WHERE
									tia.SOURCE_ID = p.PARTY_ID
								for json path, include_null_values, without_array_wrapper
							)) as [address],
					json_query((
						select *
						from
						(
							select
							'us'  as country,
							'1' as countryCode,
							--'false' as preferredMethod,
							'phone' as [type],
							c.contact_phone as [value]
							--'7272901574' as [value]
							UNION
							SELECT
							null as country,
							null as countryCode,
							--'true' preferredMethod,
							'email' as [type],
							-- 'Farhad.Imam@Vault.Insurance' as [value]
							c.contact_person_email as [value]
						) as a
						for json path, include_null_values
					) ) as contactMethods,
					CASE
						WHEN p.IS_ORG_PARTY = 'Y' THEN cast(p.party_name as varchar(255))
					END AS company,
					-- contact_person_email
					p.PARTY_ID as externalReferenceNumber
				FROM
					(
						select distinct
                        cp.CASE_ID, cp.PARTY_ID,case when ext.snapsheet_exposure_type in ('InjuredPerson', 'PipMedPay') 
                        --and prd.product_cd in ('AU','PEL') 
                        then 'passenger'
                        end as claimPartyType,
                    CASE
                        WHEN pp.IS_ORG_PARTY = 'Y' THEN 'ORGANIZATION'
                        ELSE 'PERSON'
                    END AS partyType,
                    IS_ORG_PARTY,
                   cast(cp. party_name as varchar(max)) as party_name
                    from 
                    edw_stage.t_clm_party cp
                    inner JOIN edw_stage.t_clm_object AS obj on cp.CASE_ID = obj.CASE_ID and cp.PARTY_ID = obj.CLAIMANT_ID
                    LEFT JOIN edw_stage.t_clm_item i ON obj.[object_id] = i.[object_id] 
                    LEFT JOIN edw_stage.t_clm_subclaim_type sct ON obj.subclaim_type = sct.subclaim_type_code
                    LEFT JOIN edw_stage.migration_exposure_type_mapping ext on ext.product_cd = prd.product_cd
                            and ext.coverage_name = cast(i.coverage_name as varchar(max))
                            and ext.subclaim_type_name =  cast(sct.subclaim_type_name as varchar(max))
                    LEFT JOIN edw_stage.t_pty_party pp ON [cp].pty_party_id = pp.party_id
                    where
                        cp.CASE_ID = c.case_id
                    union
                    select 
                        cp.CASE_ID, cp.PARTY_ID ,null as claimPartyType,
                        CASE
                        WHEN pp.IS_ORG_PARTY = 'Y' THEN 'ORGANIZATION'
                        ELSE 'PERSON'
                    END AS partyType,
                    IS_ORG_PARTY,
                    cast(cp. party_name as varchar(max)) as party_name
                    from 
                    edw_stage.t_clm_party cp
                    left JOIN edw_stage.t_clm_object AS obj on cp.CASE_ID = obj.CASE_ID and obj.CLAIMANT_ID= cp.PARTY_ID 
                    LEFT JOIN edw_stage.t_pty_party pp ON [cp].pty_party_id = pp.party_id
                    where
                        cp.CASE_ID = c.case_id
                        and obj.CLAIMANT_ID is null
					) AS p					
				for json path, include_null_values
			) as claimParties,	
			'pending' as api_status
		from
		edw_temp.migration_create_claim_api_temp1 c
		LEFT JOIN edw_stage.t_clm_policy cp ON c.case_id=cp.case_id
		LEFT JOIN edw_core.tpolicy tp ON tp.policy_no = LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(c.policy_no, CHAR(10), CHAR(32)),CHAR(13), CHAR(32)),CHAR(160), CHAR(32)),CHAR(9),CHAR(32)))) -- Added on 01/24/2025
		--INNER JOIN edw_stage.t_clm_losscause clc on clc.LOSS_CAUSE_CODE = c.LOSS_CAUSE
		LEFT JOIN edw_core.tproduct prd ON prd.ebao_product_cd=c.product_code
		LEFT JOIN edw_stage.t_clm_case_status cstat ON c.CASE_STATUS = cstat.STATUS_CODE	
		LEFT JOIN first_open_dt fod on fod.claim_no = c.claim_no
		LEFT JOIN first_close_dt fcd on fcd.claim_no = c.claim_no
		LEFT JOIN open_dt od on od.claim_no = c.claim_no
		LEFT JOIN close_dt cd on cd.claim_no = c.claim_no
		left join 
		(
			SELECT
				subcl.cause_of_loss_cd,
				subcl.sub_cause_of_loss_desc,
				subcl.sub_cause_of_loss_cd
			FROM
			(
				SELECT
				DISTINCT
				REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.CauseofLossCode'),'"','') AS cause_of_loss_cd,
				REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.DisplayValue'),'"','') AS sub_cause_of_loss_desc,
				REPLACE(json_value(cast(DYNAMIC_FIELDS as nvarchar(max)), '$.DataValue'),'"','') AS sub_cause_of_loss_cd
				FROM
				edw_stage.t_dd_busi_data_table_record 
				WHERE DATA_TABLE_ID=98100257349
			) AS subcl
		) as sclc on sclc.cause_of_loss_cd = c.sub_cause_of_loss_code       
		) as t ; 

        insert into edw_stage.migration_create_claim_api
			(
			claimNumber, accidentCode, claimType, [status], policyNumber, firstOpenedAt,firstClosedAt,openedAt,closedAt,
			datetimeOfLoss, datetimeOfNotification,	accountCode, lossType, attachments, notes, claimIncidentDetails, notifier, exposures, 
			vehicles, claimParties, create_ts, api_status
			)
        select
            claimNumber, accidentCode, claimType, [status],policyNumber, firstOpenedAt,firstClosedAt,openedAt,closedAt,
			datetimeOfLoss, datetimeOfNotification, accountCode, lossType, attachments, notes,claimIncidentDetails, notifier, exposures,
            vehicles, claimParties,getdate() as  create_ts,api_status
        from
            edw_temp.migration_create_claim_api_temp2

		SET @rows_affected=@@ROWCOUNT;
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp1
		DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp2		
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