SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp0];
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp1];
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp2];
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp3];
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp4];
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp5] order by his_id;
SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp6] ORDER BY [data.attributes.remote_identifier], HIS_ID, amount_type;

select count(1) from edw_stage.t_clm_reserve_his;

SELECT POST_DATE, HIS_ID, ITEM_ID,
        'Reserve_Amount' AS Amt_Type, OUTSTANDING_AMOUNT AS Amt, 2 AS SortOrder
    -- Add a computed column to control the order
    FROM edw_stage.t_clm_reserve_his
    WHERE ITEM_ID IN (17575971, 17575972, 17576116, 17576117, 17576118, 17576142, 17576143, 17576144) --= 17575971
        AND OUTSTANDING_AMOUNT IS NOT NULL AND SETTLE_AMOUNT IS NOT NULL
UNION ALL
    SELECT POST_DATE, HIS_ID, ITEM_ID,
        'Payment_Amount' AS Amt_Type, SETTLE_AMOUNT AS Amt, 1 AS SortOrder
    -- Add a computed column to control the order
    FROM edw_stage.t_clm_reserve_his
    WHERE ITEM_ID IN (17575971, 17575972, 17576116, 17576117, 17576118, 17576142, 17576143, 17576144) --= 17575971
        AND OUTSTANDING_AMOUNT IS NOT NULL AND SETTLE_AMOUNT IS NOT NULL
        AND SETTLE_AMOUNT > 0
ORDER BY POST_DATE, SortOrder ;

select POST_DATE, * from edw_stage.t_clm_reserve_his
-- where ITEM_ID in (17575971, 17575972, 17576116, 17576117, 17576118, 17576142, 17576143, 17576144)
where item_id = 16954054
order by ITEM_ID, 1 ;

select his_id, item_id, business_instance_id, post_date, reserve_type, outstanding_amount, outstanding_changed, settle_amount, settle_changed, 'reserve' as trans_type from edw_stage.t_clm_reserve_his
union all
select his_id, item_id, business_instance_id, post_date, reserve_type, outstanding_amount, outstanding_changed, settle_amount, settle_changed, 'payment' as trans_type from edw_stage.t_clm_reserve_his where outstanding_changed < 0
;

select top 10 * from edw_stage.t_clm_reserve_his;

select POST_DATE, OUTSTANDING_AMOUNT, * 
from edw_stage.t_clm_reserve_his
where 1=1
and SETTLE_CHANGED != 0
;

select POST_DATE, * from edw_stage.t_clm_reserve_his
where ITEM_ID = 16954054
order by ITEM_ID ;

SELECT * FROM edw_stage.t_clm_item
WHERE ITEM_ID = 16954054
;

SELECT * FROM edw_stage.t_clm_settle_item
WHERE ITEM_ID = 16954054
;

SELECT * FROM [edw_temp].[migration_create_financial_transaction_api_temp1] where exposure_id = 16954053;

------------------------------------------------------------------------------------------------------------------------------
SELECT
    t.claimNumber,
    t.claimReferenceNumber,
    t.source_table_update_ts,
    resh.his_id,
    resh.outstanding_amount,
    resh.settle_changed,
    'financial_transaction' AS [data.type],
    CASE
        WHEN cp.organ_id = 1000000000002 THEN 'vault_reciprocal_exchange'
        WHEN cp.organ_id = 1000000000001 THEN 'vault_es_insurance_company'
        ELSE ''
    END AS [data.attributes.accountCode],
    -- CAST(resh.his_id AS VARCHAR(255)) AS [data.attributes.original_transaction_id],
    null as [data.attributes.original_transaction_id],
    resh.post_date AS [data.attributes.originated_at],
    CASE
        WHEN resh.RESERVE_TYPE IN ('RC_01', 'RC_02', 'RC_03') THEN 'indemnity'
        WHEN resh.RESERVE_TYPE IN ('RC_04', 'RC_05', 'RC_06', 'RC_07') THEN 'recovery'
    END AS [data.attributes.financial_transaction_type],
    resh.ITEM_ID AS [data.attributes.remote_identifier],
    'check' AS [data.attributes.payment_method],
    CAST(1 AS BIT) AS [data.attributes.is_historical],
    CAST(exposureReferenceNumber AS VARCHAR(255)) AS exposure_id,
    resh.outstanding_amount AS reserve_amt,
    'unspecified' AS cost_category,
    LOWER(et.exposureType) +
        CASE
            WHEN resh.RESERVE_TYPE IN ('RC_01', 'RC_04', 'RC_05') THEN '_claim'
            WHEN resh.RESERVE_TYPE IN ('RC_02', 'RC_03', 'RC_05', 'RC_06') THEN '_adjusting'
        END AS cost_type,
    CASE
        WHEN resh.reserve_type IN ('RC_01', 'RC_02') AND settle.claim_type = 'LOS' AND settle_changed > 0 THEN settle_changed
        ELSE 0
    END AS paid_amt,
    CASE
        WHEN settle_item.pay_final = 4 THEN 'final'
        ELSE 'partial'
    END AS payment_type,
    CASE
        WHEN resh.reserve_type IN ('RC_04', 'RC_07') THEN 'subrogation'
        WHEN resh.reserve_type IN ('RC_05', 'RC_06') THEN 'salvage'
    END AS reserve_method,
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
FROM [edw_temp].[migration_create_financial_transaction_api_temp1] t
LEFT JOIN edw_stage.t_clm_item i ON t.exposure_id = i.item_id
LEFT JOIN edw_stage.t_clm_object obj ON i.object_id = obj.object_id
LEFT JOIN edw_stage.t_clm_case c ON obj.CASE_ID = c.CASE_ID
LEFT JOIN edw_stage.t_clm_reserve_his resh ON resh.item_id = i.item_id
LEFT JOIN edw_stage.t_clm_policy cp ON c.case_id = cp.case_id
LEFT JOIN edw_stage.t_clm_settle_item settle_item 
    ON resh.item_id = settle_item.item_id
    AND resh.business_instance_id = settle_item.settle_item_id
LEFT JOIN edw_stage.t_clm_settle_payee settle_payee ON settle_payee.settle_payee_id = settle_item.settle_payee_id
LEFT JOIN edw_stage.t_clm_settle settle ON settle.settle_id = settle_payee.settle_id
LEFT JOIN edw_stage.t_clm_party party ON party.PARTY_ID = settle_payee.PAYEE_ID
LEFT JOIN edw_stage.t_clm_party_role party_role on party_role.ROLE_CODE = party.PARTY_ROLE 
LEFT JOIN edw_stage.t_int_address tia ON tia.source_id = c.case_id
LEFT JOIN edw_stage.t_pub_address tpa ON tia.T_ADDRESS_ID = tpa.ADDRESS_ID
LEFT JOIN [edw_temp].[migration_create_financial_transaction_api_temp2] p 
    ON party.pty_PARTY_ID = p.externalReferenceNumber
LEFT JOIN [edw_temp].[migration_create_financial_transaction_api_temp3] et
    ON t.exposure_id = et.exposureId
    AND t.claimNumber = et.claimNumber
    AND t.claimReferenceNumber = et.claimReferenceNumber
;

WITH 
titem AS (
    select * from edw_stage.t_clm_item 
    where ITEM_ID = 17575971 --16708063
)
,tobject AS (
    select * from edw_stage.t_clm_object where OBJECT_ID = (select object_id from titem)
)
,tcase AS (
    select * from edw_stage.t_clm_case where CASE_ID = (select case_id from tobject)
)

-- select * from titem
-- select * from tobject
-- select * from tcase
select * from edw_stage.t_clm_reserve_his where ITEM_ID = (select item_id from titem)
;

select * from edw_stage.t_clm_reserve_his order by ITEM_ID asc, HIS_ID asc;

-- select change_type, count(1) from edw_stage.t_clm_reserve_his group by change_type;

select * from edw_stage.t_clm_item where ITEM_ID = 17575971;
select * from edw_stage.t_clm_object where OBJECT_ID = 17575970;
select * from edw_stage.t_clm_case where CASE_ID = 17575877;
select * from edw_stage.t_clm_reserve_his where ITEM_ID = 17575972;

-- select * from edw_stage.t_clm_subclaim_type;

select * from edw_core.tproduct where ebao_product_cd = '2020001';
select * from edw_stage.t_clm_policy where CASE_ID = 17575877;
select * from edw_stage.t_clm_subclaim_type where subclaim_type_code = 'SUB_HO_01';