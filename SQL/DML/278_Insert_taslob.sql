INSERT INTO edw_core.taslob
(aslob_cd, aslob_desc, product_cd, coverage_cd, update_ts)
SELECT
    '171',
    'Other Liability',
    'Excess Liability',
    'UM/UIM  Liability',
    GETDATE()
WHERE NOT EXISTS
(
    SELECT 1
    FROM edw_core.taslob
    WHERE aslob_cd = '171'
    AND aslob_desc ='Other Liability'
      AND product_cd = 'Excess Liability'
      AND coverage_cd = 'UM/UIM  Liability'
);
