-- insert into edw_core.tetl_control (process_nm, last_source_extract_ts, update_ts) values('py_hubspot_to_metal_note','1900-01-01 00:00:00',null);
-- UPDATE edw_core.tetl_control SET last_source_extract_ts = '', update_ts = GETDATE() WHERE process_nm = 'python_vault_load_metaldb_note_table'
select * from edw_core.tetl_control where process_nm = 'py_hubspot_to_metal_note';


SELECT
    NEWID() as Id
    ,'00000000-0000-0000-0000-000000000000' as UserId
    ,qn.hs_note_body as Content
    ,acc.id as ParentId
    ,'Account' as ObjectType
    ,GETDATE() as CreatedDate
    ,GETDATE() as UpdatedDate
    ,null as TaggedUserIds
    ,null as ExternalSourceId
    ,null as DocumentIds
    ,0 as IsExternallyShared
    ,0 as IsFlagged
    ,null as PlainTextContent
    ,qn.create_ts as notes_create_ts
FROM [edw_stage].[Account] AS acc
INNER JOIN [edw_stage].[hubspot_quote_notes] AS qn
ON acc.policynumber = qn.quote_no
AND qn.create_ts > (select last_source_extract_ts from edw_core.tetl_control where process_nm = 'py_hubspot_to_metal_note')
;

-- *** Vault_EDW ***

SELECT TOP 10 * FROM edw_core.tetl_control WHERE process_nm = 'py_hubspot_to_metal_note';
SELECT TOP 10 * FROM [edw_stage].[hubspot_quote_notes];

-- *** Vault_EDW ***


-- *** MetalDB ***

-- SELECT top 10 * FROM dbo.Note WHERE CreatedDate > '2024-09-26 00:00:00';
SELECT MAX(CreatedDate), COUNT(1) FROM dbo.Note; 

SELECT * FROM dbo.Note where ObjectType = 'Account' and TaggedUserIds is null and CreatedDate >= '2024-10-18 07:18:33.1900000';
-- *** MetalDB ***
