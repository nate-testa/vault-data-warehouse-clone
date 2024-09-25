-- select distinct policy_number,product,risk_address 
-- from edw_stage.OneShieldPolicy where policy_number in
-- (
-- select policynumber from edw_integration.claim_clue_property_feed where trim(riskAddressHseNum)='' and policytype!='J'
-- )
-- ;


-- DROP TABLE edw_stage.OneShieldPolicy_clue;

SELECT * FROM edw_stage.OneShieldPolicy_clue;

-- CREATE TABLE edw_stage.OneShieldPolicy_clue
-- (
-- policy_no                  varchar(255),
-- product                    varchar(255),
-- risk_address               varchar(255),
-- home_no                    varchar(255),
-- address_nm             varchar(255),
-- unit_no				       varchar(255),
-- city_nm                    varchar(255),
-- state_cd                   varchar(255),
-- zip_cd                     varchar(255)
-- );
