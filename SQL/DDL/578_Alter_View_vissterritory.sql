CREATE OR ALTER VIEW [edw_core].[vissterritory]
AS
SELECT line, state_cd, zip_cd, territory, create_ts
FROM edw_stage.stage_iss_territory ;