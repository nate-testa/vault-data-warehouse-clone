-- truncate table edw_cat_model.lc360_temp_table;
-- delete from edw_cat_model.Insp_LC360_historical where inspection_update_dt = '2024-10-15';
-- delete from edw_cat_model.Insp_LC360_cleaned where inspection_update_dt = '2024-10-15';

select COUNT(1) AS CT from edw_cat_model.lc360_temp_table;
select COUNT(1) AS CT from edw_cat_model.Insp_LC360_historical;--64310
select COUNT(1) AS CT from edw_cat_model.Insp_LC360_cleaned;--50561
    


select TOP 10 * from edw_cat_model.lc360_temp_table;
select TOP 10 * from edw_cat_model.Insp_LC360_historical;
select TOP 10 * from edw_cat_model.Insp_LC360_cleaned;
    


select inspection_update_dt, COUNT(1) as ct from edw_cat_model.Insp_LC360_historical group by inspection_update_dt order by 1 desc;
/*
6045
2024-09-30	5931
2024-09-16	5765
2024-09-04	5684
2024-08-19	5518
2024-08-05	5404
2024-07-22	5284
2024-07-08	5192
2024-06-17	4929
2024-05-15	4402
2024-05-07	4334
2024-04-29	4036
2024-04-22	3952
2024-04-15	3879
*/

select inspection_update_dt, COUNT(1) as ct from edw_cat_model.Insp_LC360_cleaned group by inspection_update_dt order by 1 desc;
/*
4674
2024-09-30	4584
2024-09-16	4447
2024-09-04	4390
2024-08-19	4299
2024-08-05	4223
2024-07-22	4146
2024-07-08	4092
2024-06-17	3874
2024-05-15	3425
2024-05-07	3371
2024-04-29	3311
2024-04-22	3230
2024-04-15	3169
*/
