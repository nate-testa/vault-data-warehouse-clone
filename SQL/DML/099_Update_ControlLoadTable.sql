update edw_stage.ControlLoadTable
set active = 0
where JSON_value(SourceObjectSettings,'$.tableName') like '%t_pub_user%';


update edw_stage.ControlLoadTable
set active = 0
where JSON_value(SourceObjectSettings,'$.tableName') like '%t_pub_diary%';