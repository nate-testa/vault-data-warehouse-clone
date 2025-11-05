select top 100 * from edw_core.tetl_audit where process_nm like '%yacht%' ORDER BY 1 DESC;
select top 100 * from edw_core.tetl_control where process_nm like '%yacht%';
-- update edw_core.tetl_control set last_source_extract_ts = '1900-01-01 00:00:00' where process_nm = 'sp_tquote_marine_boat_yacht_watercraft_wip';

-- truncate table [edw_core].[tmarine_boat_yacht_watercraft];
-- truncate table [edw_core].[tquote_marine_boat_yacht_watercraft];

-- EXEC [edw_core].[sp_tmarine_boat_yacht_watercraft];
-- EXEC [edw_core].[sp_tquote_marine_boat_yacht_watercraft];
-- EXEC [edw_core].[sp_tquote_marine_boat_yacht_watercraft_wip];


select * from edw_core.tmarine_boat_yacht_watercraft;
select * from edw_core.tquote_marine_boat_yacht_watercraft;

EXEC sp_help'edw_core.tquote_marine_boat_yacht_watercraft';

select distinct [Name] from edw_stage.Product;


select distinct atvof.Field, atvof.label, atvo.ObjectType, atvof.[Group]
FROM edw_stage.AccountTransaction act
INNER JOIN edw_stage.Product p ON p.Id = act.ProductId
INNER JOIN edw_stage.AccountTransactionVersion atv ON act.Id = atv.AccountTransactionId
INNER JOIN edw_stage.AccountTransactionVersionObject atvo ON atv.Id = atvo.AccountTransactionVersionId
INNER JOIN edw_stage.AccountTransactionVersionObjectField atvof ON atvo.Id = atvof.VersionObjectId
WHERE 1=1
    -- AND act.PolicyNumber IS NOT NULL 
    -- AND act.[State] = 'ISSUED'
    AND p.[Name] = 'Marine Boat & Yacht'
    -- AND p.ProductLine = 'PersonalLines'
    -- AND atvo.ObjectType = 'Watercraft'
;

select * from edw_core.tquote_history where quote_no = 'BY200042561';
select * from edw_core.tquote_transaction where item_sk=0 and product_sk=6 and quote_history_sk = 29146;
select * from edw_core.tquote_marine_boat_yacht_coverage where quote_history_sk=29146;
select * from edw_core.tquote_marine_boat_yacht_coverage where quote_history_sk=29146;

SELECT * FROM [edw_stage].[AccountTransaction] WHERE PolicyNumber = 'BY200042561';
SELECT * FROM [edw_stage].[Account] WHERE PolicyNumber = 'BY200042561';



select * from edw_core.tquote_marine_boat_yacht_coverage where quote_history_sk=29146;
select * from edw_core.tquote_marine_boat_yacht_location where quote_history_sk=29146;
select * from edw_core.tquote_marine_boat_yacht_operator where quote_history_sk=29146;
select * from edw_core.tquote_marine_boat_yacht_watercraft where quote_history_sk=29146;

EXEC [edw_core].[sp_tquote_marine_boat_yacht_operator_wip];
EXEC [edw_core].[sp_tquote_marine_boat_yacht_coverage_wip];
EXEC [edw_core].[sp_tquote_marine_boat_yacht_watercraft_wip];