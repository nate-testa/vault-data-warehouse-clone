-- =============================================
-- Author:		Yunus Mohammed
-- Description: This procedures migrats ebao claims to snapsheet
---------------------------------------------------------------------------------------------------
-- Change date 		|Author						|	Change Description
---------------------------------------------------------------------------------------------------
-- 10/24/24			Yunus Mohammed					1. Created this procedure
-- ================================================================================================= 
CREATE OR ALTER   PROCEDURE [edw_core].[sp_migration_create_claim_api]

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

        DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp1;

		SELECT claimNumber, accidentCode,claimType, 
		-- case when [status] = 'OPEN' THEN 'DRAFT' ELSE [status] END AS [status],
		'DRAFT' AS [status],
		policyNumber,
		FORMAT(datetimeOfLoss, 'yyyy-MM-ddTHH:mm:ssZ') as datetimeOfLoss, 
		FORMAT(datetimeOfNotification, 'yyyy-MM-ddTHH:mm:ssZ') as datetimeOfNotification,
		accountCode, lossType,
		attachments, notes,claimIncidentDetails,
		notifier,exposures,
		-- causeOfAccident, incidentComments,
		vehicles, claimParties, getdate() as create_ts,api_status
		INTO edw_temp.migration_create_claim_api_temp1
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
			c.POLICY_NO as policyNumber,
			c.ACCIDENT_TIME as datetimeOfLoss,
			c.NOTICE_TIME as datetimeOfNotification,
			CASE
				WHEN cp.organ_id=1000000000002 THEN 'vault_reciprocal_exchange' 
				WHEN cp.organ_id=1000000000001 THEN 'vault_es_insurance_company' ELSE ''
			END AS accountCode,
			case
				when prd.product_nm in ( 'Condo', 'Homeowners') and c.sub_cause_of_loss_code is null then 'property_claim_other'
			else
				(
					select
						distinct slt.lossType
					from
						edw_stage.migration_loss_type_mapping slt
						where slt.cause_of_loss_cd = c.LOSS_CAUSE and 
						slt.sub_cause_of_loss_cd = isnull( c.sub_cause_of_loss_code,slt.sub_cause_of_loss_cd) and 
						slt.product_cd = prd.product_cd                
				)
			end as lossType,
			(
				select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
			) as attachments,
			(
				select ISNULL( (SELECT 1 as a where 1=2 FOR JSON PATH), '[]')
			) as notes,
			(
				select top 1 pty_party_id as claimPartyId
				from
					edw_stage.t_clm_party p
				where p.[CASE_ID] = c.[CASE_ID] and PARTY_ROLE = '01' 
				-- and cast( p.PARTY_NAME as varchar(max)) = c.CONTACT_NAME
				for json path, include_null_values, without_array_wrapper
			) as notifier,
			(
				select
					cast(c.ACCIDENT_DESC as varchar(max)) as incidentLocationDescription,
					case
					when prd.product_cd in ('HO','CO','LUX') then 'dwelling' 
					when prd.product_cd in ('AU') then 'highway'
					when prd.product_cd in ('PEL') then 'business_address'
					end	as incidentLocationType,
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
			clc.LOSS_CAUSE_NAME as causeOfAccident,
			null as incidentComments,
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
						ISNULL(case when rowNum > 1 and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') then 'Other'
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
							select 	ext.PTY_PARTY_ID as claimPartyId
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
							for json path, include_null_values
						)) as notes,
						JSON_QUERY
						(
							(
								select ext.[OBJECT_ID] as vehicleId 
								where
									prd.product_cd = 'AU'
		--As per Snapsheet, vehicle id should not be present for ('InjuredPerson', 'PipMedPay') exposure types--
									and ext.snapsheet_exposure_type not in ('InjuredPerson', 'PipMedPay')
								for json path, include_null_values, without_array_wrapper
							)
						) as vehicle,			
						JSON_QUERY
						(
							(
								select ext.PTY_PARTY_ID as id,
								ext.PTY_PARTY_ID as [injuredParty.claimPartyId] 
								where
									ext.snapsheet_exposure_type in ('InjuredPerson', 'PipMedPay')
								for json path, include_null_values, without_array_wrapper
							)
						)
							as injuredPerson,
						
						JSON_QUERY((select ext.item_id as id  ,
							'policy_address' as propertyLocation ,
							'personal_property' as propertyType,
							JSON_QUERY((
										select ext.PTY_PARTY_ID as claimPartyId
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
							and ISNULL(case when rowNum > 1 and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') then 'Other'
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
								ISNULL(case when rowNum > 1 and ext.snapsheet_exposure_type in('Dwelling', 'OtherStructures', 'PersonalProperty', 'LivingExpense') then 'Other'
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
									ext.snapsheet_coverage_nm as coverageCode,
									ext.coverage_name as externalCoverageDetails
									-- '2024-06-07' as startDate,
									-- '2025-06-07' as endDate,
									-- 'exposure' as [limits.limitType],
									--100 as [limits.amount],
									-- i.coverage_name as [limits.description],
									-- cov.snapsheet_coverage_cd as [limits.code]
								/*FROM
									edw_stage.t_clm_pol_insured cpi 
									ON  and pivottable.VIN = cast(cpi.insured_name as varchar(max))
								WHERE
									cpi.insured_id = ext.insured_id
								*/
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
							ext.snapsheet_coverage_nm as coverageCode,
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
										ext.snapsheet_coverage_nm as coverageCode,
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
												and pl1.effective_Dt = pl.effective_dt
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
								ext.snapsheet_coverage_nm as coverageCode,
								ext.coverage_name as externalCoverageDetails
								for json path, include_null_values, without_array_wrapper
							)
						)
						END ) as coverage
				
					FROM
						(
							select
								row_number() over(partition by ISNULL(ext.snapsheet_exposure_type,'Other')
									order by ISNULL(ext.snapsheet_exposure_type,'Other')) as rowNum,
								ext.snapsheet_exposure_type,
								cov.snapsheet_coverage_nm,
								o.[OBJECT_ID],
								o.insured_id,
								i.item_id,sct.subclaim_type_name,i.coverage_name,
								i.STATUS_CODE,par.PTY_PARTY_ID,
								prd.product_cd,
								p.policy_no,
								p.eff_date
							from
								edw_stage.t_clm_case clm
								inner join edw_stage.t_clm_object o on clm.CASE_ID = o.CASE_ID
								left join edw_stage.t_clm_item i ON o.[object_id] = i.[object_id]
								left join edw_stage.t_clm_policy p on p.POLICY_NO = clm.POLICY_NO and p.CASE_ID = clm.CASE_ID
								LEFT JOIN edw_core.tproduct prd ON prd.ebao_product_cd=c.product_code
								left join edw_stage.t_clm_party par on o.CLAIMANT_ID = par.PARTY_ID
								left JOIN edw_stage.t_clm_party_role tcpr on par.PARTY_ROLE = tcpr.ROLE_CODE
								LEFT JOIN edw_stage.t_clm_subclaim_type sct ON o.subclaim_type = sct.subclaim_type_code
								left join edw_stage.migration_exposure_type_mapping ext on ext.product_cd = prd.product_cd
								and ext.coverage_name =  cast(i.coverage_name as varchar(max))
								and ext.subclaim_type_name = case
																when cast(i.coverage_name as varchar(max)) = 'Dwelling' then ''
																else cast(sct.subclaim_type_name as varchar(max))
															end
						left join edw_stage.migration_coverage_mapping cov on cov.sub_claimtype_nm = cast(sct.subclaim_type_name as varchar(max))
							and cov.coverage_nm = cast(i.coverage_name as varchar(max)) and cov.product_cd = prd.product_cd
						WHERE
							clm.case_id = c.CASE_ID
						) as ext
					) as a
				for json path, include_null_values
			) as exposures
			,(
				select
					obj.[OBJECT_ID] as id,pivottable.VIN as vinNumber,pivottable.Make as make,pivottable.Model as model,
					pivottable.ModelYear as [year],pivottable.EngineSize as engineSize
					-- ,pivottable.VehicleType as vehicleType,pivottable.VehicleUsage as vehicleUsage
				from
				(
				SELECT
					-- cast(obj.RISK_NAME as varchar(max)) as id
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
							AccountTransaction acct
						where
							acct.PolicyNumber = c.POLICY_NO
							and acct.[State] = 'Issued'
							and acct.EffectiveDate < = cast(c.ACCIDENT_TIME as date)
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
				) as pivottable
				INNER JOIN edw_stage.t_clm_object AS obj ON pivottable.case_id = obj.CASE_ID
				INNER JOIN edw_stage.t_clm_pol_insured cpi ON obj.insured_id = cpi.insured_id and pivottable.VIN = cast(cpi.insured_name as varchar(max))
				FOR JSON PATH, INCLUDE_NULL_VALUES
			) as vehicles
			,(
				select distinct
					par.pty_party_id as id,			
					case when ext.snapsheet_exposure_type in ('InjuredPerson', 'PipMedPay') and prd.product_cd in ('AU','PEL') then 'passenger'end 
					 as claimPartyType,
					-- null as partyType
					CASE
						WHEN pp.IS_ORG_PARTY = 'Y' THEN 'ORGANIZATION'
						ELSE 'PERSON'
					END AS partyType,
					CASE
						WHEN pp.IS_ORG_PARTY != 'Y' THEN
							substring(cast(par.party_name as varchar(255)),1,charindex(' ', cast(par.party_name as varchar(255)))-1)
						end	as firstName,
					CASE
						WHEN pp.IS_ORG_PARTY != 'Y' then SUBSTRING(cast(par.party_name as varchar(255)), CHARINDEX(' ', 
						cast(par.party_name as varchar(255))) + 1, LEN(cast(par.party_name as varchar(255)))) 
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
									tia.SOURCE_ID = pp.PARTY_ID
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
							--c.contact_phone as [value]
							'7272901574' as [value]
							UNION
							SELECT
							null as country,
							null as countryCode,
							--'true' preferredMethod,
							'email' as [type],
							'Farhad.Imam@Vault.Insurance' as [value]
							--c.contact_person_email as [value]
						) as a
						for json path, include_null_values
					) ) as contactMethods,
					CASE
						WHEN pp.IS_ORG_PARTY = 'Y' THEN cast(par.party_name as varchar(255))
					END AS company,
					-- contact_person_email
					par.pty_party_id as externalReferenceNumber
				FROM
					(
						SELECT
							obj.CASE_ID, obj.[object_id],obj.subclaim_type, obj.CLAIMANT_ID AS PARTY_ID
						FROM					
							edw_stage.t_clm_object AS obj
						UNION
						SELECT 
							obj.CASE_ID, obj.[object_id], obj.subclaim_type, settle_payee.PAYEE_ID AS PARTY_ID
						FROM					
							edw_stage.t_clm_object AS obj
							LEFT JOIN edw_stage.t_clm_item i ON obj.[object_id] = i.[object_id]
							INNER JOIN edw_stage.t_clm_reserve_his his on his.ITEM_ID = i.ITEM_ID
							LEFT JOIN edw_stage.t_clm_settle_item settle_item 
									ON his.item_id = settle_item.item_id
									AND his.business_instance_id = settle_item.settle_item_id
							LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id
					) AS p
					LEFT JOIN edw_stage.t_clm_item i ON p.[object_id] = i.[object_id]
					INNER JOIN edw_stage.t_clm_party par on par.PARTY_ID = p.PARTY_ID
					LEFT JOIN edw_stage.t_clm_party_role parole on par.PARTY_ROLE = parole.ROLE_CODE
					LEFT JOIN edw_stage.t_pty_party pp ON par.pty_party_id = pp.party_id
					LEFT JOIN edw_stage.t_pty_party_type ppt ON ppt.party_type = pp.party_type
					LEFT JOIN edw_stage.t_clm_subclaim_type sct ON p.subclaim_type = sct.subclaim_type_code
					LEFT JOIN edw_stage.migration_exposure_type_mapping ext on ext.product_cd = prd.product_cd
						and ext.coverage_name = cast(i.coverage_name as varchar(max))
						and ext.subclaim_type_name = case
															when cast(i.coverage_name as varchar(max)) = 'Dwelling' then ''
															else cast(sct.subclaim_type_name as varchar(max))
														end
				WHERE
					p.CASE_ID = c.case_id 
				for json path, include_null_values
			) as claimParties,	
			'pending' as api_status

		from
		edw_stage.t_clm_case c
		LEFT JOIN edw_stage.t_clm_policy cp ON c.case_id=cp.case_id
		INNER JOIN edw_stage.t_clm_losscause clc on clc.LOSS_CAUSE_CODE = c.LOSS_CAUSE
		LEFT JOIN edw_core.tproduct prd ON prd.ebao_product_cd=c.product_code
		LEFT JOIN edw_stage.t_clm_case_status cstat ON c.CASE_STATUS = cstat.STATUS_CODE
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
		-- where c.claim_no  in('C23HOA00038','C23HOA00009')
		) as t ; 

		
        insert into edw_stage.migration_create_claim_api
			(
			claimNumber, accidentCode, claimType, [status], policyNumber, datetimeOfLoss, datetimeOfNotification,
			accountCode, lossType, attachments, notes, claimIncidentDetails, notifier, exposures, 
			vehicles, claimParties, create_ts, api_status
			)
		
        select
            claimNumber, accidentCode, claimType, [status],policyNumber, datetimeOfLoss, datetimeOfNotification,
            accountCode, lossType, attachments, notes,claimIncidentDetails, notifier, exposures,
            vehicles, claimParties,getdate() as  create_ts,api_status
        from
            edw_temp.migration_create_claim_api_temp1

		DROP TABLE IF EXISTS edw_temp.migration_create_claim_api_temp1

		
		SET @rows_affected=@@ROWCOUNT;
		
		
		-- Update audit table
		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

		-- Drop temp table
		DROP TABLE IF EXISTS edw_temp.nfp_claim_policy_search_api_temp1
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
