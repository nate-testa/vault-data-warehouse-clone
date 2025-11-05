/*
    Hi team, 

    I have a couple of policy examples where the underwriter_nm on the new business transaction in tpolicy_history doesn’t line up with what is in Metal. Here are a couple:

    Sharon Reo (not an UW) - HO200033298, HO200031874, HO200026792
    Nathan Compton (not an UW) - HO200028931
    Nicholas Mabe (not an UW) - HO200028824

    Let me know if you need anything else.

    Thanks!
*/

--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'HO200033298'
        -- 'HO200031874'
        -- 'HO200028931'
    ) 
)
,acctv AS (
    SELECT * FROM edw_stage.AccountTransactionVersion 
    WHERE AccountTransactionId in (select Id from acct)
)
,acctvo AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObject 
    WHERE AccountTransactionVersionId in (select Id from acctv)
)
,acctvof AS (
    SELECT * FROM edw_stage.AccountTransactionVersionObjectField 
    WHERE VersionObjectId in (select Id from acctvo)
)

--***All
-- select * from acct;
select * from acctv;
-- select * from acctvo;
-- select * from acctvof;



--*******************************
--****FIND VALUE INTO A TABLE****
--*******************************

select *
from edw_core.tpolicy_history
where policy_no IN (
    'HO200033298'
)
;

select 
    policy_no, underwriter_nm, COUNT(1) AS Row_Count
from edw_core.tpolicy_history
where policy_no IN (
    'HO200033298',
    'HO200031874',
    'HO200026792',
    'HO200028931',
    'HO200028824'
)
group by policy_no, underwriter_nm
order by policy_no, underwriter_nm
;

SELECT DISTINCT 
    acct.PolicyNumber, acctv.UnderwriterUserId, usr.Name, COUNT(1) AS Row_Count
FROM edw_stage.AccountTransaction acct 
INNER JOIN edw_stage.Account acc ON acct.AccountId = acc.Id 
INNER JOIN edw_stage.AccountTransactionVersion acctv ON acctv.AccountTransactionId = acct.Id 
left join edw_stage.[user] usr on usr.id = acctv.UnderwriterUserId 
WHERE acct.PolicyNumber IN (
    'HO200033298',
    'HO200031874',
    'HO200026792',-- Same Values as in the UI
    'HO200028931',
    'HO200028824',-- Same Values as in MetalDB but differente as in the UI
    ''
)
GROUP BY acct.PolicyNumber, acctv.UnderwriterUserId, usr.Name
ORDER BY acct.PolicyNumber, acctv.UnderwriterUserId
;

