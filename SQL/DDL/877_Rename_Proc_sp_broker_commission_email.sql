if exists(
select * from INFORMATION_SCHEMA.ROUTINES
where
	ROUTINE_SCHEMA = 'edw_core'
	and ROUTINE_NAME = 'sp_broker_commission_email'
)
begin
	exec sp_rename 'edw_core.sp_broker_commission_email','sp_broker_commission_email_api'
end