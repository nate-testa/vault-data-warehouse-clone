INSERT INTO edw_core.tproduct (product_cd,product_nm,ebao_product_cd,update_ts)
SELECT 'BY' AS product_cd,'Marine Boat & Yacht' AS product_nm,'NA' as ebao_product_cd,getdate() as update_ts
where not exists(select 1 from edw_core.tproduct where product_cd = 'BY')
