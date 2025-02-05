--01202025--WIP on -ve settle change for recoveries--

 -- =================================================================================================
 -- Description: This procedures load table migration_create_financial_transaction_api
 ---------------------------------------------------------------------------------------------------
 -- Change date 				|Author						|	Change Description
 ---------------------------------------------------------------------------------------------------
 --	11-08-2024				Alberto Almario				1. Created procedure
  -- 01-07-2025             Yunus Mohammed        2. payee_type updated to claim_party only
  --01-17-2025              Yunus Mohammed        3. Option 3 --restrict sending -ve payments (stop/cancel/adjusting/etc.)
  --01-20-2025              Yunus Mohammed        4. Updated payment_status (stage)
  --01-23-2025              Yunus Mohammed        5. Sending eBao CANCEL & STOPPED payments
  --01-27-2025              Yunus Mohammed        6. Added TPOLICY  table to get UW Company Name when it's not available in eBao table
  --01-29-2025              Yunus Mohammed        7. Shipping address join updated
  --01-30-2025              Sandeep Gundreddy     8. Added logic to handle stop/cancelled/refund payments
  --01-31-2025              Sandeep Gundreddy     9. Added logic to send $0 reserves for overpayment recovery(refunds in ebao)
  --02-02-2025              Sandeep Gundreddy     10.UseD amount_type in the order by clause in final insert query
  -- 02-05-2025             Yunus Mohammed         11 Used party_id to join migration_create_financial_transaction_api_temp2 to party table
  --                                                                                        and also used claimNumber 
 -- ================================================================================================= 
 
 CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_create_financial_transaction_api]
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

        --************Start************
        
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp0];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp1];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp2];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp3];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp4];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp5];
        DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp6];

        ----------------------------------------------------------
        -- *** Create temp table to extract info to process *** --
        ----------------------------------------------------------
        SELECT 
            claimNumber,
            claimReferenceNumber,
            api_response,
            exposures,
            update_ts as source_table_update_ts
        INTO [edw_temp].[migration_create_financial_transaction_api_temp0]
        FROM edw_stage.migration_create_claim_api
        WHERE 1=1
        AND api_status = 'Success'
        AND api_response is not null
        AND cast(update_ts as datetime2(7)) > @last_source_extract_ts       
        ---------------------------------------------------------------------------------------------
        -- *** Create temp table using CROSS APPLY to extract exposures data from JSON column. *** --
        ---------------------------------------------------------------------------------------------
        SELECT 
            claimNumber,
            claimReferenceNumber,
            exposure.exposureReferenceNumber,
            exposure.externalReferenceNumber,
            substring(exposure.externalReferenceNumber,1,charindex('-',exposure.externalReferenceNumber)-1) as exposure_id,
            source_table_update_ts
        INTO [edw_temp].[migration_create_financial_transaction_api_temp1]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp0]
        CROSS APPLY
            OPENJSON(api_response, '$.exposures')
            WITH (
                exposureReferenceNumber NVARCHAR(100) '$.exposureReferenceNumber',
                externalReferenceNumber NVARCHAR(250) '$.externalReferenceNumber'
            ) AS exposure
        ;

        ------------------------------------------------------------------------------------------------
        -- *** Create temp table using CROSS APPLY to extract claimParties data from JSON column. *** --
        ------------------------------------------------------------------------------------------------
        SELECT 
            claimNumber,
            claimReferenceNumber,
            claimParties.claimPartyReferenceNumber,
            claimParties.externalReferenceNumber
        INTO [edw_temp].[migration_create_financial_transaction_api_temp2]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp0]
        CROSS APPLY
            OPENJSON(api_response, '$.claimParties')
            WITH (
                claimPartyReferenceNumber NVARCHAR(100) '$.claimPartyReferenceNumber',
                externalReferenceNumber NVARCHAR(100) '$.externalReferenceNumber'
            ) AS claimParties
        ;

        ------------------------------------------------------------------------------------------------------
        -- *** Create temp table using CROSS APPLY to extract original exposures data from JSON column. *** --
        ------------------------------------------------------------------------------------------------------
        SELECT 
            claimNumber,
            claimReferenceNumber,
            original_exposures.exposureId,
            original_exposures.exposureType
        INTO [edw_temp].[migration_create_financial_transaction_api_temp3]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp0]
        CROSS APPLY
            OPENJSON(exposures)
            WITH (
                exposureId NVARCHAR(100) '$.id',
                exposureType NVARCHAR(100) '$.exposureType'
            ) AS original_exposures
        ;

        ---------------------------------------------------
        -- *** Create temp table for clm_reserve_his *** --
        ---------------------------------------------------
        SELECT * 
        INTO [edw_temp].[migration_create_financial_transaction_api_temp4]
        FROM (
            SELECT 
                'Reserve_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.[object_id],
                c.case_id,
                resh.his_id, 
                resh.item_id as resh_item_id, 
                resh.business_instance_id, 
                resh.post_date, 
                /*CASE WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN 'RC_00' 
                ELSE resh.reserve_type  END AS */
                resh.reserve_type, 
                /*CASE                   
                     WHEN resh.reserve_type IN ('RC_01', 'RC_02') and resh.outstanding_amount<0 THEN -1 * resh.outstanding_amount  --Snapsheet don't accept -ve reserves
                     WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN settle_changed  --refund payments 
                     ELSE resh.outstanding_amount
                END AS */ 
                outstanding_amount, 
                resh.outstanding_changed, 
                resh.settle_amount, 
                resh.settle_changed,                
                CASE
                    --WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN 'recovery' --refunds are being sent as recovery
                    WHEN resh.reserve_type IN ('RC_01', 'RC_02') THEN 'indemnity'
                    WHEN resh.reserve_type IN ('RC_04', 'RC_05', 'RC_06', 'RC_07') THEN 'recovery'
                END AS financial_transaction_type, 
                CASE
                    WHEN resh.reserve_type IN ('RC_04', 'RC_07') THEN 'subrogation'
                    WHEN resh.reserve_type IN ('RC_05', 'RC_06') THEN 'salvage'
                --    WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN 'overpayment' --refunds are being sent as overpayment recovery
                END AS reserve_method,
				c.POLICY_NO -- Added on 01/24/2024
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            LEFT JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            LEFT JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id 
            LEFT JOIN edw_stage.t_clm_settle_item settle_item ON resh.item_id = settle_item.item_id AND resh.business_instance_id = settle_item.settle_item_id
            LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id		
            WHERE ((resh.reserve_type in ('RC_01','RC_02') and resh.outstanding_amount>=0) or (resh.reserve_type in ('RC_04','RC_05','RC_06','RC_07') ) ) 	
 --           WHERE resh.outstanding_amount > 0 --disabled on 01172025 to push zero reserve amount--
            UNION ALL 
            SELECT 
                'Reserve_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.[object_id],
                c.case_id,
                resh.his_id, 
                resh.item_id as resh_item_id, 
                resh.business_instance_id, 
                resh.post_date, 
                /*CASE WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN 'RC_00' 
                ELSE resh.reserve_type  END AS */
                resh.reserve_type, 
                settle_changed  --refund payments 
                     AS outstanding_amount, 
                resh.outstanding_changed, 
                resh.settle_amount, 
                resh.settle_changed,                
                'recovery' AS financial_transaction_type, 
                'overpayment' --refunds are being sent as overpayment recovery
                 AS reserve_method,
				c.POLICY_NO -- Added on 01/24/2024
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            LEFT JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            LEFT JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id 
            LEFT JOIN edw_stage.t_clm_settle_item settle_item ON resh.item_id = settle_item.item_id AND resh.business_instance_id = settle_item.settle_item_id
            LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id			
            WHERE resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0
            UNION ALL --- creating $0 reserve transaction for refunds
            SELECT 
                'Reserve_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.[object_id],
                c.case_id,
                resh.his_id, 
                resh.item_id as resh_item_id, 
                resh.business_instance_id, 
                resh.post_date, 
                /*CASE WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 THEN 'RC_00' 
                ELSE resh.reserve_type  END AS */
                resh.reserve_type, 
                0  AS outstanding_amount, --refund payments 
                resh.outstanding_changed, 
                resh.settle_amount, 
                resh.settle_changed,                
                'recovery' AS financial_transaction_type, 
                'overpayment' --refunds are being sent as overpayment recovery
                 AS reserve_method,
				c.POLICY_NO -- Added on 01/24/2024
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            LEFT JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            LEFT JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id 
            LEFT JOIN edw_stage.t_clm_settle_item settle_item ON resh.item_id = settle_item.item_id AND resh.business_instance_id = settle_item.settle_item_id
            LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id			
            WHERE resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0
            UNION ALL
            SELECT 
                'Payment_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.[object_id],
                c.case_id,
                resh.his_id, 
                resh.item_id as resh_item_id, 
                resh.business_instance_id, 
                resh.post_date, 
                resh.reserve_type, 
                resh.outstanding_amount, 
                resh.outstanding_changed, 
                resh.settle_amount, 
                resh.settle_changed, 
                CASE
                    WHEN resh.reserve_type IN ('RC_01', 'RC_02') THEN 'indemnity'
                    WHEN resh.reserve_type IN ('RC_04', 'RC_05', 'RC_06', 'RC_07') THEN 'recovery'
                END AS financial_transaction_type,
                CASE
                    WHEN resh.reserve_type IN ('RC_04', 'RC_07') THEN 'subrogation'
                    WHEN resh.reserve_type IN ('RC_05', 'RC_06') THEN 'salvage'
                END AS reserve_method,
				c.POLICY_NO -- Added on 01/24/2024
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            INNER JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            INNER JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            INNER JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            INNER JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id
            -- WHERE resh.outstanding_changed < 0
            -- 12_09_2024
            WHERE ((resh.reserve_type in ('RC_01','RC_02') and resh.SETTLE_CHANGED>0) or (resh.reserve_type in ('RC_04','RC_05','RC_06','RC_07') and resh.SETTLE_CHANGED!=0) ) 
                        --excluding stop/cancelled loss and expense payments; instead of passing 2 transactions just first transaction is being passed on stopped 
                --resh.SETTLE_CHANGED != 0 -- Option 2 --WIP-01202025--
--            WHERE resh.SETTLE_CHANGED > 0 -- Option 3 --added on 01172025 to restrict sending -ve payments (stop/cancel/adjusting/etc.)
            UNION ALL --Refund payments sent as overpayment recovery
            SELECT 
                'Payment_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.[object_id],
                c.case_id,
                resh.his_id, 
                resh.item_id as resh_item_id, 
                resh.business_instance_id, 
                resh.post_date, 
                resh.reserve_type, 
                resh.outstanding_amount, 
                resh.outstanding_changed, 
                resh.settle_amount, 
                resh.settle_changed, 
                'recovery' AS financial_transaction_type,
                'overpayment' AS reserve_method,
				c.POLICY_NO 
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            INNER JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            INNER JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            INNER JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            INNER JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id 
            LEFT JOIN edw_stage.t_clm_settle_item settle_item ON resh.item_id = settle_item.item_id AND resh.business_instance_id = settle_item.settle_item_id
            LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id	
            WHERE  resh.reserve_type IN ('RC_01', 'RC_02') AND settle_payee.payment_status='PENDING' AND resh.settle_changed<0 
        ) tbl
        ;

        ---------------------------------------------------------------------
        -- *** Create temp table to extract info from edw_state tables *** --
        ---------------------------------------------------------------------
        SELECT
            resh.amount_type,
            resh.claimNumber,
            resh.claimReferenceNumber,
            resh.source_table_update_ts,
            resh.his_id,
            resh.ITEM_ID,
            resh.post_date, 
            resh.outstanding_amount,
            resh.outstanding_changed,
            resh.settle_amount,
            resh.settle_changed,
            'financial_transaction' AS [data.type],
            CASE
                WHEN cp.organ_id = 1000000000002 THEN 'vault_reciprocal_exchange'
                WHEN cp.organ_id = 1000000000001 THEN 'vault_es_insurance_company'
				WHEN tp.uw_company_nm='Vault Reciprocal Exchange' THEN 'vault_reciprocal_exchange' -- Added on 01/24/2025
				WHEN tp.uw_company_nm='Vault E & S Insurance Company' THEN 'vault_es_insurance_company' -- Added on 01/24/2025
                ELSE ''
            END AS [data.attributes.accountCode],
            null as [data.attributes.original_transaction_id],
            resh.post_date AS [data.attributes.originated_at],
            resh.financial_transaction_type AS [data.attributes.financial_transaction_type],
            CASE WHEN amount_type = 'Payment_Amount' THEN settle_payee.settle_payee_id ELSE resh.his_id END AS [data.attributes.remote_identifier],
/*
            case when settle_payee.PAY_MODE = '100' then ''
            when settle_payee.PAY_MODE = '101' then 'check'
            when settle_payee.PAY_MODE = '110' then 'One Inc Payment'
            when settle_payee.PAY_MODE = '106' then 'Bank Transfer'
*/
            'check' AS [data.attributes.payment_method],
            CASE WHEN amount_type = 'Payment_Amount' THEN CAST(1 AS BIT) END AS [data.attributes.is_historical],
		    CASE
--				WHEN payment_status in ('ISSUED','IN_PROGRESS','PENDING','SUBMITTED_TO_ONE_INC') THEN 'issued' --commented out on 01182025 cause added below--
				WHEN payment_status in ('ISSUED','IN_PROGRESS','PENDING','SUBMITTED_TO_ONE_INC') and resh.financial_transaction_type = 'recovery' THEN 'submitted' --added on 01182025--
				WHEN payment_status in ('ISSUED','IN_PROGRESS','PENDING','SUBMITTED_TO_ONE_INC') and resh.financial_transaction_type != 'recovery' THEN 'issued' --added on 01182025--
				WHEN payment_status = 'SUCCESS' THEN 'cleared'
				WHEN payment_status = 'ERROR' THEN 'failed'
				WHEN payment_status = 'CANCEL' THEN 'cancelled' 
--                WHEN payment_status = 'CANCEL'  and settle_changed > 0 then 'issued' -- This is to migrate eBao CANCEL & STOPPED payments - 01232025
--                WHEN payment_status in ('CANCEL', 'STOP', 'STOP_PENDING') and settle_changed > 0 THEN 'issued' -- This is to migrate eBao CANCEL & STOPPED payments - 01232025
                WHEN payment_status in ('STOP', 'STOP_PENDING') then 'stopped' 
 --               else 'cancelled' --added on 01172025 cause some claims initial payment transaction status has been updated to cancel when actual cancellation transaction came in--
			END
           AS [data.attributes.stage],
            CAST(1 AS BIT) AS [data.attributes.is_notification_only], 
            CAST(resh.exposureReferenceNumber AS VARCHAR(255)) AS exposure_id,
            resh.outstanding_amount AS reserve_amt,
            'unspecified' AS cost_category,
            LOWER(et.exposureType) +
                CASE
                    WHEN resh.reserve_type IN ('RC_01', 'RC_04', 'RC_05') THEN '_claim'
                    WHEN resh.reserve_type IN ('RC_02', 'RC_06', 'RC_07') THEN '_adjusting'
                END AS cost_type,
            CASE
                WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle.claim_type = 'LOS' AND settle_changed > 0 THEN settle_changed
				WHEN resh.RESERVE_TYPE IN ('RC_03','RC_04','RC_06','RC_07') THEN settle_changed
				WHEN resh.reserve_type='RC_05' OR 
                (
                        resh.reserve_type='RC_01' AND claim_type LIKE '%SAL%' AND 
						CAST(SETTLE_payee.payee_name AS VARCHAR(MAX))='Copart'
                ) THEN settle_changed
				WHEN (resh.reserve_type='RC_01' AND claim_type='LOS' AND settle_changed < 0 )
					OR (resh.reserve_type ='RC_01' AND claim_type LIKE '%SAL%' AND CAST(settle_payee.payee_name AS VARCHAR(MAX)) NOT IN ('Copart')) THEN settle_changed
				WHEN resh.reserve_type='RC_02' AND 
					(
						(claim_type = 'LOS' AND settle_changed < 0)
						OR
						(claim_type ='LOS,SAL,SUB'  AND settle_changed != 0 )
					) THEN settle_changed
            END AS paid_amt,
            CASE
                WHEN settle_item.pay_final = 4 THEN 'final'
                ELSE 'partial'
            END AS payment_type,
            resh.reserve_type,
            resh.reserve_method,
            REPLACE(REPLACE(JSON_VALUE(CAST(pty.DYNAMIC_FIELDS AS NVARCHAR(MAX)),'$.MobileTel'),'-',''),'+','') AS [payee_phone_no],
            'phone' AS [payee_contact_type],
            --'Farhad.Imam@Vault.Insurance' AS [payee_email],
			JSON_VALUE(CAST(pty.DYNAMIC_FIELDS AS NVARCHAR(MAX)),'$.Email') AS [payee_email],
            p.claimPartyReferenceNumber AS PAYEE_ID,
          -- party.pty_PARTY_ID AS PAYEE_ID,
/*
            CASE 
                WHEN party_role.ROLE_CODE in ('02','03','05','06','08','10','15','16','19','21','22','23') THEN 'vendor' 
                ELSE 'claim_party' 
            END AS payee_type,
*/
            'claim_party' as payee_type, --added on 01172025
            'standard' AS [data.attributes.shipping_option],
            party.PARTY_NAME AS [name],
            tpa.ADDRESS_LINE_1 AS [address1],
            tpa.CITY AS [city],
            tpa.POST_CODE AS [postal_code],
            tpa.[STATE] AS [region],
            tpa.COUNTRY AS [country]
        INTO [edw_temp].[migration_create_financial_transaction_api_temp5]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp4] resh
        LEFT JOIN edw_stage.t_clm_policy cp ON resh.case_id = cp.case_id
		LEFT JOIN edw_core.tpolicy tp ON tp.policy_no = resh.POLICY_NO -- Added on 01/24/2025
        LEFT JOIN edw_stage.t_clm_settle_item settle_item 
            ON resh.item_id = settle_item.item_id
            AND resh.business_instance_id = settle_item.settle_item_id
        LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id
        LEFT JOIN edw_stage.t_clm_settle settle ON settle.settle_id = settle_payee.settle_id
        LEFT JOIN edw_stage.t_clm_party party ON party.PARTY_ID = settle_payee.PAYEE_ID
        LEFT JOIN edw_stage.t_pty_party pty on pty.PARTY_ID = party.PTY_PARTY_ID
        LEFT JOIN edw_stage.t_clm_party_role party_role on party_role.ROLE_CODE = party.PARTY_ROLE 
        -- LEFT JOIN edw_stage.t_int_address tia ON tia.source_id = resh.case_id -- commented on 01/29/2025
        -- LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID = tpa.ADDRESS_ID -- commented on 01/29/2025
        LEFT JOIN edw_stage.t_pub_address tpa on tpa.ADDRESS_ID= settle_payee.PTY_ADDRESS_ID -- added on 01/29/2025
        LEFT JOIN [edw_temp].[migration_create_financial_transaction_api_temp2] p 
            ON party.PARTY_ID = p.externalReferenceNumber 
            and resh.claimNumber = p.claimNumber
        INNER JOIN [edw_temp].[migration_create_financial_transaction_api_temp3] et
            ON resh.exposure_id = et.exposureId
            AND resh.claimNumber = et.claimNumber
            AND resh.claimReferenceNumber = et.claimReferenceNumber
        ;

        ---------------------------------------------------------------------
        -- *** Create temp table to prepare the final JSON data column *** --
        ---------------------------------------------------------------------
        SELECT
            HIS_ID,
            post_date, 
            claimNumber AS claim_no,
            item_id,
            [data.attributes.remote_identifier],
            cost_type,
            outstanding_amount,
            outstanding_changed,
            settle_amount,
            settle_changed,
            reserve_type,
            reserve_method,
            CAST(reserve_amt AS VARCHAR(255)) AS amount,
            CAST(paid_amt AS VARCHAR(255)) AS paid_amt,
            case when amount_type='Reserve_Amount' then reserve_amt else paid_amt end as reserve_paid_amount,
            amount_type,
            CASE
                -- Reserve Section - Remove Payment Information -- 
                WHEN amount_type = 'Reserve_Amount' THEN 
                (
                    SELECT
                        [data.type],
                        [data.attributes.accountCode],
                        [data.attributes.financial_transaction_type],
                        [data.attributes.remote_identifier],
--11/15/2024                        [data.attributes.originated_at],
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT
                                        exposure_id,
                                        CAST(
                                                CASE
                                                WHEN [data.attributes.financial_transaction_type] = 'recovery' and reserve_amt < 0 
                                                THEN
                                                    reserve_amt * -1
                                                ELSE
                                                    reserve_amt
                                                END
                                             AS VARCHAR(255)                                            
                                            ) AS amount,
                                        cost_category,
                                        cost_type,
                                        reserve_method
--                                        'Migrated' as note --removed on 01172025 because it's creating additional row in notes table
                                    -- WHERE reserve_amt > 0
                                    FOR JSON PATH, INCLUDE_NULL_VALUES
                                )
                            ), '[]'
                        ) AS [data.attributes.reserve_items],
                        claimReferenceNumber AS [data.relationships.claim.data.id],
                        'claim' AS [data.relationships.claim.data.type]
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                ) 
                -- Payment Section --
                WHEN amount_type = 'Payment_Amount' THEN 
               JSON_MODIFY( (
                    SELECT
                        [data.type],
                        [data.attributes.accountCode],
                        [data.attributes.financial_transaction_type],
                        [data.attributes.remote_identifier],
                        [data.attributes.originated_at],
--11/15/2024                        [data.attributes.original_transaction_id],
                        [data.attributes.is_historical],
                        [data.attributes.is_notification_only],  
                        [data.attributes.stage],
                        CASE
                            WHEN paid_amt != 0
                                THEN [data.attributes.payment_method]
                        END AS [data.attributes.payment_method],
                        CASE WHEN paid_amt != 0  AND [data.attributes.financial_transaction_type] != 'recovery' 
                            THEN [data.attributes.shipping_option] END AS [data.attributes.shipping_option],
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT
                                        exposure_id,                                        
                                        CAST
                                        (
                                            CASE
                                                WHEN [data.attributes.financial_transaction_type] = 'recovery' and paid_amt < 0 
                                                THEN
                                                    paid_amt * -1
                                                ELSE
                                                    paid_amt
                                                END
                                             AS VARCHAR(255)
                                        ) AS amount,
                                        cost_category,
                                        cost_type,
                                        payment_type
                                    WHERE
                                        paid_amt != 0
                                    FOR JSON PATH, INCLUDE_NULL_VALUES
                                )
                            ), '[]'
                        ) AS [data.attributes.payment_items],                        
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT
                                        [name],
                                        [address1],
                                        [city],
                                        [postal_code],
                                        [region],
                                        [country]
                                    WHERE
                                        paid_amt != 0
                                        and [data.attributes.payment_method] in ('check','self_select')
                                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                                )
                            ), '{}'
                        ) AS [data.attributes.shipping_address],
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT *
                                    FROM
                                    (
                                        SELECT
                                            payee_phone_no AS [value],
                                            'us' AS [country],
                                            'phone' AS [contact_type]
                                        WHERE
                                            paid_amt != 0
                                        UNION
                                        SELECT
                                            payee_email AS [value],
                                            'us' AS [country],
                                            'email' AS [contact_type]
                                        WHERE
                                            paid_amt != 0
                                    ) AS a
                                    FOR JSON PATH, INCLUDE_NULL_VALUES
                                )
                            ), '[]'
                        ) AS [data.attributes.payee.contact_methods],
                        JSON_QUERY(
                            (
                                SELECT
                                    PAYEE_ID AS [id],
                                    payee_type AS [type]
                                WHERE
                                    PAYEE_ID IS NOT NULL
                                FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                            )
                        ) AS [data.relationships.original_payee.data],
                        claimReferenceNumber AS [data.relationships.claim.data.id],
                        'claim' AS [data.relationships.claim.data.type]
                    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER
                ),'$.data.attributes.payment_method', 
                case when [data.attributes.financial_transaction_type] = 'recovery' then null ELSE
                [data.attributes.payment_method]
                END
                )
            END AS [data],
            'pending' AS api_status,
            GETDATE() AS create_ts,
            source_table_update_ts
        INTO [edw_temp].[migration_create_financial_transaction_api_temp6]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp5] a
        WHERE ISNULL(reserve_amt,0) != 0 OR ISNULL(paid_amt,0) != 0
        ORDER BY his_id
        ;

       --  Start Insert process
         INSERT INTO edw_stage.migration_create_financial_transaction_api
         (
             claim_no, 
             reserve_type, POST_DATE, ITEM_ID, remote_identifier, HIS_ID, amount_type,
             create_ts,
             api_status,
             [data]
         )	
         SELECT
             claim_no, 
             reserve_type, POST_DATE, ITEM_ID, [data.attributes.remote_identifier], HIS_ID, amount_type,
             create_ts,
             api_status,
             [data]
         FROM [edw_temp].[migration_create_financial_transaction_api_temp6]
         where ISNULL(reserve_method,'XX')!='overpayment'
         ORDER BY claim_no, ITEM_ID, post_date,reserve_type,HIS_ID,amount_type;

        INSERT INTO edw_stage.migration_create_financial_transaction_api
         (
             claim_no, 
             reserve_type, POST_DATE, ITEM_ID, remote_identifier, HIS_ID, amount_type,
             create_ts,
             api_status,
             [data]
         )
            SELECT
             claim_no, 
             reserve_type, POST_DATE, ITEM_ID, [data.attributes.remote_identifier], HIS_ID, amount_type,
             create_ts,
             api_status,
             [data]
         FROM [edw_temp].[migration_create_financial_transaction_api_temp6]
         where reserve_method='overpayment'
         ORDER BY claim_no, ITEM_ID, post_date,reserve_type,HIS_ID,reserve_paid_amount,amount_type desc ;

        --************End************

 		SET @rows_affected=@@ROWCOUNT;

 		-- Update control table
 		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(source_table_update_ts) FROM [edw_temp].[migration_create_financial_transaction_api_temp4]),@last_source_extract_ts);
         EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
 		-- Update audit table
 		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
 		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;
		
         -- Drop temp table
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp0];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp1];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp2];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp3];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp4];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp5];
         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp6];

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