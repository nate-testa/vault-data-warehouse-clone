select * from edw_core.tetl_control where process_nm like '%sp_policy_ivans_home%';
select top 1000 * from edw_core.tetl_audit where process_nm like '%sp_policy_ivans_home%' order by etl_audit_sk desc;

SELECT FROM edw_core.tpolicy WHERE policy_no in ('HO200034458','HO200033212-06');

SELECT COUNT(DISTINCT etl_audit_sk), count(1) FROM [edw_integration].[policy_ivans_home_feed];--147-147864

SELECT * FROM [edw_integration].[policy_ivans_home_feed] WHERE [PolicyNumber_053] in ('HO200034458','HO200033212-06');
SELECT * FROM [edw_integration].[policy_ivans_home_feed] WHERE [PolicyNumber_030] in ('HO200034458','HO200033212-06');



-- SELECT edw_core.fn_get_last_source_extract_ts('sp_policy_ivans_home');--2024-07-12 04:12:55.5800000

-- last_source_extract_ts >2024-04-18 05:20:31.0733333 AND last_source_extract_ts <=2024-04-19 05:23:40.9166667
-- last_source_extract_ts >2024-04-18 23:19:56.2200000 AND last_source_extract_ts <=2024-04-20 01:30:02.8000000

SELECT transaction_ts, * FROM [edw_core].[tpolicy_history] WHERE policy_no in ('HO200034458','HO200033212-06');
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp1] WHERE policy_sk in (71870,45670);
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp3] WHERE policy_sk in (71870,45670);
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp4] WHERE policy_no in ('HO200034458','HO200033212-06');
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp5] WHERE policy_no in ('HO200034458','HO200033212-06');-- no data
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp6] WHERE policy_sk in (71870,45670);
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp7] WHERE original_policy_no in ('HO200034458','HO200033212-06');--policy lost HO200033212-06
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp8] WHERE policy_no in ('HO200034458','HO200033212-06');--policy lost HO200033212-06
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp2] WHERE [030_PolicyNumber] in ('HO200034458','HO200033212-06') AND [053_PolicyNumber] IS NOT NULL;
SELECT MAX(t1.policy_history_transaction_ts), MIN(t1.policy_history_transaction_ts) FROM [edw_temp].[policy_ivans_home_temp_temp2] t1;

----***Investigation***
--0) get policy_sk
SELECT policy_sk, broker_id, * FROM [edw_core].[tpolicy] WHERE policy_no in ('HO200034458','HO200033212-06');

--1) rows inserted on 2024-06-08 into policy_history table, but transaction_ts are 2024-04-05 and 19
SELECT create_ts, update_ts, transaction_ts, * FROM [edw_core].[tpolicy_history] WHERE policy_no in ('HO200034458','HO200033212-06');

-- 2) Log shows that executions after 2024-06-08 are filtering data iqual o greater that 2024-06-08
select * from edw_core.tetl_audit where process_nm like '%sp_policy_ivans_home%' and process_start_ts >= '2024-06-01 00:00:00' order by etl_audit_sk desc;

--2) the Policies are loaded into temp1 tbl
SELECT * FROM [edw_temp].[policy_ivans_home_temp_temp1] WHERE policy_sk in (71870,45670);

--Joins the temp1 table to insert into final table temp2
WITH join_to_insert_into_2 AS
(
    select pt.*
    from [edw_temp].[policy_ivans_home_temp_temp1] as pt
    INNER JOIN edw_core.tpolicy p ON pt.policy_sk = p.policy_sk
    INNER JOIN edw_core.tbroker b ON p.broker_id = b.broker_id
    where b.ivans_y_account IS NOT NULL
)
select * from join_to_insert_into_2 where policy_sk in (71870,45670)
;



SELECT distinct p.broker_id
FROM [edw_core].[tpolicy] AS p
LEFT JOIN [edw_core].[tbroker] AS b
ON p.broker_id = p.broker_id
WHERE b.broker_id IS NULL
;


SELECT *
    -- DATEDIFF(DAY,create_ts, transaction_ts) AS Difference_in_Days
    -- ,COUNT(1) AS Row_Count
FROM [edw_core].[tpolicy_history] 
WHERE DATEDIFF(DAY,create_ts, transaction_ts) = -1085
;

SELECT ph.create_ts, MIN(ph.transaction_ts) min_td, MAX(ph.transaction_ts) max_td
FROM edw_core.tpolicy_transaction as pt	
INNER JOIN edw_core.tpolicy_history ph 
ON pt.policy_sk = ph.policy_sk 
AND pt.transaction_seq_no = ph.transaction_seq_no
WHERE pt.product_sk in (1, 5)
GROUP BY ph.create_ts
ORDER BY ph.create_ts asc
;