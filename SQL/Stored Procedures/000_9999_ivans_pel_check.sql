select top 100 * from edw_core.tetl_audit where process_nm like 'sp_tpel_vehicle' order by etl_audit_sk desc;
SELECT * FROM edw_core.tetl_control where process_nm = 'sp_tpel_vehicle';
select vehicle_deleted_in, COUNT(1) from [edw_core].[tpel_vehicle] group by vehicle_deleted_in;
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm in ('sp_tpel_vehicle');
-- truncate table [edw_core].[tpel_vehicle];
EXEC [edw_core].[sp_tpel_vehicle];


-- Error Number:2627 Error State:1 Error Severity:14 Error Procedure:edw_core.sp_tpel_vehicle Error Line:90 Error Message:Violation of UNIQUE KEY constraint 'uidx_tpel_vehicle_polno_effdt_transeq_vehno'. Cannot insert duplicate key in object 'edw_core.tpel_vehicle'. The duplicate key value is (EX100021288-02, 2022-12-02, 11, 5).

SELECT TOP 100 * FROM [edw_temp].[tpel_vehicle_temp1]
WHERE PolicyNumber = 'EX100021288-02'
AND EffectiveDate = '2022-12-02'
AND transaction_seq_no = '11'
AND [Index] = '5'
;

SELECT TOP 100 * FROM [edw_core].[tpel_vehicle]
WHERE policy_no = 'EX100021288-02'
AND effective_dt = '2022-12-02'
AND transaction_seq_no = '11'
AND vehicle_no = '5'
;


SELECT vehicle_deleted_in, count(1) FROM [edw_core].[tpel_vehicle] group by vehicle_deleted_in;

select * from [edw_temp].[policy_ivans_pel_feed_temp1];--2024-07-19 00:00:00.000


----- Create new ROW
SELECT COUNT(1) FROM edw_integration.policy_ivans_pel_feed;--39748

-- EXEC [edw_core].[sp_policy_ivans_pel_feed];

SELECT top 10 * FROM edw_integration.policy_ivans_pel_feed
WHERE PolicyNumber_033 = 'EX100212986-01'
-- and transaction_seq_no = 0
;--39285

SELECT * FROM edw_core.tpolicy WHERE policy_no = 'EX100212986-01';
select * from edw_core.tbroker where broker_id = '57278';
SELECT * FROM edw_core.tpolicy_history WHERE policy_no = 'EX100212986-01';
SELECT * FROM edw_core.tpolicy_transaction WHERE policy_sk = 112646;
select * from edw_core.tdate where date_sk in (2547,2607);
select * from edw_core.tsource_system;


SELECT *
    -- phf.policy_no, phf.effective_dt, phf.transaction_seq_no,
    -- (
    --     SELECT
    --         pv.vehicle_no as id,
    --         ph.customer_id as insuredId,
    --         pv.vehicle_type as vehicleType,
    --         pv.vehicle_vin as vin,
    --         pv.vehicle_year as modelyear,
    --         pv.vehicle_make as manufacturer,
    --         pv.vehicle_model as model  
    --     FROM edw_core.tpel_vehicle as pv
    --     INNER JOIN edw_core.tpolicy_history as ph ON pv.policy_history_sk = ph.policy_history_sk
    --     WHERE pv.policy_no = phf.policy_no
    --     AND pv.effective_dt = phf.effective_dt
    --     AND pv.transaction_seq_no = phf.transaction_seq_no
    --     FOR JSON PATH, INCLUDE_NULL_VALUES
    -- ) AS PEL_Vehicles,
    -- (
    --     SELECT
    --         pw.watercraft_no as id,
    --         ph.customer_id as insuredId,
    --         pw.watercraft_year as yearbuilt,
    --         pw.watercraft_make as manufacturer,
    --         pw.watercraft_model as model,
    --         pw.watercraft_length as [length],
    --         pw.watercraft_horsepower as horsepower
    --     FROM edw_core.tpel_watercraft as pw
    --     INNER JOIN edw_core.tpolicy_history as ph ON pw.policy_history_sk = ph.policy_history_sk
    --     WHERE pw.policy_no = phf.policy_no
    --     AND pw.effective_dt = phf.effective_dt
    --     AND pw.transaction_seq_no = phf.transaction_seq_no
    --     FOR JSON PATH, INCLUDE_NULL_VALUES
    -- ) AS PEL_Watercrafts
FROM edw_core.tpolicy_history AS phf
WHERE policy_no = 'EX100144699-02'
-- GROUP BY phf.policy_no, phf.effective_dt, phf.transaction_seq_no
;

SELECT
    pv.vehicle_no as id,
    ph.customer_id as insuredId,
    pv.vehicle_type as vehicleType,
    pv.vehicle_vin as vin,
    pv.vehicle_year as modelyear,
    pv.vehicle_make as manufacturer,
    pv.vehicle_model as model  
FROM edw_core.tpel_vehicle as pv
INNER JOIN edw_core.tpolicy_history as ph ON pv.policy_history_sk = ph.policy_history_sk
WHERE pv.policy_no = phf.policy_no
AND pv.effective_dt = phf.effective_dt
AND pv.transaction_seq_no = phf.transaction_seq_no
AND pv.policy_no = 'EX100144699-02'
;


SELECT *
FROM edw_core.tpel_vehicle as pv
WHERE pv.policy_no = 'EX100144699-02'
;

--***************************************
--****SEARCH COLUMNS BY POLICY NUMBER****
--***************************************

WITH acct AS (
    SELECT * 
    FROM edw_stage.AccountTransaction 
    WHERE PolicyNumber IN (
        'EX100021288-02'
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

--***Filters
SELECT 
    acct.PolicyNumber, acct.EffectiveDate, acct.PolicyChangeNumber, acctvo.[Index], acctvo.IsDeletedOnPolicyChange, acctvof.Field, acctvof.[Value]
    -- '****acct****' as acct, acct.*, 
    -- '****acctv****' as acctv, acctv.*, 
    -- '****acctvo****' as acctvo, acctvo.*, 
    -- '****acctvof****' as acctvof, acctvof.*,
    -- ''
FROM acct
INNER JOIN acctv ON acct.Id = acctv.AccountTransactionId
INNER JOIN acctvo ON acctv.Id = acctvo.AccountTransactionVersionId
INNER JOIN acctvof ON acctvo.id = acctvof.VersionObjectId
WHERE 1=1 
and acct.PolicyChangeNumber = 11
and acctvo.[Index] = 5
and acct.PolicyNumber is not null 
and acct.[State] ='ISSUED'
AND acctvo.ObjectType='Vehicle'
AND acctvof.Field in ('Vin')
;


select * from [edw_core].[tpolicy_history] where policy_sk = 16410 and transaction_seq_no = '11';

select * from edw_core.tpolicy where policy_no = 'EX100021288-02';


select top 1000 atvo.[UniqueId]
from edw_stage.AccountTransaction act
inner join edw_stage.Product p on p.Id=act.ProductId
inner join edw_stage.AccountTransactionVersion atv on act.Id=atv.AccountTransactionId
inner join edw_stage.AccountTransactionVersionObject atvo on atv.Id=atvo.AccountTransactionVersionId
where act.ExternalSourceId IS NOT NULL
-- and atvo.[UniqueId] is null
;

select top 10 * from edw_integration.policy_ivans_pel_feed where PolicyNumber_033 = 'EX100013174-03';
select * from edw_core.tpel_watercraft where policy_no = 'EX100013174-03';