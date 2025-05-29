if not exists(select *
from information_schema.table_constraints
where table_name = 'tcommercial_quote_subjectivity'
and table_schema = 'edw_commercial'
and constraint_type = 'UNIQUE'
and constraint_name = 'uidx_tcommercial_quote_subjectivity_quote_no_effective_dt' 
)
BEGIN
Alter table edw_commercial.tcommercial_quote_subjectivity
add constraint uidx_tcommercial_quote_subjectivity_quote_no_effective_dt
unique(quote_no, effective_dt)
END