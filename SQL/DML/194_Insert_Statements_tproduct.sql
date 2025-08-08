INSERT INTO edw_core.tproduct (
    product_cd,
    product_nm,
    ebao_product_cd,
    update_ts,
    product_category_nm
)
SELECT
    N'GRPEL',
    N'Group Umbrella',
    NULL,
    GETDATE(),
    'PersonalLines'
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tproduct
    WHERE product_cd = 'GRPEL'
);
