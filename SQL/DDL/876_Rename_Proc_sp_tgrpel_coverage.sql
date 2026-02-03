if exists(
select * from INFORMATION_SCHEMA.ROUTINES
where
	ROUTINE_SCHEMA = 'edw_core'
	and ROUTINE_NAME = 'sp_tgrpel_coverage'
)
begin
	exec sp_rename 'edw_core.sp_tgrpel_coverage','sp_tgrpel_coverage_nfp'
end