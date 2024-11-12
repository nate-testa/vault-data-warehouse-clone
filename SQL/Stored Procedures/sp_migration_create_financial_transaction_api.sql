-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO

-- -- =================================================================================================
-- -- Description: This procedures load table migration_create_financial_transaction_api
-- ---------------------------------------------------------------------------------------------------
-- -- Change date 				|Author						|	Change Description
-- ---------------------------------------------------------------------------------------------------
-- --	11-08-2024				Alberto Almario				1. Created procedure
-- -- ================================================================================================= 
-- CREATE OR ALTER PROCEDURE [edw_core].[sp_migration_create_financial_transaction_api]
-- AS
-- BEGIN
--     -- SET NOCOUNT ON added to prevent extra result sets from
--     -- interfering with SELECT statements.
--     SET NOCOUNT ON

-- 	BEGIN TRY
-- 		DECLARE @last_source_extract_ts DATETIME2(7)
-- 		DECLARE @etl_audit_sk INT
-- 		DECLARE @new_last_source_extract_ts DATETIME2(7)
-- 		DECLARE @rows_affected INT
-- 		DECLARE @process_nm VARCHAR(255)=OBJECT_NAME(@@PROCID)
-- 		DECLARE @current_date DATETIME=GETDATE()
-- 		DECLARE @parameter_desc VARCHAR(255)
-- 		-- Get last source extract date
-- 		SELECT @last_source_extract_ts = edw_core.fn_get_last_source_extract_ts(@process_nm);
-- 		EXEC edw_core.sp_ins_tetl_audit @process_nm,@current_date,@etl_audit_sk=@etl_audit_sk OUTPUT;
-- 		SET @parameter_desc= 'last_source_extract_ts >' + CAST(@last_source_extract_ts AS VARCHAR(200))

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
        -- AND cast(update_ts as datetime2(7)) > @last_source_extract_ts
        AND claimNumber = 'C24HOA00064'--'C24HOA00074'


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
                o.object_id,
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
                    WHEN resh.reserve_type IN ('RC_01', 'RC_02', 'RC_03') THEN 'indemnity'
                    WHEN resh.reserve_type IN ('RC_04', 'RC_05', 'RC_06', 'RC_07') THEN 'recovery'
                END AS financial_transaction_type, 
                CASE
                    WHEN resh.reserve_type IN ('RC_04', 'RC_07') THEN 'subrogation'
                    WHEN resh.reserve_type IN ('RC_05', 'RC_06') THEN 'salvage'
                END AS reserve_method
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            LEFT JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            LEFT JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id
            UNION ALL
            SELECT 
                'Payment_Amount' AS amount_type,
                t.exposure_id,
                t.claimNumber,
                t.claimReferenceNumber,
                t.exposureReferenceNumber,
                t.source_table_update_ts,
                i.item_id,
                o.object_id,
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
                    WHEN resh.reserve_type IN ('RC_01', 'RC_02', 'RC_03') THEN 'indemnity'
                    WHEN resh.reserve_type IN ('RC_04', 'RC_05', 'RC_06', 'RC_07') THEN 'recovery'
                END AS financial_transaction_type,
                CASE
                    WHEN resh.reserve_type IN ('RC_04', 'RC_07') THEN 'subrogation'
                    WHEN resh.reserve_type IN ('RC_05', 'RC_06') THEN 'salvage'
                END AS reserve_method
            FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
            LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
            LEFT JOIN edw_stage.t_clm_object o ON i.object_id = o.object_id
            LEFT JOIN edw_stage.t_clm_case c ON o.case_id = c.case_id
            LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id
            WHERE resh.outstanding_changed < 0
            -- WHERE rest.settle_amount > 0 -- Option 2
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
            resh.outstanding_amount,
            resh.outstanding_changed,
            resh.settle_amount,
            resh.settle_changed,
            'financial_transaction' AS [data.type],
            CASE
                WHEN cp.organ_id = 1000000000002 THEN 'vault_reciprocal_exchange'
                WHEN cp.organ_id = 1000000000001 THEN 'vault_es_insurance_company'
                ELSE ''
            END AS [data.attributes.accountCode],
            null as [data.attributes.original_transaction_id],
            resh.post_date AS [data.attributes.originated_at],
            resh.financial_transaction_type AS [data.attributes.financial_transaction_type],
            resh.item_id AS [data.attributes.remote_identifier],
            'check' AS [data.attributes.payment_method],
            CAST(1 AS BIT) AS [data.attributes.is_historical],
            CAST(resh.exposureReferenceNumber AS VARCHAR(255)) AS exposure_id,
            resh.outstanding_amount AS reserve_amt,
            'unspecified' AS cost_category,
            LOWER(et.exposureType) +
                CASE
                    WHEN resh.reserve_type IN ('RC_01', 'RC_04', 'RC_05') THEN '_claim'
                    WHEN resh.reserve_type IN ('RC_02', 'RC_03', 'RC_05', 'RC_06') THEN '_adjusting'
                END AS cost_type,
            CASE
                WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle.claim_type = 'LOS' AND settle_changed > 0 THEN settle_changed
                ELSE 0
            END AS paid_amt,
            CASE
                WHEN settle_item.pay_final = 4 THEN 'final'
                ELSE 'partial'
            END AS payment_type,
            resh.reserve_method,
            '7272900434' AS [payee_phone_no],
            'phone' AS [payee_contact_type],
            'Farhad.Imam@Vault.Insurance' AS [payee_email],
            p.claimPartyReferenceNumber AS PAYEE_ID,
            CASE 
                WHEN party_role.ROLE_CODE in (02,03,05,06,08,10,15,16,19,21,22,23) THEN 'vendor' 
                ELSE 'claim_party' 
            END AS payee_type,
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
        LEFT JOIN edw_stage.t_clm_settle_item settle_item 
            ON resh.item_id = settle_item.item_id
            AND resh.business_instance_id = settle_item.settle_item_id
        LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id
        LEFT JOIN edw_stage.t_clm_settle settle ON settle.settle_id = settle_payee.settle_id
        LEFT JOIN edw_stage.t_clm_party party ON party.PARTY_ID = settle_payee.PAYEE_ID
        LEFT JOIN edw_stage.t_clm_party_role party_role on party_role.ROLE_CODE = party.PARTY_ROLE 
        LEFT JOIN edw_stage.t_int_address tia ON tia.source_id = resh.case_id
        LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID = tpa.ADDRESS_ID
        LEFT JOIN [edw_temp].[migration_create_financial_transaction_api_temp2] p 
            ON party.pty_PARTY_ID = p.externalReferenceNumber
        LEFT JOIN [edw_temp].[migration_create_financial_transaction_api_temp3] et
            ON resh.exposure_id = et.exposureId
            AND resh.claimNumber = et.claimNumber
            AND resh.claimReferenceNumber = et.claimReferenceNumber
        ;


        ---------------------------------------------------------------------
        -- *** Create temp table to prepare the final JSON data column *** --
        ---------------------------------------------------------------------
        SELECT
            HIS_ID,
            claimNumber AS claim_no,
            [data.attributes.remote_identifier],
            cost_type,
            outstanding_amount,
            outstanding_changed,
            settle_amount,
            settle_changed,
            CAST(reserve_amt AS VARCHAR(255)) AS amount,
            CAST(paid_amt AS VARCHAR(255)) AS paid_amt,
            amount_type,
            CASE
                -- Reserve Section - Remove Payment Information -- 
                WHEN amount_type = 'Reserve_Amount' THEN 
                (
                    SELECT
                        [data.type],
                        [data.attributes.accountCode],
                        [data.attributes.financial_transaction_type],
                        CASE 
                            WHEN paid_amt != 0 THEN NULL 
                            ELSE [data.attributes.remote_identifier]
                        END AS [data.attributes.remote_identifier],
                        [data.attributes.originated_at],
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT
                                        exposure_id,
                                        CAST(reserve_amt AS VARCHAR(255)) AS amount,
                                        cost_category,
                                        cost_type,
                                        reserve_method
                                    WHERE
                                        reserve_amt > 0
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
                (
                    SELECT
                        [data.type],
                        [data.attributes.accountCode],
                        [data.attributes.financial_transaction_type],
                        [data.attributes.remote_identifier],
                        [data.attributes.originated_at],
                        [data.attributes.original_transaction_id],
                        [data.attributes.is_historical],
                        CASE WHEN paid_amt != 0 THEN [data.attributes.payment_method] END AS [data.attributes.payment_method],
                        CASE WHEN paid_amt != 0 THEN [data.attributes.shipping_option] END AS [data.attributes.shipping_option],
                        ISNULL(
                            JSON_QUERY(
                                (
                                    SELECT
                                        exposure_id,
                                        CAST(paid_amt AS VARCHAR(255)) AS amount,
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
                )
            END AS [data],
            'pending' AS api_status,
            GETDATE() AS create_ts,
            source_table_update_ts
        INTO [edw_temp].[migration_create_financial_transaction_api_temp6]
        FROM [edw_temp].[migration_create_financial_transaction_api_temp5] a
        WHERE reserve_amt != 0 OR paid_amt != 0
        ORDER BY his_id
        ;

        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp0];
        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp1];
        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp2];
        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp3];
        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp4];
        -- SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp5] order by his_id;
        SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp6] ORDER BY [data.attributes.remote_identifier], HIS_ID, amount_type;


        -- * Start Insert process
        -- INSERT INTO edw_stage.migration_create_financial_transaction_api
        -- (
        --     claim_no, 
        --     create_ts,
        --     api_status,
        --     [data]
        -- )
        -- SELECT 
        --     claim_no, 
        --     create_ts,
        --     api_status,
        --     [data]
        -- FROM [edw_temp].[migration_create_financial_transaction_api_temp5]

        --************End************

-- 		SET @rows_affected=@@ROWCOUNT;

		
-- 		-- Update control table
-- 		SET @new_last_source_extract_ts=COALESCE((SELECT MAX(source_table_update_ts) FROM [edw_temp].[migration_create_financial_transaction_api_temp4]),@last_source_extract_ts);
--         EXEC edw_core.sp_upd_tetl_control @process_nm,@new_last_source_extract_ts;
-- 		-- Update audit table
-- 		SET @parameter_desc= @parameter_desc + ' AND last_source_extract_ts <=' + CAST(@new_last_source_extract_ts AS VARCHAR(200))
-- 		EXEC edw_core.sp_upd_tetl_audit @etl_audit_sk,@rows_affected,@parameter_desc;

--         -- Drop temp table
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp0];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp1];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp2];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp3];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp4];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp5];
--         DROP TABLE IF EXISTS [edw_temp].[migration_create_financial_transaction_api_temp6];

-- 	END TRY
-- 	BEGIN CATCH
-- 		DECLARE @error_message nvarchar(4000)
-- 		SET @error_message = 'Error Number:' + ISNULL(CAST(ERROR_NUMBER() AS NVARCHAR(100)),'') + 
-- 						    ' Error State:' + ISNULL(CAST(ERROR_STATE() AS NVARCHAR(100)),'')
-- 							+ ' Error Severity:' + ISNULL(CAST(ERROR_SEVERITY() AS NVARCHAR(100)),'') +
-- 							CHAR(13) + 'Error Procedure:' + ISNULL(ERROR_PROCEDURE(),'') + ' Error Line:' + ISNULL(CAST(ERROR_LINE() AS NVARCHAR(100)),'') +
-- 							CHAR(13) + 'Error Message:' + ISNULL(ERROR_MESSAGE(),'')
	
-- 		EXEC [edw_core].[sp_upd_error_tetl_audit] @etl_audit_sk,@error_message;

-- 		THROW 99001,'Error occured: see tetl_audit table for more info', 1;
	
--     END CATCH
-- END
