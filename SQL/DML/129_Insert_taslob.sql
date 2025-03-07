insert into edw_core.taslob
(aslob_cd,aslob_desc,product_cd,coverage_cd,update_ts)
select '091' as aslob_cd,'Inland Marine' as aslob_desc,'Homeowners' as product_cd,'HO Collections - Blanket' as coverage_cd,getdate() as update_ts
union 
select '091' as aslob_cd,'Inland Marine' as aslob_desc,'Collections' as product_cd,'Collections - Blanket',getdate() as update_ts