select TOP 10 * from edw_core.tetl_audit where process_nm like '%sp_policy_ivans_collection_feed%' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm in ('sp_policy_ivans_collection_feed');
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_policy_ivans_collection_feed');
EXEC sp_help 'edw_integration.policy_ivans_collections_feed';

SELECT COUNT(1) FROM edw_integration.policy_ivans_collections_feed;
SELECT * FROM edw_integration.policy_ivans_collections_feed;
-- DROP TABLE edw_integration.policy_ivans_collections_feed;

-- TRUNCATE TABLE edw_integration.policy_ivans_collections_feed;
EXEC [edw_core].[sp_policy_ivans_collection_feed];

SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp1];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp2];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp3];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp4];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp5];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp6];
SELECT COUNT(1) FROM [edw_temp].[policy_ivans_collection_temp7];

SELECT TOP 10 * FROM [edw_temp].[policy_ivans_collection_temp3] where policy_no = 'CO100122506';
SELECT TOP 10 * FROM [edw_temp].[policy_ivans_collection_temp4] where policy_no = 'CO100122506';
SELECT TOP 10 * FROM [edw_temp].[policy_ivans_collection_temp5] where policy_sk = (select policy_sk from edw_core.tpolicy where policy_no = 'CO100122506') AND transaction_seq_no = 1;;
SELECT TOP 10 * FROM [edw_temp].[policy_ivans_collection_temp6] where policy_sk = (select policy_sk from edw_core.tpolicy where policy_no = 'CO100122506') AND transaction_seq_no = 1;;

SELECT * FROM [edw_temp].[policy_ivans_collection_temp1] WHERE policy_sk = (select policy_sk from edw_core.tpolicy where policy_no = 'CO100120957') AND transaction_seq_no = 1;
SELECT * FROM [edw_temp].[policy_ivans_collection_temp2] WHERE [053_PolicyNumber] = 'CO100122506' AND transaction_seq_no = 1;

SELECT TOP 10 transaction_ts, * FROM [edw_core].tpolicy_history where policy_no = 'CO100122506';
-- update [edw_core].tpolicy_history set transaction_ts = '1800-01-01' where policy_no = 'CO100122506';
-- update [edw_core].tpolicy_history set transaction_ts = '2022-02-07 19:09:16.700' where policy_no = 'CO100122506' and transaction_seq_no = 0;
-- update [edw_core].tpolicy_history set transaction_ts = '2022-02-08 13:19:57.800' where policy_no = 'CO100122506' and transaction_seq_no = 1;

SELECT TOP 10 [053_PolicyNumber], [034_EffectiveDt], transaction_seq_no FROM [edw_temp].[policy_ivans_collection_temp2];
SELECT [053_PolicyNumber], [034_EffectiveDt], transaction_seq_no, COUNT(1) AS RC FROM [edw_temp].[policy_ivans_collection_temp2] GROUP BY [053_PolicyNumber], [034_EffectiveDt], transaction_seq_no HAVING COUNT(1) > 1;


select * from edw_core.tdate;

SELECT *
FROM (SELECT * FROM [edw_temp].[policy_ivans_collection_temp1] WHERE policy_sk = (select policy_sk from edw_core.tpolicy where policy_no = 'CO100120957') AND transaction_seq_no = 1) pt
INNER JOIN edw_core.tpolicy p ON pt.policy_sk = p.policy_sk
INNER JOIN edw_core.tbroker b ON p.broker_id = b.broker_id
LEFT JOIN edw_core.tproduct pr ON p.product_cd = pr.product_cd
LEFT JOIN edw_core.tpolicy_insured as poi ON p.policy_no = poi.policy_no
AND p.effective_dt = poi.effective_dt AND pt.transaction_seq_no = poi.transaction_seq_no
AND poi.primary_insured_in = 'Yes'
LEFT JOIN edw_core.tdate AS d1 ON pt.transaction_effective_dt_sk = d1.date_sk
LEFT JOIN edw_core.tdate AS d2 ON pt.transaction_dt_sk = d2.date_sk
LEFT JOIN [edw_core].[tpolicy_transaction_type] ptt on pt.policy_transaction_type_sk = ptt.policy_transaction_type_sk
LEFT JOIN [edw_core].[tbillingaccount] ba on p.billingaccount_sk = ba.billingaccount_sk
LEFT JOIN edw_core.tcustomer AS c ON pt.customer_sk = c.customer_sk
LEFT JOIN edw_core.tcollection_location cl on cl.policy_no = p.policy_no and cl.effective_dt = p.effective_dt
LEFT JOIN [edw_temp].[policy_ivans_collection_temp7] lh on p.policy_no = lh.policy_no
        AND p.effective_dt = lh.effective_dt AND pt.transaction_seq_no = lh.transaction_seq_no
LEFT JOIN [edw_temp].[policy_ivans_collection_temp6] AS op ON p.original_policy_no = op.original_policy_no 		
LEFT JOIN [edw_temp].[policy_ivans_collection_temp5] jhcc on pt.policy_sk = jhcc.policy_sk AND pt.effective_dt_sk = jhcc.effective_dt_sk
    AND pt.transaction_seq_no = jhcc.transaction_seq_no
LEFT JOIN [edw_temp].[policy_ivans_collection_temp3] jai on p.policy_no = jai.policy_no AND p.effective_dt = jai.effective_dt
    AND pt.transaction_seq_no = jai.transaction_seq_no
-- LEFT JOIN [edw_temp].[policy_ivans_collection_temp4] jsi on p.policy_no = jsi.policy_no AND p.effective_dt = jsi.effective_dt
--     AND pt.transaction_seq_no = jsi.transaction_seq_no
-- LEFT JOIN (
--         select broker_sk, broker_id, national_producer_no
--             ,ROW_NUMBER() OVER (PARTITION BY broker_id ORDER BY producer_sk DESC) AS rn
--         from edw_core.tproducer
--     ) tprc
-- ON p.broker_id = tprc.broker_id AND tprc.rn = 1
WHERE 1=1
-- and cast(pt.transaction_ts as datetime2(7)) > @last_source_extract_ts
AND b.ivans_y_account IS NOT NULL
;

SELECT ai.policy_no, ai.effective_dt, ai.transaction_seq_no
FROM
    edw_core.tadditional_interest ai
    INNER JOIN edw_core.tpolicy_history ph ON ai.policy_history_sk = ph.policy_history_sk
WHERE ai.policy_no = 'CO100120957'
;

select * from edw_core.tadditional_interest 
;