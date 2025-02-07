update [target]
set [target].coverage_cd = [source].snapsheet_coverage_cd,[target].aslob_cd = [source].aslob_cd,
[target].update_ts = GETDATE()
from
edw_stage.aslob_snapsheet_update [source]
inner join edw_core.taslob [target] on [source].product_cd = [target].product_cd and [source].coverage_nm = [target].coverage_cd