select top 100 * from edw_core.tetl_audit where process_nm like 'sp_policy_ivans_auto_feed' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm = 'sp_policy_ivans_auto_feed';
select COUNT(1) from [edw_integration].[policy_ivans_auto_feed];
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_policy_ivans_auto_feed');
-- truncate table [edw_integration].[policy_ivans_auto_feed];
-- EXEC [edw_core].[sp_policy_ivans_auto_feed];

SELECT TOP 10 * FROM [edw_integration].[policy_ivans_auto_feed] ;WHERE PolicyNumber_031 = 'AU100005779-04';

SELECT TOP 10 * FROM edw_core.tauto_garage_location WHERE policy_no = 'AU100005779-04';
SELECT * FROM edw_core.tpolicy WHERE policy_no in ('AU100005779-04');
SELECT * FROM edw_core.tpolicy_history WHERE policy_no in ('AU100001284-01');
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk in (SELECT policy_sk FROM edw_core.tpolicy WHERE policy_no in ('AU100005779-04'));


SELECT 
    policy_no, effective_dt, transaction_seq_no, garage_unique_id,
    CONCAT('L',ROW_NUMBER() OVER(PARTITION BY policy_no, effective_dt, transaction_seq_no ORDER BY garage_unique_id)) AS locationNo2,
    CONCAT('L',agl.garage_location_no) as locationNo,
    agl.garage_address_line1 as addr1,
    agl.garage_address_city_nm as city,
    agl.garage_address_state_cd as [state],
    agl.garage_address_zip_code as zip,
    '' as latitude,
    '' as longitude,
    agl.garage_address_county_nm as county
FROM edw_core.tauto_garage_location as agl
WHERE policy_no = 'AU100005779-04'
;


SELECT 
    policy_no, effective_dt, transaction_seq_no, garage_unique_id,
    count(1) as ct
FROM edw_core.tauto_garage_location as agl
group by policy_no, effective_dt, transaction_seq_no, garage_unique_id
having count(1) > 1
;

