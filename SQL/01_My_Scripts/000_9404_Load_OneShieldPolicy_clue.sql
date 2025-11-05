--Source Data
select policy_number, product, risk_address, ct, ROW_NUMBER() OVER (PARTITION BY policy_number order by ct desc) rn from 
(
    SELECT policy_number,product,risk_address, COUNT(1) ct 
    FROM edw_stage.OneShieldPolicy 
    where product='Auto' 
    and risk_address is not null 
    group by policy_number,product,risk_address
) as t
ORDER BY policy_number
;

--Final Table
SELECT TOP 10 * FROM edw_stage.OneShieldPolicy_clue WHERE product = 'Auto';

SELECT product, COUNT(1) CT FROM edw_stage.OneShieldPolicy_clue GROUP BY product;

SELECT * FROM [edw_integration].[claim_clue_auto_feed] where PolicyHolderMailAddrHseNum is null;

SELECT 
    DISTINCT 
    SUBSTRING(mailing_address_line1, 1, PATINDEX('%[^0-9]%', mailing_address_line1 + 'x') - 1) AS home_no,
    LEFT(TRIM(SUBSTRING(mailing_address_line1, PATINDEX('%[^0-9]%', mailing_address_line1), 30)),20) AS address_line_1,
    '' as address_line_2,
    LEFT(mailing_address_unit_no, 5) AS unit_no,
    LEFT(mailing_address_city_nm, 20) AS city_nm,
    LEFT(mailing_address_state_cd, 2) AS state_cd,
    LEFT(mailing_address_zip_cd,5) AS zip_cd
FROM edw_core.tpolicy
WHERE mailing_address_line1 IS NULL

;

--Delete Old Rows
-- DELETE FROM edw_stage.OneShieldPolicy_clue WHERE Product = 'Auto';


