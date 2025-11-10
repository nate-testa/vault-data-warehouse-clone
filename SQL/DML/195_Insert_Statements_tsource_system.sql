INSERT INTO edw_core.tsource_system (
    source_system_nm,
    update_ts
)
SELECT
    N'NFP',
    GETDATE()
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tsource_system
    WHERE source_system_nm = 'NFP'
);
