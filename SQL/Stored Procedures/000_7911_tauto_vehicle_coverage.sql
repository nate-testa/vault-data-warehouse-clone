select top 100 * from edw_core.tetl_audit where process_nm like '%vehicle_coverage%' ORDER BY 1 DESC;
select top 100 * from edw_core.tetl_control where process_nm like '%yacht%';
-- update edw_core.tetl_control set last_source_extract_ts = '2000-01-01 00:00:00' where process_nm in ('sp_tauto_vehicle_coverage','sp_tquote_auto_vehicle_coverage','sp_tquote_auto_vehicle_coverage_wip');

-- truncate table [edw_core].[tauto_vehicle_coverage];
-- truncate table [edw_core].[tquote_auto_vehicle_coverage];


-- EXEC [edw_core].[sp_tauto_vehicle_coverage];
-- EXEC [edw_core].[sp_tquote_auto_vehicle_coverage];
-- EXEC [edw_core].[sp_tquote_auto_vehicle_coverage_wip];

select COUNT(1) from edw_core.tauto_vehicle_coverage where rater_pip_discount is not null;
select COUNT(1) from edw_core.tquote_auto_vehicle_coverage where rater_pip_discount is not null;

EXEC sp_help'edw_core.tquote_auto_vehicle_coverage';
-- policy_no, effective_dt, vehicle_unique_id, transaction_seq_no
-- quote_no, effective_dt, vehicle_unique_id, transaction_seq_no

-------backfill process----

select a.policy_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no, count(1) as ct
from (
    SELECT a.policy_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no, a.rater_pip_discount, b.RaterPIPDiscount
    -- UPDATE a SET a.rater_pip_discount = b.RaterPIPDiscount
    FROM [edw_core].[tauto_vehicle_coverage] a
    INNER JOIN [edw_temp].[tauto_vehicle_coverage_backfill_7911_temp1] b
    ON a.policy_no = b.policy_no
    AND a.effective_dt = b.effective_dt
    AND a.vehicle_unique_id = b.vehicle_unique_id
    AND a.transaction_seq_no = b.transaction_seq_no
) as a
group by a.policy_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no
having count(1) > 1
;

select count(1) from [edw_temp].[tquote_auto_vehicle_coverage_backfill_7911_temp1];
select count(1) from [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1];

select a.quote_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no, count(1) as ct
from (
    SELECT a.quote_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no, a.rater_pip_discount, b.RaterPIPDiscount
    -- UPDATE a SET a.rater_pip_discount = b.RaterPIPDiscount
    FROM [edw_core].[tquote_auto_vehicle_coverage] a
    -- INNER JOIN [edw_temp].[tquote_auto_vehicle_coverage_backfill_7911_temp1] b
    INNER JOIN [edw_temp].[tquote_auto_vehicle_coverage_wip_backfill_7911_temp1] b
    ON a.quote_no = b.quote_no
    AND a.effective_dt = b.effective_dt
    AND a.vehicle_unique_id = b.vehicle_unique_id
    AND a.transaction_seq_no = b.transaction_seq_no
) as a
group by a.quote_no, a.effective_dt, a.vehicle_unique_id, a.transaction_seq_no
having count(1) > 1
;

