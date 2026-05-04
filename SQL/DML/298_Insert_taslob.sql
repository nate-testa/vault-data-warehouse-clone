INSERT INTO edw_core.taslob
(aslob_cd, aslob_desc, product_cd, coverage_cd, update_ts)
SELECT
    '080',
    'Marine Boat & Yacht',
    'Marine Boat & Yacht',
    'Hull Value',
    GETDATE()
WHERE NOT EXISTS
(
    SELECT 1
    FROM edw_core.taslob
    WHERE aslob_cd = '080'
    AND aslob_desc ='Marine Boat & Yacht'
      AND product_cd = 'Marine Boat & Yacht'
      AND coverage_cd = 'Hull Value'
);