select * from edw_core.tclaim_task;

SELECT 
    c.claim_number AS claim_no,
    tc.claim_sk AS claim_sk,
    NULL AS claim_feature_sk,
    t.exposure_id AS exposure_sk,
    t.status AS task_status,
    t.priority AS task_priority,
    t.note AS task_note,
    t.task_type_name AS task_type_nm,
    t.task_category_name AS task_category_nm,
    t.task_file_type AS task_file_type_nm,
    u1.name AS created_by_nm,
    u2.name AS completed_by_nm,
    u3.name AS assigned_to_nm,
    u4.name AS assigned_by_nm,
    u5.name AS first_assigned_by_nm,
    t.assigned_at AS assigned_at_ts,
    t.effective_at AS effective_at_ts,
    t.created_at AS created_at_ts,
    t.updated_at AS updated_at_ts,
    t.completed_at AS completed_at_ts,
    t.first_assigned_at AS first_assigned_at_ts
FROM edw_stage_snapsheet.tasks as t
INNER JOIN edw_stage_snapsheet.claims as c ON c.id = t.claim_id
INNER JOIN edw_core.tclaim as tc ON tc.claim_no = c.claim_number
LEFT JOIN edw_stage_snapsheet.users as u1 ON u1.id = t.created_by_user_id
LEFT JOIN edw_stage_snapsheet.users as u2 ON u2.id = t.completed_by_user_id
LEFT JOIN edw_stage_snapsheet.users as u3 ON u3.id = t.assigned_to_user_id
LEFT JOIN edw_stage_snapsheet.users as u4 ON u4.id = t.assigned_by_user_id
LEFT JOIN edw_stage_snapsheet.users as u5 ON u5.id = t.first_assigned_by_user_id
-- WHERE t.created_at > @last_source_extract_ts
;