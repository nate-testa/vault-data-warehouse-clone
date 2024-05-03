UPDATE edw_core.tstate 
SET state_territory_nm = 
(CASE 
    WHEN state_cd IN ('AL', 'FL', 'GA', 'NC', 'SC', 'TN') THEN 'Southeast'
    WHEN state_cd IN ('AK', 'AZ', 'CA', 'CO', 'ID', 'MT', 'NV', 'OR', 'UT', 'WA', 'WY') THEN 'West'
    WHEN state_cd IN ('IA', 'IL', 'IN', 'KS', 'KY', 'MI', 'MN', 'MO', 'ND', 'NE', 'OH', 'SD', 'WI') THEN 'North Central'
    WHEN state_cd IN ('AR', 'LA', 'MS', 'NM', 'OK', 'TX') THEN 'South Central'
    WHEN state_cd IN ('CT', 'DC', 'DE', 'MA', 'MD', 'ME', 'NH', 'NJ', 'NY', 'PA', 'RI', 'VA', 'VT', 'WV') THEN 'Northeast'
    ELSE 'Other'
END)
;