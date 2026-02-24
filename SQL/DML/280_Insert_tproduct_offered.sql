INSERT INTO edw_core.tproduct_offered_state
    (state_cd, homeowners_in, condo_in, auto_in, pel_in, collections_in, collections_on_endorsement_in, marine_in, update_ts)
SELECT
    final.state_cd,
    final.homeowners_in,
    final.condo_in,
    final.auto_in,
    final.pel_in,
    final.collections_in,
    final.collections_on_endorsement_in,
    final.marine_in,
    final.update_ts
FROM (
    SELECT 
        ISNULL(s.state_cd, a.state_cd) AS state_cd,
        a.homeowners_in,
        a.condo_in,
        a.auto_in,
        a.pel_in,
        a.collections_in,
        a.collections_on_endorsement_in,
        a.marine_in,
        a.update_ts
    FROM (
        VALUES 
  ('AK', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE()),
        ('HI', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE()),
        ('IA', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE()),
        ('KY', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE()),
        ('ND', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE()),
        ('NE', 'No', 'No', 'No', 'No', 'No', 'No', 'No', GETDATE())

    ) AS a(
        state_cd, 
        homeowners_in, 
        condo_in, 
        auto_in, 
        pel_in,                       -- correct order
        collections_in,               -- correct order
        collections_on_endorsement_in, 
        marine_in, 
        update_ts
    )
    LEFT JOIN edw_core.tstate s 
        ON s.state_nm = CASE WHEN a.state_cd = 'DC' THEN 'District of Columbia' ELSE a.state_cd END
) AS final
WHERE NOT EXISTS (
    SELECT 1
    FROM edw_core.tproduct_offered_state t
    WHERE t.state_cd = final.state_cd
);