# Task-9272:

create a generic function/s in python to entry logs in tetl_audit table, 
the idea is to use this generic funtion to new proces that will load data indo EDW:

this is tetl_audit table structure:
Column_name	Type	Computed	Length	Prec	Scale	Nullable
etl_audit_sk	int	no	4	10   	0    	no
process_nm	varchar	no	255	     	     	yes
process_start_ts	datetime	no	8	     	     	yes
process_end_ts	datetime	no	8	     	     	yes
record_ct	int	no	4	10   	0    	yes
status_desc	varchar	no	255	     	     	yes
error_message_desc	varchar	no	2000	     	     	yes
parameter_desc	varchar	no	255	     	     	yes

use the next procedures to create the python funtion using similar logic
edw_core.sp_ins_tetl_audit
edw_core.sp_upd_tetl_audit
edw_core.sp_upd_error_tetl_audit