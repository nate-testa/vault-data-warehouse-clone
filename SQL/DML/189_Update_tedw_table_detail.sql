
update edw_core.tedw_table_detail
set schema_nm = 'edw_commercial'
where table_nm like 'tcommercial%'

update edw_core.tedw_table_detail
set schema_nm = 'edw_core'
where table_nm not like 'tcommercial%'