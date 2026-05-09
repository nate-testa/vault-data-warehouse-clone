
INSERT INTO edw_core.taslob
(aslob_cd, aslob_desc, product_cd, coverage_cd, update_ts)
SELECT
    '171',
    'Other Liability',
    'Excess Liability',
    'Extra Contractual',
    GETDATE()
WHERE NOT EXISTS
(
    SELECT 1
    FROM edw_core.taslob
    WHERE aslob_cd = '171'
    AND aslob_desc ='Other Liability'
      AND product_cd = 'Excess Liability'
      AND coverage_cd = 'Extra Contractual'
);

INSERT INTO edw_core.taslob
(aslob_cd, aslob_desc, product_cd, coverage_cd, update_ts)
SELECT
    '040',
    'Homeowners',
    'Homeowners',
    'Extra Contractual',
    GETDATE()
WHERE NOT EXISTS
(
    SELECT 1
    FROM edw_core.taslob
    WHERE aslob_cd = '040'
    AND aslob_desc ='Homeowners'
      AND product_cd = 'Homeowners'
      AND coverage_cd = 'Extra Contractual'
);

INSERT INTO edw_core.taslob
(aslob_cd, aslob_desc, product_cd, coverage_cd, update_ts)
SELECT
    '091',
    'Inland Marine',
    'Collections',
    'Extra Contractual',
    GETDATE()
WHERE NOT EXISTS
(
    SELECT 1
    FROM edw_core.taslob
    WHERE aslob_cd = '091'
    AND aslob_desc ='Inland Marine'
      AND product_cd = 'Collections'
      AND coverage_cd = 'Extra Contractual'
);