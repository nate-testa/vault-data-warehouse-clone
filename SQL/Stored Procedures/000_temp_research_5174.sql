select * from edw_core.tpolicy where policy_no = 'AU200023723-02';

select PolicyNumber_031, PolicyNumber_054, * from [edw_integration].[policy_ivans_auto_feed] WHERE PolicyNumber_031 = 'AU200023723-02' OR PolicyNumber_054 = 'AU200023723-02';


select distinct
    ba.bill_type,
    CASE WHEN ba.bill_type in ('Insured', 'Mortgagee') THEN 'Direct' ELSE 'Not Direct' END AS [BillingMethodCd_039]
from edw_core.tbillingaccount ba;

select PolicyNumber_031, PhoneNumber_027, create_ts, update_ts
from [edw_integration].[policy_ivans_auto_feed] 
WHERE PolicyNumber_031 in ('AU100101755-02', 'AU100225810-01', 'AU100126106-02', 'AU100128429-02')
;

WITH 
pi AS (
    SELECT 
        pi.policy_no,
        pi.home_phone_no,
        pi.mobile_phone_no,
        CASE
            WHEN pi.home_phone_no is not null THEN 'Home'
            WHEN pi.mobile_phone_no is not null THEN 'Mobile'
            ELSE ''
        END as [PhoneTypeCd_026],
        RIGHT(REPLACE(TRANSLATE(pi.home_phone_no, '+-/()#', '      '), ' ', ''), 10) as [HomePhoneNumber_027],
        RIGHT(REPLACE(TRANSLATE(pi.mobile_phone_no, '+-/()#', '      '), ' ', ''), 10) as [MobilePhoneNumber_027]
    FROM edw_core.tpolicy_insured pi 
    WHERE pi.policy_no IN ('AU100101755-02', 'AU100225810-01', 'AU100126106-02', 'AU100128429-02')
)
SELECT *,
CASE
    WHEN [HomePhoneNumber_027] IS NOT NULL
        AND LEN([HomePhoneNumber_027]) = 10
        AND LEFT([HomePhoneNumber_027], 1) NOT IN ('0', '1')
        THEN [HomePhoneNumber_027]
    WHEN [MobilePhoneNumber_027] IS NOT NULL
        AND LEN([MobilePhoneNumber_027]) = 10
        AND LEFT([MobilePhoneNumber_027], 1) NOT IN ('0', '1')
        THEN [MobilePhoneNumber_027]
    ELSE ''
END AS [PhoneNumber_027]
FROM pi
;

select 
    CASE WHEN ivans_y_account is null then 'null' else 'value' end as dif,
    count(1)
from edw_core.tbroker
WHERE ivans_y_account IS NOT NULL
group by 
    CASE WHEN ivans_y_account is null then 'null' else 'value' end
;

select top 10 * from edw_core.tpel_vehicle;

select top 10 * from edw_core.tpel_coverage ;

select broker_id, count(1) 
from edw_core.tbroker WHERE ivans_y_account IS NOT NULL
group by broker_id
-- having count(1) > 1
;



select vehicle_deleted_in, count(1)
from edw_core.tauto_vehicle_coverage
group by vehicle_deleted_in
;

