if not exists (
select 1 from information_schema.tables 
where table_schema = 'edw_stage'
and table_name = 'stage_majesco_agency_level_monthly_commission_balance')
begin
create table edw_stage.stage_majesco_agency_level_monthly_commission_balance(
commission_entity_code	varchar(255) null, 
commission_entity_name	varchar(255) null, 
begining_balance	varchar(255) null, 
commission_to_be_paid	varchar(255) null, 
commission_adjustment	varchar(255) null, 
commission_paid	varchar(255) null, 
ending_balance	varchar(255) null, 
month	varchar(255) null, 
create_ts	datetime null
)
end ; 